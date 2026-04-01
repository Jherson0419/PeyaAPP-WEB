import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

async function createBranchCategoryAction(formData: FormData) {
  "use server";
  const session = await getSessionFromCookies();
  if (!session || session.role !== "ADMIN") {
    redirect("/login");
  }

  const name = String(formData.get("name") ?? "").trim();
  if (!name) return;

  const existing = await (prisma as any).branchCategory.findFirst({
    where: { name: { equals: name, mode: "insensitive" } },
    select: { id: true }
  });
  if (existing) return;

  await (prisma as any).branchCategory.create({
    data: { name }
  });

  revalidatePath("/admin/configuracion");
  revalidatePath("/vendor/tienda");
}

export default async function AdminConfiguracionPage() {
  const session = await getSessionFromCookies();
  if (!session || session.role !== "ADMIN") {
    redirect("/login");
  }

  const categories = await (prisma as any).branchCategory.findMany({
    orderBy: { name: "asc" },
    select: { id: true, name: true, createdAt: true }
  });

  return (
    <section className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold text-slate-900">Categorías de sucursal</h2>
        <p className="mt-1 text-sm text-slate-500">
          Crea tipos de negocio para que los distribuidores puedan asignarlos al registrar sus sucursales.
        </p>
      </div>

      <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
        <form action={createBranchCategoryAction} className="flex flex-col gap-3 sm:flex-row sm:items-end">
          <div className="flex-1">
            <label htmlFor="category-name" className="mb-1 block text-sm font-medium text-slate-700">
              Nombre de categoría
            </label>
            <input
              id="category-name"
              name="name"
              type="text"
              placeholder="Ej. Restaurante, Centro comercial, Farmacia"
              className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 outline-none ring-emerald-500/20 focus:border-emerald-500 focus:ring-2"
              required
            />
          </div>
          <button
            type="submit"
            className="inline-flex h-11 items-center justify-center rounded-xl bg-emerald-600 px-5 text-sm font-semibold text-white transition hover:bg-emerald-700"
          >
            Añadir categoría
          </button>
        </form>
      </div>

      <div className="rounded-xl border border-slate-100 bg-white shadow-sm">
        <div className="border-b border-slate-100 px-4 py-3">
          <h3 className="text-sm font-semibold text-slate-900">Categorías registradas</h3>
          <p className="text-xs text-slate-500">{categories.length} en total</p>
        </div>
        <ul className="divide-y divide-slate-100">
          {categories.length === 0 ? (
            <li className="px-4 py-8 text-center text-sm text-slate-500">
              Aún no hay categorías. Crea la primera para habilitar la creación de sucursales en Vendor.
            </li>
          ) : (
            categories.map((c: { id: string; name: string; createdAt: Date }) => (
              <li key={c.id} className="flex items-center justify-between px-4 py-3">
                <span className="text-sm font-medium text-slate-800">{c.name}</span>
                <span className="text-xs text-slate-400">{new Date(c.createdAt).toLocaleDateString("es-PE")}</span>
              </li>
            ))
          )}
        </ul>
      </div>
    </section>
  );
}
