import Quickshell
import QtQuick
import "Theme.js" as Theme

Text {
    id: root

    required property string icon
    property string command: ""
    property bool available: true
    signal triggered

    opacity: available ? 1 : 0.35
    enabled: available

    text: icon
    color: mouse.containsMouse ? "#ffffff" : Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: 17

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        onClicked: {
            if (root.command)
                Quickshell.execDetached(["playerctl", root.command])
            root.triggered()
        }
    }
}
