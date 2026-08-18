import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

Rectangle {
    id: root

    required property var node

    readonly property bool available: node && node.audio
    readonly property int percent: available ? Math.round(node.audio.volume * 100) : 0
    readonly property string appName: {
        if (!node) return "Application"
        const properties = node.properties || {}
        return properties["application.name"] || node.description || node.name || "Application"
    }

    width: ListView.view ? ListView.view.width : 350
    height: 54
    radius: 8
    color: Theme.backgroundRaised

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰎆"
            color: root.available && root.node.audio.muted ? Theme.critical : Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: 116
            Text {
                width: parent.width
                text: root.appName
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: root.available && root.node.audio.muted ? "Muted" : root.percent + "%"
                color: root.available && root.node.audio.muted ? Theme.critical : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 8
            }
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 188
            height: 20
            enabled: root.available
            from: 0
            to: 1
            value: root.available ? root.node.audio.volume : 0
            onMoved: root.node.audio.volume = value

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
                width: 13
                height: 13
                radius: 7
                color: Theme.text
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.available && root.node.audio.muted ? "󰝟" : "󰕾"
            color: muteMouse.containsMouse ? "#ffffff" : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 14
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                anchors.margins: -7
                enabled: root.available
                hoverEnabled: true
                onClicked: root.node.audio.muted = !root.node.audio.muted
            }
        }
    }
}
