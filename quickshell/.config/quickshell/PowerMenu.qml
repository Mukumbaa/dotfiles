import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: root

  property bool isOpen: PowerMenuState.visible
  property real animProgress: isOpen ? 1.0 : 0.0
  visible: isOpen || animProgress > 0.001
  IpcHandler {
    target: "powermenu"

    function toggle(): void {
      PowerMenuState.toggle()
    }

    function open(): void {
      PowerMenuState.visible = true
    }

    function close(): void {
      PowerMenuState.close()
    }
  }
  Behavior on animProgress {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutQuad
    }
  }

  // Copre l'intero schermo
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // Scorciatoia globale nativa per Hyprland
  GlobalShortcut {
    name: "powermenu"
    onPressed: PowerMenuState.toggle()
  }

  function executeAction(cmd) {
    PowerMenuState.close()
    Quickshell.execDetached(["sh", "-c", cmd])
  }

  // Sfondo scuro oscurato con fade-in
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0.05, 0.04, 0.08, 0.75 * root.animProgress)
    opacity: root.animProgress

    // Chiudi cliccando ovunque sullo sfondo
    MouseArea {
      anchors.fill: parent
      onClicked: PowerMenuState.close()
    }

    // Gestione tasti fisici da tastiera (ESC per chiudere, L, S, E, R, P per le azioni)
    FocusScope {
      anchors.fill: parent
      focus: root.isOpen

      Keys.onEscapePressed: PowerMenuState.close()
      Keys.onPressed: event => {
        if (event.key === Qt.Key_L) executeAction("hyprlock")
        else if (event.key === Qt.Key_S) executeAction("systemctl suspend")
        else if (event.key === Qt.Key_E) executeAction("hyprctl dispatch exit")
        else if (event.key === Qt.Key_R) executeAction("systemctl reboot")
        else if (event.key === Qt.Key_P) executeAction("systemctl poweroff")
      }

      // Contenitore centrale dei 5 pulsanti
      RowLayout {
        anchors.centerIn: parent
        spacing: 20
        scale: 0.9 + (0.1 * root.animProgress)
        opacity: root.animProgress

        // 1. LOCK
        PowerButton {
          icon: "󰌾"
          label: "Lock"
          keyHint: "L"
          accentColor: Theme.iris
          onTriggered: root.executeAction("hyprlock")
        }

        // 2. SUSPEND
        PowerButton {
          icon: "󰒲"
          label: "Suspend"
          keyHint: "S"
          accentColor: Theme.foam
          onTriggered: root.executeAction("systemctl suspend")
        }

        // 3. LOGOUT
        PowerButton {
          icon: "󰍃"
          label: "Logout"
          keyHint: "E"
          accentColor: Theme.rose
          onTriggered: root.executeAction("hyprctl dispatch exit")
        }

        // 4. REBOOT
        PowerButton {
          icon: "󰜉"
          label: "Reboot"
          keyHint: "R"
          accentColor: Theme.gold
          onTriggered: root.executeAction("systemctl reboot")
        }

        // 5. SHUTDOWN
        PowerButton {
          icon: "󰐥"
          label: "Shutdown"
          keyHint: "P"
          accentColor: Theme.love
          onTriggered: root.executeAction("systemctl poweroff")
        }
      }
    }
  }

  // Componente pulsante riutilizzabile
  component PowerButton: Rectangle {
    id: btn
    property string icon: ""
    property string label: ""
    property string keyHint: ""
    property color accentColor: Theme.text
    signal triggered()

    implicitWidth: 105
    implicitHeight: 115
    radius: 14
    color: btnMouse.containsMouse ? Theme.overlay : Theme.surface
    border.color: btnMouse.containsMouse ? btn.accentColor : Theme.overlay
    border.width: 1.5

    scale: btnMouse.containsMouse ? 1.05 : 1.0

    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 6

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: btn.icon
        color: btnMouse.containsMouse ? btn.accentColor : Theme.text
        font.pixelSize: 34
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: btn.label
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "[" + btn.keyHint + "]"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.triggered()
    }
  }
}
