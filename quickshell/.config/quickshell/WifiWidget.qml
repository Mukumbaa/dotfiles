import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
  id: wifiWidget
  implicitWidth: wifiLayout.implicitWidth
  implicitHeight: wifiLayout.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: ConnectionsState.toggle("wifi")

  RowLayout {
    id: wifiLayout
    spacing: Theme.spacingSmall
    property string ssid: "Disconnected"

    // Query SSID attivo
    Process {
      id: wifiProc
      command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
      stdout: StdioCollector {
        onStreamFinished: {
          let trimmed = this.text.trim()
          let match = trimmed.match(/^yes:(.*)$/m)
          wifiLayout.ssid = (match && match[1]) ? match[1] : "Disconnected"
        }
      }
    }

    // Timer per evitare picchi di processi quando nmcli monitor genera eventi a raffica
    Timer {
      id: wifiDebounceTimer
      interval: 350
      onTriggered: {
        if (!wifiProc.running) wifiProc.running = true
      }
    }

    // Monitor eventi NetworkManager in ascolto continuo
    Process {
      id: wifiMonitorProc
      running: true
      command: ["nmcli", "monitor"]
      stdout: SplitParser {
        onRead: wifiDebounceTimer.restart()
      }
    }

    Component.onCompleted: wifiProc.running = true

    Text {
      text: wifiLayout.ssid !== "Disconnected" && wifiLayout.ssid !== "" ? "󰤨" : "󰤮"
      color: wifiLayout.ssid !== "Disconnected" ? Theme.text : Theme.subtle
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
    }

    Text {
      text: wifiLayout.ssid
      color: wifiLayout.ssid !== "Disconnected" ? Theme.text : Theme.subtle
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
    }
  }
}
