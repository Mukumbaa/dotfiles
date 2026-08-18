import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  implicitWidth: wifiLayout.implicitWidth
  implicitHeight: wifiLayout.implicitHeight

  RowLayout {
    id: wifiLayout
    spacing: 4
    property string ssid: "Disconnected"

    // OTTIMIZZATO (Zero polling, reattivo agli eventi istantaneamente)
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

    Process {
      id: wifiMonitorProc
      running: true
      command: ["nmcli", "monitor"]
      stdout: SplitParser {
        onRead: {
          if (!wifiProc.running) wifiProc.running = true
        }
      }
    }

    Component.onCompleted: wifiProc.running = true


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
