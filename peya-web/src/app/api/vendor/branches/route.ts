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

export async function GET() {
  const session = await requireVendorSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
  }

  const rows = await (prisma as any).vendorBranch.findMany({
    where: { userId: session.sub },
    include: { category: { select: { id: true, name: true } } },
    orderBy: { createdAt: "desc" }
  });

  const data = rows.map((r: any) => ({
    id: r.id,
    name: r.name,
    address: r.address,
    verticalId: r.verticalId ?? null,
    categoryId: r.categoryId,
    categoryName: r.category?.name ?? "Sin categoría",
    iconUrl: r.iconUrl,
    latitude: Number(r.latitude),
    longitude: Number(r.longitude),
    isActive: r.isActive,
    createdAt: r.createdAt.toISOString()
  }));

  return NextResponse.json(data);
}

export async function POST(request: Request) {
  const session = await requireVendorSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado." }, { status: 401 });
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

  const { name, address, categoryId, iconUrl, latitude, longitude } = parsed.data;

  const category = await (prisma as any).branchCategory.findUnique({
    where: { id: categoryId },
    select: { id: true, name: true, verticalId: true }
  });
  if (!category) {
    return NextResponse.json({ error: "La categoría seleccionada no existe." }, { status: 400 });
  }

  const created = await (prisma as any).vendorBranch.create({
    data: {
      user: { connect: { id: session.sub } },
      category: { connect: { id: categoryId } },
      verticalId: category.verticalId ?? null,
      name,
      address,
      iconUrl,
      latitude,
      longitude
    }
  });

  return NextResponse.json({
    id: created.id,
    name: created.name,
    address: created.address,
    verticalId: created.verticalId ?? null,
    categoryId: created.categoryId,
    categoryName: category.name,
    iconUrl: created.iconUrl,
    latitude: Number(created.latitude),
    longitude: Number(created.longitude),
    isActive: created.isActive,
    createdAt: created.createdAt.toISOString()
  });
}
