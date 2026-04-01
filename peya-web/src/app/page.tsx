import { redirect } from "next/navigation";
import { getSessionFromCookies } from "@/lib/auth";

export default async function HomePage() {
  const session = await getSessionFromCookies();
  if (!session?.role) {
    redirect("/login");
  }
  if (session.role === "ADMIN") {
    redirect("/admin/dashboard");
  }
  if (session.role === "VENDOR") {
    redirect("/vendor");
  }
  redirect("/login");
}
