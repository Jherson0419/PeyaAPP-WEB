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
  imageUrl: z
    .string()
    .trim()
    .url("La URL de imagen no es valida.")
    .or(z.literal(""))
    .optional()
    .default("")
});

export type ProductInput = z.infer<typeof productSchema>;
