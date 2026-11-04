import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { CacheFirst, ExpirationPlugin, NetworkFirst, Serwist } from "serwist";

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}
declare const self: ServiceWorkerGlobalScope;

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: false,
  clientsClaim: true,
  navigationPreload: false,
  runtimeCaching: [
    {
      matcher: ({ url, sameOrigin }) =>
        sameOrigin && url.pathname === "/templates/kannada-item-bank-template.xlsx",
      handler: new NetworkFirst({
        cacheName: "padalab-item-bank-template",
        networkTimeoutSeconds: 4,
        plugins: [new ExpirationPlugin({ maxEntries: 2, maxAgeSeconds: 60 * 60 * 24 * 30 })]
      })
    },
    {
      matcher: ({ request, sameOrigin }) =>
        sameOrigin && ["script", "style", "font"].includes(request.destination),
      handler: new CacheFirst({
        cacheName: "padalab-static-resources",
        plugins: [new ExpirationPlugin({ maxEntries: 140, maxAgeSeconds: 60 * 60 * 24 * 30 })]
      })
    },
    {
      matcher: ({ request, sameOrigin }) => sameOrigin && request.destination === "image",
      handler: new CacheFirst({
        cacheName: "padalab-local-images",
        plugins: [new ExpirationPlugin({ maxEntries: 100, maxAgeSeconds: 60 * 60 * 24 * 30 })]
      })
    }
  ],
  fallbacks: {
    entries: [{ url: "/offline", matcher: ({ request }) => request.destination === "document" }]
  }
});
serwist.addEventListeners();

self.addEventListener("message",(event:ExtendableMessageEvent)=>{
  if(event.data?.type==="SKIP_WAITING")void self.skipWaiting();
});
