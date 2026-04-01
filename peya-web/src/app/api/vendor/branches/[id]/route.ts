import { NextResponse } from "next/server";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { vendorBranchSchema } from "@/lib/validations";

function requireVendorSession() {
  return getSessionFromCookies().then((s) => {
    if (!s || s.role !== "VENDOR") return null;
    return s;
  });
}

function parseIdFromUrl(request: Request) {
  const parts = new URL(request.url).pathname.split("/").filter(Boolean);
  return parts[parts.length - 1] ?? "";
}

export async function PATCH(request: Request) {
  const session = await requireVendorSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  const id = parseIdFromUrl(request);
  if (!id) {
    return NextResponse.json({ error: "ID de sucursal inválido." }, { status: 400 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "JSON inválido." }, { status: 400 });
  }

  const parsed = vendorBranchSchema.safeParse(body);
  if (!parsed.success) {
    const msg = parsed.error.flatten().fieldErrors;
    return NextResponse.json({ error: "Datos inválidos.", fields: msg }, { status: 400 });
  }

  const exists = await (prisma as any).vendorBranch.findFirst({
    where: { id, userId: session.sub },
    select: { id: true }
  });
  if (!exists) {
    return NextResponse.json({ error: "Sucursal no encontrada." }, { status: 404 });
  }

  const { name, address, categoryId, iconUrl, latitude, longitude } = parsed.data;

  const category = await (prisma as any).branchCategory.findUnique({
    where: { id: categoryId },
    select: { id: true }
  });
  if (!category) {
    return NextResponse.json({ error: "La categoría seleccionada no existe." }, { status: 400 });
  }

  const updated = await (prisma as any).vendorBranch.update({
    where: { id },
    data: { name, address, categoryId, iconUrl, latitude, longitude },
    include: { category: { select: { id: true, name: true } } }
  });

  return NextResponse.json({
    id: updated.id,
    name: updated.name,
    address: updated.address,
    categoryId: updated.categoryId,
    categoryName: updated.category?.name ?? "Sin categoría",
    iconUrl: updated.iconUrl,
    latitude: Number(updated.latitude),
    longitude: Number(updated.longitude),
    isActive: updated.isActive,
    createdAt: updated.createdAt.toISOString()
  });
}

export async function DELETE(request: Request) {
  const session = await requireVendorSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  const id = parseIdFromUrl(request);
  if (!id) {
    return NextResponse.json({ error: "ID de sucursal inválido." }, { status: 400 });
  }

  const exists = await (prisma as any).vendorBranch.findFirst({
    where: { id, userId: session.sub },
    select: { id: true }
  });
  if (!exists) {
    return NextResponse.json({ error: "Sucursal no encontrada." }, { status: 404 });
  }

  await (prisma as any).vendorBranch.delete({ where: { id } });
  return NextResponse.json({ ok: true });
}
