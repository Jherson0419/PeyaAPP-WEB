"use server";

import bcrypt from "bcryptjs";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { setSessionCookie, signSessionToken } from "@/lib/auth";

type ActionState = {
  error?: string;
};

export async function loginAction(_: ActionState, formData: FormData): Promise<ActionState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "Completa correo y contrasena." };
  }

  let user;
  try {
    user = await prisma.user.findUnique({ where: { email } });
  } catch (error) {
    console.error("loginAction database error:", error);
    return { error: "No se pudo conectar a la base de datos. Intenta de nuevo en unos minutos." };
  }
  if (!user) {
    return { error: "Credenciales invalidas." };
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    return { error: "Credenciales invalidas." };
  }

  if (user.role !== "ADMIN" && user.role !== "VENDOR") {
    return { error: "Tu cuenta no tiene acceso al panel web." };
  }

  const token = await signSessionToken({
    sub: user.id,
    email: user.email,
    name: user.name,
    role: user.role
  });
  await setSessionCookie(token);

  if (user.role === "ADMIN") {
    redirect("/admin/dashboard");
  }
  redirect("/vendor");
}
