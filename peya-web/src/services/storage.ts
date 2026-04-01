"use server";

import { getSupabaseServerClient } from "@/lib/supabase";

function sanitizeFileName(name: string) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9.-]/g, "-")
    .replace(/-+/g, "-");
}

export async function uploadImage(file: File, productId: string) {
  const supabase = getSupabaseServerClient();
  await ensureProductImagesBucket(supabase);

  const extension = file.name.split(".").pop()?.toLowerCase() || "jpg";
  const safeName = sanitizeFileName(file.name.replace(/\.[^/.]+$/, ""));
  const filePath = `${productId}/${crypto.randomUUID()}-${safeName}.${extension}`;
  const { error } = await supabase.storage.from("product-images").upload(filePath, file, {
    upsert: false,
    contentType: file.type
  });

  if (error) {
    throw new Error(error.message);
  }

  const { data } = supabase.storage.from("product-images").getPublicUrl(filePath);
  return data.publicUrl;
}

async function ensureProductImagesBucket(supabase: ReturnType<typeof getSupabaseServerClient>) {
  const { data, error } = await supabase.storage.getBucket("product-images");
  if (!error && data) return;

  throw new Error(
    'Bucket "product-images" no existe o no es accesible. Crea el bucket público en Supabase Storage antes de subir imágenes.'
  );
}
