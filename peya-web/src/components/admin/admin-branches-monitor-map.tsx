"use client";

import { GoogleMap, Marker, useJsApiLoader, type Libraries } from "@react-google-maps/api";
import { useEffect, useMemo, useState } from "react";
import type { VendorBranchRow } from "@/lib/types/vendor-branch";

const defaultCenter = { lat: -8.1091, lng: -79.0215 };
const libraries: Libraries = ["places"];

type Props = {
  apiKey: string;
  branches: VendorBranchRow[];
};

export function AdminBranchesMonitorMap({ apiKey, branches }: Props) {
  const { isLoaded, loadError } = useJsApiLoader({
    id: "google-maps-js-api",
    googleMapsApiKey: apiKey,
    libraries
  });

  const [iconSizeByUrl, setIconSizeByUrl] = useState<Record<string, { w: number; h: number }>>({});
  const markerMaxSide = 30;

  const center = useMemo(() => {
    if (branches.length > 0) {
      return { lat: branches[0].latitude, lng: branches[0].longitude };
    }
    return defaultCenter;
  }, [branches]);

  useEffect(() => {
    if (!isLoaded || !!loadError) return;
    const urls = Array.from(new Set(branches.map((b) => b.iconUrl).filter((x): x is string => !!x)));
    urls.forEach((url) => {
      if (iconSizeByUrl[url]) return;
      const img = new window.Image();
      img.onload = () => {
        const w = img.naturalWidth || markerMaxSide;
        const h = img.naturalHeight || markerMaxSide;
        const scale = markerMaxSide / Math.max(w, h);
        const nextW = Math.max(16, Math.round(w * scale));
        const nextH = Math.max(16, Math.round(h * scale));
        setIconSizeByUrl((prev) => ({ ...prev, [url]: { w: nextW, h: nextH } }));
      };
      img.src = url;
    });
  }, [branches, iconSizeByUrl, isLoaded, loadError]);

  const markerIcon = useMemo(() => {
    return (url: string | null) => {
      if (!url || !isLoaded || loadError) return undefined;
      const s = iconSizeByUrl[url];
      return {
        url,
        scaledSize: new google.maps.Size(s?.w ?? markerMaxSide, s?.h ?? markerMaxSide)
      };
    };
  }, [iconSizeByUrl, isLoaded, loadError]);

  if (!apiKey) {
    return (
      <div className="flex h-[min(480px,60vh)] items-center justify-center rounded-xl border border-amber-200 bg-amber-50 px-4 text-center text-sm text-amber-900">
        Configura <code className="rounded bg-amber-100 px-1">NEXT_PUBLIC_GOOGLE_MAPS_API_KEY</code> para ver el mapa.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-xl border border-slate-100 bg-white shadow-sm">
      <div className="border-b border-slate-100 px-4 py-3">
        <h2 className="text-sm font-semibold text-slate-900">Sucursales (pines)</h2>
        <p className="text-xs text-slate-500">{branches.length} activa(s)</p>
      </div>
      <div className="relative h-[min(520px,70vh)] w-full bg-slate-100">
        {isLoaded && !loadError ? (
          <GoogleMap
            mapContainerClassName="h-full w-full"
            center={center}
            zoom={branches.length === 0 ? 13 : 14}
            options={{
              streetViewControl: false,
              mapTypeControl: false,
              fullscreenControl: false,
              clickableIcons: false
            }}
          >
            {branches.map((b) => (
              <Marker
                key={b.id}
                position={{ lat: b.latitude, lng: b.longitude }}
                title={b.name}
                icon={markerIcon(b.iconUrl)}
              />
            ))}
          </GoogleMap>
        ) : (
          <div className="flex h-full items-center justify-center p-6 text-center text-sm text-slate-500">
            {loadError
              ? "No se pudo cargar Google Maps. Revisa la API key y la facturación del proyecto."
              : "Cargando mapa…"}
          </div>
        )}
      </div>
    </div>
  );
}

