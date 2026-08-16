import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io

RowLayout {
  Layout.alignment: Qt.AlignLeft
  spacing: 12

  Process {
    id: hyprDispatcher
  }

  function focusWorkspace(id) {
    let cmd = "hl.dsp.focus({ workspace = \"" + id + "\" })"
    hyprDispatcher.command = ["hyprctl", "dispatch", cmd]
    hyprDispatcher.running = true
  }

  // Calcola dinamicamente la lista dei workspace aperti oltre il 5 (es. [6, 7...])
  property var extraWorkspaces: {
    let list = []
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      for (let ws of Hyprland.workspaces.values) {
        if (ws.id > 5) {
          list.push(ws.id)
        }
      }
    }
    let focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    if (focusedId > 5 && !list.includes(focusedId)) {
      list.push(focusedId)
    }
    list.sort((a, b) => a - b)
    return list
  }

  // 1. Workspace Fissi (1 .. 5)
  Repeater {
    model: 5

    Item {
      id: wsSlot
      property int wsId: index + 1
      property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
      property bool isActive: Hyprland.focusedWorkspace?.id === wsId
      property bool occupied: ws ? (ws.toplevels ? ws.toplevels.values.length > 0 : ws.clients.values.length > 0) : false

      implicitWidth: 10
      implicitHeight: 10

      Text {
        anchors.centerIn: parent
        color: wsSlot.isActive ? Theme.text : (wsSlot.occupied ? Theme.text : Theme.subtle)
        font { pixelSize: 12; family: Theme.fontFamily }
        text: wsSlot.isActive ? "󱓻" : wsSlot.wsId.toString()
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: focusWorkspace(wsSlot.wsId)
      }
    }
  }

  // 2. Puntini Dinamici per Workspace Extra (> 5)
  Repeater {
    model: extraWorkspaces

    Item {
      id: extraWsSlot
      property int extraId: modelData
      property var ws: Hyprland.workspaces.values.find(w => w.id === extraId)
      property bool isActive: Hyprland.focusedWorkspace?.id === extraId
      property bool occupied: ws ? (ws.toplevels ? ws.toplevels.values.length > 0 : ws.clients.values.length > 0) : false

      implicitWidth: 10
      implicitHeight: 10

      // Puntino reattivo: si accende se è attivo o se ha finestre dentro
      Rectangle {
        anchors.centerIn: parent
        width: extraWsSlot.isActive ? 6 : (extraWsSlot.occupied ? 5 : 4)
        height: width
        radius: width / 2

        // Acceso (Theme.text) se c'è qualcosa dentro o se ci sei sopra, altrimenti spento (Theme.subtle)
        color: (extraWsSlot.isActive || extraWsSlot.occupied) ? Theme.text : Theme.subtle

        Behavior on width { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: focusWorkspace(extraWsSlot.extraId)
      }
    }
  }
}
