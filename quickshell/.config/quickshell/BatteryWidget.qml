import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
  id: batWidget
  implicitWidth: batRow.implicitWidth
  implicitHeight: batRow.implicitHeight

  // -------------------------------------------------------------
  // MONITORAGGIO AUTOMATICO BATTERIA SCARICA
  // -------------------------------------------------------------
  property var displayDevice: UPower.displayDevice
  property int batteryLevel: displayDevice ? Math.round(displayDevice.percentage * 100) : 0
  property bool isCharging: displayDevice ? displayDevice.state === UPowerDeviceState.Charging : false

  // Flag per evitare notifiche duplicate a raffica
  property bool notified15: false
  property bool notified10: false
  property bool notified5: false

  // Quando colleghi il caricatore, resetta i promemoria
  onIsChargingChanged: {
    if (isCharging) {
      notified15 = false
      notified10 = false
      notified5 = false
    }
  }

  // Controlla il livello e invia la notifica automatica al superamento delle soglie
  onBatteryLevelChanged: {
    if (isCharging || batteryLevel <= 0) return

    if (batteryLevel <= 5 && !notified5) {
      notified5 = true
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "System", "Critical Battery (5%)", "Connect the charger"])
    } else if (batteryLevel <= 10 && !notified10) {
      notified10 = true
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "System", "Low Battery (10%)", "Connect the charger"])
    } else if (batteryLevel <= 15 && !notified15) {
      notified15 = true
      Quickshell.execDetached(["notify-send", "-a", "System", "Battery Running Low (15%)", "Connect the charger"])
    }
  }
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
