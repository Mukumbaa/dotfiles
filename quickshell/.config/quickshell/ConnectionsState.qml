pragma Singleton
import QtQuick

QtObject {
  property bool visible: false
  property string currentTab: "wifi" // "wifi" oppure "bluetooth"

  function toggle(tab) {
    if (visible && currentTab === tab) {
      visible = false
    } else {
      if (tab) currentTab = tab
      visible = true
    }
  }

  function open(tab) {
    if (tab) currentTab = tab
    visible = true
  }

  function close() {
    visible = false
  }
}
