import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "@fontsource/noto-sans-kannada/400.css";
import "@fontsource/noto-sans-kannada/500.css";
import "@fontsource/noto-sans-kannada/600.css";
import "@fontsource/noto-sans-kannada/700.css";
import "./globals.css";

export const metadata: Metadata = {
  applicationName: "ಪದLab",
  title: { default: "ಪದLab | Kannada Word Reading", template: "%s | ಪದLab" },
  description: "Offline-first Kannada word-reading assessment for supervised research sessions.",
  appleWebApp: { capable: true, statusBarStyle: "black-translucent", title: "ಪದLab" },
  formatDetection: { telephone: false },
  icons: {
    icon: [
      { url: "/icons/icon-192.svg", type: "image/svg+xml", sizes: "192x192" },
      { url: "/icons/icon-512.svg", type: "image/svg+xml", sizes: "512x512" }
    ],
    apple: [{ url: "/icons/icon-192.svg", type: "image/svg+xml" }]
  }
};

export const viewport: Viewport = {
  themeColor: "#173d35",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover"
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return <html lang="en-IN"><body>{children}</body></html>;
}
