import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ userId: string }>;
};

export default async function AdminDistribuidorBranchesPage({ params }: PageProps) {
  const session = await getSessionFromCookies();
  if (!session || session.role !== "ADMIN") {
    redirect("/login");
  }

  const { userId } = await params;
  const vendor = await prisma.user.findFirst({
    where: { id: userId, role: "VENDOR" },
    select: {
      id: true,
      name: true,
      email: true,
      vendorBranches: {
        orderBy: { createdAt: "desc" },
        select: { id: true, name: true, address: true, isActive: true }
      }
    }
  });

  if (!vendor) notFound();

  const branchIds = vendor.vendorBranches.map((b) => b.id);
  const productCountRows =
    branchIds.length > 0
      ? await prisma.product.groupBy({
          by: ["storeId"],
          where: { storeId: { in: branchIds } },
          _count: { _all: true }
        })
      : [];
  const productCountByBranchId = new Map(
    productCountRows.map((row) => [row.storeId as string, row._count._all])
  );

  return (
    <section className="space-y-6">
      <div>
        <Link
          href="/admin/distribuidores"
          className="mb-3 inline-flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-emerald-600"
        >
          <ArrowLeft className="h-4 w-4" />
          Volver a distribuidores
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">{vendor.name}</h1>
        <p className="mt-1 text-sm text-slate-500">{vendor.email}</p>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-100 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px] text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <th className="px-5 py-3.5">Sucursal</th>
                <th className="px-5 py-3.5">Dirección</th>
                <th className="px-5 py-3.5">Productos</th>
                <th className="px-5 py-3.5">Estado</th>
                <th className="px-5 py-3.5 text-right">Inventario</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {vendor.vendorBranches.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-5 py-8 text-center text-slate-500">
                    Este distribuidor aún no tiene sucursales.
                  </td>
                </tr>
              ) : (
                vendor.vendorBranches.map((branch) => (
                  <tr key={branch.id}>
                    <td className="px-5 py-4 font-medium text-slate-900">{branch.name}</td>
                    <td className="px-5 py-4 text-slate-600">{branch.address}</td>
                    <td className="px-5 py-4 text-slate-700">
                      {productCountByBranchId.get(branch.id) ?? 0}
                    </td>
                    <td className="px-5 py-4">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          branch.isActive ? "bg-emerald-100 text-emerald-800" : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {branch.isActive ? "Activa" : "Inactiva"}
                      </span>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <Link
                        href={`/admin/sucursales/${branch.id}`}
                        className="inline-flex rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-1.5 text-xs font-medium text-emerald-700 transition hover:bg-emerald-100"
                      >
                        Ver inventario
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
