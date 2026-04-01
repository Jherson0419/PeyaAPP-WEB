"use server";

import { getSessionFromCookies } from "@/lib/auth";
import { uploadImage } from "@/services/storage";

export type UploadBranchIconState = {
  success: boolean;
  message?: string;
  imageUrl?: string;
};

export async function uploadBranchIconImage(file: File, branchRef: string): Promise<UploadBranchIconState> {
  try {
    const session = await getSessionFromCookies();
    if (!session || session.role !== "VENDOR") {
      return { success: false, message: "No autorizado para subir iconos." };
    }

    if (file.type !== "image/png") {
      return { success: false, message: "Solo se permite imagen PNG para icono de sucursal." };
    }
    if (file.size > 3 * 1024 * 1024) {
      return { success: false, message: "El icono supera el límite de 3MB." };
    }

    const publicUrl = await uploadImage(file, `branch-icons/${branchRef}`);
    return {
      success: true,
      imageUrl: publicUrl
    };
  } catch (error) {
    console.error("uploadBranchIconImage error:", error);
    return { success: false, message: "No se pudo subir el icono a Supabase." };
  }
}
