import Quickshell
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var stats
    required property var anchorWindow
    required property var cpuAnchor
    required property var memoryAnchor
    required property var gpuAnchor
    required property var targetScreen

    readonly property string metric: shell.hardwareMetric
    readonly property var selectedAnchor: memoryAnchor
    readonly property real currentValue: metric === "memory" ? stats.memory : metric === "gpu" ? stats.gpu : stats.cpu
    readonly property string title: metric === "memory" ? "Memory activity" : metric === "gpu" ? "GPU activity" : "CPU activity"
    readonly property string subtitle: metric === "memory" ? "Physical memory and swap" : metric === "gpu" ? "Graphics load and VRAM" : "Processor load · updates every 5 seconds"
    readonly property url iconSource: "file://" + Quickshell.shellPath(metric === "memory" ? "assets/ram-address-space.svg" : metric === "gpu" ? "assets/gpu-dual-fan.svg" : "assets/cpu-processor.svg")
    readonly property color statusColor: currentValue >= (metric === "gpu" ? 95 : 90) ? Theme.critical
        : currentValue >= (metric === "gpu" ? 80 : 70) ? Theme.warning
        : Theme.accent
    readonly property var processList: metric === "cpu" ? stats.cpuProcesses : metric === "memory" ? stats.memoryProcesses : []
    readonly property int processRows: Math.min(10, processList.length)
    readonly property int processSectionHeight: metric === "gpu" ? 0 : 244
    readonly property int gpuActiveRows: Math.min(5, stats.gpuActiveProcesses.length)
    readonly property int gpuClientRows: Math.min(5, stats.gpuClients.length)
    readonly property int gpuSectionHeight: metric === "gpu" ? 276 : 0
    readonly property var details: {
        if (metric === "memory") {
            return [
                { label: "Used", value: popup.formatKib(stats.memoryUsedKib) },
                { label: "Available", value: popup.formatKib(stats.memoryAvailableKib) },
                { label: "Cache", value: popup.formatKib(stats.memoryCachedKib) },
                { label: "Total", value: popup.formatKib(stats.memoryTotalKib) },
                { label: "Swap used", value: popup.formatKib(stats.swapUsedKib) },
                { label: "Swap total", value: popup.formatKib(stats.swapTotalKib) },
            ]
        }
        if (metric === "gpu") {
            return [
                { label: "VRAM used", value: popup.formatMib(stats.gpuMemoryUsedMib) },
                { label: "VRAM total", value: popup.formatMib(stats.gpuMemoryTotalMib) },
                { label: "Memory engine", value: popup.percent(stats.gpuMemoryUtil) },
                { label: "Temperature", value: popup.temperature(stats.gpuTemperature) },
                { label: "Power", value: popup.powerText(stats.gpuPower, stats.gpuPowerLimit) },
                { label: "Core clock", value: popup.clockText(stats.gpuClockMhz) },
            ]
        }
        return [
            { label: "Temperature", value: popup.temperature(stats.cpuTemperature) },
            { label: "Average clock", value: popup.clockText(stats.cpuMhz) },
            { label: "Load · 1 min", value: Number(stats.load1).toFixed(2) },
            { label: "Load · 5 min", value: Number(stats.load5).toFixed(2) },
            { label: "Load · 15 min", value: Number(stats.load15).toFixed(2) },
            { label: "Threads", value: stats.cpuThreads.toString() },
        ]
    }

    function formatKib(value) {
        return value > 0 ? (value / 1048576).toFixed(1) + " GiB" : "N/A"
    }

    function formatMib(value) {
        return value >= 0 ? (value / 1024).toFixed(1) + " GiB" : "N/A"
    }

    function percent(value) {
        return value >= 0 ? Math.round(value) + "%" : "N/A"
    }

    function temperature(value) {
        return value >= 0 ? Math.round(value) + "°C" : "N/A"
    }

    function powerText(value, limit) {
        if (value < 0)
            return "N/A"
        return Math.round(value) + (limit > 0 ? " / " + Math.round(limit) : "") + " W"
    }

    function clockText(value) {
        return value >= 0 ? (value / 1000).toFixed(2) + " GHz" : "N/A"
    }

    function processValue(value) {
        if (metric === "cpu")
            return Number(value.cpu_percent).toFixed(1) + "%"
        const mib = Number(value.rss_mib)
        return mib >= 1024 ? (mib / 1024).toFixed(1) + " GiB" : Math.round(mib) + " MiB"
    }

    function gpuActivityValue(value) {
        if (value.sm_percent > 0)
            return value.sm_percent + "% SM"
        if (value.memory_percent > 0)
            return value.memory_percent + "% MEM"
        if (value.encoder_percent > 0)
            return value.encoder_percent + "% ENC"
        return value.decoder_percent + "% DEC"
    }

    function gpuMemoryValue(value) {
        const mib = Number(value.vram_mib)
        return mib >= 1024 ? (mib / 1024).toFixed(1) + " GiB" : Math.round(mib) + " MiB"
    }

    anchor.window: anchorWindow
    anchor.rect.x: selectedAnchor.mapToItem(anchorWindow.contentItem, 0, 0).x + selectedAnchor.width / 2 - width / 2
    anchor.rect.y: -height - Theme.gap
    implicitWidth: 360
    implicitHeight: metric === "gpu" ? 626 : 350 + processSectionHeight
    visible: shell.hardwareOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.hardwareOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.hardwareOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Row {
                width: parent.width
                height: 38
                spacing: 10

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    source: popup.iconSource
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 38
                    Text {
                        text: popup.title
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 17
                        font.bold: true
                    }
                    Text {
                        text: popup.subtitle
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                radius: Theme.radius
                color: Theme.backgroundRaised

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 7

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - currentPercent.width
                            text: popup.metric === "memory" ? "Physical memory used" : "Current utilization"
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            id: currentPercent
                            text: Math.round(popup.currentValue) + "%"
                            color: popup.statusColor
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 7
                        radius: 4
                        color: Theme.border
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(100, popup.currentValue)) / 100
                            height: parent.height
                            radius: 4
                            color: popup.statusColor
                        }
                    }
                }
            }

            Grid {
                width: parent.width
                height: 166
                columns: 2
                spacing: 8

                Repeater {
                    model: popup.details

                    delegate: Rectangle {
                        id: detailCard
                        required property var modelData

                        width: (parent.width - 8) / 2
                        height: 50
                        radius: 9
                        color: Theme.backgroundRaised

                        Column {
                            anchors.centerIn: parent
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: detailCard.modelData.value
                                color: Theme.text
                                font.family: Theme.usageFontFamily
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: detailCard.modelData.label
                                color: Theme.textMuted
                                font.family: Theme.usageFontFamily
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }

            Column {
                id: processSection
                visible: popup.metric !== "gpu"
                width: parent.width
                height: popup.processSectionHeight
                spacing: 4

                Row {
                    width: parent.width
                    height: 20
                    Text {
                        width: parent.width - processThreshold.width
                        text: popup.metric === "cpu" ? "Top CPU processes" : "Top memory processes"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    Text {
                        id: processThreshold
                        text: popup.metric === "cpu" ? "≥ 1% · top 10" : "≥ 100 MiB · top 10"
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 220
                    radius: 9
                    color: Theme.backgroundRaised

                    Text {
                        anchors.centerIn: parent
                        visible: popup.processRows === 0
                        text: "No processes above threshold"
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 10
                    }

                    Column {
                        anchors.fill: parent
                        visible: popup.processRows > 0

                        Repeater {
                            model: popup.processList.slice(0, 10)

                            delegate: Item {
                                id: processRow
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: 22

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        text: processRow.index + 1
                                        color: Theme.textMuted
                                        font.family: Theme.usageFontFamily
                                        font.pixelSize: 9
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 22 - 62 - 68
                                        text: processRow.modelData.name
                                        color: Theme.text
                                        font.family: Theme.usageFontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 62
                                        text: "#" + processRow.modelData.pid
                                        color: Theme.textMuted
                                        font.family: Theme.usageFontFamily
                                        font.pixelSize: 8
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 68
                                        text: popup.processValue(processRow.modelData)
                                        color: Theme.accent
                                        font.family: Theme.usageFontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                Rectangle {
                                    visible: processRow.index < popup.processRows - 1
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    height: 1
                                    color: Theme.border
                                    opacity: 0.35
                                }
                            }
                        }
                    }
                }
            }

            Column {
                visible: popup.metric === "gpu"
                width: parent.width
                height: popup.gpuSectionHeight
                spacing: 8

                Column {
                    width: parent.width
                    height: 134
                    spacing: 4

                    Row {
                        width: parent.width
                        height: 20
                        Text {
                            width: parent.width - gpuActiveThreshold.width
                            text: "Active GPU processes"
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            id: gpuActiveThreshold
                            text: "≥ 5% · recent 8s"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 110
                        radius: 9
                        color: Theme.backgroundRaised

                        Text {
                            anchors.centerIn: parent
                            visible: popup.gpuActiveRows === 0
                            width: parent.width - 20
                            text: stats.gpuProcessError || (popup.currentValue >= 5 ? "No process exceeded 5% in the latest sample" : "GPU load is below the 5% attribution threshold")
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            anchors.fill: parent
                            visible: popup.gpuActiveRows > 0

                            Repeater {
                                model: stats.gpuActiveProcesses.slice(0, 5)

                                delegate: Item {
                                    id: activeGpuRow
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    height: 22

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 22
                                            text: activeGpuRow.index + 1
                                            color: Theme.textMuted
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 9
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 22 - 62 - 78
                                            text: activeGpuRow.modelData.name
                                            color: Theme.text
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 62
                                            text: "#" + activeGpuRow.modelData.pid
                                            color: Theme.textMuted
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignRight
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 78
                                            text: popup.gpuActivityValue(activeGpuRow.modelData)
                                            color: Theme.accent
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    height: 134
                    spacing: 4

                    Row {
                        width: parent.width
                        height: 20
                        Text {
                            width: parent.width - gpuClientThreshold.width
                            text: "Largest VRAM clients"
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            id: gpuClientThreshold
                            text: "≥ 25 MiB · top 5"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 110
                        radius: 9
                        color: Theme.backgroundRaised

                        Text {
                            anchors.centerIn: parent
                            visible: popup.gpuClientRows === 0
                            text: "No VRAM clients above threshold"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                        }

                        Column {
                            anchors.fill: parent
                            visible: popup.gpuClientRows > 0

                            Repeater {
                                model: stats.gpuClients.slice(0, 5)

                                delegate: Item {
                                    id: gpuClientRow
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    height: 22

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 22
                                            text: gpuClientRow.index + 1
                                            color: Theme.textMuted
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 9
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 22 - 62 - 78
                                            text: gpuClientRow.modelData.name
                                            color: Theme.text
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 62
                                            text: "#" + gpuClientRow.modelData.pid
                                            color: Theme.textMuted
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignRight
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 78
                                            text: popup.gpuMemoryValue(gpuClientRow.modelData)
                                            color: Theme.accent
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
