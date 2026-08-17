pragma Singleton
import QtQuick

QtObject {
  property bool visible: false
  property string currentTab: "output" // "output" oppure "input"

  function toggle(tab) {
    if (tab) currentTab = tab
    visible = !visible
  }

  function open(tab) {
    if (tab) currentTab = tab
    visible = true
  }

  function close() {
    visible = false
  }
}
