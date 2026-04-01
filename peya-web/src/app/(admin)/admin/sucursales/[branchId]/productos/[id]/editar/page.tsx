import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { prisma } from "@/lib/prisma";
import { ProductForm } from "@/components/dashboard/product-form";
import { updateProductAction } from "@/app/actions/product-actions";
import { getSessionFromCookies } from "@/lib/auth";
import { getAuthorizedBranches } from "@/lib/branch-access";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ branchId: string; id: string }>;
};

export default async function AdminEditarProductoPage({ params }: PageProps) {
  const session = await getSessionFromCookies();
  if (!session || session.role !== "ADMIN") {
    redirect("/login");
  }

  const { branchId, id } = await params;

  const [product, categories, branches] = await Promise.all([
    prisma.product.findUnique({ where: { id } }),
    prisma.productCategory.findMany({ orderBy: { name: "asc" } }),
    getAuthorizedBranches(session.sub, "ADMIN")
  ]);

  if (!product) {
    notFound();
  }
  if (product.storeId !== branchId) {
    notFound();
  }

  return (
    <section className="space-y-8">
      <div>
        <Link
          href={`/admin/sucursales/${branchId}`}
          className="mb-3 inline-flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-emerald-600"
        >
          <ArrowLeft className="h-4 w-4" />
          Volver al inventario
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Editar producto (Admin)</h1>
        <p className="mt-1 text-sm text-slate-500">{product.name}</p>
      </div>

      <ProductForm
        categories={categories}
        branches={branches.map((b) => ({ id: b.id, name: b.name }))}
        role="ADMIN"
        mode="edit"
        action={updateProductAction}
        submitLabel="Guardar cambios"
        redirectPath={`/admin/sucursales/${branchId}`}
        defaultValues={{
          id: product.id,
          name: product.name,
          description: product.description ?? "",
          price: product.price.toFixed(2),
          stock: String(product.stock),
          storeId: product.storeId ?? "",
          isActive: product.isActive,
          categoryId: product.categoryId,
          imageUrl: product.imageUrl ?? ""
        }}
      />
    </section>
  );
}
