"use client";
import { useEffect } from "react";
export default function PwaRegistration() {
  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;
    let cancelled = false;
    navigator.serviceWorker.register("/sw.js", { scope: "/" }).catch(() => {
      if (!cancelled) {
        // The assessor screen remains usable online; field readiness must be verified separately.
      }
    });
    return () => { cancelled = true; };
  }, []);
  return <span className="pwa-status" title="Offline readiness must be checked on the target tablet"><i /> Offline-first PWA</span>;
}
