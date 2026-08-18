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

  implicitWidth: 350
  implicitHeight: 330
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // Richiede il focus della tastiera solo quando stai digitando la password del Wi-Fi
  WlrLayershell.keyboardFocus: isPasswordPromptOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // -------------------------------------------------------------
  // GESTIONE AUTO-CHIUSURA
  // -------------------------------------------------------------
  HoverHandler {
    id: panelHover
    onHoveredChanged: {
      if (hovered || isPasswordPromptOpen) {
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
      if (!panelHover.hovered && !isPasswordPromptOpen) {
        ControlCenterState.visible = false
      }
    }
  }

  Timer {
    id: inactivityTimer
    interval: 3500
    onTriggered: {
      if (!panelHover.hovered && !isPasswordPromptOpen) {
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
      isPasswordPromptOpen = false
      autoCloseTimer.stop()
      inactivityTimer.stop()
    }
  }

  // =============================================================
  // 1. LOGICA WI-FI COMPLETA
  // =============================================================
  property bool wifiEnabled: true
  property var wifiNetworks: []
  property var savedConnections: []
  property string wifiActionSsid: ""

  property bool isPasswordPromptOpen: false
  property string targetSsid: ""
  property string targetSecurity: ""
  property string passwordInput: ""
  property bool isConnectingWithPass: false
  property string wifiErrorMsg: ""

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

  // Legge TUTTE le connessioni Wi-Fi salvate
  Process {
    id: savedWifiProc
    command: ["sh", "-c", "nmcli -t -f TYPE,NAME connection show | grep -E '^(802-11-wireless|wifi):' | cut -d: -f2"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        for (let l of lines) {
          let s = l.trim()
          if (s) list.push(s)
        }
        root.savedConnections = list
      }
    }
  }

  property real lastWifiScan: 0

  // Scansione Wi-Fi robusta con doppio rilevamento stato attivo
  Process {
    id: wifiScanProc
    property bool forceRescan: false
    command: [
      "sh", "-c",
      "active=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E ':(802-11-wireless|wifi)$' | cut -d: -f1 | head -n1); " +
      "[ -z \"$active\" ] && active=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep -E '^(\\*|yes):' | head -n1 | cut -d: -f2); " +
      "echo \"ACTIVE:$active\"; " +
      "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan " + (forceRescan ? "yes" : "no") + " 2>/dev/null"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let activeSsid = ""
        let list = []
        let activeItem = null

        for (let line of lines) {
          if (!line) continue
          if (line.startsWith("ACTIVE:")) {
            activeSsid = line.substring(7).trim()
            continue
          }

          let parts = line.split(":")
          if (parts.length >= 4) {
            let inUseFlag = parts[0].trim()
            let ssid = parts[1].trim()
            let signal = parseInt(parts[2]) || 0
            let security = parts.slice(3).join(":").trim()

            if (!ssid) continue

            let inUse = (inUseFlag === "*" || inUseFlag === "yes" || (activeSsid.length > 0 && ssid === activeSsid))
            let isSaved = root.savedConnections.includes(ssid)
            let isOpen = (security === "Open" || security === "--" || security === "")

            if (!list.find(n => n.ssid === ssid) && (!activeItem || activeItem.ssid !== ssid)) {
              let item = { inUse: inUse, ssid: ssid, signal: signal, security: security, isSaved: isSaved, isOpen: isOpen }
              if (inUse) activeItem = item
              else list.push(item)
            }
          }
        }

        if (activeItem) list.unshift(activeItem)
        root.wifiNetworks = list
        root.wifiActionSsid = ""
        root.lastWifiScan = Date.now()
      }
    }
  }

  // Timer di delay post-connessione per attendere DHCP / attivazione
  Timer {
    id: wifiPostConnectTimer
    interval: 600
    onTriggered: root.scanWifi(true)
  }

  // Connessione a reti salvate o aperte
  Process {
    id: wifiConnectDirectProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.wifiActionSsid = ""
        wifiPostConnectTimer.restart()
      }
    }
  }

  // Connessione con password
  Process {
    id: wifiConnectPassProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.isConnectingWithPass = false
        if (this.text.includes("successfully activated") || this.text.includes("attivata con successo") || this.text.includes("successfully")) {
          root.isPasswordPromptOpen = false
          root.passwordInput = ""
          wifiPostConnectTimer.restart()
        } else {
          root.wifiErrorMsg = "Wrong password or failed connection"
        }
      }
    }
  }

  // Dimentica rete Wi-Fi
  Process {
    id: wifiForgetProc
    stdout: StdioCollector {
      onStreamFinished: root.scanWifi(true)
    }
  }

  function scanWifi(force = false) {
    if (!force && root.wifiNetworks.length > 0 && (Date.now() - root.lastWifiScan < 20000)) {
      return
    }

    wifiScanProc.forceRescan = force
    savedWifiProc.running = false
    wifiToggleProc.running = false
    wifiScanProc.running = false
    savedWifiProc.running = true
    wifiToggleProc.running = true
    wifiScanProc.running = true
  }

  function handleWifiClick(net) {
    if (net.inUse || wifiConnectDirectProc.running || wifiConnectPassProc.running) return

    if (net.isSaved || net.isOpen) {
      root.wifiActionSsid = net.ssid
      wifiConnectDirectProc.command = ["nmcli", "dev", "wifi", "connect", net.ssid]
      wifiConnectDirectProc.running = true
    } else {
      root.targetSsid = net.ssid
      root.targetSecurity = net.security
      root.passwordInput = ""
      root.wifiErrorMsg = ""
      root.isPasswordPromptOpen = true
    }
  }

  function submitWifiPassword() {
    if (!root.passwordInput) return
    root.isConnectingWithPass = true
    root.wifiErrorMsg = ""
    wifiConnectPassProc.command = ["nmcli", "dev", "wifi", "connect", root.targetSsid, "password", root.passwordInput]
    wifiConnectPassProc.running = true
  }

  function forgetWifi(ssid) {
    wifiForgetProc.command = ["nmcli", "connection", "delete", "id", ssid]
    wifiForgetProc.running = true
  }

  // =============================================================
  // 2. LOGICA BLUETOOTH COMPLETA
  // =============================================================
  property bool btEnabled: true
  property var btDevices: []
  property var btAvailableDevices: []
  property string btActionMac: ""
  property bool isBtScanning: false

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
        root.btActionMac = "" // Azzera lo spinner
        btActionTimeoutTimer.stop()
      }
    }
  }

  Process {
    id: btDiscoveryProc
    command: ["sh", "-c", "bluetoothctl --timeout 6 scan on >/dev/null 2>&1; bluetoothctl devices 2>/dev/null | sed -r 's/\\x1b\\[[0-9;]*[a-zA-Z]//g'"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.isBtScanning = false
        let lines = this.text.trim().split("\n")
        let list = []
        let pairedMacs = root.btDevices.map(d => d.mac)

        for (let line of lines) {
          let match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/)
          if (match) {
            let mac = match[1]
            let name = match[2].trim()
            if (!pairedMacs.includes(mac) && name && !name.match(/^[0-9A-Fa-f-]{17}$/)) {
              if (!list.find(d => d.mac === mac)) {
                list.push({ mac: mac, name: name })
              }
            }
          }
        }
        root.btAvailableDevices = list
      }
    }
  }

  // Timer di sincronizzazione Bluetooth con FORZATURA attiva
  Timer {
    id: btSyncDelayTimer
    interval: 500
    onTriggered: root.scanBt(true) // <-- Passa true per bypassare il cooldown!
  }

  // Timer di sicurezza anti-blocco (se il bluetooth ci mette troppo)
  Timer {
    id: btActionTimeoutTimer
    interval: 8000
    onTriggered: {
      if (root.btActionMac.length > 0) {
        root.btActionMac = ""
        root.scanBt(true)
      }
    }
  }

  Process {
    id: btActionProc
    stdout: StdioCollector {
      onStreamFinished: btSyncDelayTimer.restart()
    }
  }

  Process {
    id: btPowerOnProc
    command: [
      "sh", "-c",
      "rfkill unblock bluetooth 2>/dev/null; " +
      "for i in $(seq 1 30); do " +
      "  bluetoothctl power on >/dev/null 2>&1; " +
      "  if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then " +
      "    echo 'enabled'; exit 0; " +
      "  fi; " +
      "  sleep 0.1; " +
      "done; " +
      "echo 'disabled'"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        let state = this.text.trim()
        root.btEnabled = (state === "enabled")
        if (root.btEnabled) {
          btScanProc.running = false
          btScanProc.running = true
        }
      }
    }
  }

  Process {
    id: btPowerOffProc
    command: ["bluetoothctl", "power", "off"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.btEnabled = false
        root.btDevices = []
        root.btAvailableDevices = []
      }
    }
  }

  property real lastBtScan: 0

  function scanBt(force = false) {
    if (!force && root.btDevices.length > 0 && (Date.now() - root.lastBtScan < 15000)) {
      return
    }
    root.lastBtScan = Date.now()
    btPowerProc.running = false
    btScanProc.running = false
    btPowerProc.running = true
    btScanProc.running = true
  }

  function startBtDiscovery() {
    root.isBtScanning = true
    btDiscoveryProc.running = false
    btDiscoveryProc.running = true
  }

  function toggleDeviceConnection(device) {
    if (btActionProc.running) return
    root.btActionMac = device.mac
    btActionTimeoutTimer.restart()
    let action = device.connected ? "disconnect" : "connect"
    btActionProc.command = ["bluetoothctl", action, device.mac]
    btActionProc.running = true
  }

  function pairNewDevice(device) {
    if (btActionProc.running) return
    root.btActionMac = device.mac
    btActionTimeoutTimer.restart()
    btActionProc.command = ["sh", "-c", "bluetoothctl pair " + device.mac + " && bluetoothctl trust " + device.mac + " && bluetoothctl connect " + device.mac]
    btActionProc.running = true
  }

  function forgetBtDevice(mac) {
    Quickshell.execDetached(["bluetoothctl", "remove", mac])
    btSyncDelayTimer.restart()
  }

  // =============================================================
  // 3. INTERFACCIA GRAFICA
  // =============================================================
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
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.topMargin: 10
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
              onClicked: { ControlCenterState.currentTab = "wifi"; root.scanWifi(false) }
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
              onClicked: { ControlCenterState.currentTab = "bluetooth"; root.scanBt(false) }
            }
          }
        }

        // 2. Sotto-header unificato
        RowLayout {
          visible: !root.isPasswordPromptOpen
          Layout.fillWidth: true
          implicitHeight: 24
          spacing: 6

          Text {
            text: ControlCenterState.currentTab === "wifi" ? "Wi-Fi" : "Bluetooth"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
          }

          Item { Layout.fillWidth: true }

          // Bottone Refresh
          Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 5
            color: refreshMouse.containsMouse ? Theme.overlay : "transparent"

            Text {
              anchors.centerIn: parent
              text: "󰑐"
              color: {
                let isScanning = ControlCenterState.currentTab === "wifi" ? wifiScanProc.running : btScanProc.running
                if (isScanning) return (ControlCenterState.currentTab === "wifi" ? Theme.foam : Theme.iris)
                return Theme.subtle
              }
              font.pixelSize: 13

              RotationAnimation on rotation {
                running: ControlCenterState.currentTab === "wifi" ? wifiScanProc.running : btScanProc.running
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
              enabled: ControlCenterState.currentTab === "wifi" ? root.wifiEnabled : root.btEnabled
              onClicked: {
                if (ControlCenterState.currentTab === "wifi") root.scanWifi(true)
                else root.scanBt(true)
              }
            }
          }

          // Switch On/Off
          Rectangle {
            property bool isTabEnabled: ControlCenterState.currentTab === "wifi" ? root.wifiEnabled : root.btEnabled
            property color accentColor: ControlCenterState.currentTab === "wifi" ? Theme.foam : Theme.iris

            implicitWidth: 36
            implicitHeight: 18
            radius: 9
            color: isTabEnabled ? accentColor : Theme.overlay

            Rectangle {
              x: parent.isTabEnabled ? 20 : 2
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
              enabled: !(ControlCenterState.currentTab === "bluetooth" && (btPowerOnProc.running || btPowerOffProc.running))
              onClicked: {
                if (ControlCenterState.currentTab === "wifi") {
                  if (root.wifiEnabled) {
                    root.wifiEnabled = false
                    root.wifiNetworks = []
                    Quickshell.execDetached(["nmcli", "radio", "wifi", "off"])
                  } else {
                    root.wifiEnabled = true
                    Quickshell.execDetached(["nmcli", "radio", "wifi", "on"])
                    wifiPowerOnDelayTimer.restart()
                  }
                } else {
                  if (root.btEnabled) {
                    root.btEnabled = false
                    btPowerOffProc.running = false
                    btPowerOffProc.running = true
                  } else {
                    root.btEnabled = true
                    btPowerOnProc.running = false
                    btPowerOnProc.running = true
                  }
                }
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // =========================================================
        // 4. VISTA WI-FI
        // =========================================================
        Item {
          visible: ControlCenterState.currentTab === "wifi"
          Layout.fillWidth: true
          Layout.fillHeight: true

          // Scheda Password
          ColumnLayout {
            visible: root.isPasswordPromptOpen
            anchors.fill: parent
            spacing: 8

            Text {
              text: "Connect to " + root.targetSsid
              color: Theme.text
              font.family: Theme.fontFamily
              font.pixelSize: 12
              font.bold: true
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 32
              radius: 6
              color: Theme.overlay
              border.color: passInput.activeFocus ? Theme.foam : Theme.overlay
              border.width: 1

              TextInput {
                id: passInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                echoMode: TextInput.Password
                focus: root.isPasswordPromptOpen
                onTextEdited: root.passwordInput = text
                onAccepted: root.submitWifiPassword()
              }

              Text {
                visible: !passInput.text
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "Insert password..."
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
              }
            }

            Text {
              visible: root.wifiErrorMsg.length > 0
              text: root.wifiErrorMsg
              color: Theme.love
              font.family: Theme.fontFamily
              font.pixelSize: 10
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 6
                color: Theme.overlay
                Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 11 }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.isPasswordPromptOpen = false
                }
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 6
                color: root.isConnectingWithPass ? Theme.overlay : Theme.foam
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text {
                    visible: root.isConnectingWithPass
                    text: "󰑐"; color: Theme.base; font.pixelSize: 12
                    RotationAnimation on rotation { running: root.isConnectingWithPass; loops: Animation.Infinite; from: 0; to: 360; duration: 800 }
                  }
                  Text {
                    text: root.isConnectingWithPass ? "Connecting..." : "Connetti"
                    color: root.isConnectingWithPass ? Theme.subtle : Theme.base
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  enabled: !root.isConnectingWithPass && root.passwordInput.length > 0
                  onClicked: root.submitWifiPassword()
                }
              }
            }

            Item { Layout.fillHeight: true }
          }

          // Lista Reti
          ListView {
            visible: !root.isPasswordPromptOpen && root.wifiEnabled
            anchors.fill: parent
            clip: true
            model: root.wifiNetworks

            delegate: Rectangle {
              id: wifiItem
              width: ListView.view.width
              implicitHeight: 34
              radius: 5
              color: modelData.inUse ? Theme.overlay : (rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

              property bool isBusy: root.wifiActionSsid === modelData.ssid
              property bool isSavedNet: root.savedConnections.includes(modelData.ssid)

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: wifiItem.isBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
                enabled: !wifiItem.isBusy && !modelData.inUse
                onClicked: root.handleWifiClick(modelData)
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 8

                Text {
                  text: wifiItem.isBusy ? "󰑐" : (modelData.signal > 70 ? "󰤨" : (modelData.signal > 40 ? "󰤥" : "󰤟"))
                  color: wifiItem.isBusy ? Theme.gold : (modelData.inUse ? Theme.foam : Theme.subtle)
                  font.pixelSize: 13
                  RotationAnimation on rotation { running: wifiItem.isBusy; loops: Animation.Infinite; from: 0; to: 360; duration: 800 }
                }

                Text {
                  text: modelData.ssid
                  color: modelData.inUse ? Theme.foam : Theme.text
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  font.bold: modelData.inUse
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  visible: !modelData.isOpen && !wifiItem.isSavedNet && !modelData.inUse
                  text: "󰌾"
                  color: Theme.subtle
                  font.pixelSize: 10
                }

                Text {
                  text: {
                    if (wifiItem.isBusy) return "Connecting..."
                    return modelData.inUse ? "Connected" : ""
                  }
                  color: wifiItem.isBusy ? Theme.gold : Theme.foam
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                }

                Rectangle {
                  id: forgetBtn
                  z: 2
                  visible: wifiItem.isSavedNet && !wifiItem.isBusy
                  implicitWidth: 22
                  implicitHeight: 22
                  radius: 4
                  color: forgetWifiMouse.containsMouse ? Theme.love : "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: "󰆴"
                    color: forgetWifiMouse.containsMouse ? Theme.base : Theme.subtle
                    font.pixelSize: 12
                  }

                  MouseArea {
                    id: forgetWifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.forgetWifi(modelData.ssid)
                  }
                }
              }
            }
          }

          Text {
            visible: !root.wifiEnabled
            anchors.centerIn: parent
            text: "Wi-Fi disactivated"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 11
          }
        }

        // =========================================================
        // 5. VISTA BLUETOOTH
        // =========================================================
        ColumnLayout {
          visible: ControlCenterState.currentTab === "bluetooth"
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 6

          ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.btDevices

            delegate: Rectangle {
              id: devItem
              width: ListView.view.width
              implicitHeight: 36
              radius: 5
              color: modelData.connected ? Theme.overlay : (devMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
              property bool isBusy: root.btActionMac === modelData.mac

              MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: devItem.isBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
                enabled: !devItem.isBusy
                onClicked: root.toggleDeviceConnection(modelData)
              }

              RowLayout {
                id: btRowLayout
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 8

                Text {
                  text: devItem.isBusy ? "󰑐" : (modelData.connected ? "󰂱" : "󰂲")
                  color: devItem.isBusy ? Theme.gold : (modelData.connected ? Theme.iris : Theme.subtle)
                  font.pixelSize: 14
                  RotationAnimation on rotation { running: devItem.isBusy; loops: Animation.Infinite; from: 0; to: 360; duration: 800 }
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
                    if (devItem.isBusy) return modelData.connected ? "Disconnecting..." : "Connecting..."
                    return modelData.connected ? "Connected" : ""
                  }
                  color: devItem.isBusy ? Theme.gold : Theme.iris
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                }

                Rectangle {
                  id: forgetBtBtn
                  z: 2
                  visible: !devItem.isBusy
                  implicitWidth: 22
                  implicitHeight: 22
                  radius: 4
                  color: forgetBtMouse.containsMouse ? Theme.love : "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: "󰆴"
                    color: forgetBtMouse.containsMouse ? Theme.base : Theme.subtle
                    font.pixelSize: 12
                  }

                  MouseArea {
                    id: forgetBtMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.forgetBtDevice(modelData.mac)
                  }
                }
              }
            }
          }

          Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

          RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text { text: "Nearby"; color: Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
            Item { Layout.fillWidth: true }

            Rectangle {
              implicitWidth: 75; implicitHeight: 20; radius: 4
              color: root.isBtScanning ? Theme.overlay : Theme.base
              RowLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                  visible: root.isBtScanning
                  text: "󰑐"; color: Theme.iris; font.pixelSize: 10
                  RotationAnimation on rotation { running: root.isBtScanning; loops: Animation.Infinite; from: 0; to: 360; duration: 800 }
                }
                Text {
                  text: root.isBtScanning ? "Searching" : "Search"
                  color: Theme.iris
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.isBtScanning && root.btEnabled
                onClicked: root.startBtDiscovery()
              }
            }
          }

          ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 70)
            clip: true
            model: root.btAvailableDevices

            delegate: Rectangle {
              id: availItem
              width: ListView.view.width
              implicitHeight: 28
              radius: 4
              color: availMouse.containsMouse ? Theme.overlay : "transparent"
              property bool isBusy: root.btActionMac === modelData.mac

              RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                Text { text: availItem.isBusy ? "󰑐" : "󰂲"; color: Theme.subtle; font.pixelSize: 11 }
                Text { text: modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: availItem.isBusy ? "Pairing..." : "Pair"; color: Theme.iris; font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true }
              }

              MouseArea {
                id: availMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !availItem.isBusy
                onClicked: root.pairNewDevice(modelData)
              }
            }
          }
        }
      }
    }
  }
}
