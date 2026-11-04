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
const nextConfig = { reactStrictMode: true, poweredByHeader: false };
export default withSerwist(nextConfig);