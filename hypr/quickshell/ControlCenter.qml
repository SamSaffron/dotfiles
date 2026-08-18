import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var stats
    required property var anchorWindow
    required property var targetScreen

    readonly property var sink: Pipewire.defaultAudioSink
    property string mediaTitle: "Nothing playing"
    property string mediaArtist: ""
    property bool confirmLogout: false

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width - Theme.gap
    anchor.rect.y: -height - Theme.gap
    width: 390
    height: 470
    visible: shell.controlCenterOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.controlCenterOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.controlCenterOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    PwObjectTracker {
        objects: [popup.sink]
    }

    Process {
        id: mediaProcess
        command: ["sh", "-c", "playerctl metadata --format '{{title}}\\n{{artist}}' 2>/dev/null"]
        running: popup.visible
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                popup.mediaTitle = lines[0] || "Nothing playing"
                popup.mediaArtist = lines.slice(1).join(" · ")
            }
        }
    }

    Timer {
        interval: 3000
        running: popup.visible
        repeat: true
        onTriggered: if (!mediaProcess.running) mediaProcess.running = true
    }

    Timer {
        interval: 3000
        running: popup.confirmLogout
        onTriggered: popup.confirmLogout = false
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
            spacing: 14

            Row {
                width: parent.width
                height: 36

                Column {
                    width: parent.width - closeButton.width
                    Text {
                        text: "Control center"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: Qt.formatDateTime(shell.clock.date, "dddd, d MMMM")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    id: closeButton
                    width: 32
                    height: 32
                    radius: 9
                    color: closeMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    Text { anchors.centerIn: parent; text: "󰅖"; color: Theme.text; font.family: Theme.fontFamily }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: shell.controlCenterOpen = false
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 3
                spacing: 8

                QuickAction {
                    icon: "󰖩"
                    label: "Wi-Fi"
                    onTriggered: Quickshell.execDetached(["sh", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"])
                }
                QuickAction {
                    icon: "󰂯"
                    label: "Bluetooth"
                    onTriggered: Quickshell.execDetached(["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"])
                }
                QuickAction {
                    icon: shell.doNotDisturb ? "󰂛" : "󰂚"
                    label: shell.doNotDisturb ? "DND on" : "DND off"
                    active: shell.doNotDisturb
                    onTriggered: shell.doNotDisturb = !shell.doNotDisturb
                }
                QuickAction {
                    icon: "󰍹"
                    label: "Display"
                    onTriggered: Quickshell.execDetached(["sh", "-c", "command -v wdisplays >/dev/null && wdisplays || ~/.config/hypr/resolution.sh"])
                }
                QuickAction {
                    icon: "󰌾"
                    label: "Lock"
                    onTriggered: {
                        shell.controlCenterOpen = false
                        Quickshell.execDetached(["hyprlock"])
                    }
                }
                QuickAction {
                    icon: popup.confirmLogout ? "󰜺" : "󰍃"
                    label: popup.confirmLogout ? "Confirm exit" : "Log out"
                    active: popup.confirmLogout
                    onTriggered: {
                        if (popup.confirmLogout) {
                            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
                        } else {
                            popup.confirmLogout = true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 62
                radius: Theme.radius
                color: Theme.backgroundRaised

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - volumeValue.width
                            text: popup.sink && popup.sink.audio && popup.sink.audio.muted ? "  Volume muted" : "  Volume"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            id: volumeValue
                            text: popup.sink && popup.sink.audio ? Math.round(popup.sink.audio.volume * 100) + "%" : "--"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                    Slider {
                        width: parent.width
                        height: 18
                        from: 0
                        to: 1
                        value: popup.sink && popup.sink.audio ? popup.sink.audio.volume : 0
                        onMoved: if (popup.sink && popup.sink.audio) popup.sink.audio.volume = value
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth
                            height: 5
                            radius: 3
                            color: Theme.border
                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                radius: 3
                                color: Theme.accent
                            }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.text
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 78
                radius: Theme.radius
                color: Theme.backgroundRaised

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰎆"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - mediaButtons.width - 54
                        Text {
                            width: parent.width
                            text: popup.mediaTitle
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: popup.mediaArtist
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Row {
                        id: mediaButtons
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        MediaButton { icon: "󰒮"; command: "previous" }
                        MediaButton { icon: "󰐊"; command: "play-pause" }
                        MediaButton { icon: "󰒭"; command: "next" }
                    }
                }
            }

            Row {
                id: metricsRow
                readonly property int metricCount: stats.gpu >= 0 ? 4 : 3

                width: parent.width
                spacing: 8
                MetricCard {
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    iconSource: "file://" + Quickshell.shellPath("assets/cpu-processor.svg")
                    label: "CPU"
                    value: stats.cpu + "%"
                }
                MetricCard {
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    iconSource: "file://" + Quickshell.shellPath("assets/ram-address-space.svg")
                    label: "RAM"
                    value: stats.memory + "%"
                }
                MetricCard {
                    visible: stats.gpu >= 0
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    iconSource: "file://" + Quickshell.shellPath("assets/gpu-dual-fan.svg")
                    label: "GPU"
                    value: stats.gpu + "%"
                }
                MetricCard {
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    icon: "󰋊"
                    label: "Disk"
                    value: stats.disk + "%"
                }
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 9
                color: fallbackMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                Text {
                    anchors.centerIn: parent
                    text: "Return to Waybar · Fuzzel · Dunst"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
                MouseArea {
                    id: fallbackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/shell-mode current"])
                }
            }
        }
    }
}
