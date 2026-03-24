import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { prisma } from "@/lib/prisma";
import { ProductForm } from "@/components/dashboard/product-form";
import { updateProductAction } from "../../actions";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function EditarProductoPage({ params }: PageProps) {
  const { id } = await params;

  const [product, categories] = await Promise.all([
    prisma.product.findUnique({ where: { id } }),
    prisma.category.findMany({ orderBy: { name: "asc" } })
  ]);

  if (!product) {
    notFound();
  }

  return (
    <section className="space-y-8">
      <div>
        <Link
          href="/dashboard/productos"
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
        mode="edit"
        action={updateProductAction}
        submitLabel="Guardar cambios"
        defaultValues={{
          id: product.id,
          name: product.name,
          description: product.description ?? "",
          price: product.price.toFixed(2),
          stock: String(product.stock),
          categoryId: product.categoryId,
          imageUrl: product.imageUrl ?? ""
        }}
      />
    </section>
  );
}
