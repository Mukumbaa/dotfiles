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

  // Stessa identica curva super-fluida del Calendario e dell'Audio
  Behavior on animProgress {
    NumberAnimation {
      duration: Theme.animationDuration
      easing.type: Easing.OutCubic
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
  // LOGICA BATTERIA, TEMPO E WATT (Calcolo Matematico Esatto)
  // -------------------------------------------------------------
  property var displayDevice: UPower.displayDevice
  property int batteryLevel: displayDevice ? Math.round(displayDevice.percentage * 100) : 0
  property bool isCharging: displayDevice ? displayDevice.state === UPowerDeviceState.Charging : false
  property real wattageValue: displayDevice && displayDevice.changeRate ? Math.abs(displayDevice.changeRate) : 0.0

  property var iconsCharging: "󰂄"
  property var iconsDefault:  ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  property string batIcon: {
    let idx = Math.max(0, Math.min(Math.floor(batteryLevel / 10), 9))
    return isCharging ? iconsCharging : iconsDefault[idx]
  }

  // Lettura precisa: se c'è power_now legge solo quello, altrimenti fa corrente x tensione
  Process {
    id: wattQueryProc
    command: ["sh", "-c", "if [ -f /sys/class/power_supply/BAT*/power_now ]; then cat /sys/class/power_supply/BAT*/power_now 2>/dev/null | head -n1; elif [ -f /sys/class/power_supply/BAT*/current_now ] && [ -f /sys/class/power_supply/BAT*/voltage_now ]; then c=$(cat /sys/class/power_supply/BAT*/current_now 2>/dev/null | head -n1); v=$(cat /sys/class/power_supply/BAT*/voltage_now 2>/dev/null | head -n1); echo \"$c $v\"; fi"]
    stdout: StdioCollector {
      onStreamFinished: {
        let parts = this.text.trim().split(/\s+/)
        if (parts.length === 1 && parts[0].length > 0) {
          let p = parseFloat(parts[0])
          if (!isNaN(p) && p > 0) root.wattageValue = p / 1000000
        } else if (parts.length >= 2) {
          let c = parseFloat(parts[0])
          let v = parseFloat(parts[1])
          if (!isNaN(c) && !isNaN(v) && c > 0 && v > 0) {
            root.wattageValue = (c * v) / 1000000000000
          }
        }
      }
    }
  }

  // Poll periodico: parte solo a popup fermo e aperto, senza bloccare l'animazione iniziale
  Timer {
    id: wattPollTimer
    interval: 2000
    repeat: true
    running: root.isOpen
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
  // PROFILI ENERGETICI (Zero conflitti e zero delay)
  // -------------------------------------------------------------
  property string currentProfile: "balanced"

  Process {
    id: profileQueryProc
    command: ["sh", "-c", "cat /etc/tuned/active_profile 2>/dev/null || powerprofilesctl get 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        let raw = this.text.trim().toLowerCase()
        if (raw.includes("performance") || raw.includes("throughput")) {
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
    // Imposta subito la selezione grafica permanente
    root.currentProfile = profile

    let tunedTarget = "balanced"
    if (profile === "performance") tunedTarget = "throughput-performance"
    else if (profile === "power-saver") tunedTarget = "powersave"

    Quickshell.execDetached(["sh", "-c", "tuned-adm profile " + tunedTarget + " 2>/dev/null || powerprofilesctl set " + profile])
    profileCheckTimer.restart()
  }

  // Timer di verifica allungato a 1.5 secondi per dare tempo a tuned di salvare
  Timer {
    id: profileCheckTimer
    interval: 1500
    onTriggered: {
      profileQueryProc.running = false
      profileQueryProc.running = true
    }
  }

  // Legge il profilo 1 sola volta all'avvio del sistema
  Component.onCompleted: profileQueryProc.running = true

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
    interval: Theme.autoCloseTimer
    onTriggered: {
      if (!panelHover.hovered) {
        BatteryState.close()
      }
    }
  }

  Timer {
    id: inactivityTimer
    interval: Theme.inactivityTimer
    onTriggered: {
      if (!panelHover.hovered) {
        BatteryState.close()
      }
    }
  }

  // ZERO PROCESSI AL CLICK: apertura istantanea e fluida a 144 FPS
  onIsOpenChanged: {
    if (isOpen) {
      inactivityTimer.restart()
      // Avvia la prima lettura precisa dei Watt dopo 400ms (quando la finestra è già ferma)
      wattDelayTimer.restart()
    } else {
      autoCloseTimer.stop()
      inactivityTimer.stop()
      wattDelayTimer.stop()
      wattQueryProc.running = false
    }
  }

  Timer {
    id: wattDelayTimer
    interval: 1000
    onTriggered: {
      if (root.isOpen) {
        wattQueryProc.running = false
        wattQueryProc.running = true
      }
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

      opacity: root.animProgress
      transform: Translate {
        y: (1.0 - root.animProgress) * -3 // scorrimento leggero di 15px verso il basso
      }

      color: Theme.base
      radius: Theme.radius
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

              // Badge Watt
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

          ProfileItem {
            icon: "󰓅"
            title: "Performance"
            profileKey: "performance"
            accentColor: Theme.love
            isActive: root.currentProfile === "performance"
            onSelected: root.setProfile("performance")
          }

          ProfileItem {
            icon: "󰾅"
            title: "Balanced"
            profileKey: "balanced"
            accentColor: Theme.foam
            isActive: root.currentProfile === "balanced"
            onSelected: root.setProfile("balanced")
          }

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
