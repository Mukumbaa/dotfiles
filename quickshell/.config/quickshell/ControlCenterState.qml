pragma Singleton
import QtQuick

QtObject {
  property bool visible: false
  property string currentTab: "wifi"

  function toggle(tab) {
    if (visible && currentTab === tab) {
      visible = false
    } else {
      currentTab = tab
      visible = true
    }
  }
}
