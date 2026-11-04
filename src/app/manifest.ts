import type { MetadataRoute } from "next";
export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/", name: "ಪದLab — Kannada Word Reading Assessment", short_name: "ಪದLab",
    description: "Offline Kannada word-reading assessment for supervised research sessions.",
    start_url: "/", scope: "/", display: "standalone", orientation: "landscape",
    background_color: "#f7f8f4", theme_color: "#173d35", lang: "kn-IN",
    icons: [
      { src: "/icons/icon-192.svg", sizes: "192x192", type: "image/svg+xml", purpose: "any" },
      { src: "/icons/icon-512.svg", sizes: "512x512", type: "image/svg+xml", purpose: "any" }
    ]
  };
}
