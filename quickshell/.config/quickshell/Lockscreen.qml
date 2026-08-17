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

  onIsLockedChanged: {
    if (isLocked) {
      errorMessage = ""
      isAuthenticating = false
      pwdInput.text = ""
      pam.pendingPassword = ""
      pam.start()
    } else {
      pam.abort()
    }
  }

  WlSessionLock {
    locked: lockScope.isLocked

    WlSessionLockSurface {
      id: lockSurface
      color: Theme.base

      // Fa partire l'animazione di entrata nel momento esatto in cui la superficie è pronta a schermo
      Component.onCompleted: introAnimation.restart()

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

          // Ripristina l'icona perfettamente dritta (angolo 0)
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

      // -------------------------------------------------------------
      // ANIMAZIONI
      // -------------------------------------------------------------
      // 1. Animazione di Entrata (Visibile e morbida)
      ParallelAnimation {
        id: introAnimation
        NumberAnimation { target: contentCol; property: "opacity"; from: 0.0; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: contentCol; property: "scale"; from: 0.92; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
      }

      // 2. Animazione di Uscita (Sblocco)
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

      // -------------------------------------------------------------
      // CONTENUTO CENTRALE
      // -------------------------------------------------------------
      ColumnLayout {
        id: contentCol
        anchors.centerIn: parent
        spacing: 16
        opacity: 0.0 // Parte invisibile per far risaltare l'animazione di entrata

        // Orologio
        SystemClock { id: lockClock; precision: SystemClock.Minutes }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(lockClock.date, "hh:mm")
          color: Theme.text
          font.family: Theme.fontFamily
          font.pixelSize: 72
          font.bold: true
        }

        // Data
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(lockClock.date, "dddd, dd MMMM yyyy")
          color: Theme.subtle
          font.family: Theme.fontFamily
          font.pixelSize: 15
        }

        Item { implicitHeight: 12 }

// Box Password (Autocentrato Dinamicamente)
        Rectangle {
          id: inputCard
          Layout.alignment: Qt.AlignHCenter
          implicitWidth: 260
          implicitHeight: 42
          radius: 21
          color: Theme.surface
          border.color: lockScope.errorMessage.length > 0 ? Theme.love : (lockScope.isAuthenticating ? Theme.gold : Theme.overlay)
          border.width: 4

          Behavior on border.color { ColorAnimation { duration: 150 } }

          // Placeholder centrato (visibile quando non c'è testo)
          Text {
            anchors.centerIn: parent
            text: "Password"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 12
            visible: !pwdInput.text.length && !lockScope.isAuthenticating
          }

          // Input Password centrato in tempo reale
TextInput {
            id: pwdInput
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.letterSpacing: 2
            echoMode: TextInput.Password
            passwordCharacter: ""
            focus: lockScope.isLocked
            enabled: !lockScope.isAuthenticating

            // Sostituisce il cursore con un elemento vuoto invisibile al 100%
            cursorDelegate: Component { Item {} }

            onTextEdited: {
              if (lockScope.errorMessage.length > 0) {
                lockScope.errorMessage = ""
              }
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

          // Icona Lucchetto / Spinner ancorata a destra
          Text {
            id: statusIcon
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: lockScope.isAuthenticating ? "󰑐" : "󰌾"
            color: lockScope.isAuthenticating ? Theme.gold : (lockScope.errorMessage.length > 0 ? Theme.love : Theme.subtle)
            font.pixelSize: 15
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

          // Effetto Shake su errore
          SequentialAnimation {
            id: errorAnim
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x - 12; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x + 12; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x - 8; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x + 8; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: inputCard; property: "x"; to: inputCard.x; duration: 40; easing.type: Easing.InOutQuad }
          }
        }

        // Testo di Errore
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: lockScope.errorMessage
          color: Theme.love
          font.family: Theme.fontFamily
          font.pixelSize: 11
          font.bold: true
          visible: lockScope.errorMessage.length > 0
          opacity: visible ? 1.0 : 0.0

          Behavior on opacity { NumberAnimation { duration: 150 } }
        }
      }
    }
  }
}
