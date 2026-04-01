import { NextResponse } from "next/server";
import { getSessionFromCookies } from "@/lib/auth";
import { uploadImage } from "@/services/storage";

function requireVendorSession() {
  return getSessionFromCookies().then((s) => {
    if (!s || s.role !== "VENDOR") return null;
    return s;
  });
}

export async function POST(request: Request) {
  const session = await requireVendorSession();
  if (!session) {
    return NextResponse.json({ error: "No autorizado para subir iconos." }, { status: 401 });
  }

  const form = await request.formData();
  const rawFile = form.get("file");
  if (!(rawFile instanceof File)) {
    return NextResponse.json({ error: "Archivo inválido." }, { status: 400 });
  }

  if (rawFile.type !== "image/png") {
    return NextResponse.json({ error: "Solo se permite imagen PNG para icono de sucursal." }, { status: 400 });
  }
  if (rawFile.size > 3 * 1024 * 1024) {
    return NextResponse.json({ error: "El icono supera el límite de 3MB." }, { status: 400 });
  }

  const branchRef = String(form.get("branchRef") ?? session.sub).trim() || session.sub;

  try {
    const imageUrl = await uploadImage(rawFile, `branch-icons/${branchRef}`);
    return NextResponse.json({ imageUrl });
  } catch {
    return NextResponse.json({ error: "No se pudo subir el icono a Supabase." }, { status: 500 });
  }
}
