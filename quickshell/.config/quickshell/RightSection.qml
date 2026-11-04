import QtQuick
import QtQuick.Layouts

RowLayout {
  Layout.alignment: Qt.AlignRight
  spacing: Theme.barSpacing

  KeyboardWidget {}
  CpuWidget {}
  BluetoothWidget {}
  WifiWidget {}
  BrightnessWidget {}
  VolumeWidget {}
  BatteryWidget {}
}
