import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: root

  property bool isOpen: ThemeState.visible
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
    target: "theme"
    function toggle(): void { ThemeState.toggle() }
    function open(): void { ThemeState.open() }
    function close(): void { ThemeState.close() }
  }

  GlobalShortcut {
    name: "theme"
    onPressed: ThemeState.toggle()
  }

  // -------------------------------------------------------------
  // CARICAMENTO DINAMICO TEMI DA ~/.config/themes/
  // -------------------------------------------------------------
  readonly property string switchScript: (Quickshell.env("HOME") || "/home/mukumba") + "/.config/scripts/switch-theme.lua"

  property string searchFilter: ""
  property string activeThemeId: "rose-pine"
  property var allThemes: []

  function formatLabel(id) {
    return id.split("-").map(w => w.length ? (w[0].toUpperCase() + w.slice(1)) : w).join(" ")
  }

  Process {
    id: loadProc
    command: [
      "lua", "-e",
      "local h=os.getenv('HOME'); local cur=''; " +
      "local cf=io.open(h..'/.cache/current-theme/quickshell.json','r'); " +
      "if cf then cur=cf:read('*a'):match('\"name\"%s*:%s*\"([^\"]+)\"') or ''; cf:close() end; " +
      "local p=io.popen('ls -1 \"'..h..'/.config/themes\" 2>/dev/null | sort'); " +
      "if p then for d in p:lines() do " +
      "local tf=io.open(h..'/.config/themes/'..d..'/quickshell.json','r'); " +
      "if tf then local r=tf:read('*a'); tf:close(); " +
      "local function c(k) return r:match('\"'..k..'\"%s*:%s*\"([^\"]+)\"') or '#000000' end; " +
      "print(d..'\\t'..(d==cur and '1' or '0')..'\\t'..c('base')..'\\t'..c('error')..'\\t'..c('warning')..'\\t'..c('success')..'\\t'..c('accent')..'\\t'..c('accent2')) " +
      "end end p:close() end"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        let activeIdx = 0

        for (let line of lines) {
          if (!line) continue
          let parts = line.split("\t")
          if (parts.length < 8) continue

          let id = parts[0].trim()
          let isActive = parts[1].trim() === "1"
          if (isActive) {
            root.activeThemeId = id
            activeIdx = list.length
          }

          list.push({
            id: id,
            label: root.formatLabel(id),
            labelLower: id.toLowerCase(),
            base: parts[2].trim(),
            swatches: [
              parts[3].trim(), // love
              parts[4].trim(), // gold
              parts[5].trim(), // pine
              parts[6].trim(), // foam
              parts[7].trim()  // iris
            ]
          })
        }

        root.allThemes = list
        if (root.searchFilter === "" && list.length > 0) {
          themeListView.currentIndex = activeIdx
          themeListView.positionViewAtIndex(activeIdx, ListView.Contain)
        }
      }
    }
  }

  property var filteredThemes: {
    let q = searchFilter.trim().toLowerCase()
    if (!q) return allThemes
    return allThemes.filter(t => t.labelLower.includes(q))
  }

  onFilteredThemesChanged: {
    if (searchFilter !== "") {
      themeListView.currentIndex = 0
      themeListView.positionViewAtBeginning()
    }
  }

  function applyTheme(item) {
    if (!item || !/^[a-zA-Z0-9._-]+$/.test(item.id)) return
    root.activeThemeId = item.id
    ThemeState.close()
    Quickshell.execDetached(["lua", root.switchScript, item.id])
  }

  function applySelected() {
    if (themeListView.count > 0 && themeListView.currentIndex >= 0) {
      root.applyTheme(root.filteredThemes[themeListView.currentIndex])
    }
  }

  onIsOpenChanged: {
    if (isOpen) {
      root.searchFilter = ""
      searchInput.text = ""
      loadProc.running = false
      loadProc.running = true
      searchInput.forceActiveFocus()
    }
  }

  // -------------------------------------------------------------
  // CONTENITORE (Identico ad AppLauncher / ClipboardPopup)
  // -------------------------------------------------------------
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.backdrop
    opacity: root.animProgress

    MouseArea {
      anchors.fill: parent
      onClicked: ThemeState.close()
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
      border.color: Theme.border
      border.width: Theme.borderWidth

      MouseArea {
        anchors.fill: parent
        onClicked: searchInput.forceActiveFocus()
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingWindow
        spacing: Theme.spacingLarge

        // 1. Barra di Ricerca
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 42
          radius: Theme.radiusCard
          color: Theme.surface
          border.color: searchInput.activeFocus ? Theme.accent : Theme.border
          border.width: 1

          Behavior on border.color { ColorAnimation { duration: 120 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.spacingLarge

            Text {
              text: ""
              color: searchInput.text.length > 0 ? Theme.accent : Theme.subtle
              font.family: Theme.fontFamily
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
                  themeListView.currentIndex = 0
                }

                Keys.onPressed: event => {
                  if (event.key === Qt.Key_Escape) {
                    ThemeState.close()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                    if (themeListView.count > 0) {
                      themeListView.currentIndex = (themeListView.currentIndex + 1) % themeListView.count
                      themeListView.positionViewAtIndex(themeListView.currentIndex, ListView.Contain)
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    if (themeListView.count > 0) {
                      themeListView.currentIndex = (themeListView.currentIndex - 1 + themeListView.count) % themeListView.count
                      themeListView.positionViewAtIndex(themeListView.currentIndex, ListView.Contain)
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.applySelected()
                    event.accepted = true
                  }
                }
              }

              Text {
                visible: !searchInput.text.length
                text: "Select theme..."
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

        // 2. Lista Temi con Anteprima Palette
        ListView {
          id: themeListView
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          model: root.filteredThemes
          spacing: 4
          currentIndex: 0

          delegate: Rectangle {
            id: themeItem
            width: ListView.view.width
            implicitHeight: 46
            radius: Theme.radiusMedium

            property bool isSelected: themeListView.currentIndex === index
            property bool isCurrentActive: modelData.id === root.activeThemeId

            color: isSelected ? Theme.overlay : (itemMouse.containsMouse ? Theme.hover : "transparent")
            border.color: isSelected ? Theme.accent2 : "transparent"
            border.width: isSelected ? 1 : 0

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Theme.paddingLarge
              anchors.rightMargin: Theme.paddingLarge
              spacing: Theme.spacingLarge

              // Mini card anteprima colori (sfondo del tema + 5 pallini accenti)
              Rectangle {
                implicitWidth: paletteRow.implicitWidth + 12
                implicitHeight: 24
                radius: Theme.radiusSmall
                color: modelData.base
                border.color: Theme.border
                border.width: 1

                Row {
                  id: paletteRow
                  anchors.centerIn: parent
                  spacing: 4

                  Repeater {
                    model: modelData.swatches
                    Rectangle {
                      width: 8
                      height: 8
                      radius: 4
                      color: modelData
                    }
                  }
                }
              }

              // Nome Tema
              Text {
                text: modelData.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: themeItem.isSelected || themeItem.isCurrentActive
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              // Badge Active se è il tema attualmente applicato
              Rectangle {
                visible: themeItem.isCurrentActive
                implicitWidth: activeText.implicitWidth + 10
                implicitHeight: 18
                radius: Theme.radiusSmall
                color: Theme.surface
                border.color: Theme.accent
                border.width: 1

                Text {
                  id: activeText
                  anchors.centerIn: parent
                  text: "Active"
                  color: Theme.accent
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                  font.bold: true
                }
              }

              // Badge Invio su riga selezionata
              Text {
                visible: themeItem.isSelected
                text: "󰌑"
                color: Theme.accent2
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
              }
            }

            MouseArea {
              id: itemMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: themeListView.currentIndex = index
              onClicked: root.applyTheme(modelData)
            }
          }

          Text {
            anchors.centerIn: parent
            visible: themeListView.count === 0
            text: "No theme found"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
          }
        }
      }
    }
  }
}
