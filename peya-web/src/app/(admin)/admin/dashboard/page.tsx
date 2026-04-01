import { Bike, Store, TrendingUp } from "lucide-react";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

function orderStatusLabel(status: string) {
  const map: Record<string, string> = {
    PENDING: "Pendiente",
    PREPARING: "Preparando",
    ON_WAY: "En camino",
    DELIVERED: "Entregado"
  };
  return map[status] ?? status;
}

function statusBadgeClass(status: string) {
  switch (status) {
    case "DELIVERED":
      return "bg-emerald-100 text-emerald-800";
    case "ON_WAY":
      return "bg-blue-100 text-blue-800";
    case "PREPARING":
      return "bg-amber-100 text-amber-800";
    default:
      return "bg-slate-100 text-slate-700";
  }
}

export default async function AdminDashboardPage() {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const [vendorsActive, ordersTodayCount, ridersOnline, recentOrders] = await Promise.all([
    prisma.user.count({ where: { role: "VENDOR" } }),
    prisma.order.count({ where: { createdAt: { gte: todayStart } } }),
    prisma.riderProfile.count({ where: { isAvailable: true } }),
    prisma.order.findMany({
      orderBy: { createdAt: "desc" },
      take: 6,
      include: { store: true }
    })
  ]);

  const ventasDiaDemo = "8,240.50";

  return (
    <section className="space-y-8">
      <div>
        <p className="text-sm text-slate-500">Resumen operativo de la plataforma</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <article className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-slate-500">Distribuidores activos</p>
              <p className="mt-2 text-3xl font-bold tracking-tight text-slate-900">{vendorsActive}</p>
              <p className="mt-1 text-xs text-slate-500">Cuentas con rol VENDOR</p>
            </div>
            <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100">
              <Store className="h-6 w-6" strokeWidth={2} />
            </span>
          </div>
        </article>

        <article className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-slate-500">Ventas globales del día</p>
              <p className="mt-2 text-3xl font-bold tracking-tight text-slate-900">
                S/ {ventasDiaDemo}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                Demo · {ordersTodayCount} pedidos hoy
              </p>
            </div>
            <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-slate-50 text-slate-700 ring-1 ring-slate-200">
              <TrendingUp className="h-6 w-6" strokeWidth={2} />
            </span>
          </div>
        </article>

        <article className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm sm:col-span-2 xl:col-span-1">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-slate-500">Repartidores conectados</p>
              <p className="mt-2 text-3xl font-bold tracking-tight text-slate-900">{ridersOnline}</p>
              <p className="mt-1 text-xs text-slate-500">Disponibles ahora</p>
            </div>
            <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-sky-50 text-sky-700 ring-1 ring-sky-100">
              <Bike className="h-6 w-6" strokeWidth={2} />
            </span>
          </div>
        </article>
      </div>

      <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
        <div className="mb-4">
          <h2 className="text-base font-semibold text-slate-900">Ingresos semanales</h2>
          <p className="text-sm text-slate-500">Área reservada para un gráfico de ingresos (próximamente).</p>
        </div>
        <div className="flex min-h-[220px] items-center justify-center rounded-xl border border-dashed border-slate-200 bg-gray-50/80">
          <p className="text-sm text-slate-400">Gráfico de ingresos semanales</p>
        </div>
      </div>

      <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
        <h2 className="text-base font-semibold text-slate-900">Últimos pedidos en la plataforma</h2>
        <p className="mb-4 text-sm text-slate-500">Pedidos más recientes (montos de demostración).</p>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[520px] text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <th className="pb-3 pr-4">ID pedido</th>
                <th className="pb-3 pr-4">Tienda</th>
                <th className="pb-3 pr-4">Monto</th>
                <th className="pb-3">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {recentOrders.length === 0 ? (
                <tr>
                  <td colSpan={4} className="py-8 text-center text-slate-500">
                    No hay pedidos registrados.
                  </td>
                </tr>
              ) : (
                recentOrders.map((order, i) => (
                  <tr key={order.id} className="text-slate-700">
                    <td className="py-3 pr-4 font-mono text-xs text-slate-600">
                      {order.id.slice(0, 8)}…
                    </td>
                    <td className="py-3 pr-4 font-medium text-slate-900">{order.store.name}</td>
                    <td className="py-3 pr-4">S/ {(24.9 + i * 7.25).toFixed(2)}</td>
                    <td className="py-3">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${statusBadgeClass(order.status)}`}
                      >
                        {orderStatusLabel(order.status)}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}
