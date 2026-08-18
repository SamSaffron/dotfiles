import Quickshell
import QtQuick
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var stats
    required property var anchorWindow
    required property var anchorItem
    required property var targetScreen

    function conditionIcon(description) {
        const value = description.toLowerCase()
        if (value.includes("thunder")) return "󰙾"
        if (value.includes("snow") || value.includes("sleet")) return "󰖘"
        if (value.includes("rain") || value.includes("drizzle")) return "󰖗"
        if (value.includes("fog") || value.includes("mist")) return "󰖑"
        if (value.includes("cloud") || value.includes("overcast")) return "󰖐"
        return "󰖙"
    }

    function dayLabel(date, index) {
        if (index === 0)
            return "Today"
        return Qt.formatDate(new Date(date + "T00:00:00"), "ddd d")
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorItem.mapToItem(anchorWindow.contentItem, 0, 0).x + anchorItem.width - width
    anchor.rect.y: -height - Theme.gap
    width: 410
    height: 580
    visible: shell.weatherOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.weatherOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.weatherOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
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
                height: 68
                spacing: 14

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.conditionIcon(stats.weatherDescription)
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 50
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 88
                    Text {
                        text: stats.weather
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: stats.weatherDescription
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "󰍎  " + stats.weatherLocation
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                radius: Theme.radius
                color: Theme.backgroundRaised

                Row {
                    anchors.centerIn: parent
                    spacing: 20

                    WeatherMetric { icon: "󰔏"; label: "Feels like"; value: stats.weatherFeelsLike }
                    WeatherMetric { icon: "󰖎"; label: "Humidity"; value: stats.weatherHumidity }
                    WeatherMetric { icon: "󰖝"; label: "Wind"; value: stats.weatherWind }
                }
            }

            Rectangle {
                width: parent.width
                height: 112
                radius: Theme.radius
                color: Theme.backgroundRaised

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        text: "NEXT 4 HOURS"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: stats.hourlyForecast

                            delegate: Rectangle {
                                id: hourCard
                                required property var modelData

                                width: (parent.width - 18) / 4
                                height: 75
                                radius: 8
                                color: Theme.background

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: hourCard.modelData.time
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: popup.conditionIcon(hourCard.modelData.description)
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 18
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: hourCard.modelData.temperature
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "󰖌 " + hourCard.modelData.precipitation
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 184
                radius: Theme.radius
                color: Theme.backgroundRaised

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        text: "4-DAY FORECAST"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    Column {
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: stats.dailyForecast

                            delegate: Rectangle {
                                id: dayRow
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: 34
                                radius: 7
                                color: index === 0 ? Theme.accentSoft : Theme.background

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 62
                                        text: popup.dayLabel(dayRow.modelData.date, dayRow.index)
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 28
                                        text: popup.conditionIcon(dayRow.modelData.description)
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 92
                                        text: dayRow.modelData.description
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 50
                                        text: "󰖌 " + dayRow.modelData.precipitation
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 232
                                        text: dayRow.modelData.low + " / " + dayRow.modelData.high
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: stats.weatherAvailable
                      ? "Updated at " + stats.weatherObservedAt + " · Open-Meteo"
                      : "Weather data is currently unavailable"
                color: stats.weatherAvailable ? Theme.textMuted : Theme.warning
                font.family: Theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: 34
                    radius: 9
                    color: refreshMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐  Refresh"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: stats.refreshWeather()
                    }
                }

                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: 34
                    radius: 9
                    color: detailsMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    Text {
                        anchors.centerIn: parent
                        text: "󰇧  Full forecast"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: detailsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(["xdg-open", "https://www.bom.gov.au/places/nsw/sydney/"])
                    }
                }
            }
        }
    }
}
