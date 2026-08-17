import QtQuick
import Quickshell

Item {
  implicitWidth: cpuText.implicitWidth
  implicitHeight: cpuText.implicitHeight

  Text {
    id: cpuText
    text: "󰍛"
    color: Theme.text
    font { pixelSize: 18; family: Theme.fontFamily }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["alacritty", "-e", "btop"])
  }
}
