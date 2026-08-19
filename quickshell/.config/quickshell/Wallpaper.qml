import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.layer: WlrLayer.Background
  exclusiveZone: -1
  color: "black"

  // -------------------------------------------------------------
  // LOGICA SFONDI E IPC
  // -------------------------------------------------------------
  property var wallpaperList: []
  property int currentIndex: 0

  // Percorso della cartella sfondi
  property string wallpaperDir: (Quickshell.env("HOME") || "/home/user") + "/.config/hypr/wallpaper"

  // Scansiona la cartella e ordina i file
  Process {
    id: scanWallpapersProc
    command: ["sh", "-c", "find \"" + root.wallpaperDir + "\" -maxdepth 1 -type f \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \\) | sort -V"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        for (let l of lines) {
          let path = l.trim()
          if (path.length > 0) list.push(path)
        }
        root.wallpaperList = list

        if (list.length === 0) return

        // Primo avvio: imposta lo sfondo iniziale
        if (!bgImage.source.toString()) {
          bgImage.source = list[0]
          root.currentIndex = 0
        } else {
          // Risincronizza l'indice se la cartella cambia
          let cleanSource = bgImage.source.toString().replace(/^file:\/\//, "")
          let foundIdx = list.indexOf(cleanSource)
          if (foundIdx !== -1) {
            root.currentIndex = foundIdx
          } else {
            root.currentIndex = Math.max(0, Math.min(root.currentIndex, list.length - 1))
            bgImage.source = list[root.currentIndex]
          }
        }
      }
    }
  }

  Timer {
    id: scanDebounceTimer
    interval: 150
    onTriggered: {
      scanWallpapersProc.running = false
      scanWallpapersProc.running = true
    }
  }

  // Monitoraggio modifiche nella cartella sfondi
  Process {
    id: wallpaperDirWatcher
    running: true
    command: ["sh", "-c", "stdbuf -oL -eL inotifywait -m -e create -e delete -e moved_to -e moved_from \"" + root.wallpaperDir + "\" 2>/dev/null"]
    stdout: SplitParser {
      onRead: scanDebounceTimer.restart()
    }
  }

  Component.onCompleted: scanWallpapersProc.running = true

  // Ricevitore comandi IPC per il cambio sfondo
  IpcHandler {
    target: "wallpaper"

    function next(): void {
      root.changeWallpaper(1)
    }

    function prev(): void {
      root.changeWallpaper(-1)
    }

    function reload(): void {
      scanWallpapersProc.running = false
      scanWallpapersProc.running = true
    }
  }

  // Cambio sfondo istantaneo
  function changeWallpaper(step) {
    if (root.wallpaperList.length === 0) return
    root.currentIndex = (root.currentIndex + step + root.wallpaperList.length) % root.wallpaperList.length
    bgImage.source = root.wallpaperList[root.currentIndex]
  }

  // -------------------------------------------------------------
  // SINGOLA IMMAGINE OTTIMIZZATA (Caricamento diretto e leggero)
  // -------------------------------------------------------------
  Image {
    id: bgImage
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    // sourceSize.width: Screen.width
    // sourceSize.height: Screen.height
  }
}
