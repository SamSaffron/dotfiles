import Quickshell
import QtQuick
import "Theme.js" as Theme

Text {
    id: root

    required property string icon
    required property string command

    text: icon
    color: mouse.containsMouse ? "#ffffff" : Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: 17

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["playerctl", root.command])
    }
}
