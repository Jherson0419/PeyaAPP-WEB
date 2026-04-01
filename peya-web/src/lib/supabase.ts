import { createClient } from "@supabase/supabase-js";

function getEnv(name: "NEXT_PUBLIC_SUPABASE_URL" | "SUPABASE_SERVICE_ROLE_KEY") {
  const isServer = typeof window === "undefined";

  if (name === "NEXT_PUBLIC_SUPABASE_URL") {
    const publicUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const serverUrl = isServer ? process.env.SUPABASE_URL : undefined;
    const value = publicUrl || serverUrl;
    if (!value) {
      console.error("⚠️ Error Crítico: Faltan variables de entorno de Supabase en el servidor");
      throw new Error("NEXT_PUBLIC_SUPABASE_URL/SUPABASE_URL no esta configurado.");
    }
    return value;
  }

  const value = process.env[name];
  if (!value) {
    console.error("⚠️ Error Crítico: Faltan variables de entorno de Supabase en el servidor");
    throw new Error(`${name} no esta configurado.`);
  }
  if (
    name === "SUPABASE_SERVICE_ROLE_KEY" &&
    (value === "tu_llave_secreta_aqui" || !value.includes("."))
  ) {
    throw new Error(
      "SUPABASE_SERVICE_ROLE_KEY no es valida. Configura la service_role key real desde Supabase Project Settings > API."
    );
  }
  return value;
}

export function getSupabaseServerClient() {
  return createClient(getEnv("NEXT_PUBLIC_SUPABASE_URL"), getEnv("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: {
      persistSession: false
    }
  });
}
