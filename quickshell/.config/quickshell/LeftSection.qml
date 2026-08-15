import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io

RowLayout {
  Layout.alignment: Qt.AlignLeft
  spacing: 16

  Process {
    id: hyprDispatcher
  }

  function focusWorkspace(id) {
    let cmd = "hl.dsp.focus({ workspace = \"" + id + "\" })"
    hyprDispatcher.command = ["hyprctl", "dispatch", cmd]
    hyprDispatcher.running = true
  }

  Repeater {
    model: 5

    Text {
      property int wsId: index + 1
      property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
      property bool isActive: Hyprland.focusedWorkspace?.id === wsId
      property bool occupied: ws ? (ws.toplevels ? ws.toplevels.values.length > 0 : ws.clients.values.length > 0) : false

      color: isActive ? Theme.text : (occupied ? Theme.text : Theme.subtle)
      font { pixelSize: 12; family: Theme.fontFamily }

      text: isActive ? "󱓻" : wsId.toString()

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: focusWorkspace(wsId)
      }
    }
  }
}
