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

  // Slider a scomparsa
  Rectangle {
    id: brightSliderContainer
    implicitWidth: brightGroup.isHovered ? 80 : 0
    implicitHeight: 12
    color: Theme.subtle ?? "#313244"
    radius: 6
    visible: implicitWidth > 0
    clip: true

    Behavior on implicitWidth {
      NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
    }

    Rectangle {
      width: parent.width * (BrightnessState.brightness / 100)
      height: parent.height
      color: Theme.text ?? "#cdd6f4"
      radius: 6
    }

    MouseArea {
      id: brightSliderMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onEntered: brightGroup.checkHover()
      onExited: brightGroup.checkHover()
      onReleased: brightGroup.checkHover()

      onPressed: mouse => {
        brightGroup.checkHover()
        BrightnessState.setBrightness((mouse.x / width) * 100)
      }
      onPositionChanged: mouse => {
        if (pressed) BrightnessState.setBrightness((mouse.x / width) * 100)
      }
      onWheel: wheel => BrightnessState.adjustBrightness(wheel.angleDelta.y)
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
