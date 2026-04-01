import { redirect } from "next/navigation";
import { VendorTiendaClient } from "@/components/vendor/vendor-tienda-client";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export default async function VendorTiendaPage() {
  const session = await getSessionFromCookies();
  if (!session || session.role !== "VENDOR") {
    redirect("/login");
  }

  const rows = await (prisma as any).vendorBranch.findMany({
    where: { userId: session.sub },
    include: { category: { select: { id: true, name: true } } },
    orderBy: { createdAt: "desc" }
  });

  const initialBranches = rows.map((r: any) => ({
    id: r.id,
    name: r.name,
    address: r.address,
    categoryId: r.categoryId,
    categoryName: r.category?.name ?? "Sin categoría",
    iconUrl: r.iconUrl,
    latitude: Number(r.latitude),
    longitude: Number(r.longitude)
  }));

  const categories = await (prisma as any).branchCategory.findMany({
    orderBy: { name: "asc" },
    select: { id: true, name: true }
  });

  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ?? "";

  return <VendorTiendaClient initialBranches={initialBranches} categories={categories} apiKey={apiKey} />;
}
