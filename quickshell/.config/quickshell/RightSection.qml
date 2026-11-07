import QtQuick
import QtQuick.Layouts

RowLayout {
  Layout.alignment: Qt.AlignRight
  spacing: Theme.barSpacing

  KeyboardWidget {}
  BluetoothWidget {}
  WifiWidget {}
  BrightnessWidget {}
  VolumeWidget {}
  BatteryWidget {}
}
