"use server";

import { revalidatePath } from "next/cache";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { productSchema, type ProductInput } from "@/lib/validations";

export type ProductActionState = {
  success: boolean;
  message?: string;
  errors?: Partial<Record<keyof ProductInput, string>>;
};

async function requireSession() {
  const session = await getSessionFromCookies();
  if (!session) {
    throw new Error("No autorizado");
  }
}

export async function toggleProductStatusAction(formData: FormData) {
  await requireSession();
  const id = String(formData.get("id") ?? "");
  const current = String(formData.get("current") ?? "false") === "true";
  if (!id) return;

  await prisma.product.update({
    where: { id },
    data: { isActive: !current }
  });

  revalidatePath("/dashboard/productos");
}

export async function deleteProductAction(formData: FormData) {
  await requireSession();
  const id = String(formData.get("id") ?? "");
  if (!id) return;

  await prisma.product.delete({ where: { id } });
  revalidatePath("/dashboard");
  revalidatePath("/dashboard/productos");
}

function mapZodErrors(fieldErrors: Record<string, string[] | undefined>) {
  return {
    name: fieldErrors.name?.[0],
    description: fieldErrors.description?.[0],
    price: fieldErrors.price?.[0],
    stock: fieldErrors.stock?.[0],
    categoryId: fieldErrors.categoryId?.[0],
    imageUrl: fieldErrors.imageUrl?.[0]
  };
}

export async function createProductAction(_: ProductActionState, formData: FormData): Promise<ProductActionState> {
  try {
    await requireSession();
    const rawData = {
      name: String(formData.get("name") ?? ""),
      description: String(formData.get("description") ?? ""),
      price: String(formData.get("price") ?? ""),
      stock: String(formData.get("stock") ?? ""),
      categoryId: String(formData.get("categoryId") ?? ""),
      imageUrl: String(formData.get("imageUrl") ?? "")
    };

    const parsed = productSchema.safeParse(rawData);
    if (!parsed.success) {
      return {
        success: false,
        message: "Revisa los campos del formulario.",
        errors: mapZodErrors(parsed.error.flatten().fieldErrors)
      };
    }

    const category = await prisma.category.findUnique({
      where: { id: parsed.data.categoryId },
      select: { id: true }
    });
    if (!category) {
      return {
        success: false,
        message: "La categoría seleccionada no existe.",
        errors: { categoryId: "Selecciona una categoría válida." }
      };
    }

    await prisma.product.create({
      data: {
        name: parsed.data.name,
        description: parsed.data.description || null,
        price: parsed.data.price,
        stock: parsed.data.stock,
        categoryId: parsed.data.categoryId,
        imageUrl: parsed.data.imageUrl || null
      }
    });

    revalidatePath("/dashboard");
    revalidatePath("/dashboard/productos");
    return { success: true, message: "¡Plato añadido al catálogo! 🚀" };
  } catch (error) {
    console.error("createProductAction error:", error);
    return { success: false, message: "Hubo un problema al conectar con Supabase ❌" };
  }
}

export async function updateProductAction(_: ProductActionState, formData: FormData): Promise<ProductActionState> {
  try {
    await requireSession();
    const id = String(formData.get("id") ?? "").trim();
    if (!id) {
      return { success: false, message: "Producto inválido." };
    }

    const rawData = {
      name: String(formData.get("name") ?? ""),
      description: String(formData.get("description") ?? ""),
      price: String(formData.get("price") ?? ""),
      stock: String(formData.get("stock") ?? ""),
      categoryId: String(formData.get("categoryId") ?? ""),
      imageUrl: String(formData.get("imageUrl") ?? "")
    };

    const parsed = productSchema.safeParse(rawData);
    if (!parsed.success) {
      return {
        success: false,
        message: "Revisa los campos del formulario.",
        errors: mapZodErrors(parsed.error.flatten().fieldErrors)
      };
    }

    const category = await prisma.category.findUnique({
      where: { id: parsed.data.categoryId },
      select: { id: true }
    });
    if (!category) {
      return {
        success: false,
        message: "La categoría seleccionada no existe.",
        errors: { categoryId: "Selecciona una categoría válida." }
      };
    }

    await prisma.product.update({
      where: { id },
      data: {
        name: parsed.data.name,
        description: parsed.data.description || null,
        price: parsed.data.price,
        stock: parsed.data.stock,
        categoryId: parsed.data.categoryId,
        imageUrl: parsed.data.imageUrl || null
      }
    });

    revalidatePath("/dashboard");
    revalidatePath("/dashboard/productos");
    return { success: true, message: "¡Producto actualizado correctamente! ✅" };
  } catch (error) {
    console.error("updateProductAction error:", error);
    return { success: false, message: "Hubo un problema al conectar con Supabase ❌" };
  }
}
