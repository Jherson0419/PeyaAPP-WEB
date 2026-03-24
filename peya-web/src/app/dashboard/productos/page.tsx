import { prisma } from "@/lib/prisma";
import { ProductsTableClient } from "@/components/dashboard/products-table-client";

export const dynamic = "force-dynamic";

type PageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export default async function ProductosPage({ searchParams }: PageProps) {
  await searchParams;
  const [categories, products] = await Promise.all([
    prisma.category.findMany({ orderBy: { name: "asc" } }),
    prisma.product.findMany({
      include: { category: true },
      orderBy: { createdAt: "desc" }
    })
  ]);

  const serializedProducts = products.map((p) => ({
    id: p.id,
    name: p.name,
    categoryId: p.categoryId,
    categoryName: p.category.name,
    price: Number(p.price),
    stock: p.stock,
    imageUrl: p.imageUrl,
    isActive: p.isActive
  }));

  return <ProductsTableClient categories={categories} products={serializedProducts} />;
}
