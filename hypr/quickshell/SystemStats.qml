import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property int cpu: 0
    property int cpuTemperature: -1
    property int cpuMhz: -1
    property int cpuThreads: 0
    property real load1: 0
    property real load5: 0
    property real load15: 0
    property int memory: 0
    property real memoryTotalKib: 0
    property real memoryUsedKib: 0
    property real memoryAvailableKib: 0
    property real memoryCachedKib: 0
    property real swapTotalKib: 0
    property real swapUsedKib: 0
    property int gpu: -1
    property int gpuMemoryUtil: -1
    property real gpuMemoryUsedMib: -1
    property real gpuMemoryTotalMib: -1
    property int gpuTemperature: -1
    property real gpuPower: -1
    property real gpuPowerLimit: -1
    property int gpuClockMhz: -1
    property int disk: 0
    property real diskTotalKib: 0
    property real diskUsedKib: 0
    property real diskAvailableKib: 0
    property string diskDevice: ""
    property string diskType: ""
    property string diskMount: "/"
    property var cpuProcesses: []
    property var memoryProcesses: []
    property var gpuActiveProcesses: []
    property var gpuClients: []
    property string gpuProcessError: ""
    property int dockerRunning: 0
    property var dockerRunningContainers: []
    property var dockerStoppedContainers: []
    property string dockerError: ""
    property bool dockerAvailable: false
    property int updates: 0
    property var updatesList: []
    property string updatesCheckedAt: ""
    readonly property bool updatesLoading: updatesProcess.running
    property string weather: "--°C"
    property string weatherDescription: "Weather unavailable"
    property string weatherLocation: "Sydney"
    property string weatherFeelsLike: "--°C"
    property string weatherHumidity: "--%"
    property string weatherWind: "-- km/h"
    property string weatherObservedAt: ""
    property var hourlyForecast: []
    property var dailyForecast: []
    property bool weatherAvailable: false

    readonly property string configDir: Quickshell.shellDir

    function refreshWeather() {
        if (!weatherProcess.running)
            weatherProcess.running = true
    }

    function refreshDocker() {
        if (!dockerProcess.running)
            dockerProcess.running = true
    }

    function handleDockerEvent(data) {
        const action = data.trim().split(":")[0]
        const refreshActions = [
            "create", "destroy", "die", "health_status", "kill", "oom", "pause",
            "rename", "restart", "start", "stop", "unpause", "update"
        ]
        if (refreshActions.indexOf(action) >= 0)
            dockerRefreshDebounce.restart()
    }

    function refreshUpdates() {
        if (!updatesProcess.running)
            updatesProcess.running = true
    }

    function formatTemperature(value) {
        const number = Number(value)
        return (Math.round(number * 10) / 10).toString() + "°C"
    }

    function describeWeather(code) {
        if (code === 0) return "Clear sky"
        if (code === 1) return "Mostly clear"
        if (code === 2) return "Partly cloudy"
        if (code === 3) return "Overcast"
        if (code === 45 || code === 48) return "Foggy"
        if (code >= 51 && code <= 57) return "Drizzle"
        if (code >= 61 && code <= 67) return "Rain"
        if (code >= 71 && code <= 77) return "Snow"
        if (code >= 80 && code <= 82) return "Rain showers"
        if (code >= 85 && code <= 86) return "Snow showers"
        if (code >= 95) return "Thunderstorm"
        return "Current conditions"
    }

    Process {
        id: statsProcess
        command: [root.configDir + "/system-stats.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text.trim())
                    root.cpu = value.cpu
                    root.cpuTemperature = value.cpu_temp ?? -1
                    root.cpuMhz = value.cpu_mhz ?? -1
                    root.cpuThreads = value.cpu_threads ?? 0
                    root.load1 = value.load_1 ?? 0
                    root.load5 = value.load_5 ?? 0
                    root.load15 = value.load_15 ?? 0
                    root.memory = value.memory
                    root.memoryTotalKib = value.memory_total_kib ?? 0
                    root.memoryUsedKib = value.memory_used_kib ?? 0
                    root.memoryAvailableKib = value.memory_available_kib ?? 0
                    root.memoryCachedKib = value.memory_cached_kib ?? 0
                    root.swapTotalKib = value.swap_total_kib ?? 0
                    root.swapUsedKib = value.swap_used_kib ?? 0
                    root.gpu = value.gpu ?? -1
                    root.gpuMemoryUtil = value.gpu_memory_util ?? -1
                    root.gpuMemoryUsedMib = value.gpu_memory_used_mib ?? -1
                    root.gpuMemoryTotalMib = value.gpu_memory_total_mib ?? -1
                    root.gpuTemperature = value.gpu_temp ?? -1
                    root.gpuPower = value.gpu_power ?? -1
                    root.gpuPowerLimit = value.gpu_power_limit ?? -1
                    root.gpuClockMhz = value.gpu_clock ?? -1
                    root.disk = value.disk
                    root.diskTotalKib = value.disk_total_kib ?? 0
                    root.diskUsedKib = value.disk_used_kib ?? 0
                    root.diskAvailableKib = value.disk_available_kib ?? 0
                    root.diskDevice = value.disk_device || ""
                    root.diskType = value.disk_type || ""
                    root.diskMount = value.disk_mount || "/"
                } catch (error) {
                    console.warn("Could not parse system statistics:", error)
                }
            }
        }
    }

    Process {
        id: processStatsProcess
        command: [root.configDir + "/process-stats.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text.trim())
                    root.cpuProcesses = value.cpu || []
                    root.memoryProcesses = value.memory || []
                } catch (error) {
                    console.warn("Could not parse process statistics:", error)
                }
            }
        }
    }

    Process {
        id: gpuProcessStatsProcess
        command: [root.configDir + "/gpu-process-stats.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text.trim())
                    root.gpuActiveProcesses = value.active || []
                    root.gpuClients = value.clients || []
                    root.gpuProcessError = value.error || ""
                } catch (error) {
                    root.gpuProcessError = "Could not read GPU processes"
                    console.warn("Could not parse GPU process statistics:", error)
                }
            }
        }
    }

    Process {
        id: dockerProcess
        command: ["python3", root.configDir + "/docker-stats.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text.trim())
                    root.dockerAvailable = value.available || false
                    root.dockerRunningContainers = value.running || []
                    root.dockerStoppedContainers = value.stopped || []
                    root.dockerRunning = root.dockerRunningContainers.length
                    root.dockerError = value.error || ""
                } catch (error) {
                    root.dockerAvailable = false
                    root.dockerRunning = 0
                    root.dockerError = "Could not read Docker containers"
                    console.warn("Could not parse Docker statistics:", error)
                }
            }
        }
    }

    Process {
        id: dockerEventsProcess
        command: [
            "docker", "events", "--filter", "type=container",
            "--filter", "event=create", "--filter", "event=destroy",
            "--filter", "event=die", "--filter", "event=health_status",
            "--filter", "event=kill", "--filter", "event=oom",
            "--filter", "event=pause", "--filter", "event=rename",
            "--filter", "event=restart", "--filter", "event=start",
            "--filter", "event=stop", "--filter", "event=unpause",
            "--filter", "event=update", "--format", "{{.Action}}"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => root.handleDockerEvent(data)
        }

        onStarted: {
            if (!root.dockerAvailable)
                root.refreshDocker()
        }

        onRunningChanged: {
            if (!running) {
                root.dockerAvailable = false
                root.dockerError = "Docker event stream disconnected"
            }
        }
    }

    Process {
        id: updatesProcess
        command: ["sh", "-c", "checkupdates 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim() ? text.trim().split("\n") : []
                root.updatesList = lines.map(line => {
                    const match = line.match(/^(\S+)\s+(\S+)\s+->\s+(\S+)$/)
                    return match ? { name: match[1], current: match[2], available: match[3] }
                                 : { name: line, current: "", available: "" }
                })
                root.updates = root.updatesList.length
                root.updatesCheckedAt = new Date().toISOString()
            }
        }
    }

    Process {
        id: weatherProcess
        command: ["sh", "-c", "curl -fsS --max-time 8 'https://api.open-meteo.com/v1/forecast?latitude=-33.8688&longitude=151.2093&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m&hourly=temperature_2m,precipitation_probability,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&temperature_unit=celsius&wind_speed_unit=kmh&timezone=Australia%2FSydney&forecast_days=5' 2>/dev/null || printf '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text.trim())
                    const current = value.current
                    if (!current || current.temperature_2m === undefined)
                        throw new Error("no current weather in response")

                    root.weather = root.formatTemperature(current.temperature_2m)
                    root.weatherDescription = root.describeWeather(current.weather_code)
                    root.weatherLocation = "Sydney"
                    root.weatherFeelsLike = root.formatTemperature(current.apparent_temperature)
                    root.weatherHumidity = current.relative_humidity_2m + "%"
                    root.weatherWind = current.wind_speed_10m + " km/h"
                    root.weatherObservedAt = current.time ? current.time.slice(11, 16) : Qt.formatDateTime(new Date(), "HH:mm")

                    const hourly = value.hourly
                    const firstHour = hourly && hourly.time
                                      ? Math.max(0, hourly.time.findIndex(time => time >= current.time))
                                      : -1
                    root.hourlyForecast = firstHour >= 0 ? hourly.time.slice(firstHour, firstHour + 4).map((time, offset) => {
                        const index = firstHour + offset
                        return {
                            time: time.slice(11, 16),
                            temperature: root.formatTemperature(hourly.temperature_2m[index]),
                            description: root.describeWeather(hourly.weather_code[index]),
                            precipitation: (hourly.precipitation_probability[index] ?? 0) + "%"
                        }
                    }) : []

                    const daily = value.daily
                    root.dailyForecast = daily && daily.time ? daily.time.slice(0, 4).map((date, index) => {
                        return {
                            date: date,
                            high: root.formatTemperature(daily.temperature_2m_max[index]),
                            low: root.formatTemperature(daily.temperature_2m_min[index]),
                            description: root.describeWeather(daily.weather_code[index]),
                            precipitation: (daily.precipitation_probability_max[index] ?? 0) + "%"
                        }
                    }) : []

                    root.weatherAvailable = true
                } catch (error) {
                    root.weatherAvailable = false
                    console.warn("Could not parse weather:", error)
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!statsProcess.running) statsProcess.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!processStatsProcess.running) processStatsProcess.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!gpuProcessStatsProcess.running) gpuProcessStatsProcess.running = true
    }

    Timer {
        id: dockerRefreshDebounce
        interval: 250
        onTriggered: root.refreshDocker()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!dockerEventsProcess.running)
                dockerEventsProcess.running = true
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: if (!updatesProcess.running) updatesProcess.running = true
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: if (!weatherProcess.running) weatherProcess.running = true
    }
}
