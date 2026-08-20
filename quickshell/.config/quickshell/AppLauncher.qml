import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: root

  property bool isOpen: LauncherState.visible
  property real animProgress: isOpen ? 1.0 : 0.0
  visible: isOpen || animProgress > 0.001

  Behavior on animProgress {
    NumberAnimation {
      duration: Theme.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  // Copre tutto lo schermo per catturare click esterni e sfondo oscurato
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // Ricevitore IPC per aprirlo/chiuderlo da terminale o Hyprland
  IpcHandler {
    target: "launcher"
    function toggle(): void { LauncherState.toggle() }
    function open(): void { LauncherState.open() }
    function close(): void { LauncherState.close() }
  }

  // Scorciatoia globale nativa Quickshell
  GlobalShortcut {
    name: "launcher"
    onPressed: LauncherState.toggle()
  }

  // -------------------------------------------------------------
  // LOGICA FILTRO APPLICAZIONI
  // -------------------------------------------------------------
  property string searchFilter: ""

  property var filteredApps: {
    let q = searchFilter.trim().toLowerCase()
    let apps = []

    if (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values) {
      for (let app of DesktopEntries.applications.values) {
        if (!app || app.noDisplay || !app.name) continue

        if (!q) {
          apps.push(app)
        } else {
          let name = (app.name || "").toLowerCase()
          let gen = (app.genericName || "").toLowerCase()
          let comm = (app.comment || "").toLowerCase()
          let id = (app.id || "").toLowerCase()

          if (name.includes(q) || gen.includes(q) || comm.includes(q) || id.includes(q)) {
            apps.push(app)
          }
        }
      }
    }

    // Ordina: prima i risultati che iniziano con la query, poi alfabetico
    apps.sort((a, b) => {
      let aStarts = q ? (a.name.toLowerCase().startsWith(q) ? 1 : 0) : 0
      let bStarts = q ? (b.name.toLowerCase().startsWith(q) ? 1 : 0) : 0
      if (aStarts !== bStarts) return bStarts - aStarts
      return a.name.localeCompare(b.name)
    })

    return apps
  }

  onFilteredAppsChanged: {
    appListView.currentIndex = 0
    appListView.positionViewAtBeginning()
  }

  function launchApp(app) {
    if (!app) return
    LauncherState.close()
    app.execute()
  }

  function launchSelected() {
    if (appListView.count > 0 && appListView.currentIndex >= 0) {
      let selected = root.filteredApps[appListView.currentIndex]
      root.launchApp(selected)
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      root.searchFilter = ""
      searchInput.text = ""
      appListView.currentIndex = 0
      searchInput.forceActiveFocus()
    }
  }

  // -------------------------------------------------------------
  // SFONDO E CONTENITORE CENTRALE
  // -------------------------------------------------------------
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0.05, 0.04, 0.08, 0.65 * root.animProgress)
    opacity: root.animProgress

    // Click fuori per chiudere
    MouseArea {
      anchors.fill: parent
      onClicked: LauncherState.close()
    }

    // Finestra Card Centrata
    Rectangle {
      id: card
      anchors.centerIn: parent
      implicitWidth: 480
      implicitHeight: 420

      scale: 0.94 + (0.06 * root.animProgress)
      opacity: root.animProgress

      color: Theme.base
      radius: Theme.radius
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      // Intercetta i click interni per evitare la chiusura
      MouseArea {
        anchors.fill: parent
        onClicked: searchInput.forceActiveFocus()
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // 1. Barra di Ricerca
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 42
          radius: 8
          color: Theme.surface
          border.color: searchInput.activeFocus ? Theme.foam : Theme.overlay
          border.width: 1

          Behavior on border.color { ColorAnimation { duration: 120 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: "󰍉"
              color: searchInput.text.length > 0 ? Theme.foam : Theme.subtle
              font.pixelSize: 16
            }

            TextInput {
              id: searchInput
              Layout.fillWidth: true
              verticalAlignment: TextInput.AlignVCenter
              color: Theme.text
              font.family: Theme.fontFamily
              font.pixelSize: 13
              focus: root.isOpen

              onTextEdited: {
                root.searchFilter = text
                appListView.currentIndex = 0
              }

              // Gestione completa tastiera (ESC, Frecce, Invio)
              Keys.onPressed: event => {
                // 1. ESC -> Chiude il Launcher
                if (event.key === Qt.Key_Escape) {
                  LauncherState.close()
                  event.accepted = true
                } 
                // 2. GIÙ o TAB -> Scorri in avanti
                else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                  if (appListView.count > 0) {
                    // Scorre alla successiva o ricomincia dall'inizio (loop)
                    appListView.currentIndex = (appListView.currentIndex + 1) % appListView.count
                    appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain)
                  }
                  event.accepted = true
                } 
                // 3. SU o SHIFT+TAB (Backtab) -> Scorri all'indietro
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                  if (appListView.count > 0) {
                    // Scorre alla precedente o va all'ultima (loop)
                    appListView.currentIndex = (appListView.currentIndex - 1 + appListView.count) % appListView.count
                    appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain)
                  }
                  event.accepted = true
                } 
                // 4. INVIO -> Esegue l'app selezionata
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.launchSelected()
                  event.accepted = true
                }
              }
            }

            Text {
              visible: !searchInput.text.length
              text: "Search"
              color: Theme.subtle
              font.family: Theme.fontFamily
              font.pixelSize: 12
              anchors.left: parent.left
              anchors.leftMargin: 22
              anchors.verticalCenter: parent.verticalCenter
            }

            // Tasto rapido ESC visualizzato
            Rectangle {
              implicitWidth: 32
              implicitHeight: 20
              radius: 4
              color: Theme.overlay

              Text {
                anchors.centerIn: parent
                text: "ESC"
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.bold: true
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // 2. Lista Applicazioni
        ListView {
          id: appListView
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          model: root.filteredApps
          spacing: 3
          currentIndex: 0

          onCountChanged: {
            if (count > 0) {
              currentIndex = 0
              positionViewAtBeginning()
            }
          }

          delegate: Rectangle {
            id: appItem
            width: ListView.view.width
            implicitHeight: 40
            radius: 6

            property bool isSelected: appListView.currentIndex === index

            color: isSelected ? Theme.overlay : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
            border.color: isSelected ? Theme.iris : "transparent"
            border.width: isSelected ? 1 : 0

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 12

              // Icona App (con fallback elegante)
              Image {
                id: appIcon
                source: Quickshell.iconPath(modelData.icon || "", true)
                sourceSize: Qt.size(48, 48)
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: source.toString().length > 0
              }

              Text {
                visible: !appIcon.visible
                text: " 󰀻 "
                color: appItem.isSelected ? Theme.foam : Theme.subtle
                font.pixelSize: 21
              }

              // Nome e Descrizione
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: modelData.name || ""
                  color: appItem.isSelected ? Theme.foam : Theme.text
                  font.family: Theme.fontFamily
                  font.pixelSize: 12
                  font.bold: appItem.isSelected
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  visible: (modelData.genericName || modelData.comment || "").length > 0
                  text: modelData.genericName || modelData.comment || ""
                  color: Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              // Badge Invio su elemento selezionato
              Text {
                visible: appItem.isSelected
                text: "󰌑"
                color: Theme.foam
                font.pixelSize: 14
              }
            }

            MouseArea {
              id: itemMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: appListView.currentIndex = index
              onClicked: root.launchApp(modelData)
            }
          }

          // Placeholder se non trova app
          Text {
            anchors.centerIn: parent
            visible: appListView.count === 0
            text: "No app found"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 12
          }
        }
      }
    }
  }
}
