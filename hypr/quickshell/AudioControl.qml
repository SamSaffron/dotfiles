import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

Rectangle {
    id: root

    required property var node
    required property string icon
    required property string title

    readonly property bool available: node && node.audio
    readonly property int percent: available ? Math.round(node.audio.volume * 100) : 0
    readonly property string deviceName: {
        if (!node) return "No device available"
        return node.description || node.nickname || node.name
    }

    width: parent ? parent.width : 360
    height: 86
    radius: Theme.radius
    color: Theme.backgroundRaised

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Row {
            width: parent.width
            height: 30
            spacing: 9

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                color: root.available && root.node.audio.muted ? Theme.critical : Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 19
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - muteButton.width - 45
                Text {
                    text: root.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    width: parent.width
                    text: root.deviceName
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: muteButton
                width: 66
                height: 28
                radius: 8
                color: muteMouse.containsMouse ? Theme.backgroundHover
                     : root.available && root.node.audio.muted ? Theme.accentSoft
                     : Theme.background

                Text {
                    anchors.centerIn: parent
                    text: root.available && root.node.audio.muted ? "󰝟  Muted" : "󰕾  " + root.percent + "%"
                    color: root.available && root.node.audio.muted ? Theme.critical : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    enabled: root.available
                    hoverEnabled: true
                    onClicked: root.node.audio.muted = !root.node.audio.muted
                }
            }
        }

        Slider {
            width: parent.width
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
                height: 6
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
                width: 15
                height: 15
                radius: 8
                color: parent.pressed ? "#ffffff" : Theme.text
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (root.available)
                root.node.audio.volume = Math.max(0, Math.min(1, root.node.audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05)))
        }
    }
}
