import withSerwistInit from "@serwist/next";
const withSerwist = withSerwistInit({
  swSrc: "src/app/sw.ts",
  swDest: "public/sw.js",
  register: false,
  additionalPrecacheEntries: [
    { url: "/", revision: process.env.NEXT_PUBLIC_APP_VERSION || "0.1.0" },
    { url: "/offline", revision: process.env.NEXT_PUBLIC_APP_VERSION || "0.1.0" }
  ],
  disable: process.env.NODE_ENV === "development"
});
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  async headers() {
    return [{
      source: "/:path*",
      headers: [
        { key: "X-Content-Type-Options", value: "nosniff" },
        { key: "X-Frame-Options", value: "DENY" },
        { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
        { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
        { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
        { key: "Cross-Origin-Resource-Policy", value: "same-origin" }
      ]
    }];
  }
};
export default withSerwist(nextConfig);