pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // Tipografia
  readonly property string fontFamily: "CaskaydiaMono NF"
  readonly property int fontSizeMicro: 9
  readonly property int fontSizePopup: 10
  readonly property int fontSizeSmall: 11
  readonly property int fontSize: 12
  readonly property int fontSizeMedium: 14
  readonly property int fontSizeLarge: 15
  readonly property int fontSizeIcon: 18
  readonly property int fontSizeTitle: 21
  readonly property int fontSizeHuge: 34
  readonly property int fontSizeClock: 72

  // Spaziature e Margini
  readonly property int marginTop: 8
  readonly property int marginRight: 16
  readonly property int spacingSmall: 4
  readonly property int spacingMedium: 6
  readonly property int spacingLarge: 8
  readonly property int spacingExtra: 10
  readonly property int barSpacing: 10
  readonly property int paddingSmall: 4
  readonly property int paddingMedium: 8
  readonly property int paddingLarge: 10
  readonly property int paddingWindow: 14

  // Raggi
  readonly property int borderWidth: 4
  readonly property int radiusSmall: 4
  readonly property int radiusMedium: 6
  readonly property int radiusCard: 8
  readonly property int radius: 12
  readonly property int radiusLarge: 14
  readonly property int radiusPill: 999

  // Dimensioni Standard Finestre e Barra
  readonly property int barHeight: 26
  readonly property int popupWidthSmall: 265
  readonly property int popupWidthNormal: 320
  readonly property int popupWidthLarge: 350
  readonly property int launcherWidth: 480
  readonly property int launcherHeight: 420

  // Animazioni e Timer
  readonly property int animationDuration: 180
  readonly property int autoCloseTimer: 600
  readonly property int inactivityTimer: 1500

  // Palette Dinamica (con Rosé Pine come fallback predefinito)
  property color base: "#1B1A28"
  property color surface: "#1f1d2e"
  property color overlay: "#26233a"
  property color text: "#e0def4"
  property color subtle: "#908caa"

  property color accent: "#9ccfd8"   // Accento principale (ex foam)
  property color accent2: "#c4a7e7"  // Secondo accento (ex iris)
  property color accent3: "#ebbcba"  // Terzo accento (ex rose)
  property color error: "#eb6f92"    // Errori / Critico (ex love)
  property color warning: "#f6c177"  // Avvisi / Luminosità (ex gold)
  property color success: "#31748f"  // Positivo / Eco (ex pine)

  // Colori derivati in tempo reale
  readonly property color hover: Qt.rgba(1, 1, 1, 0.04)
  readonly property color hoverStrong: Qt.rgba(1, 1, 1, 0.08)
  readonly property color border: Qt.rgba(
    overlay.r * 0.75 + subtle.r * 0.25,
    overlay.g * 0.75 + subtle.g * 0.25,
    overlay.b * 0.75 + subtle.b * 0.25,
    1.0
  )
  readonly property color backdrop: Qt.rgba(base.r * 0.35, base.g * 0.35, base.b * 0.35, 0.65)
  readonly property color backdropDark: Qt.rgba(base.r * 0.35, base.g * 0.35, base.b * 0.35, 0.75)

  // Watcher live su ~/.cache/current-theme/quickshell.json
  readonly property string _themeJsonPath: (Quickshell.env("HOME") || "/home/mukumba") + "/.cache/current-theme/quickshell.json"

  function _applyTheme(raw) {
    if (!raw || !raw.trim()) return
    try {
      let d = JSON.parse(raw)
      if (d.base) base = d.base
      if (d.surface) surface = d.surface
      if (d.overlay) overlay = d.overlay
      if (d.text) text = d.text
      if (d.subtle) subtle = d.subtle
      if (d.accent) accent = d.accent
      if (d.accent2) accent2 = d.accent2
      if (d.accent3) accent3 = d.accent3
      if (d.error) error = d.error
      if (d.warning) warning = d.warning
      if (d.success) success = d.success
    } catch (e) {}
  }

  readonly property FileView _themeWatcher: FileView {
    path: root._themeJsonPath
    watchChanges: true
    preload: true
    onLoaded: root._applyTheme(text())
    onFileChanged: reload()
  }
}
