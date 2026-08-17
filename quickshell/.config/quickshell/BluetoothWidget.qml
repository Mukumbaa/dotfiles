import QtQuick
import Quickshell
import Quickshell.Io

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
          if (!btCheckProc.running) btCheckProc.running = true
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
