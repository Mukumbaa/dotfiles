import QtQuick
import Quickshell
import Quickshell.Io

MouseArea {
  id: btWidget
  implicitWidth: btText.implicitWidth
  implicitHeight: btText.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: ConnectionsState.toggle("bluetooth")

  Text {
    id: btText
    property string btState: "disabled"

    text: btState === "connected" ? "󰂱" : (btState === "on" ? "" : "󰂲")
    color: btState === "disabled" ? Theme.subtle : Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily

    Process {
      id: btCheckProc
      command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' || { echo 'disabled'; exit 0; }; bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo 'connected' || echo 'on'"]
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
      command: ["stdbuf", "-oL", "-eL", "dbus-monitor", "--system", "type='signal',sender='org.bluez'"]
      stdout: SplitParser {
        onRead: btDebounce.restart()
      }
    }

    Timer {
      id: btDebounce
      interval: 250
      onTriggered: {
        if (!btCheckProc.running) btCheckProc.running = true
      }
    }

    Component.onCompleted: btCheckProc.running = true
  }
}
