#!/usr/bin/env python3
"""Collect and normalize live term-llm subscription usage.

The cache contains only quota summaries, never credentials or raw provider
responses. Successful provider results survive a temporary failure in another
provider, and writes are atomic so Quickshell never reads partial JSON.
"""

from __future__ import annotations

import argparse
import calendar
import concurrent.futures
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PROVIDERS = ("chatgpt", "claude-bin", "opencode-go", "cursor-bin", "grok", "agy-bin")
CACHE_TTL_SECONDS = 3600


def cache_path() -> Path:
    root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return root / "quickshell" / "term-llm-usage.json"


def read_cache(path: Path) -> dict[str, Any] | None:
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else None
    except (OSError, json.JSONDecodeError):
        return None


def term_llm_path() -> str:
    executable = shutil.which("term-llm")
    if executable:
        return executable
    fallback = Path.home() / ".local" / "bin" / "term-llm"
    if fallback.is_file():
        return str(fallback)
    raise FileNotFoundError("term-llm was not found in PATH or ~/.local/bin")


def fetch(provider: str) -> dict[str, Any]:
    result = subprocess.run(
        [term_llm_path(), "-p", provider, "usage", "--json"],
        check=True,
        capture_output=True,
        text=True,
        timeout=60,
    )
    return json.loads(result.stdout)


def iso_from_millis(value: Any) -> str | None:
    try:
        return datetime.fromtimestamp(int(value) / 1000, timezone.utc).isoformat()
    except (TypeError, ValueError, OSError):
        return None


def limit(
    name: str,
    percent: Any,
    resets_at: Any = None,
    detail: str = "",
    *,
    window_seconds: Any = None,
    starts_at: Any = None,
) -> dict[str, Any]:
    try:
        normalized = max(0.0, min(100.0, float(percent)))
    except (TypeError, ValueError):
        normalized = 0.0
    try:
        normalized_window = max(0, int(window_seconds)) if window_seconds is not None else None
    except (TypeError, ValueError):
        normalized_window = None
    return {
        "name": name,
        "percent": round(normalized, 1),
        "resets_at": resets_at or None,
        "starts_at": starts_at or None,
        "window_seconds": normalized_window,
        "detail": detail,
    }


def previous_month_start(resets_at: Any) -> str | None:
    """Return the matching date one calendar month before an ISO reset time."""
    try:
        reset = datetime.fromisoformat(str(resets_at).replace("Z", "+00:00"))
        year = reset.year if reset.month > 1 else reset.year - 1
        month = reset.month - 1 if reset.month > 1 else 12
        day = min(reset.day, calendar.monthrange(year, month)[1])
        return reset.replace(year=year, month=month, day=day).isoformat()
    except (TypeError, ValueError):
        return None


def window_detail(minutes: Any) -> str:
    try:
        normalized = int(minutes)
    except (TypeError, ValueError):
        return ""
    if normalized <= 0:
        return ""

    units = (
        (7 * 24 * 60, "week"),
        (24 * 60, "day"),
        (60, "hour"),
    )
    for unit_minutes, name in units:
        if normalized % unit_minutes == 0:
            count = normalized // unit_minutes
            return f"{count} {name} window"
    return f"{normalized} minute window"


def normalize_chatgpt(raw: dict[str, Any]) -> dict[str, Any]:
    limits = []
    for item in raw.get("limits", []):
        for window_name in ("primary_window", "secondary_window"):
            window = item.get(window_name) or {}
            if not window:
                continue
            minutes = window.get("duration_minutes")
            limits.append(limit(
                item.get("name", "Usage"),
                window.get("used_percent"),
                window.get("resets_at"),
                window_detail(minutes),
                window_seconds=minutes * 60 if minutes else None,
            ))
    return {
        "id": "chatgpt",
        "name": "ChatGPT",
        "icon": "󰭹",
        "source": "chatgpt",
        "plan": str(raw.get("plan", "subscription")).title(),
        "limits": limits,
    }


def normalize_claude(raw: dict[str, Any]) -> dict[str, Any]:
    rates = raw.get("rate_limits") or {}
    limits = []
    five_hour = rates.get("five_hour") or {}
    seven_day = rates.get("seven_day") or {}
    limits.append(limit(
        "Current session",
        five_hour.get("utilization"),
        five_hour.get("resets_at"),
        "5 hour window",
        window_seconds=5 * 60 * 60,
    ))
    limits.append(limit(
        "All models",
        seven_day.get("utilization"),
        seven_day.get("resets_at"),
        "7 day window",
        window_seconds=7 * 24 * 60 * 60,
    ))
    for item in rates.get("model_scoped") or []:
        limits.append(limit(
            item.get("display_name", "Model"),
            item.get("utilization"),
            item.get("resets_at"),
            "7 day model limit",
            window_seconds=7 * 24 * 60 * 60,
        ))
    extra = rates.get("extra_usage") or {}
    if extra.get("credits_ever_enabled"):
        state = "enabled" if extra.get("is_enabled") else "disabled"
        limits.append(limit("Extra usage", extra.get("utilization"), None, state))
    return {
        "id": "claude-bin",
        "name": "Claude",
        "icon": "󰚩",
        "source": "claude-bin",
        "plan": str(raw.get("subscription_type", "subscription")).title(),
        "limits": limits,
    }


