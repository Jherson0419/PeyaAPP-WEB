"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import {
  Bell,
  ChevronDown,
  LayoutDashboard,
  MapPin,
  LogOut,
  Menu,
  Settings,
  Store,
  UserCircle2,
  X
} from "lucide-react";
import { logoutAction } from "@/app/actions/auth";

const nav = [
  { href: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/admin/monitor", label: "Monitor", icon: MapPin },
  { href: "/admin/distribuidores", label: "Distribuidores", icon: Store },
  { href: "/admin/configuracion", label: "Configuración", icon: Settings }
] as const;

const titleByPath: { prefix: string; title: string }[] = [
  { prefix: "/admin/dashboard", title: "Dashboard" },
  { prefix: "/admin/monitor", title: "Monitor" },
  { prefix: "/admin/distribuidores", title: "Distribuidores" },
  { prefix: "/admin/sucursales", title: "Inventario de sucursal" },
  { prefix: "/admin/configuracion", title: "Configuración" },
  { prefix: "/admin/reportes", title: "Reportes" }
];

function pageTitle(pathname: string) {
  const hit = titleByPath.find((t) => pathname === t.prefix || pathname.startsWith(`${t.prefix}/`));
  if (hit) return hit.title;
  if (pathname === "/admin") return "Dashboard";
  return "Administración";
}

type AdminShellProps = {
  children: React.ReactNode;
  profileName?: string;
  profileRole?: string;
};

function roleLabel(role?: string) {
  if (role === "ADMIN") return "Administrador";
  if (role === "VENDOR") return "Distribuidor";
  return "Usuario";
}

export function AdminShell({ children, profileName, profileRole }: AdminShellProps) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);

  const title = pageTitle(pathname);
  const displayName = profileName?.trim() || "Administrador";
  const displayRole = roleLabel(profileRole);

  useEffect(() => {
    function onDocClick(e: MouseEvent) {
      if (!profileRef.current?.contains(e.target as Node)) setProfileOpen(false);
    }
    document.addEventListener("click", onDocClick);
    return () => document.removeEventListener("click", onDocClick);
  }, []);

  const NavLinks = () => (
    <>
      {nav.map(({ href, label, icon: Icon }) => {
        const active =
          pathname === href ||
          (href === "/admin/dashboard" && pathname === "/admin") ||
          pathname.startsWith(`${href}/`);
        return (
          <Link
            key={href}
            href={href}
            onClick={() => setMobileOpen(false)}
            className={`relative flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-medium transition-all ${
              active
                ? "bg-emerald-50 text-emerald-800 ring-1 ring-emerald-200/80"
                : "text-slate-600 hover:bg-white hover:text-slate-900"
            }`}
          >
            {active ? <span className="absolute inset-y-2 left-0 w-1 rounded-full bg-emerald-600" aria-hidden /> : null}
            <Icon className="h-4 w-4 shrink-0 opacity-90" strokeWidth={2} />
            {label}
          </Link>
        );
      })}
    </>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {mobileOpen ? (
        <button
          type="button"
          aria-label="Cerrar menú"
          className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-sm lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      ) : null}

      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r border-slate-200/80 bg-white shadow-sm transition-transform duration-200 ease-out lg:translate-x-0 ${
          mobileOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
        }`}
      >
        <div className="flex h-16 items-center justify-between border-b border-slate-100 px-5">
          <Link href="/admin/dashboard" className="flex items-center gap-2 font-semibold tracking-tight text-slate-900">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-600 text-xs font-bold text-white shadow-sm">
              P
            </span>
            Peya Admin
          </Link>
          <button
            type="button"
            className="rounded-lg p-2 text-slate-500 hover:bg-gray-50 lg:hidden"
            onClick={() => setMobileOpen(false)}
            aria-label="Cerrar"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <nav className="flex flex-1 flex-col gap-1 p-4">
          <NavLinks />
        </nav>
        <div className="border-t border-slate-100 p-4">
          <div className="flex items-center gap-3 rounded-xl border border-slate-100 bg-gray-50 px-3 py-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-white text-slate-500 ring-1 ring-slate-200">
              <UserCircle2 className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-slate-800">{displayName}</p>
              <p className="truncate text-xs text-slate-500">{displayRole}</p>
            </div>
          </div>
        </div>
      </aside>

      <div className="lg:pl-64">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between gap-4 border-b border-slate-200/80 bg-gray-50/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-gray-50/80 lg:px-8">
          <div className="flex min-w-0 flex-1 items-center gap-3">
            <button
              type="button"
              className="rounded-lg p-2 text-slate-600 hover:bg-white hover:shadow-sm lg:hidden"
              onClick={() => setMobileOpen(true)}
              aria-label="Abrir menú"
            >
              <Menu className="h-5 w-5" />
            </button>
            <h1 className="truncate text-lg font-semibold tracking-tight text-slate-900">{title}</h1>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <button
              type="button"
              className="relative rounded-xl p-2.5 text-slate-600 transition-colors hover:bg-white hover:text-slate-900 hover:shadow-sm"
              aria-label="Notificaciones"
            >
              <Bell className="h-5 w-5" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-emerald-500 ring-2 ring-gray-50" />
            </button>
            <div className="relative" ref={profileRef}>
              <button
                type="button"
                onClick={() => setProfileOpen((o) => !o)}
                className="flex items-center gap-2 rounded-xl border border-slate-200/80 bg-white px-3 py-2 text-sm font-medium text-slate-800 shadow-sm transition hover:border-slate-300"
                aria-expanded={profileOpen}
                aria-haspopup="menu"
              >
                <UserCircle2 className="h-5 w-5 text-slate-500" />
                <span className="hidden max-w-40 truncate sm:inline">{displayName}</span>
                <ChevronDown className={`h-4 w-4 text-slate-400 transition ${profileOpen ? "rotate-180" : ""}`} />
              </button>
              {profileOpen ? (
                <div
                  role="menu"
                  className="absolute right-0 z-50 mt-2 w-56 overflow-hidden rounded-xl border border-slate-200 bg-white py-1 shadow-lg"
                >
                  <div className="border-b border-slate-100 px-4 py-3">
                    <p className="truncate text-sm font-semibold text-slate-900">{displayName}</p>
                    <p className="text-xs text-slate-500">Rol: {profileRole ?? "DESCONOCIDO"}</p>
                  </div>
                  <form action={logoutAction}>
                    <button
                      type="submit"
                      role="menuitem"
                      className="flex w-full items-center gap-2 px-4 py-2.5 text-left text-sm text-slate-700 transition hover:bg-gray-50"
                    >
                      <LogOut className="h-4 w-4" />
                      Cerrar sesión
                    </button>
                  </form>
                </div>
              ) : null}
            </div>
          </div>
        </header>

        <main className="mx-auto max-w-7xl px-4 py-8 lg:px-8">{children}</main>
      </div>
    </div>
  );
}
