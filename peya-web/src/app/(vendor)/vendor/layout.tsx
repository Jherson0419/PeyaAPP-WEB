import { VendorShell } from "@/components/vendor/vendor-shell";
import { getSessionFromCookies } from "@/lib/auth";

export default async function VendorLayout({ children }: { children: React.ReactNode }) {
  const session = await getSessionFromCookies();
  return (
    <VendorShell profileName={session?.name} profileRole={session?.role}>
      {children}
    </VendorShell>
  );
}
