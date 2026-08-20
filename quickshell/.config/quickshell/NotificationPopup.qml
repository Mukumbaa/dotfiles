import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications as Notifications

Scope {
  id: notifScope

  Notifications.NotificationServer {
    id: notifServer
    bodySupported: true
    actionsSupported: true
    imageSupported: true
    bodyMarkupSupported: true

    onNotification: notification => {
      notification.tracked = true
    }
  }

  PanelWindow {
    id: notifWindow

    anchors {
      top: true
      right: true
    }
    margins {
      top: Theme.marginTop
      right: Theme.marginRight
    }

    implicitWidth: 320
    implicitHeight: 700
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    mask: Region.fromItem(notifCol)
    visible: notifServer.trackedNotifications.values.length > 0

    Column {
      id: notifCol
      width: parent.width
      spacing: 0

      Repeater {
        model: notifServer.trackedNotifications

        Item {
          id: delegateRoot
          width: notifCol.width
          height: cardContent.implicitHeight + 20 + 8
          clip: true

          Rectangle {
            id: notifCard
            width: parent.width
            height: Math.max(0, parent.height - 8)
            radius: Theme.radius
            color: Theme.base
            border.color: Theme.overlay
            border.width: Theme.borderWidth

            property bool isClosing: false
            opacity: 0.0

            transform: Translate {
              id: cardTrans
              x: 30
            }

            Component.onCompleted: introAnim.start()

            // 1. ENTRATA FLUIDA (OutCubic snella)
            ParallelAnimation {
              id: introAnim
              NumberAnimation { target: notifCard; property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
              NumberAnimation { target: cardTrans; property: "x"; from: 30; to: 0; duration: 180; easing.type: Easing.OutCubic }
            }

            // 2. USCITA MORBIDA E REATTIVA (Transizione e risalita parzialmente sovrapposte)
            ParallelAnimation {
              id: exitSequence

              NumberAnimation { target: notifCard; property: "opacity"; to: 0.0; duration: 140; easing.type: Easing.OutQuad }
              NumberAnimation { target: cardTrans; property: "x"; to: 40; duration: 140; easing.type: Easing.OutQuad }
              
              // Fa scorrere verso l'alto le altre notifiche subito con un leggero ritardo (40ms) invece di attendere 140ms
              SequentialAnimation {
                PauseAnimation { duration: 40 }
                NumberAnimation {
                  target: delegateRoot
                  property: "height"
                  to: 0
                  duration: 140
                  easing.type: Easing.OutCubic
                }
              }

              onFinished: modelData.dismiss()
            }

            function closeNotification() {
              if (!isClosing) {
                isClosing = true
                expireTimer.stop()
                exitSequence.start()
              }
            }

            Timer {
              id: expireTimer
              interval: (modelData.expireTimeout && modelData.expireTimeout > 0) ? (modelData.expireTimeout * 1000) : 5000
              running: !cardHover.hovered && !notifCard.isClosing
              onTriggered: notifCard.closeNotification()
            }

            HoverHandler {
              id: cardHover
            }

            // -------------------------------------------------------
            // CONTENUTO DELLA NOTIFICA
            // -------------------------------------------------------
            ColumnLayout {
              id: cardContent
              anchors.fill: parent
              anchors.margins: 10
              spacing: 6

              // Header: Icona App + Nome + Tasto Copia + Tasto Chiudi
              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Icona App Ottimizzata (Asincrona e SourceSize vincolata)
                Image {
                  visible: modelData.appIcon !== ""
                  source: modelData.appIcon
                  sourceSize: Qt.size(24, 24)
                  asynchronous: true
                  Layout.preferredWidth: 14
                  Layout.preferredHeight: 14
                  fillMode: Image.PreserveAspectFit
                }

                Text {
                  visible: modelData.appIcon === ""
                  text: "󰂚"
                  color: Theme.foam
                  font.pixelSize: 12
                }

                Text {
                  text: modelData.appName || "Notifica"
                  color: Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                // Tasto Copia
                Rectangle {
                  id: copyBtn
                  implicitWidth: 18
                  implicitHeight: 18
                  radius: 4
                  color: copyMouse.containsMouse ? Theme.overlay : "transparent"

                  property bool isCopied: false

                  Timer {
                    id: copyTimer
                    interval: 1200
                    onTriggered: copyBtn.isCopied = false
                  }

                  Text {
                    anchors.centerIn: parent
                    text: copyBtn.isCopied ? "󰄬" : "󰅍"
                    color: copyBtn.isCopied ? Theme.foam : (copyMouse.containsMouse ? Theme.text : Theme.subtle)
                    font.pixelSize: 11
                  }

                  MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      let msg = modelData.body || ""
                      Quickshell.execDetached(["wl-copy", msg])
                      copyBtn.isCopied = true
                      copyTimer.restart()
                    }
                  }
                }

                // Tasto Chiudi
                Text {
                  text: "󰅖"
                  color: closeMouse.containsMouse ? Theme.love : Theme.subtle
                  font.pixelSize: 12

                  MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifCard.closeNotification()
                  }
                }
              }

              Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

              // Corpo Notifica
              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Image {
                  visible: modelData.image !== ""
                  source: modelData.image
                  sourceSize: Qt.size(84, 84)
                  Layout.preferredWidth: 42
                  Layout.preferredHeight: 42
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    text: modelData.summary || ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                  }

                  Text {
                    Layout.fillWidth: true
                    text: modelData.body || ""
                    color: Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                  }
                }
              }

              // Pulsanti di Azione
              RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: modelData.actions && modelData.actions.length > 0

                Repeater {
                  model: modelData.actions

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    radius: 5
                    color: actMouse.containsMouse ? Theme.overlay : Theme.base

                    Text {
                      anchors.centerIn: parent
                      text: modelData.text
                      color: Theme.foam
                      font.family: Theme.fontFamily
                      font.pixelSize: 10
                      font.bold: true
                    }

                    MouseArea {
                      id: actMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        modelData.invoke()
                        notifCard.closeNotification()
                      }
                    }
                  }
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              z: -1
              cursorShape: Qt.PointingHandCursor
              onClicked: notifCard.closeNotification()
            }
          }
        }
      }
    }
  }
}
