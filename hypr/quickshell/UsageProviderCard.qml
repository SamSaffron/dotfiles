import Quickshell
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

Rectangle {
    id: root

    required property var provider
    readonly property bool hasBrandIcon: provider.id === "cursor-bin"
        || provider.id === "chatgpt"
        || provider.id === "claude-bin"
        || provider.id === "opencode-go"

    function brandIconPath() {
        if (provider.id === "cursor-bin")
            return "file://" + Quickshell.shellPath("assets/cursor.svg")
        if (provider.id === "chatgpt")
            return "file://" + Quickshell.shellPath("assets/codex.svg")
        if (provider.id === "claude-bin")
            return "file://" + Quickshell.shellPath("assets/claude.svg")
        if (provider.id === "opencode-go")
            return "file://" + Quickshell.shellPath("assets/opencode.svg")
        return ""
    }

    function resetText(value) {
        if (!value)
            return ""
        const delta = new Date(value).getTime() - Date.now()
        if (delta <= 0)
            return "reset pending"
        const minutes = Math.floor(delta / 60000)
        if (minutes < 60)
            return "resets in " + minutes + "m"
        const hours = Math.floor(minutes / 60)
        if (hours < 24)
            return "resets in " + hours + "h " + (minutes % 60) + "m"
        return "resets in " + Math.floor(hours / 24) + "d " + (hours % 24) + "h"
    }

    function usageColor(percent) {
        if (percent >= 95) return Theme.critical
        if (percent >= 80) return Theme.warning
        return Theme.accent
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

    width: 254
    height: 225
    radius: 12
    color: Theme.backgroundRaised
    border.width: provider.stale ? 1 : 0
    border.color: Theme.warning

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        Row {
            width: parent.width
            height: 34
            spacing: 9

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22

                IconImage {
                    anchors.fill: parent
                    visible: root.hasBrandIcon
                    source: root.brandIconPath()
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.hasBrandIcon
                    text: root.provider.icon
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 21
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34
                Text {
                    width: parent.width
                    text: root.provider.name
                    color: Theme.text
                    font.family: Theme.usageFontFamily
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: "source: " + root.provider.source + "  ·  " + root.provider.plan
                    color: root.provider.stale ? Theme.warning : Theme.textMuted
                    font.family: Theme.usageFontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }

        Repeater {
            model: root.provider.limits || []

            delegate: Column {
                id: usageRow
                required property var modelData
                readonly property real pacePercent: root.pacePercent(modelData)

                width: parent.width
                height: 34
                spacing: 3

                Row {
                    width: parent.width
                    height: 14
                    Text {
                        width: parent.width - usagePercent.width
                        text: usageRow.modelData.name
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        id: usagePercent
                        text: Math.round(usageRow.modelData.percent) + "%"
                        color: root.usageColor(usageRow.modelData.percent)
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Theme.border
                    Rectangle {
                        width: parent.width * Math.min(100, usageRow.modelData.percent) / 100
                        height: parent.height
                        radius: 3
                        color: root.usageColor(usageRow.modelData.percent)
                    }
                    Rectangle {
                        visible: usageRow.pacePercent > 5
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * usageRow.pacePercent / 100 - width / 2))
                        width: 1
                        height: 7
                        radius: 0.5
                        color: Theme.text
                        opacity: 0.9
                    }
                }

                Text {
                    width: parent.width
                    text: {
                        const reset = root.resetText(usageRow.modelData.resets_at)
                        return usageRow.modelData.detail + (reset ? " · " + reset : "")
                    }
                    color: Theme.textMuted
                    font.family: Theme.usageFontFamily
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }
        }
    }
}
