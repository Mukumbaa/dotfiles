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
