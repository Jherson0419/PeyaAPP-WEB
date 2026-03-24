"use server";

import { getSupabaseServerClient } from "@/lib/supabase";

function sanitizeFileName(name: string) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9.-]/g, "-")
    .replace(/-+/g, "-");
}

export async function uploadImage(file: File, productId: string) {
  const extension = file.name.split(".").pop()?.toLowerCase() || "jpg";
  const safeName = sanitizeFileName(file.name.replace(/\.[^/.]+$/, ""));
  const filePath = `${productId}/${Date.now()}-${safeName}.${extension}`;

  const supabase = getSupabaseServerClient();
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
