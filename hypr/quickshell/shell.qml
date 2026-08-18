import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool weatherOpen: false
    property bool audioOpen: false
    property bool usageOpen: false
    property bool hardwareOpen: false
    property string hardwareMetric: "cpu"
    property bool systemInfoOpen: false
    property string systemInfoMetric: "updates"
    property bool dockerOpen: false
    property bool doNotDisturb: false
    property var popupScreen: null
    property alias clock: systemClock
    readonly property var focusedScreen: {
        const monitor = Hyprland.focusedMonitor
        if (!monitor)
            return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        return Quickshell.screens.find(screen => screen.name === monitor.name) || Quickshell.screens[0]
    }

    function closePopups() {
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
    }

    function toggleLauncher(screen) {
        popupScreen = screen || focusedScreen
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        launcherOpen = !launcherOpen
    }

    function toggleControlCenter(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        controlCenterOpen = !controlCenterOpen
    }

    function toggleWeather(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        weatherOpen = !weatherOpen
    }

    function toggleAudio(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        audioOpen = !audioOpen
    }

    function toggleUsage(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        usageOpen = !usageOpen
    }

    function toggleHardware(metric, screen) {
        const opening = !hardwareOpen || hardwareMetric !== metric
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        systemInfoOpen = false
        dockerOpen = false
        hardwareMetric = metric
        hardwareOpen = opening
    }

    function toggleSystemInfo(metric, screen) {
        const opening = !systemInfoOpen || systemInfoMetric !== metric
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        dockerOpen = false
        systemInfoMetric = metric
        systemInfoOpen = opening
    }

    function toggleDocker(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = !dockerOpen
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    SystemStats {
        id: systemStats
    }

    UsageStats {
        id: usageStats
    }

    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            root.toggleLauncher(root.focusedScreen)
        }

        function toggleControlCenter(): void {
            root.toggleControlCenter(root.focusedScreen)
        }

        function toggleUsage(): void {
            root.toggleUsage(root.focusedScreen)
        }

        function toggleCpu(): void {
            root.toggleHardware("cpu", root.focusedScreen)
        }

        function toggleMemory(): void {
            root.toggleHardware("memory", root.focusedScreen)
        }

        function toggleGpu(): void {
            root.toggleHardware("gpu", root.focusedScreen)
        }

        function toggleUpdates(): void {
            root.toggleSystemInfo("updates", root.focusedScreen)
        }

        function toggleDisk(): void {
            root.toggleSystemInfo("disk", root.focusedScreen)
        }

        function toggleDocker(): void {
            root.toggleDocker(root.focusedScreen)
        }

        function closePopups(): void {
            root.closePopups()
        }

        function toggleDoNotDisturb(): void {
            root.doNotDisturb = !root.doNotDisturb
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            shell: root
            stats: systemStats
            usage: usageStats
        }
    }

    Variants {
        model: Quickshell.screens

        Launcher {
            shell: root
        }
    }

    Notifications {
        shell: root
    }
}
