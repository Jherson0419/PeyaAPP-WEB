"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { LayoutDashboard, LogOut, Menu, Package, UserCircle2, X } from "lucide-react";
import { logoutAction } from "@/app/dashboard/actions";

const nav = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/dashboard/productos", label: "Productos", icon: Package }
];

export function DashboardShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  const NavLinks = () => (
    <>
      {nav.map(({ href, label, icon: Icon }) => {
        const active =
          href === "/dashboard" ? pathname === "/dashboard" : pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            onClick={() => setMobileOpen(false)}
            className={`relative flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-medium transition-all ${
              active
                ? "bg-teal-50 text-teal-700 ring-1 ring-teal-200/70"
                : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
            }`}
          >
            {active ? <span className="absolute inset-y-2 left-0 w-1 rounded-full bg-teal-600" aria-hidden /> : null}
            <Icon className="h-4 w-4 shrink-0 opacity-80" strokeWidth={2} />
            {label}
          </Link>
        );
      })}
    </>
  );

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Mobile overlay */}
      {mobileOpen ? (
        <button
          type="button"
          aria-label="Cerrar menu"
          className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-sm lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      ) : null}

      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-72 flex-col border-r border-slate-100 bg-white transition-transform duration-200 ease-out lg:translate-x-0 ${
          mobileOpen ? "translate-x-0 shadow-xl" : "-translate-x-full"
        }`}
      >
        <div className="flex h-16 items-center justify-between border-b border-slate-100 px-5">
          <Link href="/dashboard" className="flex items-center gap-2 font-semibold tracking-tight text-slate-900">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-teal-600 text-xs font-bold text-white shadow-sm">
              P
            </span>
            Peya
          </Link>
          <button
            type="button"
            className="rounded-lg p-2 text-slate-500 hover:bg-slate-50 lg:hidden"
            onClick={() => setMobileOpen(false)}
            aria-label="Cerrar"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <nav className="flex flex-1 flex-col gap-1.5 p-4">
          <NavLinks />
        </nav>
        <div className="space-y-3 border-t border-slate-100 p-4">
          <div className="flex items-center gap-3 rounded-xl border border-slate-100 bg-slate-50/70 px-3 py-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-white text-slate-500 ring-1 ring-slate-200">
              <UserCircle2 className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-slate-800">Administrador</p>
              <p className="truncate text-xs text-slate-500">Backoffice Peya</p>
            </div>
          </div>
          <form action={logoutAction}>
            <button
              type="submit"
              className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-600 transition-all hover:bg-slate-50 hover:text-slate-900"
            >
              <LogOut className="h-4 w-4" />
              Salir
            </button>
          </form>
        </div>
      </aside>

      <div className="lg:pl-72">
        <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-slate-200/80 bg-slate-50/90 px-4 backdrop-blur lg:hidden">
          <button
            type="button"
            className="rounded-lg p-2 text-slate-600 hover:bg-white hover:shadow-sm"
            onClick={() => setMobileOpen(true)}
            aria-label="Abrir menu"
          >
            <Menu className="h-5 w-5" />
          </button>
          <span className="text-sm font-semibold tracking-tight text-slate-800">Peya</span>
          <span className="w-9" />
        </header>

        <main className="mx-auto max-w-7xl px-4 py-8 lg:px-8">{children}</main>
      </div>
    </div>
  );
}
