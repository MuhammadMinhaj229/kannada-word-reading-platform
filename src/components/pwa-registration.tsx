"use client";
import { useEffect, useRef, useState } from "react";

interface InstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed"; platform: string }>;
}
interface PwaRegistrationProps { sessionActive?: boolean; }

export default function PwaRegistration({sessionActive=false}:PwaRegistrationProps) {
  const [online,setOnline]=useState<boolean|null>(null);
  const [offlineReady,setOfflineReady]=useState(false);
  const [installPrompt,setInstallPrompt]=useState<InstallPromptEvent|null>(null);
  const [installing,setInstalling]=useState(false);
  const [updateReady,setUpdateReady]=useState(false);
  const [applyingUpdate,setApplyingUpdate]=useState(false);
  const registrationRef=useRef<ServiceWorkerRegistration|null>(null);

  useEffect(()=>{
    let active=true;
    const handleOnline=()=>setOnline(true);
    const handleOffline=()=>setOnline(false);
    const handleInstallPrompt=(event:Event)=>{
      event.preventDefault();
      setInstallPrompt(event as InstallPromptEvent);
    };
    const handleControllerChange=()=>setOfflineReady(true);

    window.addEventListener("online",handleOnline);
    window.addEventListener("offline",handleOffline);
    window.addEventListener("beforeinstallprompt",handleInstallPrompt);

    if("serviceWorker" in navigator){
      navigator.serviceWorker.addEventListener("controllerchange",handleControllerChange);
      navigator.serviceWorker.register("/sw.js",{scope:"/"})
        .then(async registration=>{
          if(!active)return;
          registrationRef.current=registration;
          const checkWaiting=()=>{
            if(active&&registration.waiting&&navigator.serviceWorker.controller)setUpdateReady(true);
          };
          checkWaiting();
          registration.addEventListener("updatefound",()=>{
            const worker=registration.installing;
            worker?.addEventListener("statechange",()=>{
              if(active&&worker.state==="installed")checkWaiting();
            });
          });
          await navigator.serviceWorker.ready;
          let templateCached = false;
          if (navigator.serviceWorker.controller && navigator.onLine) {
            try {
              const response = await fetch("/templates/kannada-item-bank-template.xlsx", { cache: "no-store" });
              templateCached = response.ok;
            } catch { templateCached = false; }
          }
          if(active){
            setOnline(navigator.onLine);
            setOfflineReady(Boolean(navigator.serviceWorker.controller) && templateCached);
          }
          // Ask the browser to preserve this app's local assessment storage where supported.
          try { await navigator.storage?.persist?.(); } catch { /* Browser may deny persistent storage. */ }
        })
        .catch(()=>{if(active)setOnline(navigator.onLine);});
    }else{
      Promise.resolve().then(()=>{if(active)setOnline(navigator.onLine);});
    }
    return ()=>{
      active=false;
      window.removeEventListener("online",handleOnline);
      window.removeEventListener("offline",handleOffline);
      window.removeEventListener("beforeinstallprompt",handleInstallPrompt);
      if("serviceWorker" in navigator)navigator.serviceWorker.removeEventListener("controllerchange",handleControllerChange);
    };
  },[]);

  async function installApp(){
    if(!installPrompt||installing)return;
    setInstalling(true);
    try{await installPrompt.prompt();await installPrompt.userChoice;setInstallPrompt(null);}
    finally{setInstalling(false);}
  }
  function applyUpdate(){
    if(sessionActive||applyingUpdate)return;
    const worker=registrationRef.current?.waiting;
    if(!worker)return;
    setApplyingUpdate(true);
    worker.addEventListener("statechange",()=>{
      if(worker.state==="activated")window.location.reload();
    });
    worker.postMessage({type:"SKIP_WAITING"});
  }

  const label=online===false?"Offline":offlineReady?"Offline ready":online===true?"Online":"Checking";
  return <div className="pwa-tools">
    <span className={`pwa-status ${online===false?"offline":offlineReady?"ready":""}`} role="status" aria-live="polite"
      title={offlineReady?"Service worker active. Complete the device offline checklist before field use.":"Checking network and offline support."}>
      <i aria-hidden="true"/>{label}
    </span>
    {installPrompt&&<button type="button" className="install-app" onClick={()=>void installApp()} disabled={installing}>
      {installing?"Opening…":"Install app"}
    </button>}
    {updateReady&&<button type="button" className="install-app" onClick={applyUpdate} disabled={sessionActive||applyingUpdate}>
      {applyingUpdate?"Updating…":"Update app"}
    </button>}
  </div>;
}
