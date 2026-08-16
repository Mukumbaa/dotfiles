import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
  id: rootScope

  // Stato visibilità della sola barra
  property bool showBar: true

  // Ricevitore comandi IPC per la barra
  IpcHandler {
    target: "bar"

    function toggle(): void {
      rootScope.showBar = !rootScope.showBar
    }
    function isVisible(): bool {
      return rootScope.showBar
    }
  }

  // 1. Barra di Stato
  PanelWindow {
    id: barWindow
    visible: rootScope.showBar

    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: 26

    Rectangle {
      id: bar
      anchors.fill: parent
      color: Theme.base

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        LeftSection {}
        Item { Layout.fillWidth: true }
        RightSection {}
      }

      CenterSection {}
    }

  }
  ControlCenter {}

  // 2. Calendario
  CalendarPopup {}
  BatteryPopup {}

  // 3. PowerMenu (Rimane sempre attivo in memoria)
  PowerMenu {}
}
