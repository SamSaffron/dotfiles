#!/usr/bin/env python3
"""Return compact Docker container telemetry for the Quickshell bar."""

import json
import subprocess
import sys


def output(value: dict) -> None:
    json.dump(value, sys.stdout, separators=(",", ":"))


def main() -> None:
    try:
        result = subprocess.run(
            [
                "docker", "ps", "-a", "--format",
                "{{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.State}}\\t{{.Status}}\\t{{.Ports}}",
            ],
            capture_output=True,
            check=False,
            text=True,
            timeout=4,
        )
    except FileNotFoundError:
        output({"available": False, "running": [], "stopped": [], "error": "Docker is not installed"})
        return
    except subprocess.TimeoutExpired:
        output({"available": False, "running": [], "stopped": [], "error": "Docker did not respond"})
        return

    if result.returncode != 0:
        error = result.stderr.strip().splitlines()
        output({
            "available": False,
            "running": [],
            "stopped": [],
            "error": error[-1] if error else "Could not contact Docker",
        })
        return

    containers = []
    for line in result.stdout.splitlines():
        fields = line.split("\t")
        if len(fields) < 5:
            continue
        container_id, name, image, state, status = fields[:5]
        ports = fields[5] if len(fields) > 5 else ""
        health = "unhealthy" if "(unhealthy)" in status else "healthy" if "(healthy)" in status else "none"
        containers.append({
            "id": container_id[:12],
            "name": name or "Unnamed container",
            "image": image or "Unknown image",
            "state": state or "unknown",
            "status": status or "Unknown status",
            "health": health,
            "ports": ports,
        })

    running = [item for item in containers if item["state"] == "running"]
    stopped = [item for item in containers if item["state"] != "running"]
    output({"available": True, "running": running, "stopped": stopped, "error": ""})


if __name__ == "__main__":
    main()
