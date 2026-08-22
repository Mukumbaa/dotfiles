import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
  id: rootScope

  // Stato visibilità della barra
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

  // 1. Barra di Stato Multi-Monitor  
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData

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
    }
  }

  // Popup e Widget globali
  ConnectionsPopup {}
  CalendarPopup {}
  BatteryPopup {}
  AudioPopup {}
  PowerMenu {}
  OsdPopup {}
  Lockscreen {}
  Wallpaper {}
  NotificationPopup {}
  AppLauncher {}
}
