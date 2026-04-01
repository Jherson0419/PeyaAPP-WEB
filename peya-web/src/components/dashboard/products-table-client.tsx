"use client";

import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";
import { Pencil, Plus, Search, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { deleteProductAction, toggleProductStatusAction } from "@/app/actions/product-actions";

type ProductRow = {
  id: string;
  name: string;
  categoryId: string;
  categoryName: string;
  price: number;
  stock: number;
  imageUrl: string | null;
  isActive: boolean;
};

type CategoryRow = { id: string; name: string };

export function ProductsTableClient({ products, categories }: { products: ProductRow[]; categories: CategoryRow[] }) {
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");

  const filteredProducts = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();
    return products.filter((product) => {
      const matchesName = product.name.toLowerCase().includes(normalizedSearch);
      const matchesCategory = category ? product.categoryId === category : true;
      return matchesName && matchesCategory;
    });
  }, [category, products, search]);

  return (
    <section className="space-y-10">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Productos</h1>
          <p className="mt-2 text-sm text-slate-500">Gestiona precios, stock y visibilidad en la app.</p>
        </div>
        <Link
          href="/vendor/productos/nuevo"
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm transition-all hover:bg-teal-700 hover:shadow"
        >
          <Plus className="h-4 w-4" strokeWidth={2} />
          Añadir producto
        </Link>
      </div>

      <div className="flex flex-col gap-3 rounded-2xl border border-slate-100 bg-white p-5 shadow-sm sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar por nombre..."
            className="h-12 w-full rounded-2xl border-slate-200 pl-10"
          />
        </div>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="h-12 rounded-2xl border-slate-200 sm:max-w-xs"
        >
          <option value="">Todas las categorías</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                <th className="px-6 py-4">Producto</th>
                <th className="hidden px-6 py-4 md:table-cell">Categoría</th>
                <th className="px-6 py-4">Precio</th>
                <th className="px-6 py-4">Stock</th>
                <th className="px-6 py-4">Estado</th>
                <th className="px-6 py-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                    No hay productos con estos filtros.
                  </td>
                </tr>
              ) : (
                filteredProducts.map((product) => (
                  <tr key={product.id} className="group transition-colors hover:bg-slate-50/80">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="relative aspect-square h-14 w-14 shrink-0 overflow-hidden rounded-lg border border-slate-100 bg-slate-100 shadow-sm">
                          {product.imageUrl ? (
                            <Image src={product.imageUrl} alt="" fill sizes="56px" className="object-cover" unoptimized />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center text-[10px] font-medium text-slate-400">—</div>
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="font-medium text-slate-900">{product.name}</p>
                          <p className="truncate text-xs text-slate-500 md:hidden">{product.categoryName}</p>
                        </div>
                      </div>
                    </td>
                    <td className="hidden px-6 py-4 text-slate-600 md:table-cell">{product.categoryName}</td>
                    <td className="px-6 py-4">
                      <span className="font-semibold text-slate-900">S/ {product.price.toFixed(2)}</span>
                    </td>
                    <td className="px-6 py-4 text-slate-700">{product.stock}</td>
                    <td className="px-6 py-4">
                      <form
                        action={async (formData) => {
                          await toggleProductStatusAction(formData);
                          toast.success("Estado actualizado.");
                        }}
                      >
                        <input type="hidden" name="id" value={product.id} />
                        <input type="hidden" name="current" value={String(product.isActive)} />
                        <button
                          type="submit"
                          className={`inline-flex rounded-full px-3 py-1 text-xs font-medium transition-all hover:opacity-90 ${
                            product.isActive ? "bg-emerald-100 text-emerald-700" : "bg-slate-100 text-slate-600"
                          }`}
                        >
                          {product.isActive ? "Activo" : "Inactivo"}
                        </button>
                      </form>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2 opacity-40 transition-opacity group-hover:opacity-100">
                        <Link
                          href={`/vendor/productos/${product.id}/editar`}
                          className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 shadow-sm transition-all hover:border-slate-300 hover:bg-slate-50"
                        >
                          <Pencil className="h-3.5 w-3.5" />
                          Editar
                        </Link>
                        <form
                          action={async (formData) => {
                            await deleteProductAction(formData);
                            toast.success("Producto eliminado.");
                          }}
                          className="inline"
                        >
                          <input type="hidden" name="id" value={product.id} />
                          <button
                            type="submit"
                            className="inline-flex items-center gap-1.5 rounded-xl border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-medium text-rose-600 transition-all hover:bg-rose-100"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                            Eliminar
                          </button>
                        </form>
                      </div>
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
