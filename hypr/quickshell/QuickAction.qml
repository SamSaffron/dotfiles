import QtQuick
import "Theme.js" as Theme

Rectangle {
    id: root

    required property string icon
    required property string label
    property bool active: false
    signal triggered

    width: 114
    height: 58
    radius: Theme.radius
    color: active ? Theme.accent : (mouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised)

    Behavior on color { ColorAnimation { duration: 130 } }

    Column {
        anchors.centerIn: parent
        spacing: 3
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.triggered()
    }
}
