import QtQuick
import QtQuick.Layouts
import Quickshell

RowLayout {
  anchors.centerIn: parent

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
      cursorShape: Qt.PointingHandCursor
      onClicked: clockText.showFullDate = !clockText.showFullDate
    }
  }

}
