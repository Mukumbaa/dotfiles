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
    function toggle(): void { PowerMenuState.toggle() }
    function open(): void { PowerMenuState.open() }
    function close(): void { PowerMenuState.close() }
  }

  Behavior on animProgress {
    NumberAnimation {
      duration: Theme.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  GlobalShortcut {
    name: "powermenu"
    onPressed: PowerMenuState.toggle()
  }

  function executeAction(cmd) {
    PowerMenuState.close()
    Quickshell.execDetached(cmd)
  }

  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.backdropDark
    opacity: root.animProgress

    MouseArea {
      anchors.fill: parent
      onClicked: PowerMenuState.close()
    }

    FocusScope {
      anchors.fill: parent
      focus: root.isOpen

      Keys.onEscapePressed: PowerMenuState.close()
      Keys.onPressed: event => {
        if (event.key === Qt.Key_L) executeAction(["qs", "ipc", "call", "lock", "lock"])
        else if (event.key === Qt.Key_S) executeAction(["systemctl", "suspend"])
        else if (event.key === Qt.Key_E) executeAction(["hyprctl", "dispatch", "exit"])
        else if (event.key === Qt.Key_R) executeAction(["systemctl", "reboot"])
        else if (event.key === Qt.Key_P) executeAction(["systemctl", "poweroff"])
      }

      RowLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingLarge * 2
        scale: 0.9 + (0.1 * root.animProgress)
        opacity: root.animProgress

        PowerButton {
          icon: "󰌾"
          label: "Lock"
          keyHint: "L"
          accentColor: Theme.iris
          onTriggered: root.executeAction(["qs", "ipc", "call", "lock", "lock"])
        }

        PowerButton {
          icon: ""
          label: "Suspend"
          keyHint: "S"
          accentColor: Theme.foam
          onTriggered: root.executeAction(["systemctl", "suspend"])
        }

        PowerButton {
          icon: "󰍃"
          label: "Logout"
          keyHint: "E"
          accentColor: Theme.rose
          onTriggered: root.executeAction(["hyprctl", "dispatch", "exit"])
        }

        PowerButton {
          icon: "󰜉"
          label: "Reboot"
          keyHint: "R"
          accentColor: Theme.gold
          onTriggered: root.executeAction(["systemctl", "reboot"])
        }

        PowerButton {
          icon: "󰐥"
          label: "Shutdown"
          keyHint: "P"
          accentColor: Theme.love
          onTriggered: root.executeAction(["systemctl", "poweroff"])
        }
      }
    }
  }

  component PowerButton: Rectangle {
    id: btn
    property string icon: ""
    property string label: ""
    property string keyHint: ""
    property color accentColor: Theme.text
    signal triggered()

    implicitWidth: 105
    implicitHeight: 115
    radius: Theme.radiusLarge
    color: btnMouse.containsMouse ? Theme.overlay : Theme.surface
    border.color: btnMouse.containsMouse ? btn.accentColor : Theme.overlay
    border.width: Theme.borderWidth

    scale: btnMouse.containsMouse ? 1.05 : 1.0

    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: Theme.spacingMedium

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: btn.icon
        color: btnMouse.containsMouse ? btn.accentColor : Theme.text
        font.pixelSize: Theme.fontSizeHuge
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: btn.label
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "[" + btn.keyHint + "]"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizePopup
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
