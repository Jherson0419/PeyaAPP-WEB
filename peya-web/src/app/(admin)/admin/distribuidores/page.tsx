"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Ban, Pencil, Plus, Trash2, X } from "lucide-react";
import { toast } from "sonner";

type Row = {
  id: string;
  nombre: string;
  email: string;
  tienda: string;
  activo: boolean;
  branchCount?: number;
};

export default function AdminDistribuidoresPage() {
  const [rows, setRows] = useState<Row[]>([]);
  const [panelOpen, setPanelOpen] = useState(false);
  const [form, setForm] = useState({ nombre: "", email: "", password: "" });
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    async function loadRows() {
      try {
        const res = await fetch("/api/admin/distribuidores", { cache: "no-store" });
        const json = await res.json().catch(() => []);
        if (!res.ok) {
          toast.error(typeof json?.error === "string" ? json.error : "No se pudo cargar distribuidores.");
          return;
        }
        setRows(Array.isArray(json) ? (json as Row[]) : []);
      } catch {
        toast.error("Error de red al cargar distribuidores.");
      } finally {
        setLoading(false);
      }
    }
    void loadRows();
  }, []);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    try {
      const res = await fetch("/api/admin/distribuidores", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          nombre: form.nombre,
          email: form.email,
          password: form.password
        })
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        toast.error(typeof json.error === "string" ? json.error : "No se pudo crear distribuidor.");
        return;
      }
      setRows((r) => [json as Row, ...r]);
      setForm({ nombre: "", email: "", password: "" });
      setPanelOpen(false);
      toast.success("Distribuidor creado correctamente.");
    } catch {
      toast.error("Error de red. Intenta de nuevo.");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleEdit(row: Row) {
    const nombre = window.prompt("Nuevo nombre del distribuidor:", row.nombre)?.trim();
    if (!nombre) return;
    const email = window.prompt("Nuevo correo electrónico:", row.email)?.trim().toLowerCase();
    if (!email) return;

    try {
      const res = await fetch(`/api/admin/distribuidores/${row.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ nombre, email })
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        toast.error(typeof json.error === "string" ? json.error : "No se pudo actualizar.");
        return;
      }
      setRows((curr) => curr.map((x) => (x.id === row.id ? (json as Row) : x)));
      toast.success("Distribuidor actualizado.");
    } catch {
      toast.error("Error de red al editar.");
    }
  }

  async function handleDelete(row: Row) {
    const ok = window.confirm(`¿Eliminar al distribuidor ${row.nombre}? Esta acción no se puede deshacer.`);
    if (!ok) return;
    try {
      const res = await fetch(`/api/admin/distribuidores/${row.id}`, { method: "DELETE" });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        toast.error(typeof json.error === "string" ? json.error : "No se pudo eliminar.");
        return;
      }
      setRows((curr) => curr.filter((x) => x.id !== row.id));
      toast.success("Distribuidor eliminado.");
    } catch {
      toast.error("Error de red al eliminar.");
    }
  }

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm text-slate-500">
            Dueños de restaurantes con rol VENDOR y su tienda asignada.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setPanelOpen(true)}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600"
        >
          <Plus className="h-4 w-4" strokeWidth={2.5} />
          Nuevo Distribuidor
        </button>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-100 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-gray-50/80 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <th className="px-5 py-3.5">Nombre del distribuidor</th>
                <th className="px-5 py-3.5">Correo electrónico</th>
                <th className="px-5 py-3.5">Tienda asignada</th>
                <th className="px-5 py-3.5">Estado</th>
                <th className="px-5 py-3.5 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-5 py-8 text-center text-sm text-slate-500">
                    Cargando distribuidores...
                  </td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-5 py-8 text-center text-sm text-slate-500">
                    No hay distribuidores registrados.
                  </td>
                </tr>
              ) : (
                rows.map((row) => (
                  <tr key={row.id} className="text-slate-700">
                    <td className="px-5 py-4 font-medium text-slate-900">
                      <Link
                        href={`/admin/distribuidores/${row.id}`}
                        className="text-emerald-700 underline-offset-2 hover:underline"
                      >
                        {row.nombre}
                      </Link>
                    </td>
                    <td className="px-5 py-4">{row.email}</td>
                    <td className="px-5 py-4">
                      <Link
                        href={`/admin/distribuidores/${row.id}`}
                        className="text-emerald-700 underline-offset-2 hover:underline"
                      >
                        {row.tienda}
                      </Link>
                      {typeof row.branchCount === "number" ? (
                        <p className="text-xs text-slate-500">{row.branchCount} sucursal(es)</p>
                      ) : null}
                    </td>
                    <td className="px-5 py-4">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          row.activo ? "bg-emerald-100 text-emerald-800" : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {row.activo ? "Activo" : "Inactivo"}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          className="rounded-lg p-2 text-slate-500 transition hover:bg-gray-50 hover:text-slate-900"
                          aria-label="Editar"
                          onClick={() => handleEdit(row)}
                        >
                          <Pencil className="h-4 w-4" />
                        </button>
                        <button
                          type="button"
                          className="rounded-lg p-2 text-slate-500 transition hover:bg-amber-50 hover:text-amber-800"
                          aria-label="Suspender"
                          onClick={() =>
                            setRows((r) =>
                              r.map((x) => (x.id === row.id ? { ...x, activo: !x.activo } : x))
                            )
                          }
                        >
                          <Ban className="h-4 w-4" />
                        </button>
                        <button
                          type="button"
                          className="rounded-lg p-2 text-slate-500 transition hover:bg-rose-50 hover:text-rose-700"
                          aria-label="Eliminar"
                          onClick={() => handleDelete(row)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {panelOpen ? (
        <>
          <button
            type="button"
            aria-label="Cerrar panel"
            className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-sm"
            onClick={() => setPanelOpen(false)}
          />
          <div
            className="fixed inset-y-0 right-0 z-50 flex w-full max-w-md flex-col border-l border-slate-200 bg-white shadow-xl"
            role="dialog"
            aria-modal="true"
            aria-labelledby="panel-title"
          >
            <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
              <h2 id="panel-title" className="text-lg font-semibold text-slate-900">
                Nuevo distribuidor
              </h2>
              <button
                type="button"
                onClick={() => setPanelOpen(false)}
                className="rounded-lg p-2 text-slate-500 hover:bg-gray-50"
                aria-label="Cerrar"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={handleCreate} className="flex flex-1 flex-col gap-5 p-6">
              <div>
                <label htmlFor="nombre" className="block text-sm font-medium text-slate-700">
                  Nombre
                </label>
                <input
                  id="nombre"
                  name="nombre"
                  type="text"
                  autoComplete="name"
                  value={form.nombre}
                  onChange={(e) => setForm((f) => ({ ...f, nombre: e.target.value }))}
                  className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 shadow-sm outline-none ring-emerald-500/20 transition focus:border-emerald-500 focus:ring-2"
                  placeholder="Nombre completo"
                  required
                />
              </div>
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-slate-700">
                  Email
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  value={form.email}
                  onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                  className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 shadow-sm outline-none ring-emerald-500/20 transition focus:border-emerald-500 focus:ring-2"
                  placeholder="correo@ejemplo.com"
                  required
                />
              </div>
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-slate-700">
                  Contraseña temporal
                </label>
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="new-password"
                  value={form.password}
                  onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                  className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 shadow-sm outline-none ring-emerald-500/20 transition focus:border-emerald-500 focus:ring-2"
                  placeholder="Mínimo 8 caracteres"
                  minLength={8}
                  required
                />
                <p className="mt-1.5 text-xs text-slate-500">
                  El usuario deberá cambiarla en el primer inicio de sesión.
                </p>
              </div>
              <div className="mt-auto flex gap-3 border-t border-slate-100 pt-6">
                <button
                  type="button"
                  onClick={() => setPanelOpen(false)}
                  className="flex-1 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="flex-1 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-700"
                >
                  {submitting ? "Creando..." : "Crear"}
                </button>
              </div>
            </form>
          </div>
        </>
      ) : null}
    </section>
  );
}
