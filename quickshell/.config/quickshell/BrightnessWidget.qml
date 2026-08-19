import QtQuick
import QtQuick.Layouts
import Quickshell

RowLayout {
  spacing: 6
  id: brightGroup
  property bool isHovered: false

  Timer {
    id: brightHoverTimer
    interval: 150
    onTriggered: {
      if (!brightSliderMouse.pressed) {
        brightGroup.isHovered = brightSliderMouse.containsMouse || brightTextMouse.containsMouse
      }
    }
  }

  function checkHover() {
    if (brightSliderMouse.containsMouse || brightTextMouse.containsMouse || brightSliderMouse.pressed) {
      brightHoverTimer.stop()
      brightGroup.isHovered = true
    } else {
      brightHoverTimer.restart()
    }
  }


  MouseArea {
    id: brightTextMouse
    implicitWidth: brightTextRow.implicitWidth
    implicitHeight: brightTextRow.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: brightGroup.checkHover()
    onExited: brightGroup.checkHover()
    onWheel: wheel => BrightnessState.adjustBrightness(wheel.angleDelta.y)

    RowLayout {
      id: brightTextRow
      spacing: 4

      Text {
        text: BrightnessState.brightness + "%"
        color: Theme.text
        font { pixelSize: 12; family: Theme.fontFamily }
      }

      Text {
        text: BrightnessState.brightness >= 50 ? "" : ""
        color: Theme.text
        font { pixelSize: 18; family: Theme.fontFamily }
      }
    }
  }
}
