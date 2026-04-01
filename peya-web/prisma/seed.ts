import bcrypt from "bcryptjs";
import { PrismaClient, Role } from "@prisma/client";

const prisma = new PrismaClient();

async function upsertProductByName(input: {
  name: string;
  description: string;
  price: string;
  stock: number;
  imageUrl: string;
  categoryId: string;
}) {
  const existing = await prisma.product.findFirst({
    where: { name: input.name }
  });

  if (existing) {
    return prisma.product.update({
      where: { id: existing.id },
      data: {
        description: input.description,
        price: input.price,
        stock: input.stock,
        imageUrl: input.imageUrl,
        categoryId: input.categoryId,
        isActive: true
      }
    });
  }

  return prisma.product.create({
    data: {
      name: input.name,
      description: input.description,
      price: input.price,
      stock: input.stock,
      imageUrl: input.imageUrl,
      categoryId: input.categoryId,
      isActive: true
    }
  });
}

async function ensureProductCategory(name: string) {
  const existing = await prisma.productCategory.findFirst({
    where: { name }
  });
  if (existing) return existing;
  return prisma.productCategory.create({
    data: { name }
  });
}

async function main() {
  const passwordHash = await bcrypt.hash("admin123", 10);

  await prisma.user.upsert({
    where: { email: "admin@test.com" },
    update: {
      name: "Administrador",
      passwordHash,
      role: Role.ADMIN
    },
    create: {
      email: "admin@test.com",
      name: "Administrador",
      passwordHash,
      role: Role.ADMIN
    }
  });

  const vendorHash = await bcrypt.hash("vendor123", 10);
  await prisma.user.upsert({
    where: { email: "vendor@test.com" },
    update: {
      name: "Tienda Demo",
      passwordHash: vendorHash,
      role: Role.VENDOR
    },
    create: {
      email: "vendor@test.com",
      name: "Tienda Demo",
      passwordHash: vendorHash,
      role: Role.VENDOR
    }
  });

  const platosDeFondo = await ensureProductCategory("Platos de Fondo");
  await ensureProductCategory("Bebidas");
  await ensureProductCategory("Postres");
  await ensureProductCategory("Pizza");
  await ensureProductCategory("Pollo a la brasa");
  await ensureProductCategory("Cevichería");
  await ensureProductCategory("Chifa");
  await ensureProductCategory("Hamburguesas y sanguches");
  await ensureProductCategory("Parrillas");
  await ensureProductCategory("Desayunos");

  await upsertProductByName({
    name: "Lomo Saltado",
    description: "Lomo salteado con cebolla, tomate y papas fritas.",
    price: "32.90",
    stock: 20,
    imageUrl: "https://images.unsplash.com/photo-1626804475297-41608ea09aeb?auto=format&fit=crop&w=1200&q=80",
    categoryId: platosDeFondo.id
  });

  await upsertProductByName({
    name: "Aji de Gallina",
    description: "Pechuga de pollo deshilachada en crema de aji amarillo.",
    price: "28.50",
    stock: 18,
    imageUrl: "https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80",
    categoryId: platosDeFondo.id
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
    console.log("Seed completado correctamente.");
  })
  .catch(async (error) => {
    console.error("Error ejecutando seed:", error);
    await prisma.$disconnect();
    process.exit(1);
  });
