import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

RowLayout {
  Layout.alignment: Qt.AlignRight
  spacing: 12

  Process { id: appRunner }

  function runCmd(cmd) {
    let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', Qt.application)
    proc.command = ["sh", "-c", cmd + " &"]
    proc.running = true
  }

  // ------------------------------------------------------------------
  // 1. LAYOUT TASTIERA
  // ------------------------------------------------------------------
  Text {
    id: kbText
    property string layoutName: "IT"

    text: layoutName
    color: Theme.text
    font { pixelSize: 12; family: Theme.fontFamily; weight: Font.Bold }

    Process {
      id: kbProc
      command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"]
      stdout: SplitParser {
        onRead: data => {
          let raw = data.trim()
          if (raw.includes("Italian")) kbText.layoutName = "IT"
          else if (raw.includes("English")) kbText.layoutName = "US"
          else if (raw.length > 0) kbText.layoutName = raw.substring(0, 2).toUpperCase()
        }
      }
    }

    Timer { interval: 250; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbProc.running = true }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: { runCmd("hyprctl switchxkblayout all next"); kbProc.running = true }
    }
  }

  // ------------------------------------------------------------------
  // 2. CPU
  // ------------------------------------------------------------------
  Text {
    text: "󰍛"
    color: Theme.text
    font { pixelSize: 18; family: Theme.fontFamily }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: runCmd("alacritty -e btop")
    }
  }

  // ------------------------------------------------------------------
  // 3. BLUETOOTH (Zero-Delay via DBus + Feedback Ottimistico)
  // ------------------------------------------------------------------
  Text {
    id: btText
    property string btState: "disabled"

    text: btState === "connected" ? "󰂱" : (btState === "on" ? "" : "󰂲")
    color: btState === "disabled" ? Theme.subtle : Theme.text
    font { pixelSize: 18; family: Theme.fontFamily }

    // Verifica rapida e non bloccante via DBus CLI
    Process {
      id: btCheckProc
      command: ["sh", "-c", "dbus-send --system --print-reply --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Get string:'org.bluez.Adapter1' string:'Powered' 2>/dev/null | grep -q 'boolean true' && (bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo 'connected' || echo 'on') || echo 'disabled'"]
      stdout: SplitParser {
        onRead: data => {
          let state = data.trim()
          if (state.length > 0) btText.btState = state
        }
      }
    }

    // Ascolta gli eventi DBus in tempo reale direttamente dal kernel/BlueZ
    Process {
      id: btMonitorProc
      running: true
      command: ["sh", "-c", "stdbuf -oL -eL dbus-monitor --system \"type='signal',sender='org.bluez'\""]
      stdout: SplitParser {
        onRead: data => {
          // Appena viene intercettata qualsiasi modifica di stato, aggiorna subito
          if (!btCheckProc.running) {
            btCheckProc.running = true
          }
        }
      }
    }

    Timer {
      interval: 4000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: if (!btCheckProc.running) btCheckProc.running = true
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        // Feedback visivo istantaneo al click (cambia stato subito prima di verificare)
        btText.btState = (btText.btState === "disabled") ? "on" : "disabled"
        runCmd("blueman-manager")
        if (!btCheckProc.running) btCheckProc.running = true
      }
    }
  }

  // ------------------------------------------------------------------
  // 4. WI-FI
  // ------------------------------------------------------------------
  RowLayout {
    spacing: 4
    id: wifiGroup
    property string ssid: "Not connected"

    Process {
      id: wifiProc
      command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes:' | cut -d: -f2"]
      stdout: SplitParser {
        onRead: data => {
          let trimmed = data.trim()
          wifiGroup.ssid = trimmed.length > 0 ? trimmed : "Not connected"
        }
      }
    }

    Timer {
      interval: 4000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: if (!wifiProc.running) wifiProc.running = true
    }

    Text {
      text: wifiGroup.ssid !== "Not connected" && wifiGroup.ssid !== "" ? "󰤨" : "󰤮"
      color: Theme.text
      font { pixelSize: 18; family: Theme.fontFamily }
    }

    Text {
      text: wifiGroup.ssid
      color: Theme.text
      font { pixelSize: 12; family: Theme.fontFamily }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: runCmd("alacritty -e nmtui")
    }
  }

  // ------------------------------------------------------------------
  // 5. LUMINOSITÀ (Zero Delay / Event-Driven via inotifywait)
  // ------------------------------------------------------------------
  RowLayout {
    spacing: 6
    id: brightGroup
    property int brightnessLevel: 100
    property bool isHovered: false

    Timer {
      id: brightHoverTimer
      interval: 150
      onTriggered: {
        if (!brightSliderMouse.pressed) {
          brightGroup.isHovered = brightSliderMouse.containsMouse || brightTextMouse.containsMouse
        }
      }
    }

    function checkHover() {
      if (brightSliderMouse.containsMouse || brightTextMouse.containsMouse || brightSliderMouse.pressed) {
        brightHoverTimer.stop()
        brightGroup.isHovered = true
      } else {
        brightHoverTimer.restart()
      }
    }

    // Processo per la lettura istantanea del valore attuale
    Process {
      id: brightProc
      command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
      stdout: SplitParser {
        onRead: data => {
          let val = parseInt(data.trim())
          if (!isNaN(val) && !brightSliderMouse.pressed) {
            brightGroup.brightnessLevel = val
          }
        }
      }
    }

    // Stream di eventi in tempo reale: ascolta i cambiamenti del file di sistema /sys/class/backlight
    Process {
      id: brightMonitorProc
      running: true
      command: ["sh", "-c", "stdbuf -oL -eL inotifywait -m -e modify /sys/class/backlight/*/*brightness 2>/dev/null"]
      stdout: SplitParser {
        onRead: data => {
          if (!brightProc.running && !brightSliderMouse.pressed) {
            brightProc.running = true
          }
        }
      }
    }

    Component.onCompleted: brightProc.running = true

    // Slider Orizzontale Custom per Luminosità
    Rectangle {
      id: brightSliderContainer
      implicitWidth: brightGroup.isHovered ? 80 : 0
      implicitHeight: 12
      color: Theme.subtle ?? "#313244"
      radius: 6
      visible: implicitWidth > 0
      clip: true

      Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
      }

      Rectangle {
        width: parent.width * (brightGroup.brightnessLevel / 100)
        height: parent.height
        color: Theme.text ?? "#cdd6f4"
        radius: 6
      }

      MouseArea {
        id: brightSliderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: brightGroup.checkHover()
        onExited: brightGroup.checkHover()
        onReleased: brightGroup.checkHover()

        function updateBrightness(mouse) {
          let percent = Math.max(1, Math.min(100, Math.round((mouse.x / width) * 100)))
          brightGroup.brightnessLevel = percent
          runCmd("brightnessctl set " + percent + "%")
        }

        onPressed: mouse => {
          brightGroup.checkHover()
          updateBrightness(mouse)
        }
        onPositionChanged: mouse => { if (pressed) updateBrightness(mouse) }
        onWheel: (wheel) => {
          let cmd = wheel.angleDelta.y > 0 ? "brightnessctl set +5%" : "brightnessctl set 5%-"
          runCmd(cmd)
        }
      }
    }

    // Blocco Testo + Icona
    RowLayout {
      spacing: 4

      Text {
        text: brightGroup.brightnessLevel + "%"
        color: Theme.text
        font { pixelSize: 12; family: Theme.fontFamily }
      }

      Text {
        text: brightGroup.brightnessLevel >= 50 ? "" : ""
        color: Theme.text
        font { pixelSize: 18; family: Theme.fontFamily }
      }

      MouseArea {
        id: brightTextMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: brightGroup.checkHover()
        onExited: brightGroup.checkHover()

        onWheel: (wheel) => {
          let cmd = wheel.angleDelta.y > 0 ? "brightnessctl set +5%" : "brightnessctl set 5%-"
          runCmd(cmd)
        }
      }
    }
  }

  // ------------------------------------------------------------------
  // 6. VOLUME (Zero Delay Event-Driven + Slider Fluido)
  // ------------------------------------------------------------------
  RowLayout {
    spacing: 6
    id: volGroup
    property int volumeLevel: 0
    property bool isMuted: false
    property bool isHovered: false

    property string volIcon: {
      if (isMuted || volumeLevel === 0) return "󰝟"
      if (volumeLevel > 60) return ""
      if (volumeLevel > 20) return ""
      return ""
    }

    Timer {
      id: volHoverTimer
      interval: 150
      onTriggered: {
        if (!sliderMouse.pressed) {
          volGroup.isHovered = sliderMouse.containsMouse || textMouse.containsMouse
        }
      }
    }

    function checkHover() {
      if (sliderMouse.containsMouse || textMouse.containsMouse || sliderMouse.pressed) {
        volHoverTimer.stop()
        volGroup.isHovered = true
      } else {
        volHoverTimer.restart()
      }
    }

    // Processo per leggere istantaneamente il valore di PipeWire
    Process {
      id: volProc
      command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
      stdout: SplitParser {
        onRead: data => {
          let str = data.trim()
          let newMuted = str.includes("[MUTED]")
          let match = str.match(/Volume:\s+([0-9.]+)/)

          // Aggiorna solo se l'utente non sta trascinando lo slider
          if (!sliderMouse.pressed) {
            volGroup.isMuted = newMuted
            if (match && match[1]) {
              volGroup.volumeLevel = Math.round(parseFloat(match[1]) * 100)
            }
          }
        }
      }
    }

    // Stream eventi a zero latenza da PipeWire/PulseAudio
    Process {
      id: volSubscribeProc
      running: true
      command: ["sh", "-c", "stdbuf -oL -eL pactl subscribe"]
      stdout: SplitParser {
        onRead: data => {
          if (data.includes("sink") || data.includes("server")) {
            if (!volProc.running && !sliderMouse.pressed) {
              volProc.running = true
            }
          }
        }
      }
    }

    Component.onCompleted: volProc.running = true

    // Slider Orizzontale Custom
    Rectangle {
      id: sliderContainer
      implicitWidth: volGroup.isHovered ? 80 : 0
      implicitHeight: 12
      color: Theme.subtle ?? "#313244"
      radius: 6
      visible: implicitWidth > 0
      clip: true

      Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
      }

      Rectangle {
        width: parent.width * (volGroup.volumeLevel / 100)
        height: parent.height
        color: volGroup.isMuted ? (Theme.subtle ?? "#6c7086") : (Theme.text ?? "#cdd6f4")
        radius: 6
      }

      MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: volGroup.checkHover()
        onExited: volGroup.checkHover()
        onReleased: volGroup.checkHover()

        function updateVol(mouse) {
          let percent = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
          volGroup.volumeLevel = percent
          volGroup.isMuted = false
          runCmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (percent / 100).toFixed(2))
        }

        onPressed: mouse => {
          volGroup.checkHover()
          updateVol(mouse)
        }
        onPositionChanged: mouse => { if (pressed) updateVol(mouse) }
        onWheel: (wheel) => {
          let cmd = wheel.angleDelta.y > 0 ? "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" : "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          runCmd(cmd)
        }
      }
    }

    // Blocco Testo + Icona
    RowLayout {
      spacing: 4

      Text {
        text: (volGroup.isMuted ? "0" : volGroup.volumeLevel) + "%"
        color: volGroup.isMuted ? Theme.subtle : Theme.text
        font { pixelSize: 12; family: Theme.fontFamily }
      }

      Text {
        text: volGroup.volIcon
        color: volGroup.isMuted ? Theme.subtle : Theme.text
        font { pixelSize: 18; family: Theme.fontFamily }
      }

      MouseArea {
        id: textMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: volGroup.checkHover()
        onExited: volGroup.checkHover()

        onClicked: runCmd("alacritty --class menus -e wiremix")
        onWheel: (wheel) => {
          let cmd = wheel.angleDelta.y > 0 ? "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" : "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          runCmd(cmd)
        }
      }
    }
  }


  // ------------------------------------------------------------------
  // 7. BATTERIA
  // ------------------------------------------------------------------
  RowLayout {
    spacing: 4
    property var displayDevice: UPower.displayDevice
    property int batteryLevel: displayDevice ? Math.round(displayDevice.percentage * 100) : 0
    property bool isCharging: displayDevice ? displayDevice.state === UPowerDeviceState.Charging : false

    // property var iconsCharging: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    property var iconsCharging: "󰂄"
    property var iconsDefault: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]


    property string batIcon: {
      let idx = Math.min(Math.floor(batteryLevel / 10), 9)
      return isCharging ? iconsCharging : iconsDefault[idx]
    }

    Text {
      text: parent.batteryLevel + "%"
      color: (parent.batteryLevel <= 20 && !parent.isCharging) ? "#f7768e" : Theme.text
      font { pixelSize: 12; family: Theme.fontFamily }
    }

    Text {
      text: parent.batIcon
      color: (parent.batteryLevel <= 20 && !parent.isCharging) ? "#f7768e" : Theme.text
      font { pixelSize: 18; family: Theme.fontFamily }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: runCmd("alacritty --class algo -e algo ~/.config/algo/menus/power-profile-custom.txt")
    }
  }
}
