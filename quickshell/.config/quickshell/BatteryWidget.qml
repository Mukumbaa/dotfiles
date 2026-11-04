import QtQuick
import QtQuick.Layouts
import Quickshell

MouseArea {
  id: batWidget
  implicitWidth: batRow.implicitWidth
  implicitHeight: batRow.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: BatteryState.toggle()

  RowLayout {
    id: batRow
    spacing: Theme.spacingSmall

    Text {
      text: BatteryState.batteryLevel + "%"
      color: (BatteryState.batteryLevel <= 20 && !BatteryState.isCharging) ? Theme.love : Theme.text
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
    }

    Text {
      text: BatteryState.batIcon
      color: (BatteryState.batteryLevel <= 20 && !BatteryState.isCharging) ? Theme.love : Theme.text
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
    }
  }
}
