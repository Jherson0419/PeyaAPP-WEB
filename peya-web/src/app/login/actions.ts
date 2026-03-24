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

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    return { error: "Credenciales invalidas." };
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    return { error: "Credenciales invalidas." };
  }

  const token = await signSessionToken({
    sub: user.id,
    email: user.email,
    name: user.name
  });
  await setSessionCookie(token);
  redirect("/dashboard");
}
