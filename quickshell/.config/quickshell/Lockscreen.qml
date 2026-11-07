import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
  id: lockScope

  property bool isLocked: false
  property bool isAuthenticating: false
  property string errorMessage: ""

  IpcHandler {
    target: "lock"
    function lock(): void {
      lockScope.isLocked = true
    }
  }

  // Resetta solo i flag logici (nessun accesso a elementi grafici non ancora creati)
  onIsLockedChanged: {
    if (isLocked) {
      errorMessage = ""
      isAuthenticating = false
    }
  }

  WlSessionLock {
    locked: lockScope.isLocked

    WlSessionLockSurface {
      id: lockSurface
      color: Theme.base

      // Avvia PAM e prepara l'input solo quando la superficie è fisicamente pronta a schermo
      Component.onCompleted: {
        introAnimation.restart()
        lockScope.errorMessage = ""
        lockScope.isAuthenticating = false
        pwdInput.text = ""
        pam.pendingPassword = ""
        pam.start()
      }

      // Interrompe la sessione PAM quando la superficie viene distrutta
      Component.onDestruction: {
        pam.abort()
      }

      PamContext {
        id: pam
        config: "login"
        property string pendingPassword: ""

        onPamMessage: {
          if (responseRequired && pendingPassword.length > 0) {
            respond(pendingPassword)
            pendingPassword = ""
          }
        }

        onCompleted: result => {
          pendingPassword = ""
          lockScope.isAuthenticating = false
          statusIcon.rotation = 0

          if (result === PamResult.Success) {
            exitAnimation.restart()
          } else {
            pwdInput.text = ""
            lockScope.errorMessage = "Password errata"
            errorAnim.restart()
            pam.start()
          }
        }
      }

      // Animazioni
      ParallelAnimation {
        id: introAnimation
        NumberAnimation { target: contentCol; property: "opacity"; from: 0.0; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: contentCol; property: "scale"; from: 0.92; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
      }

      ParallelAnimation {
        id: exitAnimation
        NumberAnimation { target: contentCol; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.InQuad }
        NumberAnimation { target: contentCol; property: "scale"; to: 1.06; duration: 200; easing.type: Easing.InQuad }
        onFinished: {
          lockScope.isLocked = false
          contentCol.opacity = 1.0
          contentCol.scale = 1.0
          pwdInput.text = ""
          lockScope.errorMessage = ""
          statusIcon.rotation = 0
        }
      }

      // 1. Batteria in alto a destra
      RowLayout {
        id: batIndicator
        anchors {
          top: parent.top
          right: parent.right
          topMargin: Theme.marginTop
          rightMargin: Theme.marginRight
        }
        spacing: Theme.spacingSmall
        opacity: contentCol.opacity
        visible: BatteryState.displayDevice !== null

        Text {
          text: BatteryState.batteryLevel + "%"
          color: (BatteryState.batteryLevel <= 20 && !BatteryState.isCharging) ? Theme.love : Theme.text
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
        }

        Text {
          text: BatteryState.batIcon
          color: (BatteryState.batteryLevel <= 20 && !BatteryState.isCharging) ? Theme.love : (BatteryState.isCharging ? Theme.foam : Theme.text)
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSizeIcon
        }
      }

      // 2. Contenuto Centrale
      ColumnLayout {
        id: contentCol
        anchors.centerIn: parent
        spacing: Theme.spacingExtra * 2
        opacity: 0.0

        SystemClock {
          id: lockClock
          precision: SystemClock.Seconds
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(lockClock.date, "hh:mm")
          color: Theme.text
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSizeClock
          font.bold: true
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(lockClock.date, "dddd, dd MMMM yyyy")
          color: Theme.subtle
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSizeLarge
        }

        Item { implicitHeight: Theme.spacingLarge }

        // Box Password
        Rectangle {
          id: inputCard
          Layout.alignment: Qt.AlignHCenter
          implicitWidth: 260
          implicitHeight: 42
          radius: Theme.radiusPill
          color: Theme.surface
          border.color: lockScope.errorMessage.length > 0 ? Theme.love : (lockScope.isAuthenticating ? Theme.gold : Theme.overlay)
          border.width: Theme.borderWidth

          Behavior on border.color { ColorAnimation { duration: 150 } }

          Text {
            anchors.centerIn: parent
            text: "Password"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            visible: !pwdInput.text.length && !lockScope.isAuthenticating
          }

          TextInput {
            id: pwdInput
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            font.letterSpacing: 2
            echoMode: TextInput.Password
            passwordCharacter: ""
            focus: lockScope.isLocked
            enabled: !lockScope.isAuthenticating
            cursorDelegate: Component { Item {} }

            onTextEdited: {
              if (lockScope.errorMessage.length > 0) lockScope.errorMessage = ""
            }

            onAccepted: {
              if (text.length > 0 && !lockScope.isAuthenticating) {
                lockScope.isAuthenticating = true
                lockScope.errorMessage = ""

                if (pam.responseRequired) {
                  pam.respond(text)
                } else {
                  pam.pendingPassword = text
                  if (!pam.active) pam.start()
                }
              }
            }
          }

          Text {
            id: statusIcon
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingWindow
            anchors.verticalCenter: parent.verticalCenter
            text: lockScope.isAuthenticating ? "󰑐" : "󰌾"
            color: lockScope.isAuthenticating ? Theme.gold : (lockScope.errorMessage.length > 0 ? Theme.love : Theme.subtle)
            font.pixelSize: Theme.fontSizeLarge
            rotation: 0

            RotationAnimation {
              target: statusIcon
              property: "rotation"
              running: lockScope.isAuthenticating
              loops: Animation.Infinite
              from: 0
              to: 360
              duration: 800
            }
          }

          SequentialAnimation {
            id: errorAnim
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x - 12; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x + 12; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x - 8; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x + 8; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x; duration: 40; easing.type: Easing.InOutQuad }
          }
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: lockScope.errorMessage
          color: Theme.love
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSizePopup
          font.bold: true
          visible: lockScope.errorMessage.length > 0
          opacity: visible ? 1.0 : 0.0
          Behavior on opacity { NumberAnimation { duration: 150 } }
        }
      }
    }
  }
}
