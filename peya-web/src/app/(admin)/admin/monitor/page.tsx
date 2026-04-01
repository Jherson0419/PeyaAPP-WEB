import { prisma } from "@/lib/prisma";
import { AdminBranchesMonitorMap } from "@/components/admin/admin-branches-monitor-map";

export const dynamic = "force-dynamic";

export default async function AdminMonitorPage() {
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

  const branches = rows.map((r: any) => ({
    id: r.id,
    name: r.name,
    address: r.address,
    iconUrl: r.iconUrl,
    latitude: Number(r.latitude),
    longitude: Number(r.longitude)
  }));

  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ?? "";

  return (
    <section className="space-y-6">
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Monitor</h1>
        <p className="text-sm text-slate-500">Todas las sucursales activas del sistema con su pin en el mapa.</p>
      </div>

      <AdminBranchesMonitorMap apiKey={apiKey} branches={branches} />
    </section>
  );
}