def normalize_opencode(raw: dict[str, Any]) -> dict[str, Any]:
    limits = []
    for item in raw.get("limits", []):
        window = item.get("primary_window") or {}
        resets_at = window.get("resets_at")
        minutes = window.get("duration_minutes")
        label = window.get("label", "")
        limits.append(limit(
            item.get("name", "Usage"),
            window.get("used_percent"),
            resets_at,
            label,
            window_seconds=minutes * 60 if minutes else None,
            starts_at=previous_month_start(resets_at) if not minutes and "month" in label.lower() else None,
        ))
    return {
        "id": "opencode-go",
        "name": "OpenCode Go",
        "icon": "󰘦",
        "source": "opencode-go",
        "plan": "Subscription",
        "limits": limits,
    }


def normalize_cursor(raw: dict[str, Any]) -> dict[str, Any]:
    usage = raw.get("planUsage") or {}
    reset = iso_from_millis(raw.get("billingCycleEnd"))
    start = iso_from_millis(raw.get("billingCycleStart"))
    limits = [
        limit("Total usage", usage.get("totalPercentUsed"), reset, "billing cycle", starts_at=start),
        limit("API models", usage.get("apiPercentUsed"), reset, "included API usage", starts_at=start),
        limit("Auto models", usage.get("autoPercentUsed"), reset, "included auto usage", starts_at=start),
    ]
    return {
        "id": "cursor-bin",
        "name": "Cursor",
        "icon": "󰇀",
        "source": "cursor-bin",
        "plan": "Subscription",
        "limits": limits,
    }


def normalize_grok(raw: dict[str, Any]) -> dict[str, Any]:
    limits = []
    for item in raw.get("limits", []):
        window = item.get("primary_window") or {}
        minutes = window.get("duration_minutes")
        limits.append(limit(
            item.get("name", "Usage"),
            window.get("used_percent"),
            window.get("resets_at"),
            window.get("label", ""),
            window_seconds=minutes * 60 if minutes else None,
        ))
    return {
        "id": "grok",
        "name": "Grok",
        "icon": "𝕏",
        "source": "grok",
        "plan": "Subscription",
        "limits": limits,
    }


def normalize_agy(raw: dict[str, Any]) -> dict[str, Any]:
    limits = []
    for group in raw.get("groups", []):
        group_name = str(group.get("name", "Models"))
        if group_name == "Gemini Models":
            group_name = "Gemini"
        elif group_name == "Claude and GPT models":
            group_name = "Claude/GPT"
        for bucket in group.get("buckets", []):
            window = str(bucket.get("window", ""))
            window_name = "5 hour" if window == "5h" else window.title()
            try:
                used_percent = (1 - float(bucket.get("remaining_fraction", 1))) * 100
            except (TypeError, ValueError):
                used_percent = 0
            limits.append(limit(
                f"{group_name} {window_name}".strip(),
                used_percent,
                bucket.get("reset_time"),
                bucket.get("description", ""),
                window_seconds=5 * 60 * 60 if window == "5h" else 7 * 24 * 60 * 60 if window == "weekly" else None,
            ))
    return {
        "id": "agy-bin",
        "name": "Gemini",
        "icon": "✦",
        "source": "agy-bin",
        "plan": "Subscription",
        "limits": limits,
    }


NORMALIZERS = {
    "chatgpt": normalize_chatgpt,
    "claude-bin": normalize_claude,
    "opencode-go": normalize_opencode,
    "cursor-bin": normalize_cursor,
    "grok": normalize_grok,
    "agy-bin": normalize_agy,
}


def refresh_provider(provider: str, previous: dict[str, Any] | None) -> dict[str, Any]:
    try:
        normalized = NORMALIZERS[provider](fetch(provider))
        normalized.update({"stale": False, "error": ""})
    except Exception as error:  # Preserve the last known good data for this provider.
        normalized = dict(previous or {
            "id": provider,
            "name": provider,
            "icon": "󰅚",
            "source": provider,
            "plan": "Unavailable",
            "limits": [],
        })
        normalized.update({"stale": True, "error": str(error)})
    return normalized


def refresh(previous: dict[str, Any] | None) -> dict[str, Any]:
    previous_by_id = {item.get("id"): item for item in (previous or {}).get("providers", [])}

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(PROVIDERS)) as executor:
        futures = [
            executor.submit(refresh_provider, provider, previous_by_id.get(provider))
            for provider in PROVIDERS
        ]
        providers = [future.result() for future in futures]

    return {
        "updated_at": datetime.now().astimezone().isoformat(),
        "providers": providers,
    }


def write_cache(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(handle, "w") as temporary:
            json.dump(value, temporary, separators=(",", ":"))
            temporary.write("\n")
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except OSError:
            pass
        raise


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="ignore the one-hour cache TTL")
    args = parser.parse_args()

    path = cache_path()
    cached = read_cache(path)
    if not args.force and cached:
        try:
            cached_ids = {item.get("id") for item in cached.get("providers", [])}
            age = datetime.now().astimezone() - datetime.fromisoformat(cached["updated_at"])
            if age.total_seconds() < CACHE_TTL_SECONDS and set(PROVIDERS) <= cached_ids:
                json.dump(cached, sys.stdout)
                return 0
        except (KeyError, TypeError, ValueError):
            pass

    value = refresh(cached)
    write_cache(path, value)
    json.dump(value, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
