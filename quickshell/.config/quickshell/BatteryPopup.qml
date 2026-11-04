import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  property bool isOpen: BatteryState.visible
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
    right: true
  }
  margins {
    top: Theme.marginTop
    right: Theme.marginRight
  }

  implicitWidth: Theme.popupWidthSmall
  implicitHeight: 200
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // -------------------------------------------------------------
  // LETTURA DEI CONSUMI (Watt)
  // -------------------------------------------------------------
  property real wattageValue: BatteryState.displayDevice && BatteryState.displayDevice.changeRate ? Math.abs(BatteryState.displayDevice.changeRate) : 0.0

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

  // -------------------------------------------------------------
  // PROFILI ENERGETICI
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
    root.currentProfile = profile
    let tunedTarget = "balanced-battery"
    if (profile === "performance") tunedTarget = "throughput-performance"
    else if (profile === "power-saver") tunedTarget = "powersave"

    Quickshell.execDetached(["sh", "-c", "tuned-adm profile " + tunedTarget + " 2>/dev/null || powerprofilesctl set " + profile])
    profileCheckTimer.restart()
  }

  Timer {
    id: profileCheckTimer
    interval: 1500
    onTriggered: {
      profileQueryProc.running = false
      profileQueryProc.running = true
    }
  }

  Component.onCompleted: profileQueryProc.running = true

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
      if (!panelHover.hovered) BatteryState.close()
    }
  }

  Timer {
    id: inactivityTimer
    interval: Theme.inactivityTimer
    onTriggered: {
      if (!panelHover.hovered) BatteryState.close()
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      inactivityTimer.restart()
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
    interval: 800
    onTriggered: {
      if (root.isOpen) {
        wattQueryProc.running = false
        wattQueryProc.running = true
      }
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

        // 1. Dettaglio Batteria
        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.spacingLarge

          Text {
            text: BatteryState.batIcon
            font.family: Theme.fontFamily
            color: BatteryState.batteryLevel <= 20 && !BatteryState.isCharging ? Theme.love : Theme.foam
            font.pixelSize: Theme.fontSizeTitle
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
              Layout.fillWidth: true

              Text {
                text: BatteryState.batteryLevel + "%"
                color: BatteryState.batteryLevel <= 20 && !BatteryState.isCharging ? Theme.love : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
              }

              Item { Layout.fillWidth: true }

              Rectangle {
                visible: root.wattageValue > 0
                implicitWidth: wattText.implicitWidth + Theme.paddingMedium
                implicitHeight: 18
                radius: Theme.radiusSmall
                color: Theme.overlay

                Text {
                  id: wattText
                  anchors.centerIn: parent
                  text: (BatteryState.isCharging ? "+" : "-") + root.wattageValue.toFixed(1) + " W"
                  color: BatteryState.isCharging ? Theme.foam : (root.wattageValue > 25 ? Theme.love : Theme.gold)
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                  font.bold: true
                }
              }
            }

            Text {
              text: {
                let base = BatteryState.isCharging ? "Charging" : "Discharging"
                if (BatteryState.remainingTime) {
                  return base + " (" + BatteryState.remainingTime + (BatteryState.isCharging ? " to 100%" : " remaining") + ")"
                }
                return base
              }
              color: Theme.subtle
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSizePopup
            }
          }
        }

        // Barra grafica
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 4
          radius: 2
          color: Theme.overlay

          Rectangle {
            width: parent.width * (Math.min(BatteryState.batteryLevel, 100) / 100)
            height: parent.height
            radius: 2
            color: BatteryState.isCharging ? Theme.foam : (BatteryState.batteryLevel <= 20 ? Theme.love : Theme.text)
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // 2. Selettore Profili
        Text {
          text: "POWER PROFILE"
          color: Theme.subtle
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSizePopup
          font.bold: true
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Theme.spacingSmall

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
            onSelected: root.setProfile("balanced-battery")
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
    radius: Theme.radiusMedium
    color: pItem.isActive ? Theme.overlay : (pMouse.containsMouse ? Theme.hover : "transparent")

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Theme.paddingMedium
      anchors.rightMargin: Theme.paddingMedium
      spacing: Theme.spacingLarge

      Text {
        text: pItem.icon
        color: pItem.isActive ? pItem.accentColor : Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePopup
      }

      Text {
        text: pItem.title
        color: pItem.isActive ? pItem.accentColor : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePopup
        font.bold: pItem.isActive
        Layout.fillWidth: true
      }

      Text {
        visible: pItem.isActive
        text: ""
        color: pItem.accentColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePopup
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
