pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

QtObject {
  id: root

  property bool visible: false
  function toggle(): void { visible = !visible }
  function open(): void { visible = true }
  function close(): void { visible = false }

  // Dispositivo UPower
  readonly property var displayDevice: UPower.displayDevice
  readonly property int batteryLevel: displayDevice ? Math.round(displayDevice.percentage * 100) : 0
  readonly property bool isCharging: displayDevice ? displayDevice.state === UPowerDeviceState.Charging : false

  // Set Icone Batteria
  readonly property string iconsCharging: "󰂄"
  readonly property var iconsDefault: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  readonly property string batIcon: {
    let idx = Math.max(0, Math.min(Math.floor(batteryLevel / 10), 9))
    return isCharging ? iconsCharging : iconsDefault[idx]
  }

  // Stima Tempo Residuo
  readonly property string remainingTime: {
    if (!displayDevice) return ""
    let sec = isCharging ? displayDevice.timeToFull : displayDevice.timeToEmpty
    if (!sec || sec <= 0) return ""
    let h = Math.floor(sec / 3600)
    let m = Math.floor((sec % 3600) / 60)
    return h > 0 ? (h + "h " + m + "m") : (m + "m")
  }

  // Monitoraggio Notifiche Soglia
  property bool _notified15: false
  property bool _notified10: false
  property bool _notified5: false

  onIsChargingChanged: {
    if (isCharging) {
      _notified15 = false
      _notified10 = false
      _notified5 = false
    }
  }

  onBatteryLevelChanged: {
    if (isCharging || batteryLevel <= 0) return

    if (batteryLevel <= 5 && !_notified5) {
      _notified5 = true
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "System", "Critical Battery (5%)", "Connect the charger immediately"])
    } else if (batteryLevel <= 10 && !_notified10) {
      _notified10 = true
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "System", "Low Battery (10%)", "Connect the charger"])
    } else if (batteryLevel <= 15 && !_notified15) {
      _notified15 = true
      Quickshell.execDetached(["notify-send", "-a", "System", "Battery Running Low (15%)", "Connect the charger"])
    }
  }
}
