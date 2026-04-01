"use server";

import { getSessionFromCookies } from "@/lib/auth";
import { uploadImage } from "@/services/storage";

export type UploadImageState = {
  success: boolean;
  message?: string;
  imageUrl?: string;
};

export async function uploadProductImage(file: File, productId: string): Promise<UploadImageState> {
  try {
    const session = await getSessionFromCookies();
    if (!session) {
      return { success: false, message: "No autorizado para subir imagenes." };
    }

    if (!file.type.startsWith("image/")) {
      return { success: false, message: "Solo se permiten imagenes." };
    }
    if (file.size > 5 * 1024 * 1024) {
      return { success: false, message: "La imagen supera el limite de 5MB." };
    }
    const publicUrl = await uploadImage(file, productId);
    return {
      success: true,
      imageUrl: publicUrl
    };
  } catch (error) {
    console.error("uploadProductImage error:", error);
    return { success: false, message: "Hubo un problema al conectar con Supabase ❌" };
  }
}
