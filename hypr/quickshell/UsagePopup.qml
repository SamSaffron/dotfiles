import Quickshell
import QtQuick
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var usage
    required property var anchorWindow
    required property var anchorItem
    required property var targetScreen

    function updatedText(value) {
        if (!value)
            return "Waiting for usage data"
        return "Updated " + Qt.formatDateTime(new Date(value), "ddd HH:mm") + " · cached for one hour"
    }

    function usageColor(percent) {
        if (percent >= 95) return Theme.critical
        if (percent >= 80) return Theme.warning
        return Theme.accent
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorItem.mapToItem(anchorWindow.contentItem, 0, 0).x + anchorItem.width - width
    anchor.rect.y: -height - Theme.gap
    implicitWidth: 810
    implicitHeight: 590
    visible: shell.usageOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.usageOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.usageOpen && shell.popupScreen === targetScreen)
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

                Column {
                    width: parent.width - refreshButton.width
                    Text {
                        text: "LLM usage"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        text: popup.updatedText(usage.updatedAt)
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    id: refreshButton
                    width: 94
                    height: 32
                    radius: 9
                    color: refreshMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                    opacity: usage.loading ? 0.65 : 1
                    Text {
                        anchors.centerIn: parent
                        text: usage.loading ? "󰑐  Loading…" : "󰑐  Refresh"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        enabled: !usage.loading
                        hoverEnabled: true
                        onClicked: usage.refresh(true)
                    }
                }
            }

            Grid {
                width: parent.width
                height: 458
                columns: 3
                spacing: 8

                Repeater {
                    model: usage.providers
                    delegate: UsageProviderCard {
                        required property var modelData
                        provider: modelData
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 9
                color: Theme.backgroundRaised

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰚩"
                        color: popup.usageColor(usage.maximumPercent)
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 36
                        Text {
                            text: "Highest current usage: " + Math.round(usage.maximumPercent) + "%"
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            text: usage.error || "Sources are fetched concurrently through term-llm and cached locally."
                            color: usage.error ? Theme.warning : Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
