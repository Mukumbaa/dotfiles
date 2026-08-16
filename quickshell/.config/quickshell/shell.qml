import QtQuick
import QtQuick.Layouts
import Quickshell

Scope {
  // 1. Barra Superiore
  PanelWindow {
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

    ControlCenter {}
    CalendarPopup {}
  }

  // 2. Power Menu a schermo intero
  PowerMenu {}
}
