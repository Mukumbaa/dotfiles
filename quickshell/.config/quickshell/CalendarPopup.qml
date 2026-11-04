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
  // LOGICA CALENDARIO
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
  // AUTO-CHIUSURA
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

  Timer {
    id: autoCloseTimer
    interval: Theme.autoCloseTimer
    onTriggered: {
      if (!panelHover.hovered) CalendarState.close()
    }
  }

  Timer {
    id: inactivityTimer
    interval: Theme.inactivityTimer
    onTriggered: {
      if (!panelHover.hovered) CalendarState.close()
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
  // CONTENITORE
  // -------------------------------------------------------------
  Item {
    anchors.fill: parent
    clip: true

    Rectangle {
      id: card
      width: parent.width
      height: parent.height
      layer.enabled: root.isOpen || root.animProgress > 0.001

      opacity: root.animProgress
      transform: Translate { y: (1.0 - root.animProgress) * -3 }
      color: Theme.base
      radius: Theme.radius
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingLarge
        spacing: Theme.spacingLarge

        // Header Mese / Controlli
        Item {
          Layout.fillWidth: true
          implicitHeight: 24

          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 24
            implicitHeight: 24
            radius: Theme.radiusSmall
            color: prevMouse.containsMouse ? Theme.overlay : "transparent"

            Text {
              anchors.centerIn: parent
              font.family: Theme.fontFamily
              text: ""
              color: Theme.text
              font.pixelSize: Theme.fontSizePopup
            }

            MouseArea {
              id: prevMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.prevMonth()
            }
          }

          Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(root.displayDate, "MMMM yyyy").toUpperCase()
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
          }

          RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingSmall

            Rectangle {
              implicitWidth: 38
              implicitHeight: 20
              radius: Theme.radiusSmall
              color: todayMouse.containsMouse ? Theme.overlay : Theme.base

              Text {
                anchors.centerIn: parent
                text: "Today"
                color: Theme.foam
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizePopup
                font.bold: true
              }

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
              radius: Theme.radiusSmall
              color: nextMouse.containsMouse ? Theme.overlay : "transparent"

              Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                text: ""
                color: Theme.text
                font.pixelSize: Theme.fontSizePopup
              }

              MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextMonth()
              }
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
              font.pixelSize: Theme.fontSizePopup
              font.bold: true
            }
          }
        }

        // Griglia Giorni
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
              radius: Theme.radiusSmall
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
                font.pixelSize: Theme.fontSizePopup
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
