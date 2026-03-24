import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

type RouteContext = {
  params: Promise<{ id: string }>;
};

export async function GET(_: Request, { params }: RouteContext) {
  const { id } = await params;

  const product = await prisma.product.findUnique({
    where: { id },
    include: { category: true }
  });

  if (!product) {
    return NextResponse.json({ message: "Producto no encontrado." }, { status: 404 });
  }

  return NextResponse.json(product);
}
