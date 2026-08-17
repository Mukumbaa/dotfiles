import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

RowLayout {
  id: volGroup
  spacing: 6

  // Tracker Pipewire
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  property var sink: Pipewire.defaultAudioSink
  property real rawVol: (sink && sink.audio) ? sink.audio.volume : 0.0
  property int volumeLevel: Math.round(rawVol * 100)
  property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false
  property bool isHovered: false

  property string volIcon: {
    if (isMuted || volumeLevel === 0) return "󰝟"
    if (volumeLevel > 60) return ""
    if (volumeLevel > 20) return ""
    return ""
  }

  Timer {
    id: volHoverTimer
    interval: 150
    onTriggered: {
      if (!sliderMouse.pressed) {
        volGroup.isHovered = sliderMouse.containsMouse || textMouse.containsMouse
      }
    }
  }

  function checkHover() {
    if (sliderMouse.containsMouse || textMouse.containsMouse || sliderMouse.pressed) {
      volHoverTimer.stop()
      volGroup.isHovered = true
    } else {
      volHoverTimer.restart()
    }
  }

  // Icona + Testo (Click apre l'Audio Mixer Popup)
  MouseArea {
    id: textMouse
    implicitWidth: volTextRow.implicitWidth
    implicitHeight: volTextRow.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: volGroup.checkHover()
    onExited: volGroup.checkHover()

    onClicked: AudioState.toggle("output")

    onWheel: wheel => {
      if (!volGroup.sink || !volGroup.sink.audio) return
      let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      volGroup.sink.audio.muted = false
      volGroup.sink.audio.volume = Math.max(0.0, Math.min(1.0, volGroup.sink.audio.volume + delta))
    }

    RowLayout {
      id: volTextRow
      spacing: 4

      Text {
        text: (volGroup.isMuted ? "0" : volGroup.volumeLevel) + "%"
        color: volGroup.isMuted ? Theme.subtle : Theme.text
        font { pixelSize: 12; family: Theme.fontFamily }
      }

      Text {
        text: volGroup.volIcon
        color: volGroup.isMuted ? Theme.subtle : Theme.text
        font { pixelSize: 18; family: Theme.fontFamily }
      }
    }
  }
}
