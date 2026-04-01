import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

/** Listado público de sucursales activas (mapa cliente / app móvil). */
export async function GET() {
  const rows = await (prisma as any).vendorBranch.findMany({
    where: { isActive: true },
    orderBy: { createdAt: "desc" },
    select: {
      id: true,
      name: true,
      address: true,
      iconUrl: true,
      latitude: true,
      longitude: true
    }
  });

  const data = rows.map((r: any) => ({
    id: r.id,
    name: r.name,
    address: r.address,
    iconUrl: r.iconUrl,
    latitude: Number(r.latitude),
    longitude: Number(r.longitude)
  }));

  return NextResponse.json(data, {
    headers: {
      "Cache-Control": "public, s-maxage=60, stale-while-revalidate=120"
    }
  });
}
