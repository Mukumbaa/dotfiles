import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
  spacing: 6
  id: brightGroup
  property int brightnessLevel: 100
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

  Process {
    id: brightProc
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
    stdout: SplitParser {
      onRead: data => {
        let val = parseInt(data.trim())
        if (!isNaN(val) && !brightSliderMouse.pressed) {
          brightGroup.brightnessLevel = val
        }
      }
    }
  }

  Process {
    id: brightMonitorProc
    running: true
    command: ["sh", "-c", "stdbuf -oL -eL inotifywait -m -e modify /sys/class/backlight/*/*brightness 2>/dev/null"]
    stdout: SplitParser {
      onRead: data => {
        if (!brightProc.running && !brightSliderMouse.pressed) {
          brightProc.running = true
        }
      }
    }
  }

  Component.onCompleted: brightProc.running = true

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
      width: parent.width * (brightGroup.brightnessLevel / 100)
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

      function updateBrightness(mouse) {
        let percent = Math.max(1, Math.min(100, Math.round((mouse.x / width) * 100)))
        brightGroup.brightnessLevel = percent
        Quickshell.execDetached(["brightnessctl", "set", percent + "%"])
      }

      onPressed: mouse => {
        brightGroup.checkHover()
        updateBrightness(mouse)
      }
      onPositionChanged: mouse => { if (pressed) updateBrightness(mouse) }
      onWheel: wheel => {
        let cmd = wheel.angleDelta.y > 0 ? "brightnessctl set +5%" : "brightnessctl set 5%-"
        Quickshell.execDetached(["sh", "-c", cmd])
      }
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

    onWheel: wheel => {
      let cmd = wheel.angleDelta.y > 0 ? "brightnessctl set +5%" : "brightnessctl set 5%-"
      Quickshell.execDetached(["sh", "-c", cmd])
    }

    RowLayout {
      id: brightTextRow
      spacing: 4

      Text {
        text: brightGroup.brightnessLevel + "%"
        color: Theme.text
        font { pixelSize: 12; family: Theme.fontFamily }
      }

      Text {
        text: brightGroup.brightnessLevel >= 50 ? "" : ""
        color: Theme.text
        font { pixelSize: 18; family: Theme.fontFamily }
      }
    }
  }
}
