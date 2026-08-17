import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
  id: root

  property bool isOpen: AudioState.visible
  property real animProgress: isOpen ? 1.0 : 0.0
  visible: isOpen || animProgress > 0.001

  Behavior on animProgress {
    NumberAnimation {
      duration: 200
      easing.type: Easing.InOutQuad
    }
  }

  anchors {
    top: true
    right: true
  }
  margins {
    top: 4
    right: 16
  }

  implicitWidth: 320
  implicitHeight: 310
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  // -------------------------------------------------------------
  // TRACCIAMENTO NODI PIPEWIRE (Output, Input, Volumi)
  // -------------------------------------------------------------
  PwObjectTracker {
    objects: Pipewire.nodes.values
  }

  // Dispositivi attivi predefiniti
  property var defaultSink: Pipewire.defaultAudioSink
  property var defaultSource: Pipewire.defaultAudioSource

  // Filtra solo i veri nodi fisici di output e input (esclude i singoli stream delle app)
  property var outputNodes: {
    let list = []
    for (let node of Pipewire.nodes.values) {
      if (node && node.isSink && !node.isStream) {
        list.push(node)
      }
    }
    return list
  }

  property var inputNodes: {
    let list = []
    for (let node of Pipewire.nodes.values) {
      if (node && node.isSource && !node.isStream) {
        list.push(node)
      }
    }
    return list
  }

  function setDefaultDevice(node) {
    if (!node) return
    Quickshell.execDetached(["wpctl", "set-default", node.id.toString()])
  }

  // -------------------------------------------------------------
  // AUTO-CHIUSURA AL MOUSE LEAVE
  // -------------------------------------------------------------
  HoverHandler {
    id: panelHover
    onHoveredChanged: {
      if (hovered) {
        autoCloseTimer.stop()
        inactivityTimer.stop()
      } else {
        autoCloseTimer.restart()
      }
    }
  }

  Timer {
    id: autoCloseTimer
    interval: 600
    onTriggered: {
      if (!panelHover.hovered) {
        AudioState.close()
      }
    }
  }

  Timer {
    id: inactivityTimer
    interval: 3500
    onTriggered: {
      if (!panelHover.hovered) {
        AudioState.close()
      }
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      inactivityTimer.restart()
    } else {
      autoCloseTimer.stop()
      inactivityTimer.stop()
    }
  }

  // -------------------------------------------------------------
  // CONTENITORE PRINCIPALE
  // -------------------------------------------------------------
  Item {
    anchors.fill: parent
    clip: true

    Rectangle {
      id: card
      width: parent.width
      height: parent.height

      y: (root.animProgress - 1.0) * height
      opacity: root.animProgress

      color: Theme.base
      radius: 12
      border.color: Theme.overlay
      border.width: 4

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // 1. TAB SWITCHER (Outputs / Inputs)
        RowLayout {
          Layout.fillWidth: true
          implicitHeight: 28
          spacing: 6

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: AudioState.currentTab === "output" ? Theme.overlay : "transparent"
            RowLayout {
              anchors.centerIn: parent
              spacing: 6
              Text { text: "󰕾"; color: AudioState.currentTab === "output" ? Theme.foam : Theme.subtle; font.pixelSize: 13 }
              Text { text: "Outputs"; color: AudioState.currentTab === "output" ? Theme.text : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: AudioState.currentTab = "output"
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: AudioState.currentTab === "input" ? Theme.overlay : "transparent"
            RowLayout {
              anchors.centerIn: parent
              spacing: 6
              Text { text: "󰍬"; color: AudioState.currentTab === "input" ? Theme.iris : Theme.subtle; font.pixelSize: 13 }
              Text { text: "Inputs"; color: AudioState.currentTab === "input" ? Theme.text : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: AudioState.currentTab = "input"
            }
          }
        }

        // =========================================================
        // 2. SLIDER VOLUME PRINCIPALE DEL DISPOSITIVO CORRENTE
        // =========================================================
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 46
          radius: 8
          color: Theme.overlay

          property var activeNode: AudioState.currentTab === "output" ? root.defaultSink : root.defaultSource
          property real currentVol: (activeNode && activeNode.audio) ? activeNode.audio.volume : 0.0
          property bool isMuted: (activeNode && activeNode.audio) ? activeNode.audio.muted : false
          property color accentCol: AudioState.currentTab === "output" ? Theme.foam : Theme.iris

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Bottone Mute
            Text {
              text: {
                if (parent.parent.isMuted || parent.parent.currentVol === 0) {
                  return AudioState.currentTab === "output" ? "󰝟" : "󰍭"
                }
                return AudioState.currentTab === "output" ? "󰕾" : "󰍬"
              }
              color: parent.parent.isMuted ? Theme.subtle : parent.parent.accentCol
              font.pixelSize: 16

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  let n = parent.parent.parent.activeNode
                  if (n && n.audio) n.audio.muted = !n.audio.muted
                }
              }
            }

            // Slider interattivo
            Rectangle {
              id: mainVolTrack
              Layout.fillWidth: true
              implicitHeight: 8
              radius: 4
              color: Theme.base

              Rectangle {
                width: parent.width * Math.min(1.0, parent.parent.parent.currentVol)
                height: parent.height
                radius: 4
                color: parent.parent.parent.isMuted ? Theme.subtle : parent.parent.parent.accentCol
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                function setVolume(mouse) {
                  let n = parent.parent.parent.activeNode
                  if (!n || !n.audio) return
                  let pct = Math.max(0.0, Math.min(1.0, mouse.x / width))
                  n.audio.muted = false
                  n.audio.volume = pct
                }

                onPressed: mouse => setVolume(mouse)
                onPositionChanged: mouse => { if (pressed) setVolume(mouse) }
                onWheel: wheel => {
                  let n = parent.parent.parent.activeNode
                  if (!n || !n.audio) return
                  let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                  n.audio.muted = false
                  n.audio.volume = Math.max(0.0, Math.min(1.0, n.audio.volume + delta))
                }
              }
            }

            // Percentuale
            Text {
              text: Math.round(parent.parent.currentVol * 100) + "%"
              color: Theme.text
              font.family: Theme.fontFamily
              font.pixelSize: 11
              font.bold: true
            }
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // =========================================================
        // 3. LISTA DISPOSITIVI DISPONIBILI (Click per cambiare)
        // =========================================================
        Text {
          text: AudioState.currentTab === "output" ? "SELECT OUTPUT DEVICE" : "SELECT INPUT DEVICE"
          color: Theme.subtle
          font.family: Theme.fontFamily
          font.pixelSize: 9
          font.bold: true
        }

        ListView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          model: AudioState.currentTab === "output" ? root.outputNodes : root.inputNodes

          delegate: Rectangle {
            id: devRow
            width: ListView.view.width
            implicitHeight: 34
            radius: 6

            property bool isDefault: {
              if (AudioState.currentTab === "output") return root.defaultSink && root.defaultSink.id === modelData.id
              return root.defaultSource && root.defaultSource.id === modelData.id
            }

            color: isDefault ? Theme.overlay : (devRowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 8

              Text {
                text: AudioState.currentTab === "output" ? "󰓃" : "󰍬"
                color: devRow.isDefault ? (AudioState.currentTab === "output" ? Theme.foam : Theme.iris) : Theme.subtle
                font.pixelSize: 13
              }

              Text {
                text: modelData.description || modelData.nickname || modelData.name || ("Device " + modelData.id)
                color: devRow.isDefault ? Theme.text : Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: devRow.isDefault
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              // Indicatore attivo (Spunta)
              Text {
                visible: devRow.isDefault
                text: "󰄬"
                color: AudioState.currentTab === "output" ? Theme.foam : Theme.iris
                font.pixelSize: 12
                font.bold: true
              }
            }

            MouseArea {
              id: devRowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.setDefaultDevice(modelData)
            }
          }
        }
      }
    }
  }
}
