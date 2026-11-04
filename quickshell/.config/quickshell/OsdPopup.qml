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
    NumberAnimation {
      duration: Theme.animationDuration
      easing.type: Easing.OutQuad
    }
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
    interval: Theme.inactivityTimer
    onTriggered: root.isOsdVisible = false
  }

  onCurrentVolChanged: {
    if (sink && sink.audio) {
      let icon = isMuted ? "" : (currentVol > 0.6 ? "" : (currentVol > 0.2 ? "" : ""))
      triggerOsd("volume", isMuted ? 0 : currentVol * 100, icon)
    }
  }

  onIsMutedChanged: {
    let icon = isMuted ? "󰝟" : ""
    triggerOsd("volume", isMuted ? 0 : currentVol * 100, icon)
  }

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
      radius: Theme.radiusPill
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      scale: 0.9 + (0.1 * root.animProgress)
      opacity: root.animProgress

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.marginRight
        anchors.rightMargin: Theme.marginRight
        spacing: Theme.spacingLarge

        Text {
          text: root.osdIcon
          color: root.osdType === "volume" ? Theme.foam : Theme.gold
          font.pixelSize: Theme.fontSizeIcon
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 6
          radius: Theme.radiusSmall
          color: Theme.overlay

          Rectangle {
            width: parent.width * (Math.min(root.osdValue, 100) / 100)
            height: parent.height
            radius: Theme.radiusSmall
            color: root.osdType === "volume" ? Theme.foam : Theme.gold
          }
        }

        Text {
          text: root.osdValue + "%"
          color: Theme.text
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.bold: true
        }
      }
    }
  }
}
