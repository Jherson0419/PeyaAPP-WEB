import { NextResponse } from "next/server";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

function requireAdminSession() {
  return getSessionFromCookies().then((s) => {
    if (!s || s.role !== "ADMIN") return null;
    return s;
  });
}

type Params = {
  params: Promise<{ id: string }>;
};

export async function PATCH(request: Request, { params }: Params) {
  const session = await requireAdminSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  const { id } = await params;
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "JSON inválido." }, { status: 400 });
  }

  const data = body as { nombre?: string; email?: string };
  const nombre = String(data.nombre ?? "").trim();
  const email = String(data.email ?? "").trim().toLowerCase();
  if (!nombre || !email) {
    return NextResponse.json({ error: "Nombre y email son obligatorios." }, { status: 400 });
  }

  const target = await prisma.user.findUnique({
    where: { id },
    select: { id: true, role: true }
  });
  if (!target || target.role !== "VENDOR") {
    return NextResponse.json({ error: "Distribuidor no encontrado." }, { status: 404 });
  }

  const emailTaken = await prisma.user.findFirst({
    where: {
      email,
      id: { not: id }
    },
    select: { id: true }
  });
  if (emailTaken) {
    return NextResponse.json({ error: "El correo ya está en uso." }, { status: 409 });
  }

  const updated = await prisma.user.update({
    where: { id },
    data: { name: nombre, email },
    select: {
      id: true,
      name: true,
      email: true,
      vendorBranches: {
        select: { id: true, name: true },
        orderBy: { createdAt: "desc" }
      }
    }
  });

  return NextResponse.json({
    id: updated.id,
    nombre: updated.name,
    email: updated.email,
    tienda: updated.vendorBranches[0]?.name ?? "Sin sucursales",
    branchCount: updated.vendorBranches.length,
    activo: true
  });
}

export async function DELETE(_: Request, { params }: Params) {
  const session = await requireAdminSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  const { id } = await params;
  const target = await prisma.user.findUnique({
    where: { id },
    select: { id: true, role: true }
  });
  if (!target || target.role !== "VENDOR") {
    return NextResponse.json({ error: "Distribuidor no encontrado." }, { status: 404 });
  }

  await prisma.user.delete({ where: { id } });
  return NextResponse.json({ ok: true });
}

