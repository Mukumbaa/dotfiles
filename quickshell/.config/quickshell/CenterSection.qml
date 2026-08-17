import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

RowLayout {
  anchors.centerIn: parent
  spacing: 8


  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    id: clockText
    color: Theme.text
    font.pixelSize: 12
    font.family: Theme.fontFamily

    property bool showFullDate: false
    text: showFullDate 
    ? Qt.formatDateTime(clock.date, "dd MMMM yyyy")
    : Qt.formatDateTime(clock.date, "dddd hh:mm")

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      // Hover: apre il calendario
      // onEntered: CalendarState.open()

      // Click: toggle (o cambio formato data)
      onClicked: CalendarState.toggle()
    }
  }

}
