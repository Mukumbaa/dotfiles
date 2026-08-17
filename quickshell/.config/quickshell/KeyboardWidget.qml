import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  implicitWidth: kbText.implicitWidth
  implicitHeight: kbText.implicitHeight

  Text {
    id: kbText
    property string layoutName: "IT"

    text: layoutName
    color: Theme.text
    font { pixelSize: 12; family: Theme.fontFamily; weight: Font.Bold }

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

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["sh", "-c", "hyprctl switchxkblayout all next"])
  }
}
