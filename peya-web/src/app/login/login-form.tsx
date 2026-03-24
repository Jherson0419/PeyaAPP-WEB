"use client";

import { useActionState } from "react";
import { loginAction } from "./actions";

const initialState = { error: "" };

export function LoginForm() {
  const [state, formAction, pending] = useActionState(loginAction, initialState);

  return (
    <form action={formAction} className="space-y-5 rounded-xl border border-slate-200 bg-white p-8 shadow-sm">
      <div className="space-y-1.5">
        <label className="text-sm font-medium text-slate-700" htmlFor="email">
          Correo
        </label>
        <input id="email" name="email" type="email" required placeholder="admin@tienda.com" className="w-full" />
      </div>

      <div className="space-y-1.5">
        <label className="text-sm font-medium text-slate-700" htmlFor="password">
          Contraseña
        </label>
        <input id="password" name="password" type="password" required placeholder="••••••••" className="w-full" />
      </div>

      {state.error ? (
        <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-600">{state.error}</p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className="w-full rounded-lg bg-teal-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-all hover:bg-teal-700 hover:shadow disabled:opacity-60"
      >
        {pending ? "Ingresando..." : "Ingresar"}
      </button>
    </form>
  );
}
