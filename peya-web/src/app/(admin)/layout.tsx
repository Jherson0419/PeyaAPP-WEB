import { AdminShell } from "@/components/admin/admin-shell";
import { getSessionFromCookies } from "@/lib/auth";

export default async function AdminRouteGroupLayout({ children }: { children: React.ReactNode }) {
  const session = await getSessionFromCookies();
  return (
    <AdminShell profileName={session?.name} profileRole={session?.role}>
      {children}
    </AdminShell>
  );
}
