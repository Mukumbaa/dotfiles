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

  // -------------------------------------------------------------
  // TRACCIAMENTO AUDIO (SINK E SOURCE)
  // -------------------------------------------------------------
  PwObjectTracker {
    objects: [
      ...(Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []),
      ...(Pipewire.defaultAudioSource ? [Pipewire.defaultAudioSource] : [])
    ]
  }

  property var sink: Pipewire.defaultAudioSink
  property real currentVol: (sink && sink.audio) ? sink.audio.volume : 0.0
  property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false

  property var source: Pipewire.defaultAudioSource
  property bool isMicMuted: (source && source.audio) ? source.audio.muted : false

  property string osdType: "volume"
  property int osdValue: 0
  property string osdIcon: ""

  // -------------------------------------------------------------
  // COLORI PER TIPO: Verde (Volume), Arancione (Luminosità), Viola (Mic)
  // -------------------------------------------------------------
  readonly property color osdColor: {
    if (root.osdType === "volume") return Theme.foam      // Verde (Rosé Pine)
    if (root.osdType === "brightness") return Theme.gold  // Arancione
    if (root.osdType === "mic") return Theme.iris         // Viola
    return Theme.text
  }

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
    let icon = isMuted ? "" : ""
    triggerOsd("volume", isMuted ? 0 : currentVol * 100, icon)
  }

  onIsMicMutedChanged: {
    if (source && source.audio) {
      let icon = isMicMuted ? "󰍭" : "󰍬"
      triggerOsd("mic", isMicMuted ? 0 : 100, icon)
    }
  }

  Connections {
    target: BrightnessState
    function onBrightnessChanged() {
      let val = BrightnessState.brightness
      let icon = val >= 50 ? "" : ""
      root.triggerOsd("brightness", val, icon)
    }
  }

  // -------------------------------------------------------------
  // INTERFACCIA GRAFICA
  // -------------------------------------------------------------
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

        // Icona colorata
        Text {
          text: root.osdIcon
          color: (root.osdType === "volume" && root.isMuted) || (root.osdType === "mic" && root.isMicMuted) 
            ? Theme.subtle 
            : root.osdColor
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
        }

        // Barra di progressione
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 6
          radius: Theme.radiusSmall
          color: Theme.overlay

          Rectangle {
            width: parent.width * (Math.min(root.osdValue, 100) / 100)
            height: parent.height
            radius: Theme.radiusSmall
            color: root.osdColor
          }
        }

        // Testo valore (% o stato Microfono)
        Text {
          text: {
            if (root.osdType === "mic") return root.isMicMuted ? "MUTED" : "ON"
            if (root.osdType === "volume" && root.isMuted) return "MUTED"
            return root.osdValue + "%"
          }
          color: (root.osdType === "mic" && root.isMicMuted) || (root.osdType === "volume" && root.isMuted) 
            ? Theme.love 
            : Theme.text
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          font.bold: true
        }
      }
    }
  }
}
