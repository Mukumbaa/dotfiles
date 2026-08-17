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

  // function runCmd(cmd) {
  //   let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', Qt.application)
  //   proc.command = ["sh", "-c", cmd + " &"]
  //   proc.running = true
  // }
  function runCmd(cmd) {
    Quickshell.execDetached(["sh", "-c", cmd])
  }

  // ------------------------------------------------------------------
  // 1. LAYOUT TASTIERA (Stato iniziale reale + Listener eventi)
  // ------------------------------------------------------------------
  Item {
    implicitWidth: kbText.implicitWidth
    implicitHeight: kbText.implicitHeight

    Text {
      id: kbText
      property string layoutName: "IT"

      text: layoutName
      color: Theme.text
      font { pixelSize: 12; family: Theme.fontFamily; weight: Font.Bold }

      // Legge il layout reale al caricamento o al salvataggio/refresh del file
      Process {
        id: initKbProc
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

      Component.onCompleted: initKbProc.running = true

      // Aggiorna istantaneamente quando cambi lingua con la scorciatoia
      Connections {
        target: Hyprland
        function onRawEvent(event) {
          if (event.name === "activelayout") {
            let parts = event.data.split(",")
            let layout = parts[1] || ""
            if (layout.includes("Italian")) kbText.layoutName = "IT"
            else if (layout.includes("English")) kbText.layoutName = "US"
            else kbText.layoutName = layout.trim().substring(0, 2).toUpperCase()
          }
        }
      }
    }

    // MouseArea {
    //   anchors.fill: parent
    //   cursorShape: Qt.PointingHandCursor
    //   onClicked: Hyprland.dispatch("switchxkblayout all next")
    // }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: { runCmd("hyprctl switchxkblayout all next"); 
      // kbProc.running = true
    }
  }
}

// ------------------------------------------------------------------
// 2. CPU
// ------------------------------------------------------------------
Item {
  implicitWidth: cpuText.implicitWidth
  implicitHeight: cpuText.implicitHeight

  Text {
    id: cpuText
    text: "󰍛"
    color: Theme.text
    font { pixelSize: 18; family: Theme.fontFamily }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: runCmd("alacritty -e btop")
  }
}

// ------------------------------------------------------------------
// 3. BLUETOOTH
// ------------------------------------------------------------------
Item {
  implicitWidth: btText.implicitWidth
  implicitHeight: btText.implicitHeight

  Text {
    id: btText
    property string btState: "disabled"

    text: btState === "connected" ? "󰂱" : (btState === "on" ? "" : "󰂲")
    color: btState === "disabled" ? Theme.subtle : Theme.text
    font { pixelSize: 18; family: Theme.fontFamily }

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

    Process {
      id: btMonitorProc
      running: true
      command: ["sh", "-c", "stdbuf -oL -eL dbus-monitor --system \"type='signal',sender='org.bluez'\""]
      stdout: SplitParser {
        onRead: data => {
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
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: ControlCenterState.toggle("bluetooth")
  }
}

// ------------------------------------------------------------------
// 4. WI-FI (Con rilevamento Disconnected affidabile)
// ------------------------------------------------------------------
Item {
  implicitWidth: wifiLayout.implicitWidth
  implicitHeight: wifiLayout.implicitHeight

  RowLayout {
    id: wifiLayout
    spacing: 4
    property string ssid: "Disconnected"

    Process {
      id: wifiProc
      command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2"]
      stdout: StdioCollector {
        onStreamFinished: {
          let trimmed = this.text.trim()
          wifiLayout.ssid = trimmed.length > 0 ? trimmed : "Disconnected"
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
      text: wifiLayout.ssid !== "Disconnected" && wifiLayout.ssid !== "" ? "󰤨" : "󰤮"
      color: wifiLayout.ssid !== "Disconnected" ? Theme.text : Theme.subtle
      font { pixelSize: 18; family: Theme.fontFamily }
    }

    Text {
      text: wifiLayout.ssid
      color: wifiLayout.ssid !== "Disconnected" ? Theme.text : Theme.subtle
      font { pixelSize: 12; family: Theme.fontFamily }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: ControlCenterState.toggle("wifi")
  }
}

// ------------------------------------------------------------------
// 5. LUMINOSITÀ
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

  // Blocco Testo + Icona (senza anchors)
  MouseArea {
    id: brightTextMouse
    implicitWidth: brightTextRow.implicitWidth
    implicitHeight: brightTextRow.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: brightGroup.checkHover()
    onExited: brightGroup.checkHover()

    onWheel: (wheel) => {
      let cmd = wheel.angleDelta.y > 0 ? "brightnessctl set +5%" : "brightnessctl set 5%-"
      runCmd(cmd)
    }

    RowLayout {
      id: brightTextRow
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
    }
  }
}

// ------------------------------------------------------------------
// 6. VOLUME (Pipewire con PwObjectTracker e Slider animato)
// ------------------------------------------------------------------
// Tracker obbligatorio per abilitare la lettura/scrittura di Pipewire
PwObjectTracker {
  objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
}

RowLayout {
  id: volGroup
  spacing: 6

  property var sink: Pipewire.defaultAudioSink
  property real rawVol: (sink && sink.audio) ? sink.audio.volume : 0.0
  property int volumeLevel: Math.round(rawVol * 100)
  property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false
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


  // ICONA + TESTO PERCENTUALE
  MouseArea {
    id: textMouse
    implicitWidth: volTextRow.implicitWidth
    implicitHeight: volTextRow.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: volGroup.checkHover()
    onExited: volGroup.checkHover()

    // Click: Toggle Mute istantaneo
    // onClicked: {
    //   if (volGroup.sink && volGroup.sink.audio) {
    //     volGroup.sink.audio.muted = !volGroup.sink.audio.muted
    //   }
    // }
onClicked: AudioState.toggle("output")
    onWheel: (wheel) => {
      if (!volGroup.sink || !volGroup.sink.audio) return
      let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      volGroup.sink.audio.muted = false
      volGroup.sink.audio.volume = Math.max(0.0, Math.min(1.0, volGroup.sink.audio.volume + delta))
    }

    RowLayout {
      id: volTextRow
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
    }
  }
}

// ------------------------------------------------------------------
// 7. BATTERIA
// ------------------------------------------------------------------
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
    property var iconsDefault: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    property string batIcon: {
      let idx = Math.min(Math.floor(batteryLevel / 10), 9)
      return isCharging ? iconsCharging : iconsDefault[idx]
    }

    Text {
      text: batRow.batteryLevel + "%"
      color: (batRow.batteryLevel <= 20 && !batRow.isCharging) ? "#f7768e" : Theme.text
      font { pixelSize: 12; family: Theme.fontFamily }
    }

    Text {
      text: batRow.batIcon
      color: (batRow.batteryLevel <= 20 && !batRow.isCharging) ? "#f7768e" : Theme.text
      font { pixelSize: 18; family: Theme.fontFamily }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    // Apre/chiude il popup dei profili batteria
    onClicked: BatteryState.toggle()
  }
}
}
