import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { prisma } from "@/lib/prisma";
import { ProductForm } from "@/components/dashboard/product-form";
import { createProductAction } from "../actions";

export const dynamic = "force-dynamic";

export default async function NuevoProductoPage() {
  const categories = await prisma.category.findMany({
    orderBy: { name: "asc" }
  });

  return (
    <section className="space-y-10">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <Link
            href="/dashboard/productos"
            className="mb-3 inline-flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-teal-600"
          >
            <ArrowLeft className="h-4 w-4" />
            Volver
          </Link>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Nuevo producto</h1>
          <p className="mt-2 text-sm text-slate-500">Completa los datos y revisa la vista previa tipo app.</p>
        </div>
      </div>

      <ProductForm categories={categories} mode="create" action={createProductAction} submitLabel="Crear producto" />
    </section>
  );
}
