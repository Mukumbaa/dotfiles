import QtQuick
import QtQuick.Layouts

RowLayout {
  Layout.alignment: Qt.AlignRight
  spacing: 12

  KeyboardWidget {}
  CpuWidget {}
  BluetoothWidget {}
  WifiWidget {}
  BrightnessWidget {}
  VolumeWidget {}
  BatteryWidget {}
}
