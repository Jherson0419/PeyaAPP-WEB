import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { ArrowLeft, Pencil } from "lucide-react";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ branchId: string }>;
};

export default async function AdminBranchInventoryPage({ params }: PageProps) {
  const session = await getSessionFromCookies();
  if (!session || session.role !== "ADMIN") {
    redirect("/login");
  }

  const { branchId } = await params;
  const branch = await prisma.vendorBranch.findUnique({
    where: { id: branchId },
    include: {
      user: { select: { id: true, name: true, email: true } }
    }
  });

  if (!branch) notFound();

  const products = await prisma.product.findMany({
    where: { storeId: branchId },
    include: { category: { select: { name: true } } },
    orderBy: { createdAt: "desc" }
  });

  return (
    <section className="space-y-6">
      <div>
        <Link
          href={`/admin/distribuidores/${branch.userId}`}
          className="mb-3 inline-flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-emerald-600"
        >
          <ArrowLeft className="h-4 w-4" />
          Volver a sucursales
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">{branch.name}</h1>
        <p className="mt-1 text-sm text-slate-500">
          Distribuidor: {branch.user.name} ({branch.user.email})
        </p>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-100 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[860px] text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <th className="px-5 py-3.5">Producto</th>
                <th className="px-5 py-3.5">Categoría</th>
                <th className="px-5 py-3.5">Precio</th>
                <th className="px-5 py-3.5">Stock</th>
                <th className="px-5 py-3.5">Estado</th>
                <th className="px-5 py-3.5 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {products.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-5 py-8 text-center text-slate-500">
                    Esta sucursal no tiene productos registrados.
                  </td>
                </tr>
              ) : (
                products.map((product) => (
                  <tr key={product.id}>
                    <td className="px-5 py-4 font-medium text-slate-900">{product.name}</td>
                    <td className="px-5 py-4 text-slate-600">{product.category.name}</td>
                    <td className="px-5 py-4 text-slate-800">S/ {Number(product.price).toFixed(2)}</td>
                    <td className="px-5 py-4 text-slate-700">{product.stock}</td>
                    <td className="px-5 py-4">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          product.isActive ? "bg-emerald-100 text-emerald-800" : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {product.isActive ? "Activo" : "Inactivo"}
                      </span>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <Link
                        href={`/admin/sucursales/${branch.id}/productos/${product.id}/editar`}
                        className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 transition hover:bg-slate-50"
                      >
                        <Pencil className="h-3.5 w-3.5" />
                        Editar
                      </Link>
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
