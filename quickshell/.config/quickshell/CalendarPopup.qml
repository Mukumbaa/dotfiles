import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property bool isOpen: CalendarState.visible
  property real animProgress: isOpen ? 1.0 : 0.0
  visible: isOpen || animProgress > 0.001

  Behavior on animProgress {
    NumberAnimation {
      duration: 200
      easing.type: Easing.InOutQuad
    }
  }

  // Centrato esattamente sotto l'orologio
  anchors {
    top: true
  }
  margins {
    top: -1
  }

  implicitWidth: 300
  implicitHeight: 305
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // -------------------------------------------------------------
  // LOGICA DATE E CALENDARIO
  // -------------------------------------------------------------
  property var displayDate: new Date()
  property var today: new Date()

  function prevMonth() {
    displayDate = new Date(displayDate.getFullYear(), displayDate.getMonth() - 1, 1)
  }

  function nextMonth() {
    displayDate = new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 1)
  }

  function resetToday() {
    displayDate = new Date()
  }

  // Genera i 42 giorni (6 settimane) per la griglia
  property var daysModel: {
    let year = displayDate.getFullYear()
    let month = displayDate.getMonth()
    let firstDayIndex = (new Date(year, month, 1).getDay() + 6) % 7 // Lunedì = 0
    let daysInMonth = new Date(year, month + 1, 0).getDate()
    let daysInPrevMonth = new Date(year, month, 0).getDate()

    let days = []

    // Giorni mese precedente
    for (let i = firstDayIndex - 1; i >= 0; i--) {
      days.push({ day: daysInPrevMonth - i, isCurrent: false, isToday: false })
    }

    // Giorni mese corrente
    for (let i = 1; i <= daysInMonth; i++) {
      let isToday = (i === today.getDate() && month === today.getMonth() && year === today.getFullYear())
      days.push({ day: i, isCurrent: true, isToday: isToday })
    }

    // Giorni mese successivo a riempimento griglia (totale 42)
    let nextDays = 42 - days.length
    for (let i = 1; i <= nextDays; i++) {
      days.push({ day: i, isCurrent: false, isToday: false })
    }

    return days
  }

  // -------------------------------------------------------------
  // AUTO-CHIUSURA AL MOUSE LEAVE
  // -------------------------------------------------------------
  HoverHandler {
    id: panelHover
    onHoveredChanged: {
      if (hovered) {
        autoCloseTimer.stop()
      } else {
        autoCloseTimer.restart()
      }
    }
  }

  Timer {
    id: autoCloseTimer
    interval: 600
    onTriggered: {
      if (!panelHover.hovered) {
        CalendarState.close()
      }
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      today = new Date()
      resetToday()
    } else {
      autoCloseTimer.stop()
    }
  }

  // -------------------------------------------------------------
  // CONTENITORE CON ANIMAZIONE
  // -------------------------------------------------------------
  Item {
    anchors.fill: parent
    clip: true

    Rectangle {
      id: card
      width: parent.width
      height: parent.height

      y: (root.animProgress - 1.0) * height
      opacity: root.animProgress

      color: Theme.surface
      topLeftRadius: 0
      topRightRadius: 0
      bottomLeftRadius: 12
      bottomRightRadius: 12
      border.color: Theme.base
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // 1. Header con Mese, Anno e Controlli Navigazione
        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          // Bottone Mese Precedente
          Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 6
            color: prevMouse.containsMouse ? Theme.overlay : "transparent"
            Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.text; font.pixelSize: 14 }
            MouseArea {
              id: prevMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.prevMonth()
            }
          }

          // Nome Mese e Anno
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(root.displayDate, "MMMM yyyy").toUpperCase()
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
          }

          // Bottone "Oggi"
          Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 5
            color: todayMouse.containsMouse ? Theme.overlay : Theme.base
            Text { anchors.centerIn: parent; text: "Today"; color: Theme.foam; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
            MouseArea {
              id: todayMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.resetToday()
            }
          }

          // Bottone Mese Successivo
          Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 6
            color: nextMouse.containsMouse ? Theme.overlay : "transparent"
            Text { anchors.centerIn: parent; text: "󰅂"; color: Theme.text; font.pixelSize: 14 }
            MouseArea {
              id: nextMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.nextMonth()
            }
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // 2. Intestazione Giorni della Settimana
        RowLayout {
          Layout.fillWidth: true
          spacing: 0

          Repeater {
            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            Text {
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              color: index >= 5 ? Theme.love : Theme.subtle
              font.family: Theme.fontFamily
              font.pixelSize: 10
              font.bold: true
            }
          }
        }

        // 3. Griglia dei Giorni del Mese
        GridLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          columns: 7
          rowSpacing: 4
          columnSpacing: 0

          Repeater {
            model: root.daysModel

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 26
              radius: 6
              color: modelData.isToday ? Theme.foam : (dayMouse.containsMouse && modelData.isCurrent ? Theme.overlay : "transparent")

              Text {
                anchors.centerIn: parent
                text: modelData.day
                color: {
                  if (modelData.isToday) return Theme.base
                  if (!modelData.isCurrent) return Theme.subtle
                  return Theme.text
                }
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: modelData.isToday
                opacity: modelData.isCurrent ? 1.0 : 0.35
              }

              MouseArea {
                id: dayMouse
                anchors.fill: parent
                hoverEnabled: true
              }
            }
          }
        }
      }
    }
  }
}
