#!/usr/bin/env python3
"""Validate the static Web security and cache contract in vercel.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "vercel.json"


def fail(message: str) -> None:
    raise SystemExit(f"Vercel configuration validation failed: {message}")


def main() -> int:
    try:
        config: dict[str, Any] = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read valid JSON from {CONFIG_PATH}: {exc}")

    expected = {
        "framework": None,
        "installCommand": "bash scripts/deploy/install_flutter.sh",
        "buildCommand": "bash scripts/deploy/build_flutter_web.sh",
        "outputDirectory": "build/web",
    }
    for key, value in expected.items():
        if config.get(key) != value:
            fail(f"{key} must be {value!r}, got {config.get(key)!r}")

    header_rules = config.get("headers")
    if not isinstance(header_rules, list):
        fail("headers must be an array")

    by_source: dict[str, dict[str, str]] = {}
    for rule in header_rules:
        source = rule.get("source")
        values = rule.get("headers")
        if not isinstance(source, str) or not isinstance(values, list):
            fail("each header rule needs a source and a headers array")
        by_source[source] = {
            item.get("key", "").lower(): item.get("value", "")
            for item in values
            if isinstance(item, dict)
        }

    required_global = {
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
        "referrer-policy": "strict-origin-when-cross-origin",
        "permissions-policy": "camera=(), microphone=(), geolocation=()",
        "x-robots-tag": "noindex, nofollow, noarchive",
    }
    global_headers = by_source.get("/(.*)", {})
    for key, value in required_global.items():
        if global_headers.get(key) != value:
            fail(f"global header {key} must be {value!r}")

    required_revalidation_paths = (
        "/",
        "/index.html",
        "/service-worker.js",
        "/flutter_bootstrap.js",
        "/flutter_service_worker.js",
        "/flutter.js",
        "/version.json",
        "/manifest.json",
    )
    for path in required_revalidation_paths:
        cache_control = by_source.get(path, {}).get("cache-control", "")
        if "no-cache" not in cache_control or "no-store" not in cache_control:
            fail(f"{path} must be configured with no-cache and no-store")

    rewrites = config.get("rewrites")
    if not isinstance(rewrites, list) or not any(
        rule.get("source") == "/(.*)" and rule.get("destination") == "/index.html"
        for rule in rewrites
    ):
        fail("Flutter Web must retain the SPA fallback rewrite to /index.html")

    print("Vercel config security headers, no-index, SPA fallback and cache rules: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
