import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

Scope {
    id: root

    required property var shell

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            if (root.shell.doNotDisturb) {
                notification.tracked = false
                return
            }

            while (server.trackedNotifications.values.length >= 5)
                server.trackedNotifications.values[0].expire()
            notification.tracked = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupStack
            required property var modelData

            screen: modelData
            visible: server.trackedNotifications.values.length > 0
                     && root.shell.focusedScreen !== null
                     && modelData.name === root.shell.focusedScreen.name
            color: Theme.transparent
            implicitWidth: 380
            implicitHeight: Math.max(1, cards.implicitHeight)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            margins.right: Theme.gap
            margins.bottom: Theme.barHeight + Theme.gap * 2

            anchors {
                right: true
                bottom: true
            }

            Column {
                id: cards
                width: parent.width
                spacing: 8

                Repeater {
                    model: server.trackedNotifications

                    delegate: Rectangle {
                        id: card
                        required property var modelData

                        width: cards.width
                        height: Math.max(88, bodyColumn.implicitHeight + 24)
                        radius: 12
                        color: Theme.background
                        border.width: 1
                        border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.critical : Theme.border

                        Timer {
                            interval: card.modelData.expireTimeout > 0
                                      ? card.modelData.expireTimeout
                                      : (card.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000)
                            running: true
                            onTriggered: card.modelData.expire()
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 10
                                color: Theme.backgroundRaised

                                IconImage {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    source: card.modelData.image || Quickshell.iconPath(card.modelData.appIcon, "dialog-information")
                                }
                            }

                            Column {
                                id: bodyColumn
                                width: parent.width - 78
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: card.modelData.appName || "Notification"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: card.modelData.summary
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    visible: text.length > 0
                                    text: card.modelData.body
                                    textFormat: Text.StyledText
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: "󰅖"
                                color: closeMouse.containsMouse ? "#ffffff" : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    onClicked: card.modelData.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
