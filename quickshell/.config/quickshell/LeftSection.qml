import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
  Layout.alignment: Qt.AlignLeft
  spacing: Theme.barSpacing

  function focusWorkspace(id) {
    Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + id + "\" })")
  }

  // Mappa reattiva per lookup O(1) invece di iterare l'array per ogni item
  readonly property var workspaceMap: {
    let map = {}
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      for (let w of Hyprland.workspaces.values) {
        if (w && w.id !== undefined) map[w.id] = w
      }
    }
    return map
  }

  function isWsOccupied(ws) {
    if (!ws) return false
    if (ws.toplevels && ws.toplevels.values) return ws.toplevels.values.length > 0
    if (ws.clients && ws.clients.values) return ws.clients.values.length > 0
    return false
  }

  // Lista dinamica dei workspace aperti oltre il 5
  property var extraWorkspaces: {
    let list = []
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      for (let ws of Hyprland.workspaces.values) {
        if (ws && ws.id > 5) list.push(ws.id)
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
      property var ws: workspaceMap[wsId]
      property bool isActive: Hyprland.focusedWorkspace?.id === wsId
      property bool occupied: isWsOccupied(ws)

      implicitWidth: 10
      implicitHeight: 10

      Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: wsSlot.isActive ? Theme.text : (wsSlot.occupied ? Theme.text : Theme.subtle)
        font.pixelSize: wsSlot.isActive ? Theme.fontSizeMicro : Theme.fontSize
        font.family: Theme.fontFamily
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
      property var ws: workspaceMap[extraId]
      property bool isActive: Hyprland.focusedWorkspace?.id === extraId
      property bool occupied: isWsOccupied(ws)

      implicitWidth: 10
      implicitHeight: 10

      Rectangle {
        anchors.centerIn: parent
        width: extraWsSlot.isActive ? 6 : (extraWsSlot.occupied ? 5 : 4)
        height: width
        radius: width / 2
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
