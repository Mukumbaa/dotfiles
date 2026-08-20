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
      duration: Theme.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  anchors {
    top: true
  }
  margins {
    top: Theme.marginTop
  }

  implicitWidth: 290
  implicitHeight: 295
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // -------------------------------------------------------------
  // LOGICA CALENDARIO OTTIMIZZATA
  // -------------------------------------------------------------
  property var displayDate: new Date()
  property var today: new Date()
  property var daysModel: []

  function prevMonth() {
    displayDate = new Date(displayDate.getFullYear(), displayDate.getMonth() - 1, 1)
  }

  function nextMonth() {
    displayDate = new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 1)
  }

  function resetToday() {
    displayDate = new Date()
  }

  function updateCalendar() {
    let year = displayDate.getFullYear()
    let month = displayDate.getMonth()
    let firstDayIndex = (new Date(year, month, 1).getDay() + 6) % 7
    let daysInMonth = new Date(year, month + 1, 0).getDate()
    let daysInPrevMonth = new Date(year, month, 0).getDate()

    let days = []

    for (let i = firstDayIndex - 1; i >= 0; i--) {
      days.push({ day: daysInPrevMonth - i, isCurrent: false, isToday: false })
    }

    for (let i = 1; i <= daysInMonth; i++) {
      let isToday = (i === today.getDate() && month === today.getMonth() && year === today.getFullYear())
      days.push({ day: i, isCurrent: true, isToday: isToday })
    }

    let nextDays = 42 - days.length
    for (let i = 1; i <= nextDays; i++) {
      days.push({ day: i, isCurrent: false, isToday: false })
    }

    daysModel = days
  }

  onDisplayDateChanged: updateCalendar()
  Component.onCompleted: updateCalendar()

  // -------------------------------------------------------------
  // AUTO-CHIUSURA INTELLIGENTE
  // -------------------------------------------------------------
  HoverHandler {
    id: panelHover
    onHoveredChanged: {
      if (hovered) {
        autoCloseTimer.stop()
        inactivityTimer.stop()
      } else {
        autoCloseTimer.restart()
      }
    }
  }

  // Timer di chiusura rapido quando esci dal calendario (600ms)
  Timer {
    id: autoCloseTimer
    interval: 600
    onTriggered: {
      if (!panelHover.hovered) {
        CalendarState.close()
      }
    }
  }

  // Timer di sicurezza se apri il calendario ma non ci sposti mai il cursore sopra (3 sec)
  Timer {
    id: inactivityTimer
    interval: 3000
    onTriggered: {
      if (!panelHover.hovered) {
        CalendarState.close()
      }
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      inactivityTimer.restart()
    } else {
      autoCloseTimer.stop()
      inactivityTimer.stop()
    }
  }

  // -------------------------------------------------------------
  // CONTENITORE PRINCIPALE (Accelerato via GPU)
  // -------------------------------------------------------------
  Item {
    anchors.fill: parent
    clip: true

    Rectangle {
      id: card
      width: parent.width
      height: parent.height

      // Cache GPU per fluidità assoluta durante lo scorrimento
      layer.enabled: root.isOpen || root.animProgress > 0.001

      // y: (root.animProgress - 1.0) * height
      // opacity: root.animProgress

      opacity: root.animProgress
      transform: Translate {
        y: (1.0 - root.animProgress) * -3 // scorrimento leggero di 15px verso il basso
      }
      color: Theme.base
      radius: Theme.radius
      // topLeftRadius: 0
      // topRightRadius: 0
      // bottomLeftRadius: 12
      // bottomRightRadius: 12
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header Mese / Anno / Controlli
        RowLayout {
          Layout.fillWidth: true
          spacing: 4

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 5
            color: prevMouse.containsMouse ? Theme.overlay : "transparent"
            Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.text; font.pixelSize: 13 }
            MouseArea {
              id: prevMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.prevMonth()
            }
          }

          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(root.displayDate, "MMMM yyyy").toUpperCase()
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
          }

          Rectangle {
            implicitWidth: 36
            implicitHeight: 20
            radius: 4
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

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 5
            color: nextMouse.containsMouse ? Theme.overlay : "transparent"
            Text { anchors.centerIn: parent; text: "󰅂"; color: Theme.text; font.pixelSize: 13 }
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

        // Giorni della settimana
        RowLayout {
          Layout.fillWidth: true
          spacing: 0

          Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
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

        // Griglia dei 42 Giorni
        GridLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          columns: 7
          rowSpacing: 3
          columnSpacing: 0

          Repeater {
            model: root.daysModel

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 24
              radius: 5
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
