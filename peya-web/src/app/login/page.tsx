import { LoginForm } from "./login-form";

export default function LoginPage() {
  return (
    <main className="relative mx-auto flex min-h-screen max-w-md items-center px-4 py-12">
      <div className="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-teal-100/40 via-slate-50 to-slate-50" />
      <section className="w-full space-y-6">
        <div className="text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-teal-600 text-lg font-bold text-white shadow-sm">
            P
          </div>
          <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Peya Backoffice</h1>
          <p className="mt-2 text-sm text-slate-500">Inicia sesión para gestionar tu catálogo.</p>
        </div>
        <LoginForm />
      </section>
    </main>
  );
}
