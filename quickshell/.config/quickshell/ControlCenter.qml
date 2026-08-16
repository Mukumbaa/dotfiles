import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  property bool isOpen: ControlCenterState.visible
  property real animProgress: isOpen ? 1.0 : 0.0
  visible: isOpen || animProgress > 0.001

  Behavior on animProgress {
    NumberAnimation {
      duration: 200
      easing.type: Easing.InOutQuad
    }
  }

  anchors {
    top: true
    right: true
  }
  margins {
    top: -1
    right: 16
  }

  implicitWidth: 340
  implicitHeight: 280
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay

  // -------------------------------------------------------------
  // GESTIONE AUTO-CHIUSURA AL MOUSE LEAVE
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
    interval: 1000
    onTriggered: {
      if (!panelHover.hovered) {
        ControlCenterState.visible = false
      }
    }
  }

  Timer {
    id: inactivityTimer
    interval: 3500
    onTriggered: {
      if (!panelHover.hovered) {
        ControlCenterState.visible = false
      }
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      inactivityTimer.restart()
      if (ControlCenterState.currentTab === "wifi") scanWifi()
      if (ControlCenterState.currentTab === "bluetooth") scanBt()
    } else {
      autoCloseTimer.stop()
      inactivityTimer.stop()
    }
  }

  // -------------------------------------------------------------
  // LOGICA WI-FI
  // -------------------------------------------------------------
  property bool wifiEnabled: true
  property var wifiNetworks: []
  Timer {
    id: wifiPowerOnDelayTimer
    interval: 600
    onTriggered: {
      wifiScanProc.running = false
      wifiScanProc.running = true
    }
  }
  Process {
    id: wifiToggleProc
    command: ["nmcli", "radio", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: root.wifiEnabled = (this.text.trim() === "enabled")
    }
  }

  Process {
    id: wifiScanProc
    command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        for (let line of lines) {
          if (!line) continue
          let parts = line.split(":")
          let inUse = parts[0] === "*"
          let ssid = parts[1] || ""
          let signal = parseInt(parts[2]) || 0
          let security = parts[3] || "Open"
          if (ssid && !list.find(n => n.ssid === ssid)) {
            list.push({ inUse: inUse, ssid: ssid, signal: signal, security: security })
          }
        }
        root.wifiNetworks = list
      }
    }
  }

  function scanWifi() {
    wifiToggleProc.running = false
    wifiScanProc.running = false
    wifiToggleProc.running = true
    wifiScanProc.running = true
  }

  // -------------------------------------------------------------
  // LOGICA BLUETOOTH
  // -------------------------------------------------------------
  property bool btEnabled: true
  property var btDevices: []
  property string btActionMac: ""

  Process {
    id: btPowerProc
    command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'enabled' || echo 'disabled'"]
    stdout: StdioCollector {
      onStreamFinished: root.btEnabled = (this.text.trim() === "enabled")
    }
  }

  Process {
    id: btScanProc
    command: ["sh", "-c", "bluetoothctl devices 2>/dev/null | sed -r 's/\\x1b\\[[0-9;]*[a-zA-Z]//g' | while read -r tag mac name; do if [ \"$tag\" = \"Device\" ] && [ -n \"$mac\" ]; then if bluetoothctl info \"$mac\" 2>/dev/null | grep -q 'Connected: yes'; then echo \"$mac|yes|$name\"; else echo \"$mac|no|$name\"; fi; fi; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        for (let line of lines) {
          let cleanLine = line.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").trim()
          if (!cleanLine) continue
          let parts = cleanLine.split("|")
          if (parts.length >= 3) {
            let mac = parts[0].trim()
            let isConnected = parts[1].trim() === "yes"
            let name = parts.slice(2).join("|").trim()

            let isMac = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/.test(mac)
            if (isMac && name.length > 0) {
              list.push({ mac: mac, connected: isConnected, name: name })
            }
          }
        }
        root.btDevices = list
        root.btActionMac = ""
      }
    }
  }

  Process {
    id: btActionProc
    stdout: StdioCollector {
      onStreamFinished: {
        btSyncDelayTimer.restart()
      }
    }
  }

  Timer {
    id: btSyncDelayTimer
    interval: 300
    onTriggered: root.scanBt()
  }

  Timer {
    id: btPowerOnDelayTimer
    interval: 600
    onTriggered: root.scanBt()
  }

  function scanBt() {
    btPowerProc.running = false
    btScanProc.running = false
    btPowerProc.running = true
    btScanProc.running = true
  }

  function toggleDeviceConnection(device) {
    if (btActionProc.running) return
    root.btActionMac = device.mac

    let action = device.connected ? "disconnect" : "connect"
    btActionProc.command = ["bluetoothctl", action, device.mac]
    btActionProc.running = true
  }

  // -------------------------------------------------------------
  // CONTENITORE PRINCIPALE (Layout Lineare Diretto)
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

      color: Theme.surface
      topLeftRadius: 0
      topRightRadius: 0
      bottomLeftRadius: 12
      bottomRightRadius: 12
      border.color: Theme.base
      border.width: 1

      ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        // 1. Tab Switcher
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 28
          spacing: 6

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: ControlCenterState.currentTab === "wifi" ? Theme.overlay : "transparent"
            RowLayout {
              anchors.centerIn: parent
              spacing: 6
              Text { text: "󰤨"; color: ControlCenterState.currentTab === "wifi" ? Theme.foam : Theme.subtle; font.pixelSize: 13 }
              Text { text: "Wi-Fi"; color: ControlCenterState.currentTab === "wifi" ? Theme.text : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { ControlCenterState.currentTab = "wifi"; root.scanWifi() }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: ControlCenterState.currentTab === "bluetooth" ? Theme.overlay : "transparent"
            RowLayout {
              anchors.centerIn: parent
              spacing: 6
              Text { text: "󰂯"; color: ControlCenterState.currentTab === "bluetooth" ? Theme.iris : Theme.subtle; font.pixelSize: 13 }
              Text { text: "Bluetooth"; color: ControlCenterState.currentTab === "bluetooth" ? Theme.text : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { ControlCenterState.currentTab = "bluetooth"; root.scanBt() }
            }
          }
        }

        // 2A. Sotto-Header Wi-Fi
        RowLayout {
          visible: ControlCenterState.currentTab === "wifi"
          Layout.fillWidth: true
          implicitHeight: 24
          spacing: 6

          Text {
            text: "Wi-Fi"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
          }

          Item { Layout.fillWidth: true }

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 5
            color: refreshMouse.containsMouse ? Theme.overlay : "transparent"

            Text {
              anchors.centerIn: parent
              text: "󰑐"
              color: wifiScanProc.running ? Theme.foam : Theme.subtle
              font.pixelSize: 13

              RotationAnimation on rotation {
                running: wifiScanProc.running
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
              }
            }

            MouseArea {
              id: refreshMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.wifiEnabled
              onClicked: root.scanWifi()
            }
          }

          Rectangle {
            implicitWidth: 36
            implicitHeight: 18
            radius: 9
            color: root.wifiEnabled ? Theme.foam : Theme.overlay

            Rectangle {
              x: root.wifiEnabled ? 20 : 2
              y: 2
              implicitWidth: 14
              implicitHeight: 14
              radius: 7
              color: Theme.base
              Behavior on x { NumberAnimation { duration: 120 } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.wifiEnabled) {
                  // Spegnimento immediato
                  root.wifiEnabled = false
                  root.wifiNetworks = []
                  Quickshell.execDetached(["nmcli", "radio", "wifi", "off"])
                } else {
                  // Accensione immediata
                  root.wifiEnabled = true
                  Quickshell.execDetached(["nmcli", "radio", "wifi", "on"])
                  // Diamo 600ms alla scheda Wi-Fi per accendersi prima di cercare le reti
                  wifiPowerOnDelayTimer.restart()
                }
              }
            }
          }
        }

        // 2B. Sotto-Header Bluetooth
        RowLayout {
          visible: ControlCenterState.currentTab === "bluetooth"
          Layout.fillWidth: true
          implicitHeight: 24
          spacing: 6

          Text {
            text: "Bluetooth"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
          }

          Item { Layout.fillWidth: true }

          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 5
            color: btRefreshMouse.containsMouse ? Theme.overlay : "transparent"

            Text {
              anchors.centerIn: parent
              text: "󰑐"
              color: btScanProc.running ? Theme.iris : Theme.subtle
              font.pixelSize: 13

              RotationAnimation on rotation {
                running: btScanProc.running
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
              }
            }

            MouseArea {
              id: btRefreshMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.btEnabled
              onClicked: root.scanBt()
            }
          }

          Rectangle {
            implicitWidth: 36
            implicitHeight: 18
            radius: 9
            color: root.btEnabled ? Theme.iris : Theme.overlay

            Rectangle {
              x: root.btEnabled ? 20 : 2
              y: 2
              implicitWidth: 14
              implicitHeight: 14
              radius: 7
              color: Theme.base
              Behavior on x { NumberAnimation { duration: 120 } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.btEnabled) {
                  root.btEnabled = false
                  root.btDevices = []
                  Quickshell.execDetached(["bluetoothctl", "power", "off"])
                } else {
                  root.btEnabled = true
                  Quickshell.execDetached(["bluetoothctl", "power", "on"])
                  btPowerOnDelayTimer.restart()
                }
              }
            }
          }
        }

        // 3. Divisore
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 1
          color: Theme.overlay
        }

        // 4. Area Liste / Contenuto (occupa tutto il resto)
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          // Vista Wi-Fi
          Item {
            anchors.fill: parent
            visible: ControlCenterState.currentTab === "wifi"

            RowLayout {
              anchors.centerIn: parent
              visible: wifiScanProc.running && root.wifiNetworks.length === 0
              spacing: 8

              Text {
                text: "󰑐"
                color: Theme.foam
                font.pixelSize: 13
                RotationAnimation on rotation {
                  running: true
                  loops: Animation.Infinite
                  from: 0
                  to: 360
                  duration: 900
                }
              }

              Text {
                text: "Ricerca reti..."
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
              }
            }

            Text {
              anchors.centerIn: parent
              visible: !root.wifiEnabled
              text: "Wi-Fi disattivato"
              color: Theme.subtle
              font.family: Theme.fontFamily
              font.pixelSize: 11
            }

            ListView {
              anchors.fill: parent
              visible: root.wifiEnabled && (!wifiScanProc.running || root.wifiNetworks.length > 0)
              clip: true
              model: root.wifiNetworks

              populate: Transition {
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutQuad }
              }

              delegate: Rectangle {
                width: ListView.view.width
                implicitHeight: 34
                radius: 5
                color: modelData.inUse ? Theme.overlay : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 8

                  Text {
                    text: modelData.signal > 70 ? "󰤨" : (modelData.signal > 40 ? "󰤥" : "󰤟")
                    color: modelData.inUse ? Theme.foam : Theme.subtle
                    font.pixelSize: 13
                  }

                  Text {
                    text: modelData.ssid
                    color: modelData.inUse ? Theme.foam : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }

                  Text {
                    text: modelData.inUse ? "Connesso" : ""
                    color: Theme.foam
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (!modelData.inUse) {
                      Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid])
                    }
                  }
                }
              }
            }
          }

          // Vista Bluetooth
          Item {
            anchors.fill: parent
            visible: ControlCenterState.currentTab === "bluetooth"

            RowLayout {
              anchors.centerIn: parent
              visible: btScanProc.running && root.btDevices.length === 0
              spacing: 8

              Text {
                text: "󰑐"
                color: Theme.iris
                font.pixelSize: 13
                RotationAnimation on rotation {
                  running: true
                  loops: Animation.Infinite
                  from: 0
                  to: 360
                  duration: 900
                }
              }

              Text {
                text: "Ricerca dispositivi..."
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
              }
            }

            Text {
              anchors.centerIn: parent
              visible: !root.btEnabled
              text: "Bluetooth disattivato"
              color: Theme.subtle
              font.family: Theme.fontFamily
              font.pixelSize: 11
            }

            ListView {
              anchors.fill: parent
              visible: root.btEnabled && (!btScanProc.running || root.btDevices.length > 0)
              clip: true
              model: root.btDevices

              populate: Transition {
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutQuad }
              }

              delegate: Rectangle {
                id: devItem
                width: ListView.view.width
                implicitHeight: 36
                radius: 5
                color: modelData.connected ? Theme.overlay : (devMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

                property bool isBusy: root.btActionMac === modelData.mac

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 8

                  Text {
                    text: devItem.isBusy ? "󰑐" : (modelData.connected ? "󰂱" : "󰂲")
                    color: devItem.isBusy ? Theme.gold : (modelData.connected ? Theme.iris : Theme.subtle)
                    font.pixelSize: 14

                    RotationAnimation on rotation {
                      running: devItem.isBusy
                      loops: Animation.Infinite
                      from: 0
                      to: 360
                      duration: 800
                    }
                  }

                  Text {
                    text: modelData.name
                    color: modelData.connected ? Theme.iris : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: modelData.connected
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }

                  Text {
                    text: {
                      if (devItem.isBusy) {
                        return modelData.connected ? "Disconnessione..." : "Connessione..."
                      }
                      return modelData.connected ? "Connesso" : ""
                    }
                    color: devItem.isBusy ? Theme.gold : Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                  }
                }

                MouseArea {
                  id: devMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: devItem.isBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
                  enabled: !devItem.isBusy
                  onClicked: root.toggleDeviceConnection(modelData)
                }
              }
            }
          }
        }
      }
    }
  }
}
