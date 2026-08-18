pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root
  property int brightness: 100

  function setBrightness(percent) {
    let p = Math.max(1, Math.min(100, Math.round(percent)))
    brightness = p
    Quickshell.execDetached(["brightnessctl", "set", p + "%"])
  }

  function adjustBrightness(delta) {
    let cmd = delta > 0 ? "+5%" : "5%-"
    Quickshell.execDetached(["brightnessctl", "set", cmd])
  }

  readonly property Process brightProc: Process {
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
    stdout: SplitParser {
      onRead: data => {
        let val = parseInt(data.trim())
        if (!isNaN(val)) root.brightness = val
      }
    }
  }

  readonly property Process brightMonitorProc: Process {
    running: true
    command: ["sh", "-c", "stdbuf -oL -eL inotifywait -m -e modify /sys/class/backlight/*/*brightness 2>/dev/null"]
    stdout: SplitParser {
      onRead: {
        if (!root.brightProc.running) root.brightProc.running = true
      }
    }
  }

  Component.onCompleted: brightProc.running = true
}
