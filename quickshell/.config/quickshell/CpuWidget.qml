import QtQuick
import Quickshell

MouseArea {
  id: cpuWidget
  implicitWidth: cpuText.implicitWidth
  implicitHeight: cpuText.implicitHeight
  cursorShape: Qt.PointingHandCursor
  onClicked: Quickshell.execDetached(["alacritty", "-e", "btop"])

  Text {
    id: cpuText
    anchors.fill: parent
    text: "󰍛"
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
  }
}
