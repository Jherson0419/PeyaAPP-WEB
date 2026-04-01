"use client";

import { useState } from "react";
import { ImagePlus, MapPin, Pencil, Plus, Trash2, X } from "lucide-react";
import Image from "next/image";
import { toast } from "sonner";
import { VendorTiendaMap } from "@/components/vendor/vendor-tienda-map";
import { BRANCH_ICON_LIBRARY } from "@/lib/branch-icon-library";
import type { BranchCategoryOption, VendorBranchRow } from "@/lib/types/vendor-branch";

const defaultCenter = { lat: -8.1091, lng: -79.0215 };

function normalizeText(value: string) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function categoryVisual(categoryName: string) {
  const key = normalizeText(categoryName);
  let visualId = "restaurante";
  if (key.includes("farm")) visualId = "farmacia";
  else if (key.includes("merc")) visualId = "mercado";
  else if (key.includes("cafe")) visualId = "cafeteria";
  else if (key.includes("bode")) visualId = "bodega";
  else if (key.includes("tienda")) visualId = "tienda";
  return BRANCH_ICON_LIBRARY.find((x) => x.id === visualId) ?? BRANCH_ICON_LIBRARY[0];
}

type Props = {
  initialBranches: VendorBranchRow[];
  categories: BranchCategoryOption[];
  apiKey: string;
};

