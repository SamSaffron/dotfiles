import QtQuick
import "Theme.js" as Theme

Rectangle {
    id: root

    property alias text: label.text
    property alias textColor: label.color
    property alias font: label.font
    property string tooltip: ""
    property bool active: false
    property bool interactive: true
    property int horizontalPadding: 12
    signal clicked
    signal wheel(real delta)

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: active ? Theme.accent : (mouse.containsMouse && interactive ? Theme.backgroundHover : Theme.background)

    Behavior on color {
        ColorAnimation { duration: 130 }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 15
        font.bold: true
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        onClicked: root.clicked()
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
