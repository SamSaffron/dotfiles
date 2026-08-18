#!/usr/bin/env python3
"""Report the busiest CPU and memory processes using interval /proc samples."""

from __future__ import annotations

import json
import os
import tempfile
import time
from pathlib import Path
from typing import Any

CPU_THRESHOLD_PERCENT = 1.0
MEMORY_THRESHOLD_MIB = 100.0
MAX_RESULTS = 10
CLOCK_TICKS = os.sysconf("SC_CLK_TCK")
PAGE_SIZE = os.sysconf("SC_PAGE_SIZE")


def state_path() -> Path:
    cache_root = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache_root / "quickshell" / "process-samples.json"


def read_previous(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def read_processes() -> dict[str, dict[str, Any]]:
    processes: dict[str, dict[str, Any]] = {}
    own_pid = os.getpid()

    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit() or int(entry.name) == own_pid:
            continue
        try:
            stat = (entry / "stat").read_text()
            closing = stat.rfind(")")
            fields = stat[closing + 2 :].split()
            ticks = int(fields[11]) + int(fields[12])
            start_ticks = fields[19]
            rss_bytes = max(0, int(fields[21])) * PAGE_SIZE
            name = (entry / "comm").read_text().strip() or entry.name
        except (OSError, ValueError, IndexError):
            continue

        key = f"{entry.name}:{start_ticks}"
        processes[key] = {
            "pid": int(entry.name),
            "name": name,
            "ticks": ticks,
            "rss_bytes": rss_bytes,
        }

    return processes


def write_state(path: Path, timestamp: float, processes: dict[str, dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    state = {
        "timestamp": timestamp,
        "processes": {key: value["ticks"] for key, value in processes.items()},
    }
    handle, temporary_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(handle, "w") as temporary:
            json.dump(state, temporary, separators=(",", ":"))
            temporary.write("\n")
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except OSError:
            pass
        raise


def main() -> int:
    path = state_path()
    previous = read_previous(path)
    now = time.time()
    processes = read_processes()
    previous_time = float(previous.get("timestamp") or 0)
    elapsed = now - previous_time
    previous_ticks = previous.get("processes") or {}

    rows = []
    for key, process in processes.items():
        old_ticks = previous_ticks.get(key)
        cpu_percent = 0.0
        if old_ticks is not None and elapsed > 0:
            cpu_percent = max(0.0, (process["ticks"] - int(old_ticks)) * 100 / (CLOCK_TICKS * elapsed))
        rows.append({
            "pid": process["pid"],
            "name": process["name"],
            "cpu_percent": round(cpu_percent, 1),
            "rss_mib": round(process["rss_bytes"] / 1048576, 1),
        })

    cpu = sorted(
        (row for row in rows if row["cpu_percent"] >= CPU_THRESHOLD_PERCENT and row["rss_mib"] > 0),
        key=lambda row: row["cpu_percent"],
        reverse=True,
    )[:MAX_RESULTS]
    memory = sorted(
        (row for row in rows if row["rss_mib"] >= MEMORY_THRESHOLD_MIB),
        key=lambda row: row["rss_mib"],
        reverse=True,
    )[:MAX_RESULTS]

    write_state(path, now, processes)
    json.dump({"cpu": cpu, "memory": memory}, os.sys.stdout, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
