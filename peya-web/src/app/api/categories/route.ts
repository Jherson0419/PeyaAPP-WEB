import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
  const categories = await prisma.productCategory.findMany({
    orderBy: { name: "asc" }
  });

  return NextResponse.json(categories);
}
