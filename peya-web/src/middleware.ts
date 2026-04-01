import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

const encoder = new TextEncoder();

function getJwtSecretKey() {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET no esta configurado.");
  }
  return encoder.encode(secret);
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (!pathname.startsWith("/admin") && !pathname.startsWith("/vendor")) {
    return NextResponse.next();
  }

  let secretKey: Uint8Array;
  try {
    secretKey = getJwtSecretKey();
  } catch {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  const token = request.cookies.get("admin_session")?.value;
  if (!token) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  try {
    const { payload } = await jwtVerify(token, secretKey);
    const role = String(payload.role ?? "");

    if (pathname.startsWith("/admin")) {
      if (role === "ADMIN") {
        return NextResponse.next();
      }
      if (role === "VENDOR") {
        return NextResponse.redirect(new URL("/vendor", request.url));
      }
      return NextResponse.redirect(new URL("/login", request.url));
    }

    if (pathname.startsWith("/vendor")) {
      if (role === "VENDOR") {
        return NextResponse.next();
      }
      if (role === "ADMIN") {
        return NextResponse.redirect(new URL("/admin/dashboard", request.url));
      }
      return NextResponse.redirect(new URL("/login", request.url));
    }
  } catch {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/vendor/:path*"]
};
