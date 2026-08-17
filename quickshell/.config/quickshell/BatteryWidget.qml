import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
  implicitWidth: batRow.implicitWidth
  implicitHeight: batRow.implicitHeight

  RowLayout {
    id: batRow
    spacing: 4
    property var displayDevice: UPower.displayDevice
    property int batteryLevel: displayDevice ? Math.round(displayDevice.percentage * 100) : 0
    property bool isCharging: displayDevice ? displayDevice.state === UPowerDeviceState.Charging : false

    property var iconsCharging: "󰂄"
    property var iconsDefault:  ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    property string batIcon: {
      let idx = Math.max(0, Math.min(Math.floor(batteryLevel / 10), 9))
      return isCharging ? iconsCharging : iconsDefault[idx]
    }

    Text {
      text: batRow.batteryLevel + "%"
      color: (batRow.batteryLevel <= 20 && !batRow.isCharging) ? Theme.love : Theme.text
      font { pixelSize: 12; family: Theme.fontFamily }
    }

    Text {
      text: batRow.batIcon
      color: (batRow.batteryLevel <= 20 && !batRow.isCharging) ? Theme.love : Theme.text
      font { pixelSize: 18; family: Theme.fontFamily }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: BatteryState.toggle()
  }
}
