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
  params: Promise<{ id: string }>;
};

export default async function EditarProductoPage({ params }: PageProps) {
  const session = await getSessionFromCookies();
  if (!session || (session.role !== "VENDOR" && session.role !== "ADMIN")) {
    redirect("/login");
  }

  const { id } = await params;

  const [product, categories, branches] = await Promise.all([
    prisma.product.findUnique({ where: { id } }),
    prisma.productCategory.findMany({ orderBy: { name: "asc" } }),
    getAuthorizedBranches(session.sub, session.role)
  ]);

  if (!product) {
    notFound();
  }
  if (session.role === "VENDOR" && !branches.some((b) => b.id === product.storeId)) {
    notFound();
  }

  return (
    <section className="space-y-8">
      <div>
        <Link
          href="/vendor/productos"
          className="mb-3 inline-flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-teal-600"
        >
          <ArrowLeft className="h-4 w-4" />
          Volver
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Editar producto</h1>
        <p className="mt-1 text-sm text-slate-500">{product.name}</p>
      </div>

      <ProductForm
        categories={categories}
        branches={branches.map((b) => ({ id: b.id, name: b.name }))}
        role={session.role as "ADMIN" | "VENDOR"}
        mode="edit"
        action={updateProductAction}
        submitLabel="Guardar cambios"
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
