pragma Singleton
import QtQuick

QtObject {
  property bool visible: false

  function toggle(): void { visible = !visible }
  function open(): void { visible = true }
  function close(): void { visible = false }
}
