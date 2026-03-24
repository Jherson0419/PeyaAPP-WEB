"use client";

import Image from "next/image";
import { useActionState, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, Smartphone, UploadCloud } from "lucide-react";
import { toast } from "sonner";
import type { ProductActionState } from "@/app/dashboard/productos/actions";
import { uploadProductImage } from "@/app/dashboard/productos/upload-actions";

export type CategoryOption = { id: string; name: string };

type ProductFormProps = {
  categories: CategoryOption[];
  mode: "create" | "edit";
  action: (state: ProductActionState, formData: FormData) => Promise<ProductActionState>;
  defaultValues?: {
    id?: string;
    name: string;
    description: string;
    price: string;
    stock: string;
    categoryId: string;
    imageUrl: string;
  };
  submitLabel?: string;
};

export function ProductForm({ categories, mode, action, defaultValues, submitLabel }: ProductFormProps) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [name, setName] = useState(defaultValues?.name ?? "");
  const [price, setPrice] = useState(defaultValues?.price ?? "");
  const [imageUrl, setImageUrl] = useState(defaultValues?.imageUrl ?? "");
  const [categoryId, setCategoryId] = useState(defaultValues?.categoryId ?? "");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [dragging, setDragging] = useState(false);
  const [uploadPending, setUploadPending] = useState(false);
  const [tempProductId] = useState(defaultValues?.id ?? crypto.randomUUID());

  const [saveState, saveAction, savePending] = useActionState(action, { success: false });

  useEffect(() => {
    if (!saveState.message) return;
    if (saveState.success) {
      toast.success(saveState.message);
      router.push("/dashboard/productos");
      router.refresh();
      return;
    }
    toast.error(saveState.message);
  }, [router, saveState]);

  const categoryName = useMemo(() => {
    const c = categories.find((x) => x.id === categoryId);
    return c?.name ?? "Categoría";
  }, [categories, categoryId]);

  const priceDisplay = useMemo(() => {
    const n = parseFloat(price.replace(",", "."));
    if (Number.isFinite(n)) return n.toFixed(2);
    return "0.00";
  }, [price]);

  const handleFilePick = (file: File | null) => {
    if (!file) return;
    const localPreviewUrl = URL.createObjectURL(file);
    setImageUrl(localPreviewUrl);
    setSelectedFile(file);
  };

  return (
    <div className="grid gap-8 xl:grid-cols-5">
      <div className="space-y-8 lg:col-span-3">
        <form
          ref={formRef}
          action={saveAction}
          onSubmit={async (event) => {
            event.preventDefault();
            const form = formRef.current;
            if (!form || savePending || uploadPending) return;

            const formData = new FormData(form);
            if (selectedFile) {
              setUploadPending(true);
              const upload = await uploadProductImage(selectedFile, tempProductId);
              setUploadPending(false);

              if (!upload.success || !upload.imageUrl) {
                toast.error(upload.message ?? "Hubo un problema al conectar con Supabase ❌");
                return;
              }

              formData.set("imageUrl", upload.imageUrl);
              setImageUrl(upload.imageUrl);
              setSelectedFile(null);
              toast.success("Imagen subida correctamente.");
            }

            saveAction(formData);
          }}
          className="space-y-8"
        >
          {mode === "edit" && defaultValues?.id ? <input type="hidden" name="id" value={defaultValues.id} /> : null}
          <input type="hidden" name="imageUrl" value={imageUrl} />

          <section className="rounded-2xl border border-slate-100 bg-white p-7 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold tracking-tight text-slate-900">Información básica</h2>
            <div className="space-y-4">
              <div>
                <label className="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-500">Nombre</label>
                <input
                  name="name"
                  required
                  maxLength={50}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Ej: Lomo saltado"
                  className="h-12 w-full rounded-xl border-slate-200 focus:border-teal-300 focus:ring-2 focus:ring-teal-200"
                />
                {saveState.errors?.name ? <p className="mt-1 text-xs text-rose-600">{saveState.errors.name}</p> : null}
              </div>
              <div>
                <label className="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-500">Descripción</label>
                <textarea
                  name="description"
                  rows={4}
                  defaultValue={defaultValues?.description ?? ""}
                  placeholder="Breve descripción para el catálogo..."
                  className="w-full resize-y rounded-xl border-slate-200 focus:border-teal-300 focus:ring-2 focus:ring-teal-200"
                />
                {saveState.errors?.description ? <p className="mt-1 text-xs text-rose-600">{saveState.errors.description}</p> : null}
              </div>
              <div>
                <label className="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-500">Categoría</label>
                <select
                  name="categoryId"
                  required
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="h-12 w-full rounded-xl border-slate-200 focus:border-teal-300 focus:ring-2 focus:ring-teal-200"
                >
                  <option value="">Selecciona una categoría</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
                {saveState.errors?.categoryId ? <p className="mt-1 text-xs text-rose-600">{saveState.errors.categoryId}</p> : null}
              </div>
            </div>
          </section>

          <section className="rounded-2xl border border-slate-100 bg-white p-7 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold tracking-tight text-slate-900">Precio y stock</h2>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-500">Precio (S/)</label>
                <input
                  name="price"
                  type="number"
                  step="0.01"
                  min="0"
                  required
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  className="h-12 w-full rounded-xl border-slate-200 focus:border-teal-300 focus:ring-2 focus:ring-teal-200"
                />
                {saveState.errors?.price ? <p className="mt-1 text-xs text-rose-600">{saveState.errors.price}</p> : null}
              </div>
              <div>
                <label className="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-500">Stock</label>
                <input
                  name="stock"
                  type="number"
                  min="0"
                  required
                  defaultValue={defaultValues?.stock ?? ""}
                  className="h-12 w-full rounded-xl border-slate-200 focus:border-teal-300 focus:ring-2 focus:ring-teal-200"
                />
                {saveState.errors?.stock ? <p className="mt-1 text-xs text-rose-600">{saveState.errors.stock}</p> : null}
              </div>
            </div>
          </section>

          <section className="rounded-2xl border border-slate-100 bg-white p-7 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold tracking-tight text-slate-900">Imagen</h2>
            <div className="space-y-3">
              <div
                className={`rounded-2xl border-2 border-dashed p-8 text-center transition ${
                  dragging ? "border-teal-400 bg-teal-50/40" : "border-slate-200 bg-slate-50/30"
                }`}
                onDragOver={(e) => {
                  e.preventDefault();
                  setDragging(true);
                }}
                onDragLeave={() => setDragging(false)}
                onDrop={(e) => {
                  e.preventDefault();
                  setDragging(false);
                  handleFilePick(e.dataTransfer.files.item(0));
                }}
              >
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => handleFilePick(e.target.files?.item(0) ?? null)}
                />
                <UploadCloud className="mx-auto mb-3 h-7 w-7 text-slate-400" />
                <p className="text-sm font-medium text-slate-700">Arrastra y suelta una imagen, o</p>
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="mt-3 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Subir imagen
                </button>
                <p className="mt-2 text-xs text-slate-500">JPG, PNG o WebP. Máximo 5MB.</p>
              </div>

              {uploadPending ? (
                <div className="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Subiendo imagen a Supabase...
                </div>
              ) : null}

              {imageUrl ? (
                <div className="flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5">
                  <div className="relative h-12 w-12 overflow-hidden rounded-lg border border-slate-100 shadow-sm">
                    <Image src={imageUrl} alt="Preview plato" fill className="object-cover" unoptimized />
                  </div>
                  <p className="text-sm text-slate-600">Vista previa lista para guardar.</p>
                </div>
              ) : null}

              {saveState.errors?.imageUrl ? <p className="mt-1 text-xs text-rose-600">{saveState.errors.imageUrl}</p> : null}
            </div>
          </section>

          <div className="flex flex-wrap gap-3">
            <button
              type="submit"
              disabled={savePending || uploadPending}
              className="rounded-xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm transition-all hover:bg-teal-700 hover:shadow"
            >
              {savePending || uploadPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {uploadPending ? "Subiendo imagen..." : "Guardando..."}
                </span>
              ) : (
                submitLabel ?? (mode === "create" ? "Crear producto" : "Guardar cambios")
              )}
            </button>
          </div>
        </form>
      </div>

      <aside className="xl:col-span-2">
        <div className="sticky top-24 space-y-3">
          <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-wide text-slate-500">
            <Smartphone className="h-4 w-4 text-teal-600" />
            Vista previa (app)
          </p>
          <div className="overflow-hidden rounded-3xl border border-slate-100 bg-white p-4 shadow-sm">
            <div className="mx-auto w-full max-w-[250px] rounded-[2rem] border border-slate-200 bg-slate-900 p-2.5 shadow-sm">
              <div className="mb-2 h-1.5 w-12 rounded-full bg-slate-700/80 mx-auto" />
              <div className="overflow-hidden rounded-[1.5rem] border border-slate-700 bg-white">
                <div className="border-b border-slate-100 bg-slate-50 px-4 py-2 text-center text-[10px] font-medium uppercase tracking-wider text-slate-400">
              Catálogo
                </div>
                <div className="p-4">
                  <div className="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
                    <div className="relative aspect-square w-full bg-slate-100">
                      {imageUrl ? (
                        <Image src={imageUrl} alt="" fill className="object-cover" sizes="220px" unoptimized />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center text-xs text-slate-500">Sin imagen</div>
                      )}
                    </div>
                    <div className="flex flex-col gap-1.5 border-t border-slate-100 p-3.5">
                      <span className="text-[10px] font-semibold uppercase tracking-wide text-teal-600">{categoryName}</span>
                      <span className="line-clamp-2 text-sm font-semibold leading-snug text-slate-900">
                        {name.trim() || "Nombre del producto"}
                      </span>
                      <span className="pt-1 text-base font-bold text-slate-900">S/ {priceDisplay}</span>
                    </div>
                  </div>
                  <p className="mt-3 text-center text-[11px] text-slate-400">Así podría verse en la app móvil.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </div>
  );
}
