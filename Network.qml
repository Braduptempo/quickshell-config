import Quickshell
import QtQuick

pragma singleton

QtObject {
  id: root

  property bool isWifiOn: Network.wifiEnabled

  readonly property var iconMap: {
   "0": "" 
  }

}
