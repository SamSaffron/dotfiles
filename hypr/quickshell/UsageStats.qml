import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property var providers: []
    property string updatedAt: ""
    property string error: ""
    readonly property bool loading: usageProcess.running
    readonly property real maximumPercent: {
        let maximum = 0
        for (const provider of providers) {
            for (const item of provider.limits || [])
                maximum = Math.max(maximum, Number(item.percent) || 0)
        }
        return maximum
    }
    readonly property var indicator: {
        let paced = null
        let fallback = null

        for (const provider of providers) {
            for (const item of provider.limits || []) {
                const percent = Math.max(0, Math.min(100, Number(item.percent) || 0))
                const candidate = {
                    "name": item.name || provider.name,
                    "provider": provider.name,
                    "percent": percent,
                    "pace": -1,
                    "projected": percent,
                    "stale": Boolean(provider.stale),
                }

                if (!fallback || percent > fallback.percent)
                    fallback = candidate

                const pace = root.pacePercent(item)
                if (pace <= 5)
                    continue

                candidate.pace = pace
                candidate.projected = percent * 100 / pace
                if (!paced || candidate.projected > paced.projected)
                    paced = candidate
            }
        }

        return paced || fallback || {
            "name": "Usage",
            "provider": "",
            "percent": 0,
            "pace": -1,
            "projected": 0,
            "stale": false,
        }
    }

    function pacePercent(value) {
        if (!value || !value.resets_at)
            return -1

        const end = new Date(value.resets_at).getTime()
        const now = Date.now()
        if (!isFinite(end) || end <= now)
            return -1

        let start = NaN
        if (value.starts_at)
            start = new Date(value.starts_at).getTime()
        else if (value.window_seconds > 0)
            start = end - value.window_seconds * 1000

        if (!isFinite(start) || start >= end)
            return -1
        return Math.max(0, Math.min(100, (now - start) * 100 / (end - start)))
    }

    function refresh(force) {
        if (usageProcess.running)
            return
        error = ""
        const command = [Quickshell.shellDir + "/usage-cache.py"]
        if (force)
            command.push("--force")
        usageProcess.exec(command)
    }

    Process {
        id: usageProcess
        command: [Quickshell.shellDir + "/usage-cache.py"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text.trim())
                    root.providers = value.providers || []
                    root.updatedAt = value.updated_at || ""
                    root.error = ""
                } catch (error) {
                    root.error = "Could not read usage cache"
                    console.warn("Could not parse term-llm usage:", error)
                }
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refresh(true)
    }
}
