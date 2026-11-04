import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

MouseArea {
  id: volWidget
  implicitWidth: volRow.implicitWidth
  implicitHeight: volRow.implicitHeight
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  property var sink: Pipewire.defaultAudioSink
  property real rawVol: (sink && sink.audio) ? sink.audio.volume : 0.0
  property int volumeLevel: Math.round(rawVol * 100)
  property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false

  property string volIcon: {
    if (isMuted || volumeLevel === 0) return ""
    if (volumeLevel > 60) return ""
    if (volumeLevel > 20) return ""
    return ""
  }

  onClicked: AudioState.toggle("output")

  onWheel: wheel => {
    if (!sink || !sink.audio) return
    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
    sink.audio.muted = false
    sink.audio.volume = Math.max(0.0, Math.min(1.0, sink.audio.volume + delta))
  }

  RowLayout {
    id: volRow
    spacing: Theme.spacingSmall

    Text {
      text: (volWidget.isMuted ? "0" : volWidget.volumeLevel) + "%"
      color: volWidget.isMuted ? Theme.subtle : Theme.text
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
    }

    Text {
      text: volWidget.volIcon
      color: volWidget.isMuted ? Theme.subtle : Theme.text
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
    }
  }
}
