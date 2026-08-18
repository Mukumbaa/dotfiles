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
  property bool isImg1Active: true

  // Percorso della cartella sfondi
  property string wallpaperDir: (Quickshell.env("HOME") || "/home/user") + "/.config/hypr/wallpaper"

  Process {
    id: scanWallpapersProc
    command: ["sh", "-c", "find \"" + root.wallpaperDir + "\" -maxdepth 1 -type f \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \\) | sort -V"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        for (let line of lines) {
          let path = line.trim()
          if (path.length > 0) list.push(path)
        }
        root.wallpaperList = list
        if (list.length > 0) {
          img1.source = list[0]
        }
      }
    }
  }

  Component.onCompleted: scanWallpapersProc.running = true

  IpcHandler {
    target: "wallpaper"

    function next(): void {
      root.changeWallpaper(1)
    }

    function prev(): void {
      root.changeWallpaper(-1)
    }
  }

  function changeWallpaper(step) {
    if (root.wallpaperList.length === 0) return

    root.currentIndex = (root.currentIndex + step + root.wallpaperList.length) % root.wallpaperList.length
    let nextPath = root.wallpaperList[root.currentIndex]

    if (root.isImg1Active) {
      img2.source = nextPath
      root.isImg1Active = false
    } else {
      img1.source = nextPath
      root.isImg1Active = true
    }
  }

  // -------------------------------------------------------------
  // DOPPIO LAYER PER TRANSIZIONE MORBIDA (CON RILASCIO MEMORIA RAM)
  // -------------------------------------------------------------
  Image {
    id: img1
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    sourceSize.width: root.width
    sourceSize.height: root.height
    opacity: root.isImg1Active ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: 400
        easing.type: Easing.InOutQuad
        onRunningChanged: {
          if (!running && !root.isImg1Active) {
            img1.source = "" // Scarica l'immagine dalla RAM quando invisibile
          }
        }
      }
    }
  }

  Image {
    id: img2
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    sourceSize.width: root.width
    sourceSize.height: root.height
    opacity: root.isImg1Active ? 0.0 : 1.0

    Behavior on opacity {
      NumberAnimation {
        duration: 400
        easing.type: Easing.InOutQuad
        onRunningChanged: {
          if (!running && root.isImg1Active) {
            img2.source = "" // Scarica l'immagine dalla RAM quando invisibile
          }
        }
      }
    }
  }
}
