import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool overviewOpen: false
    property bool controlCenterOpen: false
    property string controlCenterPage: "controls"
    property bool weatherOpen: false
    property bool audioOpen: false
    property bool usageOpen: false
    property bool hardwareOpen: false
    property string hardwareMetric: "cpu"
    property bool systemInfoOpen: false
    property string systemInfoMetric: "updates"
    property bool dockerOpen: false
    property bool doNotDisturb: false
    property var notificationHistory: []
    property int notificationUnread: 0
    property var popupScreen: null
    property alias clock: systemClock
    readonly property var focusedScreen: {
        const monitor = Hyprland.focusedMonitor
        if (!monitor)
            return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        return Quickshell.screens.find(screen => screen.name === monitor.name) || Quickshell.screens[0]
    }

    function recordNotification(entry, unread) {
        const existing = notificationHistory.filter(item => item.id !== entry.id)
        notificationHistory = [entry].concat(existing).slice(0, 30)
        if (unread)
            notificationUnread++
    }

    function dismissNotificationHistory(id) {
        notificationHistory = notificationHistory.filter(item => item.id !== id)
    }

    function clearNotificationHistory() {
        notificationHistory = []
        notificationUnread = 0
    }

    function markNotificationsRead() {
        notificationUnread = 0
    }

    function closePopups() {
        launcherOpen = false
        overviewOpen = false
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
        overviewOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        launcherOpen = !launcherOpen
    }

    function toggleOverview(screen) {
        const opening = !overviewOpen
        popupScreen = screen || focusedScreen
        launcherOpen = false
        controlCenterOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        overviewOpen = opening
    }

    function toggleControlCenter(screen) {
        const opening = !controlCenterOpen
        popupScreen = screen || focusedScreen
        launcherOpen = false
        overviewOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        if (opening)
            controlCenterPage = "controls"
        controlCenterOpen = opening
    }

    function showNotificationCenter(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        overviewOpen = false
        weatherOpen = false
        audioOpen = false
        usageOpen = false
        hardwareOpen = false
        systemInfoOpen = false
        dockerOpen = false
        controlCenterPage = "notifications"
        controlCenterOpen = true
        markNotificationsRead()
    }

    function toggleWeather(screen) {
        popupScreen = screen || focusedScreen
        launcherOpen = false
        overviewOpen = false
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
        overviewOpen = false
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
        overviewOpen = false
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
        overviewOpen = false
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
        overviewOpen = false
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
        overviewOpen = false
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

        function toggleOverview(): void {
            root.toggleOverview(root.focusedScreen)
        }

        function toggleControlCenter(): void {
            root.toggleControlCenter(root.focusedScreen)
        }

        function showNotifications(): void {
            root.showNotificationCenter(root.focusedScreen)
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

    Variants {
        model: Quickshell.screens

        WindowOverview {
            shell: root
        }
    }

    Notifications {
        shell: root
    }
}
