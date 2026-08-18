import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

Rectangle {
    id: root

    property string icon: ""
    property url iconSource: ""
    required property string label
    required property string value

    width: 114
    height: 54
    radius: Theme.radius
    color: Theme.backgroundRaised

    Row {
        anchors.centerIn: parent
        spacing: 8
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20

            IconImage {
                id: imageIcon
                anchors.fill: parent
                visible: root.iconSource.toString().length > 0
                source: root.iconSource
            }

            Text {
                anchors.centerIn: parent
                visible: !imageIcon.visible
                text: root.icon
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 18
            }
        }
        Column {
            Text {
                text: root.value
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                text: root.label
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }
        }
    }
}
