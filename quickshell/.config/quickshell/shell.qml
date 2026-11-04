import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
  id: rootScope

  property bool showBar: true

  IpcHandler {
    target: "bar"

    function toggle(): void {
      rootScope.showBar = !rootScope.showBar
    }
    function isVisible(): bool {
      return rootScope.showBar
    }
  }

  // Barra di Stato Multi-Monitor  
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
        implicitHeight: Theme.barHeight

        Rectangle {
          id: bar
          anchors.fill: parent
          color: Theme.base

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.marginRight
            anchors.rightMargin: Theme.marginRight

            LeftSection {}
            Item { Layout.fillWidth: true }
            RightSection {}
          }

          CenterSection {}
        }
      }
    }
  }

  // Popup e Servizi Globali
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
