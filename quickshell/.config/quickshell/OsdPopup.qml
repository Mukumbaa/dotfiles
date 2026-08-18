import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
  id: root

  property bool isOsdVisible: false
  property real animProgress: isOsdVisible ? 1.0 : 0.0
  visible: isOsdVisible || animProgress > 0.001

  Behavior on animProgress {
    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
  }

  anchors {
    bottom: true
  }
  margins {
    bottom: 60
  }

  implicitWidth: 220
  implicitHeight: 48
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // -------------------------------------------------------------
  // MONITORAGGIO VOLUME E LUMINOSITÀ
  // -------------------------------------------------------------
  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  property var sink: Pipewire.defaultAudioSink
  property real currentVol: (sink && sink.audio) ? sink.audio.volume : 0.0
  property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false

  property string osdType: "volume"
  property int osdValue: 0
  property string osdIcon: ""

  function triggerOsd(type, val, icon) {
    osdType = type
    osdValue = Math.round(val)
    osdIcon = icon
    isOsdVisible = true
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: root.isOsdVisible = false
  }

  onCurrentVolChanged: {
    if (sink && sink.audio) {
      let icon = isMuted ? "󰝟" : (currentVol > 0.6 ? "" : (currentVol > 0.2 ? "" : ""))
      triggerOsd("volume", isMuted ? 0 : currentVol * 100, icon)
    }
  }

  onIsMutedChanged: {
    let icon = isMuted ? "󰝟" : ""
    triggerOsd("volume", isMuted ? 0 : currentVol * 100, icon)
  }

  // Riceve i cambi di luminosità dal singleton
  Connections {
    target: BrightnessState
    function onBrightnessChanged() {
      let val = BrightnessState.brightness
      let icon = val >= 50 ? "" : ""
      root.triggerOsd("brightness", val, icon)
    }
  }

  Item {
    anchors.fill: parent

    Rectangle {
      anchors.fill: parent
      color: Theme.base
      radius: Theme.radius * 2
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      scale: 0.9 + (0.1 * root.animProgress)
      opacity: root.animProgress

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Text {
          text: root.osdIcon
          color: root.osdType === "volume" ? Theme.foam : Theme.gold
          font.pixelSize: 18
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 6
          radius: 3
          color: Theme.overlay

          Rectangle {
            width: parent.width * (Math.min(root.osdValue, 100) / 100)
            height: parent.height
            radius: 3
            color: root.osdType === "volume" ? Theme.foam : Theme.gold
          }
        }

        Text {
          text: root.osdValue + "%"
          color: Theme.text
          font.family: Theme.fontFamily
          font.pixelSize: 12
          font.bold: true
        }
      }
    }
  }
}
