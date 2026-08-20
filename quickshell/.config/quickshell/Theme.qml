pragma Singleton
import QtQuick

QtObject {
    readonly property string fontFamily: "Cascadia Code NF"
    readonly property int marginTop: 8
    readonly property int borderWidth: 4
    readonly property int radius: 12
    readonly property int animationDurationCalendar: 250
    readonly property int animationDuration: 250
    readonly property int marginRight: 16
    // Rosé Pine Base
    readonly property color base: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color text: "#e0def4"
    readonly property color subtle: "#908caa"
    
    // Accenti
    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ebbcba"
    readonly property color pine: "#31748f"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"
}
