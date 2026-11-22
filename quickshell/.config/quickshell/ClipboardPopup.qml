import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: root

  property bool isOpen: ClipboardState.visible
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
    target: "clipboard"
    function toggle(): void { ClipboardState.toggle() }
    function open(): void { ClipboardState.open() }
    function close(): void { ClipboardState.close() }
  }

  GlobalShortcut {
    name: "clipboard"
    onPressed: ClipboardState.toggle()
  }

  // -------------------------------------------------------------
  // LOGICA CLIPHIST & THUMBNAIL
  // -------------------------------------------------------------
  property string searchFilter: ""
  property var allEntries: []
  property bool thumbsReady: false
  property int thumbRev: 0
  property bool _preserveIndex: false

  readonly property string ttlScript: (Quickshell.env("HOME") || "/home/mukumba") + "/.config/scripts/cliphist-ttl.lua"

  // Pulizia automatica silenziosa in background ogni 15 minuti
  Timer {
    interval: 15 * 60 * 1000
    repeat: true
    running: true
    onTriggered: Quickshell.execDetached(["lua", root.ttlScript, "prune"])
  }

  Process {
    id: listProc
    command: ["lua", root.ttlScript, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.split("\n")
        let entries = []
        let decodeCmds = []

        for (let line of lines) {
          if (!line) continue
          let tabIdx = line.indexOf("\t")
          if (tabIdx === -1) continue

          let id = line.substring(0, tabIdx).trim()
          let preview = line.substring(tabIdx + 1)
          if (!/^\d+$/.test(id)) continue

          let imgMatch = preview.match(/^\[\[ binary data .*?\b(png|jpe?g|webp|gif|bmp)\b(.*?)\]\]/i)
          let isImage = !!imgMatch
          let ext = imgMatch ? imgMatch[1].toLowerCase() : ""
          let imageMeta = imgMatch ? (ext.toUpperCase() + (imgMatch[2] || "").replace(/\]\]$/, "")) : ""
          let thumbPath = isImage ? ("/tmp/qs_clip_thumbs/" + id + "." + ext) : ""
          let isUrl = !isImage && /^https?:\/\//i.test(preview.trim())

          if (isImage) {
            decodeCmds.push("[ ! -f '" + thumbPath + "' ] && cliphist decode " + id + " > '" + thumbPath + "' 2>/dev/null")
          }

          entries.push({
            id: id,
            preview: isImage ? "Image" : preview.trim(),
            previewLower: isImage ? ("image " + imageMeta).toLowerCase() : preview.toLowerCase(),
            isImage: isImage,
            imageMeta: imageMeta.trim(),
            thumbPath: thumbPath,
            isUrl: isUrl
          })
        }

        root.allEntries = entries

        if (decodeCmds.length > 0) {
          root.thumbsReady = false
          thumbProc.command = ["sh", "-c", "mkdir -p /tmp/qs_clip_thumbs; " + decodeCmds.join("; ")]
          thumbProc.running = false
          thumbProc.running = true
        } else {
          root.thumbsReady = true
        }
      }
    }
  }

  Process {
    id: thumbProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.thumbsReady = true
        root.thumbRev++
      }
    }
  }

  property var filteredEntries: {
    let q = searchFilter.trim().toLowerCase()
    if (!q) return allEntries
    return allEntries.filter(item => item.previewLower.includes(q))
  }

  onFilteredEntriesChanged: {
    if (root._preserveIndex) {
      root._preserveIndex = false
      if (clipListView.count > 0) {
        clipListView.currentIndex = Math.min(clipListView.currentIndex, clipListView.count - 1)
      }
    } else {
      clipListView.currentIndex = 0
      clipListView.positionViewAtBeginning()
    }
  }

  function refreshList() {
    listProc.running = false
    listProc.running = true
  }

  function selectEntry(item) {
    if (!item || !/^\d+$/.test(item.id)) return
    ClipboardState.close()
    Quickshell.execDetached(["sh", "-c", "cliphist decode " + item.id + " | wl-copy"])
  }

  function selectCurrent() {
    if (clipListView.count > 0 && clipListView.currentIndex >= 0) {
      root.selectEntry(root.filteredEntries[clipListView.currentIndex])
    }
  }

  function deleteEntry(item) {
    if (!item || !/^\d+$/.test(item.id)) return
    root._preserveIndex = true
    root.allEntries = root.allEntries.filter(e => e.id !== item.id)
    Quickshell.execDetached([
      "sh", "-c",
      "printf '%s\\t\\n' '" + item.id + "' | cliphist delete; rm -f /tmp/qs_clip_thumbs/" + item.id + ".*"
    ])
  }

  function deleteCurrent() {
    if (clipListView.count > 0 && clipListView.currentIndex >= 0) {
      root.deleteEntry(root.filteredEntries[clipListView.currentIndex])
    }
  }

  function wipeAll() {
    root.allEntries = []
    Quickshell.execDetached(["sh", "-c", "cliphist wipe && rm -rf /tmp/qs_clip_thumbs/* ~/.cache/cliphist/ttl.tsv"])
  }

  onIsOpenChanged: {
    if (isOpen) {
      root.searchFilter = ""
      searchInput.text = ""
      clipListView.currentIndex = 0
      root.refreshList()
      searchInput.forceActiveFocus()
    }
  }

  // -------------------------------------------------------------
  // CONTENITORE (Identico ad AppLauncher)
  // -------------------------------------------------------------
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.backdrop
    opacity: root.animProgress

    MouseArea {
      anchors.fill: parent
      onClicked: ClipboardState.close()
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
          border.color: searchInput.activeFocus ? Theme.foam : Theme.overlay
          border.width: 1

          Behavior on border.color { ColorAnimation { duration: 120 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.spacingLarge

            Text {
              text: "󰅌"
              color: searchInput.text.length > 0 ? Theme.foam : Theme.subtle
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
                  clipListView.currentIndex = 0
                }

                Keys.onPressed: event => {
                  if (event.key === Qt.Key_Escape) {
                    ClipboardState.close()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                    if (clipListView.count > 0) {
                      clipListView.currentIndex = (clipListView.currentIndex + 1) % clipListView.count
                      clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain)
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    if (clipListView.count > 0) {
                      clipListView.currentIndex = (clipListView.currentIndex - 1 + clipListView.count) % clipListView.count
                      clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain)
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                    root.deleteCurrent()
                    event.accepted = true
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.selectCurrent()
                    event.accepted = true
                  }
                }
              }

              Text {
                visible: !searchInput.text.length
                text: "Search clipboard..."
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            // Tasto Clear All (svuota cronologia)
            Rectangle {
              visible: root.allEntries.length > 0
              implicitWidth: clearRow.implicitWidth + 10
              implicitHeight: 20
              radius: Theme.radiusSmall
              color: clearMouse.containsMouse ? Theme.love : Theme.overlay

              RowLayout {
                id: clearRow
                anchors.centerIn: parent
                spacing: 4
                Text {
                  text: "󰃢"
                  color: clearMouse.containsMouse ? Theme.base : Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                }
                Text {
                  text: "Clear"
                  color: clearMouse.containsMouse ? Theme.base : Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                  font.bold: true
                }
              }

              MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wipeAll()
              }
            }

            // Badge ESC
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

        // 2. Lista Elementi Clipboard
        ListView {
          id: clipListView
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          model: root.filteredEntries
          spacing: 3
          currentIndex: 0

          delegate: Rectangle {
            id: clipItem
            width: ListView.view.width
            implicitHeight: modelData.isImage ? 50 : 40
            radius: Theme.radiusMedium

            property bool isSelected: clipListView.currentIndex === index
            property bool isHovered: itemMouse.containsMouse || deleteMouse.containsMouse

            color: isSelected ? Theme.overlay : (isHovered ? Theme.hover : "transparent")
            border.color: isSelected ? Theme.iris : "transparent"
            border.width: isSelected ? 1 : 0

            MouseArea {
              id: itemMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: clipListView.currentIndex = index
              onClicked: root.selectEntry(modelData)
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Theme.paddingLarge
              anchors.rightMargin: Theme.paddingLarge
              spacing: Theme.spacingLarge

              // Anteprima Immagine (se screenshot/immagine)
              Image {
                id: thumbImg
                visible: modelData.isImage && status === Image.Ready
                source: (modelData.isImage && root.thumbsReady) ? ("file://" + modelData.thumbPath + "?r=" + root.thumbRev) : ""
                sourceSize: Qt.size(64, 64)
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
              }

              // Icona tipo (Testo / URL / Immagine in caricamento)
              Text {
                visible: !thumbImg.visible
                text: modelData.isImage ? "󰋩" : (modelData.isUrl ? "󰖟" : "󰅍")
                color: {
                  if (clipItem.isSelected) return Theme.foam
                  if (modelData.isUrl) return Theme.foam
                  if (modelData.isImage) return Theme.iris
                  return Theme.subtle
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
              }

              // Testo / Metadati
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: modelData.preview
                  color: Theme.text
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSize
                  font.bold: clipItem.isSelected
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  visible: modelData.isImage || modelData.isUrl
                  text: modelData.isImage ? modelData.imageMeta : "URL"
                  color: Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              // Badge Invio su riga selezionata
              Text {
                visible: clipItem.isSelected
                text: "󰌑"
                color: Theme.iris
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
              }

              // Tasto Elimina singola voce
              Rectangle {
                visible: clipItem.isSelected || clipItem.isHovered
                implicitWidth: 22
                implicitHeight: 22
                radius: Theme.radiusSmall
                color: deleteMouse.containsMouse ? Theme.love : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "󰆴"
                  color: deleteMouse.containsMouse ? Theme.base : Theme.subtle
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizePopup
                }

                MouseArea {
                  id: deleteMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.deleteEntry(modelData)
                }
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: clipListView.count === 0
            text: root.allEntries.length === 0 ? "Clipboard is empty" : "No matches found"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
          }
        }
      }
    }
  }
}
