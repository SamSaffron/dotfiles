import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

PanelWindow {
    id: bar

    required property var modelData
    required property var shell
    required property var stats
    required property var usage

    screen: modelData
    color: Theme.transparent
    implicitHeight: Theme.barHeight + Theme.gap
    exclusiveZone: implicitHeight

    anchors {
        left: true
        right: true
        bottom: true
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: Theme.barHeight
        color: Theme.transparent

        Row {
            id: leftModules
            anchors.left: parent.left
            height: parent.height
            spacing: Theme.gap

            Rectangle {
                height: Theme.barHeight
                width: workspaces.implicitWidth + 8
                radius: Theme.radius
                color: Theme.background

                Row {
                    id: workspaces
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: ScriptModel {
                            values: Hyprland.workspaces.values.filter(workspace => workspace.id > 0)
                        }

                        delegate: Rectangle {
                            id: workspaceButton
                            required property var modelData

                            width: workspaceLabel.implicitWidth + 16
                            height: 28
                            radius: Theme.radius
                            color: modelData.focused ? Theme.accent
                                  : workspaceMouse.containsMouse ? Theme.accentSoft
                                  : Theme.transparent

                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Text {
                                id: workspaceLabel
                                anchors.centerIn: parent
                                text: workspaceButton.modelData.name
                                color: workspaceButton.modelData.focused ? "#ffffff" : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.bold: true
                            }

                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: workspaceButton.modelData.activate()
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors {
                left: leftModules.right
                right: rightModules.left
                verticalCenter: parent.verticalCenter
                leftMargin: 16
                rightMargin: 16
            }
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Row {
            id: rightModules
            anchors.right: parent.right
            height: parent.height
            spacing: Theme.gap

            BarPill {
                id: usageButton
                readonly property color statusColor: {
                    if (usage.error || usage.indicator.stale)
                        return Theme.warning
                    if (usage.indicator.pace > 5) {
                        if (usage.indicator.projected >= 100)
                            return Theme.critical
                        if (usage.indicator.projected >= 90)
                            return Theme.warning
                        return Theme.accent
                    }
                    if (usage.indicator.percent >= 95)
                        return Theme.critical
                    if (usage.indicator.percent >= 80)
                        return Theme.warning
                    return Theme.accent
                }

                text: ""
                width: 88
                radius: Theme.radius
                active: shell.usageOpen && shell.popupScreen === bar.screen
                onClicked: shell.toggleUsage(bar.screen)

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰚩"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 46
                        height: 6
                        radius: 3
                        color: usageButton.active ? "#668fa8c2" : Theme.border

                        Rectangle {
                            width: parent.width * usage.indicator.percent / 100
                            height: parent.height
                            radius: 3
                            color: usageButton.active ? Theme.text : usageButton.statusColor
                        }

                        Rectangle {
                            visible: usage.indicator.pace > 5
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * usage.indicator.pace / 100 - width / 2))
                            width: 1
                            height: 8
                            radius: 0.5
                            color: usageButton.active ? Theme.background : Theme.text
                        }
                    }
                }
            }
            BarPill {
                id: updatesButton
                text: ""
                width: 62
                active: shell.systemInfoOpen && shell.systemInfoMetric === "updates" && shell.popupScreen === bar.screen
                onClicked: shell.toggleSystemInfo("updates", bar.screen)

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: "󰏕"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        text: stats.updates
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            BarPill {
                id: diskButton
                text: ""
                width: Theme.barCounterWidth
                active: shell.systemInfoOpen && shell.systemInfoMetric === "disk" && shell.popupScreen === bar.screen
                onClicked: shell.toggleSystemInfo("disk", bar.screen)

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: "󰋊"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.barValueWidth
                        text: stats.disk + "%"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            BarPill {
                id: dockerButton
                text: ""
                width: 62
                active: shell.dockerOpen && shell.popupScreen === bar.screen
                onClicked: shell.toggleDocker(bar.screen)

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 18
                        implicitHeight: 18
                        source: "file://" + Quickshell.shellPath("assets/docker.svg")
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        text: stats.dockerAvailable ? stats.dockerRunning : "!"
                        color: stats.dockerAvailable ? Theme.text : Theme.warning
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            HardwareCounter {
                id: cpuButton
                iconSource: "file://" + Quickshell.shellPath("assets/cpu-processor.svg")
                value: stats.cpu
                interactive: true
                active: shell.hardwareOpen && shell.hardwareMetric === "cpu" && shell.popupScreen === bar.screen
                onClicked: shell.toggleHardware("cpu", bar.screen)
            }
            HardwareCounter {
                id: memoryButton
                iconSource: "file://" + Quickshell.shellPath("assets/ram-address-space.svg")
                value: stats.memory
                interactive: true
                active: shell.hardwareOpen && shell.hardwareMetric === "memory" && shell.popupScreen === bar.screen
                onClicked: shell.toggleHardware("memory", bar.screen)
            }
            HardwareCounter {
                id: gpuButton
                visible: stats.gpu >= 0
                iconSource: "file://" + Quickshell.shellPath("assets/gpu-dual-fan.svg")
                value: stats.gpu
                warningAt: 80
                criticalAt: 95
                interactive: true
                active: shell.hardwareOpen && shell.hardwareMetric === "gpu" && shell.popupScreen === bar.screen
                onClicked: shell.toggleHardware("gpu", bar.screen)
            }
            BarPill {
                id: volumeButton
                readonly property var sink: Pipewire.defaultAudioSink
                readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
                readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

                text: ""
                width: Theme.barCounterWidth
                active: shell.audioOpen && shell.popupScreen === bar.screen
                onClicked: shell.toggleAudio(bar.screen)
                onWheel: delta => {
                    if (sink && sink.audio)
                        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (delta > 0 ? 0.05 : -0.05)))
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: volumeButton.muted ? "" : volumeButton.volume < 45 ? "" : ""
                        color: volumeButton.muted ? Theme.critical : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.barValueWidth
                        text: volumeButton.volume + "%"
                        color: volumeButton.muted ? Theme.critical : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            BarPill {
                id: weatherButton
                text: ""
                width: 104
                active: shell.weatherOpen && shell.popupScreen === bar.screen
                onClicked: shell.toggleWeather(bar.screen)

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: "󰖐"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 62
                        text: stats.weather
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }

            Rectangle {
                visible: trayRow.children.length > 0
                implicitWidth: trayRow.implicitWidth + 12
                height: Theme.barHeight
                radius: Theme.radius
                color: Theme.background

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: SystemTray.items
                        delegate: Rectangle {
                            id: trayButton
                            required property var modelData

                            width: 30
                            height: Theme.barHeight
                            radius: Theme.radius
                            color: trayMouse.containsMouse ? Theme.backgroundHover : Theme.transparent

                            Behavior on color { ColorAnimation { duration: 130 } }

                            IconImage {
                                anchors.centerIn: parent
                                implicitWidth: 22
                                implicitHeight: 22
                                source: trayButton.modelData.icon
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        trayButton.modelData.secondaryActivate()
                                    } else if (mouse.button === Qt.RightButton || trayButton.modelData.onlyMenu) {
                                        const point = trayButton.mapToItem(bar.contentItem, 0, 0)
                                        trayButton.modelData.display(bar, point.x, point.y)
                                    } else {
                                        trayButton.modelData.activate()
                                    }
                                }
                                onWheel: event => trayButton.modelData.scroll(event.angleDelta.y, false)
                            }
                        }
                    }
                }
            }

            BarPill {
                text: " " + Qt.formatDateTime(shell.clock.date, "d MMM yyyy")
                width: 146
                onClicked: shell.toggleControlCenter(bar.screen)
            }
            BarPill {
                text: Qt.formatDateTime(shell.clock.date, "HH:mm")
                width: 64
                horizontalPadding: 10
                onClicked: shell.toggleControlCenter(bar.screen)
            }
            BarPill {
                id: controlButton
                text: "󰒓"
                radius: Theme.radius
                horizontalPadding: 10
                active: shell.controlCenterOpen && shell.popupScreen === bar.screen
                onClicked: shell.toggleControlCenter(bar.screen)
            }
        }
    }

    DockerPopup {
        shell: bar.shell
        stats: bar.stats
        anchorWindow: bar
        anchorItem: dockerButton
        targetScreen: bar.screen
    }

    SystemInfoPopup {
        shell: bar.shell
        stats: bar.stats
        anchorWindow: bar
        updatesAnchor: updatesButton
        diskAnchor: diskButton
        targetScreen: bar.screen
    }

    HardwarePopup {
        shell: bar.shell
        stats: bar.stats
        anchorWindow: bar
        cpuAnchor: cpuButton
        memoryAnchor: memoryButton
        gpuAnchor: gpuButton
        targetScreen: bar.screen
    }

    UsagePopup {
        shell: bar.shell
        usage: bar.usage
        anchorWindow: bar
        anchorItem: usageButton
        targetScreen: bar.screen
    }

    VolumePopup {
        shell: bar.shell
        anchorWindow: bar
        anchorItem: volumeButton
        targetScreen: bar.screen
    }

    WeatherPopup {
        shell: bar.shell
        stats: bar.stats
        anchorWindow: bar
        anchorItem: weatherButton
        targetScreen: bar.screen
    }

    ControlCenter {
        shell: bar.shell
        stats: bar.stats
        anchorWindow: bar
        targetScreen: bar.screen
    }
}
