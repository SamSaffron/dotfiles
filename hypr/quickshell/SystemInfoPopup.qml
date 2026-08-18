import Quickshell
import QtQuick
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var stats
    required property var anchorWindow
    required property var updatesAnchor
    required property var diskAnchor
    required property var targetScreen

    readonly property string metric: shell.systemInfoMetric
    readonly property bool showingUpdates: metric === "updates"
    readonly property var selectedAnchor: diskAnchor
    readonly property string title: showingUpdates ? "Package updates" : "Storage"
    readonly property string subtitle: showingUpdates ? "Arch packages available through pacman" : "Root filesystem capacity and tools"
    readonly property string icon: showingUpdates ? "󰏕" : "󰋊"

    function formatKib(value) {
        if (value <= 0)
            return "N/A"
        const tib = value / 1073741824
        return tib >= 1 ? tib.toFixed(1) + " TiB" : (value / 1048576).toFixed(1) + " GiB"
    }

    function checkedText() {
        if (!stats.updatesCheckedAt)
            return "Not checked yet"
        return "Checked " + Qt.formatDateTime(new Date(stats.updatesCheckedAt), "HH:mm")
    }

    anchor.window: anchorWindow
    anchor.rect.x: selectedAnchor.mapToItem(anchorWindow.contentItem, 0, 0).x + selectedAnchor.width / 2 - width / 2
    anchor.rect.y: -height - Theme.gap
    implicitWidth: 400
    implicitHeight: 550
    visible: shell.systemInfoOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.systemInfoOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.systemInfoOpen && shell.popupScreen === targetScreen)
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

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    text: popup.icon
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 25
                    horizontalAlignment: Text.AlignHCenter
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

            Column {
                visible: popup.showingUpdates
                width: parent.width
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: Theme.radius
                    color: Theme.backgroundRaised

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - refreshButton.width
                            Text {
                                text: stats.updates + (stats.updates === 1 ? " package" : " packages")
                                color: stats.updates > 0 ? Theme.accent : Theme.text
                                font.family: Theme.usageFontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Text {
                                text: popup.checkedText()
                                color: Theme.textMuted
                                font.family: Theme.usageFontFamily
                                font.pixelSize: 10
                            }
                        }

                        Rectangle {
                            id: refreshButton
                            anchors.verticalCenter: parent.verticalCenter
                            width: 84
                            height: 32
                            radius: 9
                            color: refreshMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                            opacity: stats.updatesLoading ? 0.6 : 1
                            Text {
                                anchors.centerIn: parent
                                text: stats.updatesLoading ? "󰑐  Checking" : "󰑐  Refresh"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }
                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                enabled: !stats.updatesLoading
                                hoverEnabled: true
                                onClicked: stats.refreshUpdates()
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 20
                    Text {
                        width: parent.width - updatesShown.width
                        text: "Pending packages"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    Text {
                        id: updatesShown
                        text: "showing " + Math.min(10, stats.updatesList.length) + " of " + stats.updatesList.length
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 280
                    radius: 9
                    color: Theme.backgroundRaised

                    Text {
                        anchors.centerIn: parent
                        visible: stats.updatesList.length === 0
                        text: stats.updatesLoading ? "Checking package databases…" : "System is up to date"
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                    }

                    Column {
                        anchors.fill: parent
                        visible: stats.updatesList.length > 0

                        Repeater {
                            model: stats.updatesList.slice(0, 10)

                            delegate: Item {
                                id: updateRow
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: 28

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 132
                                        text: updateRow.modelData.name
                                        color: Theme.text
                                        font.family: Theme.usageFontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 140
                                        text: updateRow.modelData.current + "  →  " + updateRow.modelData.available
                                        color: Theme.textMuted
                                        font.family: Theme.usageFontFamily
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideLeft
                                    }
                                }

                                Rectangle {
                                    visible: updateRow.index < Math.min(10, stats.updatesList.length) - 1
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    height: 1
                                    color: Theme.border
                                    opacity: 0.35
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 18
                    text: stats.updatesList.length > 10 ? "+ " + (stats.updatesList.length - 10) + " more packages" : ""
                    color: Theme.textMuted
                    font.family: Theme.usageFontFamily
                    font.pixelSize: 9
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 9
                    color: updaterMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                    Text {
                        anchors.centerIn: parent
                        text: "󰏕  Open yay updater"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: updaterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            shell.closePopups()
                            Quickshell.execDetached(["kitty", "--class", "quickshell-updater", "-e", "yay"])
                        }
                    }
                }
            }

            Column {
                visible: !popup.showingUpdates
                width: parent.width
                spacing: 10

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
                                width: parent.width - diskPercent.width
                                text: "Root filesystem used"
                                color: Theme.text
                                font.family: Theme.usageFontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Text {
                                id: diskPercent
                                text: stats.disk + "%"
                                color: stats.disk >= 95 ? Theme.critical : stats.disk >= 85 ? Theme.warning : Theme.accent
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
                                width: parent.width * Math.max(0, Math.min(100, stats.disk)) / 100
                                height: parent.height
                                radius: 4
                                color: diskPercent.color
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
                        model: [
                            { label: "Used", value: popup.formatKib(stats.diskUsedKib) },
                            { label: "Available", value: popup.formatKib(stats.diskAvailableKib) },
                            { label: "Total", value: popup.formatKib(stats.diskTotalKib) },
                            { label: "Filesystem", value: stats.diskType || "N/A" },
                            { label: "Device", value: stats.diskDevice || "N/A" },
                            { label: "Mounted at", value: stats.diskMount || "/" },
                        ]

                        delegate: Rectangle {
                            id: diskCard
                            required property var modelData
                            width: (parent.width - 8) / 2
                            height: 50
                            radius: 9
                            color: Theme.backgroundRaised
                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                Text {
                                    width: parent.width
                                    text: diskCard.modelData.value
                                    color: Theme.text
                                    font.family: Theme.usageFontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideMiddle
                                }
                                Text {
                                    width: parent.width
                                    text: diskCard.modelData.label
                                    color: Theme.textMuted
                                    font.family: Theme.usageFontFamily
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 9
                    color: Theme.backgroundRaised
                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: stats.diskDevice || "Root device unavailable"
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (stats.diskType || "filesystem") + " mounted at " + (stats.diskMount || "/")
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    text: "Storage tools"
                    color: Theme.text
                    font.family: Theme.usageFontFamily
                    font.pixelSize: 11
                    font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 38
                        radius: 9
                        color: btopMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                        Text {
                            anchors.centerIn: parent
                            text: "󰨇  Open btop"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: btopMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                shell.closePopups()
                                Quickshell.execDetached(["kitty", "--class", "quickshell-btop", "-e", "btop"])
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 38
                        radius: 9
                        color: dustMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                        Text {
                            anchors.centerIn: parent
                            text: "󰋊  Analyze home"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: dustMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                shell.closePopups()
                                Quickshell.execDetached(["kitty", "--hold", "--class", "quickshell-dust", "-e", "sh", "-lc", "dust -r -d 2 -n 30 \"$HOME\""])
                            }
                        }
                    }
                }
            }
        }
    }
}
