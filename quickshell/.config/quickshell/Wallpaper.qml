import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: wallpaperScope

  property var wallpaperList: []
  property int currentIndex: 0
  property string currentWallpaperPath: ""

  property string wallpaperDir: (Quickshell.env("HOME") || "/home/user") + "/.config/hypr/wallpaper"

  Process {
    id: scanWallpapersProc
    command: ["sh", "-c", "find \"" + wallpaperScope.wallpaperDir + "\" -maxdepth 1 -type f \\( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \\) | sort -V"]
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = this.text.trim().split("\n")
        let list = []
        for (let l of lines) {
          let path = l.trim()
          if (path.length > 0) list.push(path)
        }
        wallpaperScope.wallpaperList = list

        if (list.length === 0) return

        if (!wallpaperScope.currentWallpaperPath) {
          wallpaperScope.currentIndex = 0
          wallpaperScope.currentWallpaperPath = list[0]
        } else {
          let clean = wallpaperScope.currentWallpaperPath.replace(/^file:\/\//, "")
          let idx = list.indexOf(clean)
          if (idx !== -1) {
            wallpaperScope.currentIndex = idx
          } else {
            wallpaperScope.currentIndex = Math.max(0, Math.min(wallpaperScope.currentIndex, list.length - 1))
            wallpaperScope.currentWallpaperPath = list[wallpaperScope.currentIndex]
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

  Process {
    id: wallpaperDirWatcher
    running: true
    command: ["sh", "-c", "stdbuf -oL -eL inotifywait -m -e create -e delete -e moved_to -e moved_from \"" + wallpaperScope.wallpaperDir + "\" 2>/dev/null"]
    stdout: SplitParser {
      onRead: scanDebounceTimer.restart()
    }
  }

  Component.onCompleted: scanWallpapersProc.running = true

  IpcHandler {
    target: "wallpaper"

    function next(): void {
      wallpaperScope.changeWallpaper(1)
    }

    function prev(): void {
      wallpaperScope.changeWallpaper(-1)
    }

    function reload(): void {
      scanWallpapersProc.running = false
      scanWallpapersProc.running = true
    }
  }

  function changeWallpaper(step) {
    if (wallpaperScope.wallpaperList.length === 0) return
    wallpaperScope.currentIndex = (wallpaperScope.currentIndex + step + wallpaperScope.wallpaperList.length) % wallpaperScope.wallpaperList.length
    wallpaperScope.currentWallpaperPath = wallpaperScope.wallpaperList[wallpaperScope.currentIndex]
  }

  // -------------------------------------------------------------
  // SFONDI DISTRIBUITI CORRETTAMENTE SU OGNI MONITOR
  // -------------------------------------------------------------
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: bgWindow
        required property var modelData
        screen: modelData

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        WlrLayershell.layer: WlrLayer.Background
        exclusiveZone: -1
        color: "black"

        Image {
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          source: wallpaperScope.currentWallpaperPath
        }
      }
    }
  }
}
