import { z } from "zod";

export const productSchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, "El nombre es obligatorio.")
    .max(50, "El nombre no puede superar 50 caracteres."),
  description: z.string().trim().max(500, "La descripcion es demasiado larga.").optional().default(""),
  price: z
    .string()
    .trim()
    .refine((value) => !Number.isNaN(Number(value)), "Ingresa un precio valido.")
    .refine((value) => Number(value) >= 0, "El precio no puede ser negativo.")
    .transform((value) => Number(value)),
  stock: z
    .string()
    .trim()
    .refine((value) => Number.isInteger(Number(value)), "El stock debe ser un numero entero.")
    .refine((value) => Number(value) >= 0, "El stock no puede ser negativo.")
    .transform((value) => Number(value)),
  categoryId: z.string().trim().min(1, "Selecciona una categoria."),
  storeId: z.string().trim().optional().default(""),
  isActive: z
    .enum(["true", "false"])
    .optional()
    .default("true")
    .transform((value) => value === "true"),
  imageUrl: z
    .string()
    .trim()
    .url("La URL de imagen no es valida.")
    .or(z.literal(""))
    .optional()
    .default("")
});

export type ProductInput = z.infer<typeof productSchema>;

export const vendorBranchSchema = z.object({
  name: z.string().trim().min(1, "El nombre es obligatorio.").max(120),
  address: z.string().trim().min(1, "La dirección es obligatoria.").max(500),
  categoryId: z.string().trim().min(1, "Selecciona una categoría válida."),
  iconUrl: z
    .string()
    .trim()
    .min(1, "Sube una imagen para el icono de la sucursal.")
    .refine((value) => value.startsWith("/") || /^https?:\/\//.test(value), "La URL del icono no es válida."),
  latitude: z.number().gte(-90).lte(90),
  longitude: z.number().gte(-180).lte(180)
});

export type VendorBranchInput = z.infer<typeof vendorBranchSchema>;