export function VendorTiendaClient({ initialBranches, categories, apiKey }: Props) {
  const [branches, setBranches] = useState<VendorBranchRow[]>(initialBranches);
  const [panelOpen, setPanelOpen] = useState(false);
  const [editingBranchId, setEditingBranchId] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");
  const [categoryId, setCategoryId] = useState(categories[0]?.id ?? "");
  const [iconUrl, setIconUrl] = useState("");
  const [iconFile, setIconFile] = useState<File | null>(null);
  const [iconPreviewUrl, setIconPreviewUrl] = useState<string | null>(null);
  const [uploadingIcon, setUploadingIcon] = useState(false);
  const [draft, setDraft] = useState(defaultCenter);
  const [submitting, setSubmitting] = useState(false);

  const isEditing = editingBranchId !== null;
  const hasCategories = categories.length > 0;

  function resetForm() {
    setName("");
    setAddress("");
    setCategoryId(categories[0]?.id ?? "");
    setIconUrl("");
    setIconFile(null);
    setIconPreviewUrl(null);
    setDraft(defaultCenter);
    setEditingBranchId(null);
  }

  function openCreatePanel() {
    if (!hasCategories) {
      toast.error("No hay categorías disponibles. Pide al admin que registre categorías.");
      return;
    }
    resetForm();
    setPanelOpen(true);
  }

  function openEditPanel(branch: VendorBranchRow) {
    if (!hasCategories) {
      toast.error("No hay categorías disponibles. Pide al admin que registre categorías.");
      return;
    }
    setEditingBranchId(branch.id);
    setName(branch.name);
    setAddress(branch.address);
    setCategoryId(branch.categoryId ?? categories[0]?.id ?? "");
    setIconUrl(branch.iconUrl ?? "");
    setIconFile(null);
    setIconPreviewUrl(branch.iconUrl ?? null);
    setDraft({ lat: branch.latitude, lng: branch.longitude });
    setPanelOpen(true);
  }

  function closePanel() {
    setPanelOpen(false);
    resetForm();
  }

  async function handleDelete(branch: VendorBranchRow) {
    const ok = window.confirm(`¿Eliminar la sucursal "${branch.name}"? Esta acción no se puede deshacer.`);
    if (!ok) return;
    try {
      const res = await fetch(`/api/vendor/branches/${branch.id}`, { method: "DELETE" });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        toast.error(typeof json.error === "string" ? json.error : "No se pudo eliminar la sucursal.");
        return;
      }
      setBranches((prev) => prev.filter((b) => b.id !== branch.id));
      toast.success("Sucursal eliminada.");
    } catch {
      toast.error("Error de red. Intenta de nuevo.");
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !address.trim()) {
      toast.error("Completa nombre y dirección.");
      return;
    }
    if (!categoryId) {
      toast.error("Selecciona una categoría.");
      return;
    }
    setSubmitting(true);
    try {
      let finalIconUrl = iconUrl.trim();
      if (iconFile) {
        setUploadingIcon(true);
        const fd = new FormData();
        fd.append("file", iconFile);
        fd.append("branchRef", editingBranchId ?? crypto.randomUUID());
        const uploadRes = await fetch("/api/vendor/branch-icon-upload", { method: "POST", body: fd });
        const uploadJson = await uploadRes.json().catch(() => ({}));
        setUploadingIcon(false);
        if (!uploadRes.ok || typeof uploadJson.imageUrl !== "string") {
          toast.error(typeof uploadJson.error === "string" ? uploadJson.error : "No se pudo subir el icono.");
          return;
        }
        finalIconUrl = uploadJson.imageUrl;
        setIconUrl(finalIconUrl);
      }
      if (!finalIconUrl) {
        toast.error("Sube un icono PNG para la sucursal.");
        return;
      }

      const method = isEditing ? "PATCH" : "POST";
      const endpoint = isEditing ? `/api/vendor/branches/${editingBranchId}` : "/api/vendor/branches";
      const res = await fetch(endpoint, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: name.trim(),
          address: address.trim(),
          categoryId,
          iconUrl: finalIconUrl,
          latitude: draft.lat,
          longitude: draft.lng
        })
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        toast.error(typeof json.error === "string" ? json.error : "No se pudo guardar la sucursal.");
        return;
      }
      const savedBranch: VendorBranchRow = {
        id: json.id,
        name: json.name,
        address: json.address,
        categoryId: json.categoryId,
        categoryName: json.categoryName ?? "Sin categoría",
        iconUrl: json.iconUrl ?? null,
        latitude: json.latitude,
        longitude: json.longitude
      };

      if (isEditing) {
        setBranches((prev) => prev.map((b) => (b.id === savedBranch.id ? savedBranch : b)));
        toast.success("Sucursal actualizada.");
      } else {
        setBranches((prev) => [savedBranch, ...prev]);
        toast.success("Sucursal creada. Ya aparece en el mapa del cliente.");
      }
      closePanel();
    } catch {
      toast.error("Error de red. Intenta de nuevo.");
    } finally {
      setUploadingIcon(false);
      setSubmitting(false);
    }
  }

  return (
    <section className="space-y-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Mi tienda · Sucursales</h1>
          <p className="mt-2 max-w-2xl text-sm text-slate-500">
            Cada sucursal guarda su ubicación exacta (latitud y longitud) para mostrarse en el mapa de la app del
            cliente y, más adelante, calcular rutas de entrega.
          </p>
        </div>
        <button
          type="button"
          onClick={openCreatePanel}
          className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-700"
        >
          <Plus className="h-4 w-4" strokeWidth={2.5} />
          Nueva sucursal
        </button>
      </div>

      {!apiKey ? (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          Configura <code className="rounded bg-amber-100 px-1">NEXT_PUBLIC_GOOGLE_MAPS_API_KEY</code> en{" "}
          <code className="rounded bg-amber-100 px-1">.env</code> para ver el mapa interactivo. Las sucursales se
          guardan igual desde el formulario (coordenadas por defecto: Trujillo).
        </div>
      ) : null}
      {!hasCategories ? (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          No hay categorías registradas para sucursales. Solicita al administrador crear categorías (Restaurante,
          Farmacia, Mercado, etc.).
        </div>
      ) : null}

      <div className="grid gap-6 lg:grid-cols-2">
        {apiKey ? (
          <VendorTiendaMap
            apiKey={apiKey}
            branches={branches}
            panelOpen={panelOpen}
            draft={draft}
            setDraft={setDraft}
          />
        ) : (
          <div className="overflow-hidden rounded-xl border border-slate-100 bg-white shadow-sm">
            <div className="flex items-center gap-2 border-b border-slate-100 px-4 py-3">
              <MapPin className="h-4 w-4 text-teal-600" />
              <h2 className="text-sm font-semibold text-slate-900">Mapa</h2>
            </div>
            <div className="flex h-[min(240px,40vh)] items-center justify-center bg-slate-100 p-6 text-center text-sm text-slate-500">
              Añade la API key de Google Maps para previsualizar la ubicación.
            </div>
          </div>
        )}

        <div className="rounded-xl border border-slate-100 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-4 py-3">
            <h2 className="text-sm font-semibold text-slate-900">Sucursales registradas</h2>
            <p className="text-xs text-slate-500">{branches.length} en total</p>
          </div>
          <ul className="max-h-[min(420px,60vh)] divide-y divide-slate-100 overflow-y-auto">
            {branches.length === 0 ? (
              <li className="px-4 py-8 text-center text-sm text-slate-500">
                Aún no hay sucursales. Pulsa &quot;Nueva sucursal&quot; para crear la primera.
              </li>
            ) : (
              branches.map((b) => (
                <li key={b.id} className="px-4 py-3">
                  <div className="flex items-start gap-3">
                    {b.iconUrl ? (
                      <img
                        src={b.iconUrl}
                        alt=""
                        className="mt-0.5 h-6 w-6 shrink-0 rounded-md border border-slate-200 bg-white p-0.5"
                      />
                    ) : (
                      <span className="mt-0.5 h-6 w-6 shrink-0 rounded-md border border-slate-200 bg-slate-50" />
                    )}
                    <div className="min-w-0">
                      <p className="font-medium text-slate-900">{b.name}</p>
                      <p className="text-sm text-slate-600">{b.address}</p>
                      <p className="mt-0.5 text-xs font-medium text-teal-700">{b.categoryName ?? "Sin categoría"}</p>
                    </div>
                    <div className="ml-auto flex items-center gap-1">
                      <button
                        type="button"
                        onClick={() => openEditPanel(b)}
                        className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
                        aria-label={`Editar ${b.name}`}
                        title="Editar sucursal"
                      >
                        <Pencil className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDelete(b)}
                        className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-rose-200 text-rose-600 transition hover:bg-rose-50"
                        aria-label={`Eliminar ${b.name}`}
                        title="Eliminar sucursal"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                  <p className="mt-1 font-mono text-xs text-slate-400">
                    {b.latitude.toFixed(6)}, {b.longitude.toFixed(6)}
                  </p>
                </li>
              ))
            )}
          </ul>
        </div>
      </div>

      {panelOpen ? (
        <>
          <div className="fixed bottom-0 left-0 right-0 z-50 max-h-[85vh] overflow-y-auto rounded-t-2xl border border-slate-200 bg-white p-6 shadow-2xl sm:left-auto sm:right-6 sm:top-24 sm:max-h-[calc(100vh-8rem)] sm:w-full sm:max-w-md sm:rounded-2xl">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-slate-900">
                {isEditing ? "Editar sucursal" : "Nueva sucursal"}
              </h3>
              <button
                type="button"
                onClick={closePanel}
                className="rounded-lg p-2 text-slate-500 hover:bg-slate-50"
                aria-label="Cerrar"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label htmlFor="branch-name" className="block text-sm font-medium text-slate-700">
                  Nombre de la sucursal
                </label>
                <input
                  id="branch-name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 shadow-sm outline-none ring-teal-500/20 focus:border-teal-500 focus:ring-2"
                  placeholder="Ej. Local Centro"
                  required
                />
              </div>
              <div>
                <label htmlFor="branch-address" className="block text-sm font-medium text-slate-700">
                  Dirección
                </label>
                <textarea
                  id="branch-address"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  rows={3}
                  className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 shadow-sm outline-none ring-teal-500/20 focus:border-teal-500 focus:ring-2"
                  placeholder="Calle, número, referencia…"
                  required
                />
              </div>
              <div>
                <p className="block text-sm font-medium text-slate-700">Categoría de sucursal</p>
                <div className="mt-2 grid grid-cols-3 gap-2">
                  {categories.map((c) => {
                    const active = categoryId === c.id;
                    const visual = categoryVisual(c.name);
                    return (
                      <button
                        key={c.id}
                        type="button"
                        onClick={() => setCategoryId(c.id)}
                        className={`rounded-xl border p-2 text-left transition ${
                          active
                            ? "border-emerald-500 bg-emerald-50 ring-1 ring-emerald-200"
                            : "border-slate-200 bg-white hover:border-slate-300"
                        }`}
                      >
                        <Image
                          src={visual.iconUrl}
                          alt={c.name}
                          width={20}
                          height={20}
                          className="h-5 w-5 rounded border border-slate-200 bg-white p-0.5"
                        />
                        <p className="mt-1 truncate text-xs font-medium text-slate-700">{c.name}</p>
                      </button>
                    );
                  })}
                </div>
              </div>
              <div>
                <p className="block text-sm font-medium text-slate-700">Icono de sucursal</p>
                <label className="mt-2 flex cursor-pointer items-center gap-2 rounded-xl border border-dashed border-slate-300 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 transition hover:bg-slate-100">
                  <ImagePlus className="h-4 w-4 text-teal-700" />
                  <span>Subir imagen PNG</span>
                  <input
                    type="file"
                    accept="image/png"
                    className="hidden"
                    onChange={(e) => {
                      const file = e.target.files?.[0] ?? null;
                      if (!file) return;
                      if (file.type !== "image/png") {
                        toast.error("Solo se permite PNG.");
                        return;
                      }
                      setIconFile(file);
                      setIconPreviewUrl(URL.createObjectURL(file));
                    }}
                  />
                </label>
                <div className="mt-2 flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-3 py-2">
                  <div className="h-10 w-10 overflow-hidden rounded-lg border border-slate-200 bg-slate-50">
                    {iconPreviewUrl || iconUrl ? (
                      <img src={iconPreviewUrl ?? iconUrl} alt="Vista previa de icono" className="h-full w-full object-cover" />
                    ) : null}
                  </div>
                  <p className="text-xs text-slate-500">
                    {iconFile
                      ? `Archivo listo: ${iconFile.name}`
                      : iconUrl
                        ? "Usando icono actual guardado."
                        : "Aún no subiste un icono."}
                  </p>
                </div>
              </div>
              <div className="rounded-xl bg-slate-50 px-3 py-2 text-xs text-slate-600">
                <span className="font-medium text-slate-700">Coordenadas seleccionadas:</span>{" "}
                <span className="font-mono">
                  {draft.lat.toFixed(6)}, {draft.lng.toFixed(6)}
                </span>
              </div>
              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={closePanel}
                  className="flex-1 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={submitting || uploadingIcon}
                  className="flex-1 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-emerald-700 disabled:opacity-60"
                >
                  {uploadingIcon ? "Subiendo icono…" : submitting ? "Guardando…" : isEditing ? "Guardar cambios" : "Guardar sucursal"}
                </button>
              </div>
            </form>
          </div>
        </>
      ) : null}
    </section>
  );
}
