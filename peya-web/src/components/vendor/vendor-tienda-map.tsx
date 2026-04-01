"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Autocomplete, GoogleMap, Marker, useJsApiLoader, type Libraries } from "@react-google-maps/api";
import { MapPin } from "lucide-react";
import type { VendorBranchRow } from "@/lib/types/vendor-branch";

const defaultCenter = { lat: -8.1091, lng: -79.0215 };
const libraries: Libraries = ["places"];

type Props = {
  apiKey: string;
  branches: VendorBranchRow[];
  panelOpen: boolean;
  draft: { lat: number; lng: number };
  setDraft: (p: { lat: number; lng: number }) => void;
};

export function VendorTiendaMap({ apiKey, branches, panelOpen, draft, setDraft }: Props) {
  const { isLoaded, loadError } = useJsApiLoader({
    id: "google-maps-js-api",
    googleMapsApiKey: apiKey,
    libraries
  });

  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null);
  const [iconSizeByUrl, setIconSizeByUrl] = useState<Record<string, { w: number; h: number }>>({});

  const mapCenter = useMemo(() => {
    if (branches.length > 0) {
      return { lat: branches[0].latitude, lng: branches[0].longitude };
    }
    return defaultCenter;
  }, [branches]);

  const onPlaceChanged = useCallback(() => {
    if (!panelOpen) return;
    const place = autocompleteRef.current?.getPlace();
    const loc = place?.geometry?.location;
    if (!loc) return;
    setDraft({ lat: loc.lat(), lng: loc.lng() });
  }, [panelOpen, setDraft]);

  const onMapClick = useCallback(
    (e: google.maps.MapMouseEvent) => {
      if (!panelOpen || !e.latLng) return;
      setDraft({ lat: e.latLng.lat(), lng: e.latLng.lng() });
    },
    [panelOpen, setDraft]
  );

  const mapReady = isLoaded && !loadError;
  const markerMaxSide = 30;

  useEffect(() => {
    if (!mapReady) return;
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
  }, [branches, iconSizeByUrl, mapReady]);

  const markerIcon = useCallback((url: string | null) => {
    if (!url || !mapReady) return undefined;
    const s = iconSizeByUrl[url];
    return {
      url,
      // Mantiene proporción real del logo (sin alargarlo).
      scaledSize: new google.maps.Size(s?.w ?? markerMaxSide, s?.h ?? markerMaxSide)
    };
  }, [iconSizeByUrl, mapReady]);

  return (
    <div className="overflow-hidden rounded-xl border border-slate-100 bg-white shadow-sm">
      <div className="flex items-center gap-2 border-b border-slate-100 px-4 py-3">
        <MapPin className="h-4 w-4 text-teal-600" />
        <h2 className="text-sm font-semibold text-slate-900">Mapa</h2>
      </div>
      <div className="relative h-[min(420px,60vh)] w-full bg-slate-100">
        {mapReady ? (
          <>
            <div className="absolute left-3 top-3 z-20 w-[calc(100%-1.5rem)] max-w-md">
              <Autocomplete
                onLoad={(ref) => {
                  autocompleteRef.current = ref;
                }}
                onPlaceChanged={onPlaceChanged}
              >
                <input
                  type="text"
                  className="w-full rounded-xl border border-slate-200 bg-white/95 px-3 py-2.5 text-sm text-slate-900 shadow-sm outline-none ring-emerald-500/20 transition focus:border-emerald-500 focus:ring-2"
                  placeholder="Buscar por dirección o lugar…"
                  disabled={!panelOpen}
                />
              </Autocomplete>
            </div>
            <GoogleMap
              mapContainerClassName="h-full w-full"
              center={panelOpen ? draft : mapCenter}
              zoom={branches.length === 0 && !panelOpen ? 13 : 14}
              onClick={onMapClick}
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
              {panelOpen ? (
                <Marker
                  position={draft}
                  draggable
                  onDragEnd={(ev) => {
                    const p = ev.latLng;
                    if (p) setDraft({ lat: p.lat(), lng: p.lng() });
                  }}
                />
              ) : null}
            </GoogleMap>
          </>
        ) : (
          <div className="flex h-full items-center justify-center p-6 text-center text-sm text-slate-500">
            {loadError
              ? "No se pudo cargar Google Maps. Revisa la API key y la facturación del proyecto."
              : "Cargando mapa…"}
          </div>
        )}
      </div>
      {panelOpen ? (
        <p className="border-t border-slate-100 px-4 py-2 text-xs text-slate-500">
          Haz clic en el mapa o arrastra el pin para fijar la ubicación de la nueva sucursal.
        </p>
      ) : null}
    </div>
  );
}
