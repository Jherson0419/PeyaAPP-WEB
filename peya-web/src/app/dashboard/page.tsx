import Link from "next/link";
import Image from "next/image";
import { AlertTriangle, Layers, Package } from "lucide-react";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

function formatRelative(date: Date) {
  const diffMs = Date.now() - date.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return "Hace un momento";
  if (mins < 60) return `Hace ${mins} min`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `Hace ${hours} h`;
  const days = Math.floor(hours / 24);
  return `Hace ${days} d`;
}

export default async function DashboardPage() {
  const LOW_STOCK_THRESHOLD = 10;

  const [productsCount, categoriesCount, lowStockCount, latestProducts] = await Promise.all([
    prisma.product.count(),
    prisma.category.count(),
    prisma.product.count({ where: { stock: { lt: LOW_STOCK_THRESHOLD } } }),
    prisma.product.findMany({
      orderBy: { createdAt: "desc" },
      take: 6,
      include: { category: true }
    })
  ]);

  return (
    <section className="space-y-10">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Panel</h1>
        <p className="mt-2 text-sm text-slate-500">Resumen de tu catálogo y actividad reciente.</p>
      </div>

      <div className="grid auto-rows-fr gap-5 md:grid-cols-6">
        <article className="md:col-span-2 rounded-2xl border border-slate-100 bg-white p-7 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-slate-500">Total productos</p>
              <p className="mt-2 text-4xl font-extrabold tracking-tight text-slate-900">{productsCount}</p>
            </div>
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-teal-50 text-teal-700 ring-1 ring-teal-100">
              <Package className="h-6 w-6" strokeWidth={2} />
            </span>
          </div>
        </article>

        <article className="md:col-span-2 rounded-2xl border border-slate-100 bg-white p-7 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-slate-500">Categorías activas</p>
              <p className="mt-2 text-4xl font-extrabold tracking-tight text-slate-900">{categoriesCount}</p>
            </div>
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-50 text-slate-700 ring-1 ring-slate-200">
              <Layers className="h-6 w-6" strokeWidth={2} />
            </span>
          </div>
        </article>

        <article
          className={`md:col-span-2 rounded-2xl border bg-white p-7 shadow-sm ${
            lowStockCount > 0 ? "border-rose-200 ring-1 ring-rose-100" : "border-slate-200"
          }`}
        >
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-slate-500">Stock bajo</p>
              <p className="mt-2 text-4xl font-extrabold tracking-tight text-slate-900">{lowStockCount}</p>
              <p className="mt-1 text-xs text-slate-500">&lt; {LOW_STOCK_THRESHOLD} unidades</p>
            </div>
            <span
              className={`flex h-12 w-12 items-center justify-center rounded-2xl ring-1 ${
                lowStockCount > 0 ? "bg-rose-50 text-rose-600 ring-rose-100" : "bg-slate-50 text-slate-400 ring-slate-200"
              }`}
            >
              <AlertTriangle className="h-6 w-6" strokeWidth={2} />
            </span>
          </div>
        </article>

        <article className="md:col-span-6 rounded-2xl border border-slate-100 bg-white p-7 shadow-sm">
          <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 className="text-base font-semibold tracking-tight text-slate-900">Actividad reciente</h2>
              <p className="text-sm text-slate-500">Últimos movimientos en el catálogo.</p>
            </div>
            <Link
              href="/dashboard/productos"
              className="text-sm font-medium text-teal-600 transition-colors hover:text-teal-700"
            >
              Ver productos
            </Link>
          </div>
          <ul className="divide-y divide-slate-100">
            {latestProducts.length === 0 ? (
              <li className="py-8 text-center text-sm text-slate-500">Aún no hay productos.</li>
            ) : (
              latestProducts.map((product) => (
                <li key={product.id} className="flex items-center gap-4 py-4 first:pt-0 last:pb-0">
                  <div className="relative h-11 w-11 shrink-0 overflow-hidden rounded-xl border border-slate-100 bg-slate-100 shadow-sm">
                    {product.imageUrl ? (
                      <Image src={product.imageUrl} alt="" fill sizes="44px" className="object-cover" unoptimized />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-xs font-semibold text-slate-400">—</div>
                    )}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-slate-900">{product.name}</p>
                    <p className="truncate text-sm text-slate-500">
                      {product.category.name} · {formatRelative(product.createdAt)}
                    </p>
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-3 py-1 text-xs font-medium ${
                      product.isActive ? "bg-emerald-100 text-emerald-700" : "bg-slate-100 text-slate-600"
                    }`}
                  >
                    {product.isActive ? "Activo" : "Inactivo"}
                  </span>
                </li>
              ))
            )}
          </ul>
        </article>
      </div>
    </section>
  );
}
