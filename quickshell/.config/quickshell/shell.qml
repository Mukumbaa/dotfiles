import QtQuick
import QtQuick.Layouts
import Quickshell

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

    // Sezioni Sinistra e Destra
    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16

      LeftSection {}

      Item {
        Layout.fillWidth: true
      }

      RightSection{}
    }

    // Sezione Centro (Centrata in modo assoluto)
    CenterSection {}
  }
  ControlCenter {}
}
