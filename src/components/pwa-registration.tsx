"use client";
import { useEffect, useState } from "react";

interface InstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed"; platform: string }>;
}

export default function PwaRegistration() {
  const [online, setOnline] = useState<boolean | null>(null);
  const [offlineReady, setOfflineReady] = useState(false);
  const [installPrompt, setInstallPrompt] = useState<InstallPromptEvent | null>(null);
  const [installing, setInstalling] = useState(false);

  useEffect(() => {
    let active = true;
    const handleOnline = () => setOnline(true);
    const handleOffline = () => setOnline(false);
    const handleInstallPrompt = (event: Event) => {
      event.preventDefault();
      setInstallPrompt(event as InstallPromptEvent);
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);
    window.addEventListener("beforeinstallprompt", handleInstallPrompt);

    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/sw.js", { scope: "/" })
        .then(() => navigator.serviceWorker.ready)
        .then(() => {
          if (active) {
            setOnline(navigator.onLine);
            setOfflineReady(true);
          }
        })
        .catch(() => {
          if (active) setOnline(navigator.onLine);
        });
    } else {
      setOnline(navigator.onLine);
    }

    return () => {
      active = false;
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
      window.removeEventListener("beforeinstallprompt", handleInstallPrompt);
    };
  }, []);

  async function installApp() {
    if (!installPrompt || installing) return;
    setInstalling(true);
    try {
      await installPrompt.prompt();
      await installPrompt.userChoice;
      setInstallPrompt(null);
    } finally {
      setInstalling(false);
    }
  }

  const label = online === false
    ? "Offline"
    : offlineReady
      ? "Offline ready"
      : online === true
        ? "Online"
        : "Checking";
  return (
    <div className="pwa-tools">
      <span className={`pwa-status ${online === false ? "offline" : offlineReady ? "ready" : ""}`}
        title={offlineReady ? "The service worker is active. Verify full offline readiness on the target tablet." : "Checking network and offline support."}>
        <i aria-hidden="true" />{label}
      </span>
      {installPrompt && (
        <button type="button" className="install-app" onClick={() => void installApp()} disabled={installing}>
          {installing ? "Opening…" : "Install app"}
        </button>
      )}
    </div>
  );
}
