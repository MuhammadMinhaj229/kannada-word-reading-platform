"use client";
import { useEffect, useState } from "react";
export default function PwaRegistration() {
  const [status, setStatus] = useState("Checking offline support…");
  useEffect(() => {
    if (!("serviceWorker" in navigator)) { setStatus("PWA unavailable in this browser"); return; }
    let cancelled = false;
    navigator.serviceWorker.register("/sw.js", { scope: "/" })
      .then(() => { if (!cancelled) setStatus("Offline shell registered"); })
      .catch(() => { if (!cancelled) setStatus("Offline cache not ready"); });
    return () => { cancelled = true; };
  }, []);
  return <span className="pwa-status" title={status}><i />{status}</span>;
}
