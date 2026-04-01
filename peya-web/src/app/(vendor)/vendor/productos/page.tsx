import { prisma } from "@/lib/prisma";
import { ProductsTableClient } from "@/components/dashboard/products-table-client";
import { getSessionFromCookies } from "@/lib/auth";
import { getAuthorizedBranches } from "@/lib/branch-access";

export const dynamic = "force-dynamic";

type PageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export default async function VendorProductosPage({ searchParams }: PageProps) {
  await searchParams;
  const session = await getSessionFromCookies();
  const authorizedBranches =
    session && (session.role === "VENDOR" || session.role === "ADMIN")
      ? await getAuthorizedBranches(session.sub, session.role)
      : [];
  const authorizedBranchIds = authorizedBranches.map((b) => b.id);

  const [categories, products] = await Promise.all([
    prisma.productCategory.findMany({ orderBy: { name: "asc" } }),
    prisma.product.findMany({
      where: { storeId: { in: authorizedBranchIds.length > 0 ? authorizedBranchIds : ["__none__"] } },
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
