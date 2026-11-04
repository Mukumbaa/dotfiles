pragma Singleton
import QtQuick

QtObject {
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

  // Raggi (Border Radius)
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

  // Palette Colori Rosé Pine
  readonly property color base: "#1B1A28"
  readonly property color surface: "#1f1d2e"
  readonly property color overlay: "#26233a"
  readonly property color text: "#e0def4"
  readonly property color subtle: "#908caa"

  // Colori Sovrapposti e Interattivi
  readonly property color hover: Qt.rgba(1, 1, 1, 0.04)
  readonly property color hoverStrong: Qt.rgba(1, 1, 1, 0.08)
  readonly property color backdrop: Qt.rgba(0.05, 0.04, 0.08, 0.65)
  readonly property color backdropDark: Qt.rgba(0.05, 0.04, 0.08, 0.75)

  // Accenti
  readonly property color love: "#eb6f92"
  readonly property color gold: "#f6c177"
  readonly property color rose: "#ebbcba"
  readonly property color pine: "#31748f"
  readonly property color foam: "#9ccfd8"
  readonly property color iris: "#c4a7e7"
}
