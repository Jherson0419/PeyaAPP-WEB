"use server";

import { revalidatePath } from "next/cache";
import { getSessionFromCookies } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { assertBranchAuthorized, getAuthorizedBranches } from "@/lib/branch-access";
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
  return session;
}

async function resolveVendorBranchIds(session: { sub: string; role: string }) {
  const branches = await getAuthorizedBranches(session.sub, session.role);
  return branches.map((b) => b.id);
}

export async function toggleProductStatusAction(formData: FormData) {
  const session = await requireSession();
  const id = String(formData.get("id") ?? "");
  const current = String(formData.get("current") ?? "false") === "true";
  if (!id) return;
  const vendorBranchIds = await resolveVendorBranchIds(session);

  const target = await prisma.product.findUnique({
    where: { id },
    select: { id: true, storeId: true }
  });
  if (!target) return;
  if (session.role === "VENDOR" && !vendorBranchIds?.includes(String(target.storeId ?? ""))) return;

  await prisma.product.update({
    where: { id: target.id },
    data: { isActive: !current }
  });

  revalidatePath("/vendor/productos");
  revalidatePath("/admin");
}

export async function deleteProductAction(formData: FormData) {
  const session = await requireSession();
  const id = String(formData.get("id") ?? "");
  if (!id) return;
  const vendorBranchIds = await resolveVendorBranchIds(session);

  const target = await prisma.product.findUnique({
    where: { id },
    select: { id: true, storeId: true }
  });
  if (!target) return;
  if (session.role === "VENDOR" && !vendorBranchIds?.includes(String(target.storeId ?? ""))) return;

  await prisma.product.delete({ where: { id: target.id } });
  revalidatePath("/vendor");
  revalidatePath("/vendor/productos");
  revalidatePath("/admin");
}

function mapZodErrors(fieldErrors: Record<string, string[] | undefined>) {
  return {
    name: fieldErrors.name?.[0],
    description: fieldErrors.description?.[0],
    price: fieldErrors.price?.[0],
    stock: fieldErrors.stock?.[0],
    categoryId: fieldErrors.categoryId?.[0],
    storeId: fieldErrors.storeId?.[0],
    imageUrl: fieldErrors.imageUrl?.[0]
  };
}

export async function createProductAction(_: ProductActionState, formData: FormData): Promise<ProductActionState> {
  try {
    const session = await requireSession();
    const rawData = {
      name: String(formData.get("name") ?? ""),
      description: String(formData.get("description") ?? ""),
      price: String(formData.get("price") ?? ""),
      stock: String(formData.get("stock") ?? ""),
      categoryId: String(formData.get("categoryId") ?? ""),
      storeId: String(formData.get("storeId") ?? ""),
      isActive: String(formData.get("isActive") ?? "true"),
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

    const category = await prisma.productCategory.findUnique({
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

    const authorizedBranches = await getAuthorizedBranches(session.sub, session.role);
    const activeAuthorizedBranches = authorizedBranches.filter((b) => b.isActive);
    if (session.role === "VENDOR" && activeAuthorizedBranches.length === 0) {
      return {
        success: false,
        message: "No se encontró sucursal vinculada a tu cuenta VENDOR."
      };
    }
    const requestedStoreId = parsed.data.storeId.trim();
    const fallbackStoreId = activeAuthorizedBranches[0]?.id ?? "";
    const storeIdToUse = requestedStoreId || fallbackStoreId;
    if (!storeIdToUse) {
      return {
        success: false,
        message: "Debes seleccionar una tienda para continuar.",
        errors: { storeId: "Selecciona una tienda válida." }
      };
    }
    try {
      await assertBranchAuthorized({
        userId: session.sub,
        role: session.role,
        branchId: storeIdToUse
      });
    } catch (error) {
      return {
        success: false,
        message: error instanceof Error ? error.message : "No autorizado",
        errors: { storeId: "No autorizado para usar esta tienda." }
      };
    }

    await prisma.product.create({
      data: {
        name: parsed.data.name,
        description: parsed.data.description || null,
        price: parsed.data.price,
        stock: parsed.data.stock,
        isActive: parsed.data.isActive,
        categoryId: parsed.data.categoryId,
        imageUrl: parsed.data.imageUrl || null,
        storeId: storeIdToUse
      }
    });

    revalidatePath("/vendor");
    revalidatePath("/vendor/productos");
    revalidatePath("/admin");
    return { success: true, message: "¡Plato añadido al catálogo! 🚀" };
  } catch (error) {
    console.error("createProductAction error:", error);
    return { success: false, message: "Hubo un problema al conectar con Supabase ❌" };
  }
}

export async function updateProductAction(_: ProductActionState, formData: FormData): Promise<ProductActionState> {
  try {
    const session = await requireSession();
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
      storeId: String(formData.get("storeId") ?? ""),
      isActive: String(formData.get("isActive") ?? "true"),
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

    const category = await prisma.productCategory.findUnique({
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

    const current = await prisma.product.findUnique({
      where: { id },
      select: { id: true, storeId: true }
    });
    if (!current) {
      return { success: false, message: "Producto inválido." };
    }
    const vendorBranchIds = await resolveVendorBranchIds(session);
    if (session.role === "VENDOR" && !vendorBranchIds.includes(String(current.storeId ?? ""))) {
      return { success: false, message: "No autorizado para editar este producto." };
    }
    const requestedStoreId = parsed.data.storeId.trim() || String(current.storeId ?? "");
    if (!requestedStoreId) {
      return {
        success: false,
        message: "Debes seleccionar una tienda para continuar.",
        errors: { storeId: "Selecciona una tienda válida." }
      };
    }
    try {
      await assertBranchAuthorized({
        userId: session.sub,
        role: session.role,
        branchId: requestedStoreId
      });
    } catch (error) {
      return {
        success: false,
        message: error instanceof Error ? error.message : "No autorizado",
        errors: { storeId: "No autorizado para usar esta tienda." }
      };
    }

    await prisma.product.update({
      where: { id: current.id },
      data: {
        name: parsed.data.name,
        description: parsed.data.description || null,
        price: parsed.data.price,
        stock: parsed.data.stock,
        isActive: parsed.data.isActive,
        storeId: requestedStoreId,
        categoryId: parsed.data.categoryId,
        imageUrl: parsed.data.imageUrl || null
      }
    });

    revalidatePath("/vendor");
    revalidatePath("/vendor/productos");
    revalidatePath("/admin");
    return { success: true, message: "¡Producto actualizado correctamente! ✅" };
  } catch (error) {
    console.error("updateProductAction error:", error);
    return { success: false, message: "Hubo un problema al conectar con Supabase ❌" };
  }
}
