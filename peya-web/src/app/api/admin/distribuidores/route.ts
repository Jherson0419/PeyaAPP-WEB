import bcrypt from "bcryptjs";
import { NextResponse } from "next/server";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

function requireAdminSession() {
  return getSessionFromCookies().then((s) => {
    if (!s || s.role !== "ADMIN") return null;
    return s;
  });
}

export async function GET() {
  const session = await requireAdminSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  const rows = await prisma.user.findMany({
    where: { role: "VENDOR" },
    orderBy: { createdAt: "desc" },
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

  return NextResponse.json(
    rows.map((r) => ({
      id: r.id,
      nombre: r.name,
      email: r.email,
      tienda: r.vendorBranches[0]?.name ?? "Sin sucursales",
      branchCount: r.vendorBranches.length,
      activo: true
    }))
  );
}

export async function POST(request: Request) {
  const session = await requireAdminSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "JSON inválido." }, { status: 400 });
  }

  const data = body as {
    nombre?: string;
    email?: string;
    password?: string;
  };

  const nombre = String(data.nombre ?? "").trim();
  const email = String(data.email ?? "").trim().toLowerCase();
  const password = String(data.password ?? "");

  if (!nombre || !email || !password) {
    return NextResponse.json({ error: "Nombre, email y contraseña son obligatorios." }, { status: 400 });
  }
  if (password.length < 8) {
    return NextResponse.json({ error: "La contraseña debe tener al menos 8 caracteres." }, { status: 400 });
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return NextResponse.json({ error: "El correo ya está registrado." }, { status: 409 });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const created = await prisma.user.create({
    data: {
      name: nombre,
      email,
      passwordHash,
      role: "VENDOR"
    },
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
    id: created.id,
    nombre: created.name,
    email: created.email,
    tienda: created.vendorBranches[0]?.name ?? "Sin sucursales",
    branchCount: created.vendorBranches.length,
    activo: true
  });
}

