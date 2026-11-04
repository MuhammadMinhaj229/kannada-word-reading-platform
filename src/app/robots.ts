import type { MetadataRoute } from "next";

/** This is an internal research review tool, not a public-facing website. */
export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      disallow: "/"
    }
  };
}
