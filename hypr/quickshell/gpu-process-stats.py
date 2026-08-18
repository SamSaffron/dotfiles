#!/usr/bin/env python3
"""Report active NVIDIA GPU processes and the largest VRAM clients."""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
from typing import Any

try:
    import pynvml
except ImportError:
    json.dump({"active": [], "clients": [], "error": "NVML Python bindings unavailable"}, sys.stdout, separators=(",", ":"))
    raise SystemExit(0)

ACTIVE_THRESHOLD_PERCENT = 5
VRAM_THRESHOLD_MIB = 25
MAX_RESULTS = 5


def process_name(pid: int) -> str:
    try:
        command = Path(f"/proc/{pid}/comm").read_text().strip()
        return command or str(pid)
    except OSError:
        return str(pid)


def memory_mib(value: Any) -> float:
    try:
        number = int(value)
        if number < 0 or number >= 2**63:
            return 0.0
        return round(number / 1048576, 1)
    except (TypeError, ValueError):
        return 0.0


def running_processes(handle: Any) -> dict[int, float]:
    clients: dict[int, float] = {}
    for getter in (pynvml.nvmlDeviceGetGraphicsRunningProcesses, pynvml.nvmlDeviceGetComputeRunningProcesses):
        try:
            for process in getter(handle):
                pid = int(process.pid)
                clients[pid] = max(clients.get(pid, 0.0), memory_mib(process.usedGpuMemory))
        except pynvml.NVMLError:
            continue
    return clients


def utilization_samples(handle: Any) -> dict[int, dict[str, int]]:
    latest: dict[int, dict[str, int]] = {}
    since = int((time.time() - 8) * 1_000_000)
    try:
        samples = pynvml.nvmlDeviceGetProcessUtilization(handle, since)
    except pynvml.NVMLError:
        return latest

    for sample in samples:
        pid = int(sample.pid)
        timestamp = int(sample.timeStamp)
        previous = latest.get(pid)
        if previous and previous["timestamp"] >= timestamp:
            continue
        latest[pid] = {
            "timestamp": timestamp,
            "sm_percent": max(0, int(sample.smUtil)),
            "memory_percent": max(0, int(sample.memUtil)),
            "encoder_percent": max(0, int(sample.encUtil)),
            "decoder_percent": max(0, int(sample.decUtil)),
        }
    return latest


def main() -> int:
    try:
        pynvml.nvmlInit()
        handle = pynvml.nvmlDeviceGetHandleByIndex(0)
        clients = running_processes(handle)
        samples = utilization_samples(handle)
    except pynvml.NVMLError as error:
        json.dump({"active": [], "clients": [], "error": str(error)}, sys.stdout, separators=(",", ":"))
        return 0
    finally:
        try:
            pynvml.nvmlShutdown()
        except pynvml.NVMLError:
            pass

    active = []
    for pid, sample in samples.items():
        if not Path(f"/proc/{pid}").exists():
            continue
        peak = max(sample["sm_percent"], sample["memory_percent"], sample["encoder_percent"], sample["decoder_percent"])
        if peak < ACTIVE_THRESHOLD_PERCENT:
            continue
        active.append({
            "pid": pid,
            "name": process_name(pid),
            "sm_percent": sample["sm_percent"],
            "memory_percent": sample["memory_percent"],
            "encoder_percent": sample["encoder_percent"],
            "decoder_percent": sample["decoder_percent"],
            "vram_mib": clients.get(pid, 0.0),
            "peak_percent": peak,
        })

    active.sort(key=lambda row: (row["peak_percent"], row["vram_mib"]), reverse=True)
    vram_clients = [
        {"pid": pid, "name": process_name(pid), "vram_mib": used}
        for pid, used in clients.items()
        if used >= VRAM_THRESHOLD_MIB and Path(f"/proc/{pid}").exists()
    ]
    vram_clients.sort(key=lambda row: row["vram_mib"], reverse=True)

    json.dump(
        {"active": active[:MAX_RESULTS], "clients": vram_clients[:MAX_RESULTS], "error": ""},
        sys.stdout,
        separators=(",", ":"),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
