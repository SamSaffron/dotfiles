import Quickshell
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var stats
    required property var anchorWindow
    required property var anchorItem
    required property var targetScreen

    property bool stoppedExpanded: false

    function stateColor(state, health) {
        if (state === "running" && health === "unhealthy")
            return Theme.critical
        if (state === "running")
            return Theme.accent
        if (state === "paused")
            return Theme.warning
        return Theme.textMuted
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorItem.mapToItem(anchorWindow.contentItem, 0, 0).x + anchorItem.width / 2 - width / 2
    anchor.rect.y: -height - Theme.gap
    implicitWidth: 430
    implicitHeight: 620
    visible: shell.dockerOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.dockerOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (visible) {
            stoppedExpanded = false
            stats.refreshDocker()
        } else if (shell.dockerOpen && shell.popupScreen === targetScreen) {
            shell.closePopups()
        }
    }

    Component {
        id: containerRow

        Rectangle {
            id: row
            required property var modelData
            required property int index

            width: ListView.view.width
            height: 60
            color: index % 2 === 0 ? Theme.backgroundRaised : Theme.background

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 4
                    color: popup.stateColor(row.modelData.state, row.modelData.health)
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - stateLabel.width - 27
                    spacing: 3

                    Text {
                        width: parent.width
                        text: row.modelData.name
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: row.modelData.image
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 9
                        elide: Text.ElideMiddle
                    }

                    Text {
                        width: parent.width
                        text: row.modelData.ports ? row.modelData.status + " · " + row.modelData.ports : row.modelData.status
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: stateLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.health !== "none" ? row.modelData.health : row.modelData.state
                    color: popup.stateColor(row.modelData.state, row.modelData.health)
                    font.family: Theme.usageFontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }
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

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 28
                    implicitHeight: 28
                    source: "file://" + Quickshell.shellPath("assets/docker.svg")
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - refreshButton.width - 50

                    Text {
                        text: "Docker containers"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 17
                        font.bold: true
                    }

                    Text {
                        text: stats.dockerAvailable ? "Container runtime overview" : "Docker runtime unavailable"
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    id: refreshButton
                    anchors.verticalCenter: parent.verticalCenter
                    width: 70
                    height: 30
                    radius: 9
                    color: refreshMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐  Refresh"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: stats.refreshDocker()
                    }
                }
            }

            Row {
                width: parent.width
                height: 64
                spacing: 10

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    radius: Theme.radius
                    color: Theme.backgroundRaised

                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: stats.dockerRunningContainers.length
                            color: stats.dockerRunningContainers.length > 0 ? Theme.accent : Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Running"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    radius: Theme.radius
                    color: Theme.backgroundRaised

                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: stats.dockerStoppedContainers.length
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Stopped"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }

            Rectangle {
                visible: !stats.dockerAvailable
                width: parent.width
                height: parent.height - 122
                radius: Theme.radius
                color: Theme.backgroundRaised

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Docker is unavailable"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        width: 320
                        text: stats.dockerError
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }

            Flickable {
                id: containerFlick
                visible: stats.dockerAvailable
                width: parent.width
                height: parent.height - 122
                contentWidth: width
                contentHeight: containerContent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: containerContent
                    width: containerFlick.width
                    spacing: 0

                    Row {
                        width: parent.width
                        height: 30

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            text: "Running containers"
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Rectangle {
                        visible: stats.dockerRunningContainers.length === 0
                        width: parent.width
                        height: 72
                        radius: 9
                        color: Theme.backgroundRaised

                        Text {
                            anchors.centerIn: parent
                            text: "No containers are running"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                        }
                    }

                    ListView {
                        visible: stats.dockerRunningContainers.length > 0
                        width: parent.width
                        height: contentHeight
                        interactive: false
                        model: stats.dockerRunningContainers
                        delegate: containerRow
                    }

                    Item { width: 1; height: 10 }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 9
                        color: stoppedMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - chevron.width
                                text: "Stopped containers  ·  " + stats.dockerStoppedContainers.length
                                color: Theme.text
                                font.family: Theme.usageFontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                id: chevron
                                anchors.verticalCenter: parent.verticalCenter
                                text: popup.stoppedExpanded ? "󰅀" : "󰅂"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: stoppedMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: popup.stoppedExpanded = !popup.stoppedExpanded
                        }
                    }

                    ListView {
                        visible: popup.stoppedExpanded && stats.dockerStoppedContainers.length > 0
                        width: parent.width
                        height: visible ? contentHeight : 0
                        interactive: false
                        model: stats.dockerStoppedContainers
                        delegate: containerRow
                    }

                    Rectangle {
                        visible: popup.stoppedExpanded && stats.dockerStoppedContainers.length === 0
                        width: parent.width
                        height: 60
                        color: Theme.backgroundRaised

                        Text {
                            anchors.centerIn: parent
                            text: "No stopped containers"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    visible: containerFlick.contentHeight > containerFlick.height
                    anchors.right: parent.right
                    width: 3
                    height: Math.max(28, parent.height * parent.height / containerFlick.contentHeight)
                    y: containerFlick.visibleArea.yPosition * parent.height
                    radius: 2
                    color: Theme.textMuted
                    opacity: 0.45
                }
            }
        }
    }
}
