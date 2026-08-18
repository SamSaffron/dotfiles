import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

Scope {
    id: root

    required property var shell
    property var pendingWindows: []
    property int activationAttempt: 0

    function notificationKeys(notification) {
        const keys = []
        const appName = (notification.appName || "").toLowerCase()
        const desktopEntry = (notification.desktopEntry || "").toLowerCase().replace(/\.desktop$/, "")
        if (appName)
            keys.push(appName)
        if (desktopEntry && keys.indexOf(desktopEntry) < 0)
            keys.push(desktopEntry)
        return keys
    }

    function matchingWindows(notification) {
        const keys = notificationKeys(notification)
        return Hyprland.toplevels.values.filter(toplevel => {
            const className = String(toplevel.lastIpcObject.class || "").toLowerCase()
            const initialClass = String(toplevel.lastIpcObject.initialClass || "").toLowerCase()
            const appId = String(toplevel.wayland ? toplevel.wayland.appId : "").toLowerCase()
            return keys.some(key => (className && (className === key || className.includes(key) || key.includes(className)))
                || (initialClass && (initialClass === key || initialClass.includes(key) || key.includes(initialClass)))
                || (appId && (appId === key || appId.includes(key) || key.includes(appId))))
        })
    }

    function relevanceScore(notification, toplevel) {
        const title = String(toplevel.title || "").toLowerCase()
        const summary = String(notification.summary || "").toLowerCase()
        let score = 0
        const quoted = summary.match(/["“]([^"”]{4,})["”]/)
        if (quoted && title.includes(quoted[1]))
            score += 100
        const words = summary.split(/[^a-z0-9]+/).filter(word => word.length >= 5)
        for (let index = 0; index < words.length; index++) {
            if (title.includes(words[index]))
                score++
        }
        return score
    }

    function beginWindowRouting(notification) {
        pendingWindows = matchingWindows(notification).map(toplevel => ({
            toplevel: toplevel,
            title: toplevel.title,
            activated: toplevel.activated,
            urgent: toplevel.urgent,
            relevance: relevanceScore(notification, toplevel)
        }))
        activationAttempt = 0
        Hyprland.refreshToplevels()
        activationTimer.restart()
    }

    function finishWindowRouting() {
        activationAttempt++
        const changed = pendingWindows.filter(entry => entry.toplevel && entry.toplevel.wayland
            && (entry.toplevel.title !== entry.title
                || (!entry.urgent && entry.toplevel.urgent)
                || (!entry.activated && entry.toplevel.activated)))
        const target = changed.find(entry => entry.toplevel.urgent)
            || changed.find(entry => entry.toplevel.activated)
            || (changed.length === 1 ? changed[0] : null)

        if (target) {
            if (!target.toplevel.activated)
                target.toplevel.wayland.activate()
            pendingWindows = []
            return
        }

        if (activationAttempt < 6) {
            Hyprland.refreshToplevels()
            activationTimer.restart()
        } else {
            let fallback = null
            if (pendingWindows.length === 1) {
                fallback = pendingWindows[0]
            } else {
                const ranked = pendingWindows.slice().sort((left, right) => right.relevance - left.relevance)
                if (ranked.length > 0 && ranked[0].relevance >= 2
                        && (ranked.length === 1 || ranked[0].relevance > ranked[1].relevance))
                    fallback = ranked[0]
            }
            if (fallback && fallback.toplevel && fallback.toplevel.wayland)
                fallback.toplevel.wayland.activate()
            pendingWindows = []
        }
    }

    function defaultAction(notification) {
        if (!notification)
            return null
        for (let index = 0; index < notification.actions.length; index++) {
            if (notification.actions[index].identifier === "default")
                return notification.actions[index]
        }
        return null
    }

    function invokeDefault(notification) {
        const action = defaultAction(notification)
        if (action) {
            beginWindowRouting(notification)
            action.invoke()
        }
    }

    Timer {
        id: activationTimer
        interval: 250
        onTriggered: root.finishWindowRouting()
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            root.shell.recordNotification({
                id: notification.id,
                appName: notification.appName || "Notification",
                appIcon: notification.image || Quickshell.iconPath(notification.appIcon, "dialog-information"),
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                receivedAt: new Date().toISOString()
            }, !notification.lastGeneration)

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
            margins.top: Theme.gap

            anchors {
                right: true
                top: true
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

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            enabled: root.defaultAction(card.modelData) !== null
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.invokeDefault(card.modelData)
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
                                    linkColor: Theme.link
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
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
