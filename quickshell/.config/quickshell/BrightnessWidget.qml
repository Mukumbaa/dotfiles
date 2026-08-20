import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
  id: brightGroup
  implicitWidth: brightTextRow.implicitWidth + (brightGroup.animProgress * 78)
  implicitHeight: brightTextRow.implicitHeight
  Layout.alignment: Qt.AlignVCenter

  property bool isExpanded: false
  property real animProgress: isExpanded ? 1.0 : 0.0

  Behavior on animProgress {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Timer {
    id: collapseTimer
    interval: 800
    onTriggered: {
      if (!sliderMouse.containsMouse && !textMouse.containsMouse && !sliderMouse.pressed) {
        brightGroup.isExpanded = false
      }
    }
  }

  // 1. Icona + Percentuale (Perfettamente centrate su un'unica linea)
  RowLayout {
    id: brightTextRow
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Text {
      text: BrightnessState.brightness + "%"
      color: Theme.text
      font { pixelSize: 12; family: Theme.fontFamily }
      Layout.alignment: Qt.AlignVCenter
    }

    Text {
      text: BrightnessState.brightness >= 50 ? "" : ""
      color: Theme.text
      font { pixelSize: 18; family: Theme.fontFamily }
      Layout.alignment: Qt.AlignVCenter
    }
  }

  MouseArea {
    id: textMouse
    anchors.fill: brightTextRow
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      collapseTimer.stop()
      brightGroup.isExpanded = true
    }
    onExited: collapseTimer.restart()
    onClicked: brightGroup.isExpanded = !brightGroup.isExpanded
    onWheel: wheel => BrightnessState.adjustBrightness(wheel.angleDelta.y)
  }

  // 2. Slider (Allineato sulla stessa linea mediana del testo)
  Item {
    id: sliderContainer
    anchors.left: brightTextRow.right
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    height: parent.height
    width: 80 * brightGroup.animProgress
    opacity: brightGroup.animProgress
    visible: brightGroup.animProgress > 0.001
    clip: true

    // Barretta grafica centrata
    Rectangle {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 70
      height: 4
      radius: 2
      color: Theme.overlay

      Rectangle {
        width: parent.width * (BrightnessState.brightness / 100.0)
        height: parent.height
        radius: 2
        color: Theme.gold
      }
    }

    MouseArea {
      id: sliderMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        collapseTimer.stop()
        brightGroup.isExpanded = true
      }
      onExited: collapseTimer.restart()

      function setVal(mouse) {
        let pct = Math.max(1, Math.min(100, Math.round((mouse.x / 70) * 100)))
        BrightnessState.setBrightness(pct)
      }

      onPressed: mouse => setVal(mouse)
      onPositionChanged: mouse => { if (pressed) setVal(mouse) }
      onWheel: wheel => BrightnessState.adjustBrightness(wheel.angleDelta.y)
    }
  }
}
