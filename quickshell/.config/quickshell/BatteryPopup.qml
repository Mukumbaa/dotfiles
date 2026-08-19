import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
  id: root

  property bool isOpen: BatteryState.visible
  property real animProgress: isOpen ? 1.0 : 0.0
  visible: isOpen || animProgress > 0.001

  Behavior on animProgress {
    NumberAnimation {
      duration: Theme.animationDuration
      easing.type: Easing.InOutQuad
    }
  }

  anchors {
    top: true
    right: true
  }
  margins {
    top: Theme.marginTop
    right: Theme.marginRight
  }

  implicitWidth: 265
  implicitHeight: 200
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // -------------------------------------------------------------
  // LOGICA BATTERIA, TEMPO E WATT (Istantanea via sysfs + fallback UPower)
  // -------------------------------------------------------------
  property var displayDevice: UPower.displayDevice
  property int batteryLevel: displayDevice ? Math.round(displayDevice.percentage * 100) : 0
  property bool isCharging: displayDevice ? displayDevice.state === UPowerDeviceState.Charging : false

  // Legge da UPower changeRate come valore iniziale, aggiornato poi da sysfs
  property real wattageValue: displayDevice && displayDevice.changeRate ? Math.abs(displayDevice.changeRate) : 0.0

  // Scala completa delle icone a 10 livelli
  property var iconsCharging: "󰂄"
  property var iconsDefault:  ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  property string batIcon: {
    let idx = Math.max(0, Math.min(Math.floor(batteryLevel / 10), 9))
    return isCharging ? iconsCharging : iconsDefault[idx]
  }

  // Lettura diretta da sysfs (eseguita SOLO a popup aperto)
  Process {
    id: wattQueryProc
    command: ["sh", "-c", "if [ -f /sys/class/power_supply/BAT*/power_now ]; then awk '{printf \"%.1f\", $1 / 1000000}' /sys/class/power_supply/BAT*/power_now 2>/dev/null | head -n1; elif [ -f /sys/class/power_supply/BAT*/current_now ] && [ -f /sys/class/power_supply/BAT*/voltage_now ]; then c=$(cat /sys/class/power_supply/BAT*/current_now 2>/dev/null | head -n1); v=$(cat /sys/class/power_supply/BAT*/voltage_now 2>/dev/null | head -n1); awk \"BEGIN {printf \\\"%.1f\\\", ($c * $v) / 1000000000000}\"; fi"]
    stdout: StdioCollector {
      onStreamFinished: {
        let val = parseFloat(this.text.trim())
        if (!isNaN(val) && val > 0) {
          root.wattageValue = val
        } else if (displayDevice && displayDevice.changeRate) {
          root.wattageValue = Math.abs(displayDevice.changeRate)
        }
      }
    }
  }

  Timer {
    id: wattPollTimer
    interval: 2000
    repeat: true
    running: root.isOpen
    triggeredOnStart: true
    onTriggered: {
      wattQueryProc.running = false
      wattQueryProc.running = true
    }
  }

  // Stima del tempo residuo
  property string remainingTime: {
    if (!displayDevice) return ""
    let sec = isCharging ? displayDevice.timeToFull : displayDevice.timeToEmpty
    if (!sec || sec <= 0) return ""
    let h = Math.floor(sec / 3600)
    let m = Math.floor((sec % 3600) / 60)
    if (h > 0) return h + "h " + m + "m"
    return m + "m"
  }

  // -------------------------------------------------------------
  // LOGICA PROFILI ENERGETICI (Supporto Diretto Tuned-adm / Fedora)
  // -------------------------------------------------------------
  property string currentProfile: "" // "performance", "balanced", "power-saver"

  Process {
    id: profileQueryProc
    command: ["sh", "-c", "tuned-adm active 2>/dev/null | grep 'Current active profile:' | cut -d: -f2 | tr -d ' ' || powerprofilesctl get 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        let raw = this.text.trim().toLowerCase()
        if (raw.includes("performance")) {
          root.currentProfile = "performance"
        } else if (raw.includes("powersave") || raw.includes("power-saver")) {
          root.currentProfile = "power-saver"
        } else if (raw.includes("balanced")) {
          root.currentProfile = "balanced"
        }
      }
    }
  }

  function setProfile(profile) {
    root.currentProfile = profile

    // Traduzione nei profili nativi di tuned-adm
    let tunedTarget = "balanced"
    if (profile === "performance") tunedTarget = "throughput-performance"
    else if (profile === "power-saver") tunedTarget = "powersave"

    // Applica direttamente con tuned-adm
    Quickshell.execDetached(["sh", "-c", "tuned-adm profile " + tunedTarget + " 2>/dev/null || powerprofilesctl set " + profile])
    profileCheckTimer.restart()
  }

  Timer {
    id: profileCheckTimer
    interval: 400
    onTriggered: {
      profileQueryProc.running = false
      profileQueryProc.running = true
    }
  }

  // -------------------------------------------------------------
  // AUTO-CHIUSURA AL MOUSE LEAVE
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
    interval: 600
    onTriggered: {
      if (!panelHover.hovered) {
        BatteryState.close()
      }
    }
  }

  Timer {
    id: inactivityTimer
    interval: 3000
    onTriggered: {
      if (!panelHover.hovered) {
        BatteryState.close()
      }
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      inactivityTimer.restart()
      wattQueryProc.running = false
      wattQueryProc.running = true
      profileQueryProc.running = false
      profileQueryProc.running = true
    } else {
      autoCloseTimer.stop()
      inactivityTimer.stop()
    }
  }

  // -------------------------------------------------------------
  // CONTENITORE PRINCIPALE
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

        // 1. STATO BATTERIA, WATT E TEMPO RESIDUO
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          // Icona Dinamica Graduata
          Text {
            text: root.batIcon
            color: root.batteryLevel <= 20 && !root.isCharging ? Theme.love : Theme.foam
            font.pixelSize: 22
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
              Layout.fillWidth: true

              Text {
                text: root.batteryLevel + "%"
                color: root.batteryLevel <= 20 && !root.isCharging ? Theme.love : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
              }

              Item { Layout.fillWidth: true }

              // Badge Watt (in tempo reale da sysfs)
              Rectangle {
                visible: root.wattageValue > 0
                implicitWidth: wattText.implicitWidth + 8
                implicitHeight: 18
                radius: 4
                color: Theme.overlay

                Text {
                  id: wattText
                  anchors.centerIn: parent
                  text: (root.isCharging ? "+" : "-") + root.wattageValue.toFixed(1) + " W"
                  color: root.isCharging ? Theme.foam : (root.wattageValue > 25 ? Theme.love : Theme.gold)
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                }
              }
            }

            // Descrizione stato e tempo rimanente stimato
            Text {
              text: {
                let base = root.isCharging ? "Charging" : "Discharging"
                if (root.remainingTime) {
                  return base + " (" + root.remainingTime + (root.isCharging ? " to 100%" : " remaining") + ")"
                }
                return base
              }
              color: Theme.subtle
              font.family: Theme.fontFamily
              font.pixelSize: 9
            }
          }
        }

        // Barra di carica grafica
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 4
          radius: 2
          color: Theme.overlay

          Rectangle {
            width: parent.width * (Math.min(root.batteryLevel, 100) / 100)
            height: parent.height
            radius: 2
            color: root.isCharging ? Theme.foam : (root.batteryLevel <= 20 ? Theme.love : Theme.text)
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // 2. SELEZIONE PROFILI ENERGETICI
        Text {
          text: "POWER PROFILE"
          color: Theme.subtle
          font.family: Theme.fontFamily
          font.pixelSize: 9
          font.bold: true
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          // PRESTAZIONI
          ProfileItem {
            icon: "󰓅"
            title: "Performance"
            profileKey: "performance"
            accentColor: Theme.love
            isActive: root.currentProfile === "performance"
            onSelected: root.setProfile("performance")
          }

          // BILANCIATO
          ProfileItem {
            icon: "󰾅"
            title: "Balanced"
            profileKey: "balanced"
            accentColor: Theme.foam
            isActive: root.currentProfile === "balanced"
            onSelected: root.setProfile("balanced")
          }

          // RISPARMIO ENERGETICO
          ProfileItem {
            icon: "󰾆"
            title: "Power Saver"
            profileKey: "power-saver"
            accentColor: Theme.iris
            isActive: root.currentProfile === "power-saver"
            onSelected: root.setProfile("power-saver")
          }
        }
      }
    }
  }

  // Componente per le righe dei profili
  component ProfileItem: Rectangle {
    id: pItem
    property string icon: ""
    property string title: ""
    property string profileKey: ""
    property color accentColor: Theme.text
    property bool isActive: false
    signal selected()

    Layout.fillWidth: true
    implicitHeight: 30
    radius: 6
    color: pItem.isActive ? Theme.overlay : (pMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 8

      Text {
        text: pItem.icon
        color: pItem.isActive ? pItem.accentColor : Theme.subtle
        font.pixelSize: 13
      }

      Text {
        text: pItem.title
        color: pItem.isActive ? pItem.accentColor : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: pItem.isActive
        Layout.fillWidth: true
      }

      Text {
        visible: pItem.isActive
        text: "󰄬"
        color: pItem.accentColor
        font.pixelSize: 12
        font.bold: true
      }
    }

    MouseArea {
      id: pMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pItem.selected()
    }
  }
}
