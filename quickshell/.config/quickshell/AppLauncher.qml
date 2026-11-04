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

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  IpcHandler {
    target: "launcher"
    function toggle(): void { LauncherState.toggle() }
    function open(): void { LauncherState.open() }
    function close(): void { LauncherState.close() }
  }

  GlobalShortcut {
    name: "launcher"
    onPressed: LauncherState.toggle()
  }

  // -------------------------------------------------------------
  // CACHE ED OTTIMIZZAZIONE APPLICAZIONI
  // -------------------------------------------------------------
  property string searchFilter: ""

  // Cache pre-filtrata con stringhe lowercase già pronte
  readonly property var allValidApps: {
    let list = []
    if (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values) {
      for (let app of DesktopEntries.applications.values) {
        if (!app || app.noDisplay || !app.name) continue
        list.push({
          entry: app,
          name: app.name || "",
          nameLower: (app.name || "").toLowerCase(),
          generic: app.genericName || "",
          genericLower: (app.genericName || "").toLowerCase(),
          comment: app.comment || "",
          commentLower: (app.comment || "").toLowerCase(),
          idLower: (app.id || "").toLowerCase(),
          icon: app.icon || ""
        })
      }
    }
    return list
  }

  property var filteredApps: {
    let q = searchFilter.trim().toLowerCase()
    let apps = []

    if (!q) {
      apps = [...allValidApps]
    } else {
      for (let item of allValidApps) {
        if (item.nameLower.includes(q) || item.genericLower.includes(q) || item.commentLower.includes(q) || item.idLower.includes(q)) {
          apps.push(item)
        }
      }
    }

    apps.sort((a, b) => {
      let aStarts = q ? (a.nameLower.startsWith(q) ? 1 : 0) : 0
      let bStarts = q ? (b.nameLower.startsWith(q) ? 1 : 0) : 0
      if (aStarts !== bStarts) return bStarts - aStarts
      return a.name.localeCompare(b.name)
    })

    return apps
  }

  onFilteredAppsChanged: {
    appListView.currentIndex = 0
    appListView.positionViewAtBeginning()
  }

  function launchApp(item) {
    if (!item || !item.entry) return
    LauncherState.close()
    item.entry.execute()
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
  // CONTENITORE
  // -------------------------------------------------------------
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.backdrop
    opacity: root.animProgress

    MouseArea {
      anchors.fill: parent
      onClicked: LauncherState.close()
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      implicitWidth: Theme.launcherWidth
      implicitHeight: Theme.launcherHeight

      scale: 0.94 + (0.06 * root.animProgress)
      opacity: root.animProgress

      color: Theme.base
      radius: Theme.radius
      border.color: Theme.overlay
      border.width: Theme.borderWidth

      MouseArea {
        anchors.fill: parent
        onClicked: searchInput.forceActiveFocus()
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingWindow
        spacing: Theme.spacingLarge

        // Barra di Ricerca
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 42
          radius: Theme.radiusCard
          color: Theme.surface
          border.color: searchInput.activeFocus ? Theme.foam : Theme.overlay
          border.width: 1

          Behavior on border.color { ColorAnimation { duration: 120 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.spacingLarge

            Text {
              text: "󰍉"
              color: searchInput.text.length > 0 ? Theme.foam : Theme.subtle
              font.pixelSize: Theme.fontSizeLarge
            }

            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true

              TextInput {
                id: searchInput
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                focus: root.isOpen

                onTextEdited: {
                  root.searchFilter = text
                  appListView.currentIndex = 0
                }

                Keys.onPressed: event => {
                  if (event.key === Qt.Key_Escape) {
                    LauncherState.close()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                    if (appListView.count > 0) {
                      appListView.currentIndex = (appListView.currentIndex + 1) % appListView.count
                      appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain)
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    if (appListView.count > 0) {
                      appListView.currentIndex = (appListView.currentIndex - 1 + appListView.count) % appListView.count
                      appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain)
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
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
                font.pixelSize: Theme.fontSize
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Rectangle {
              implicitWidth: 32
              implicitHeight: 20
              radius: Theme.radiusSmall
              color: Theme.overlay

              Text {
                anchors.centerIn: parent
                text: "ESC"
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizePopup
                font.bold: true
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.overlay }

        // Lista Risultati
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
            radius: Theme.radiusMedium

            property bool isSelected: appListView.currentIndex === index

            color: isSelected ? Theme.overlay : (itemMouse.containsMouse ? Theme.hover : "transparent")
            border.color: isSelected ? Theme.iris : "transparent"
            border.width: isSelected ? 1 : 0

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Theme.paddingLarge
              anchors.rightMargin: Theme.paddingLarge
              spacing: Theme.spacingLarge

              Image {
                id: appIcon
                source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
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
                font.pixelSize: Theme.fontSizeTitle
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: modelData.name
                  color: appItem.isSelected ? Theme.foam : Theme.text
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize
                  font.bold: appItem.isSelected
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  visible: (modelData.generic || modelData.comment).length > 0
                  text: modelData.generic || modelData.comment
                  color: Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Text {
                visible: appItem.isSelected
                text: "󰌑"
                color: Theme.foam
                font.pixelSize: Theme.fontSizeMedium
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

          Text {
            anchors.centerIn: parent
            visible: appListView.count === 0
            text: "No app found"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
          }
        }
      }
    }
  }
}
