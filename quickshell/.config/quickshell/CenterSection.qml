import QtQuick
import QtQuick.Layouts
import Quickshell

RowLayout {
  anchors.centerIn: parent
  spacing: Theme.spacingLarge

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Text {
    id: clockText
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily

    property bool showFullDate: false
    text: showFullDate 
      ? Qt.formatDateTime(clock.date, "dd MMMM yyyy")
      : Qt.formatDateTime(clock.date, "dddd hh:mm")

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: CalendarState.toggle()
    }
  }
}
