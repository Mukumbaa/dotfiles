pragma Singleton
import QtQuick

QtObject {
  property bool visible: false

  function toggle() {
    visible = !visible
  }

  function open() {
    visible = true
  }

  function close() {
    visible = false
  }
}
