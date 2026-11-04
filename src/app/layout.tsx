import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "./globals.css";
export const metadata: Metadata = {
  applicationName: "ಪದLab",
  title: { default: "ಪದLab | Kannada Word Reading", template: "%s | ಪದLab" },
  description: "Offline-first Kannada lexical-decision assessment PWA.",
  appleWebApp: { capable: true, statusBarStyle: "black-translucent", title: "ಪದLab" },
  formatDetection: { telephone: false }
};
export const viewport: Viewport = {
  themeColor: "#173d35", width: "device-width", initialScale: 1, maximumScale: 1, userScalable: false
};
export default function RootLayout({ children }: { children: ReactNode }) {
  return <html lang="kn-IN"><body>{children}</body></html>;
}