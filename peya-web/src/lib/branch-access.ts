import { prisma } from "@/lib/prisma";

export type SessionLike = {
  sub: string;
  role: string;
};

export type AuthorizedBranch = {
  id: string;
  name: string;
  userId: string;
  isActive: boolean;
};

export async function getAuthorizedBranches(userId: string, role: string): Promise<AuthorizedBranch[]> {
  if (role === "ADMIN") {
    return prisma.vendorBranch.findMany({
      select: { id: true, name: true, userId: true, isActive: true },
      orderBy: { createdAt: "desc" }
    });
  }

  if (role === "VENDOR") {
    return prisma.vendorBranch.findMany({
      where: { userId },
      select: { id: true, name: true, userId: true, isActive: true },
      orderBy: { createdAt: "desc" }
    });
  }

  return [];
}

export async function assertBranchAuthorized({
  userId,
  role,
  branchId
}: {
  userId: string;
  role: string;
  branchId: string;
}) {
  const branch = await prisma.vendorBranch.findUnique({
    where: { id: branchId },
    select: { id: true, userId: true }
  });

  if (!branch) {
    throw new Error("La tienda seleccionada no existe.");
  }

  if (role === "ADMIN") {
    return branch.id;
  }

  if (role === "VENDOR" && branch.userId === userId) {
    return branch.id;
  }

  throw new Error("No autorizado para usar esta tienda.");
}
