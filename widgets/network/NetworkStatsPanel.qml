// NetworkStatsPanel.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.fillWidth: true
    color: "#1a1a1c"
    border.color: "#505050"
    border.width: 1
    radius: 6

    // Data properties
    property var netStats: ({ connected: false })
    property double downSpeed: 0
    property double upSpeed: 0

    visible: netStats.connected === true
    implicitHeight: statsGrid.implicitHeight + 16

    function formatBytes(bytes) {
        if (!bytes || bytes === 0) return "0 B";
        let k = 1024;
        let sizes = ["B", "KB", "MB", "GB", "TB"];
        let i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
    }

    function formatSpeed(bytesPerSec) {
        if (!bytesPerSec || bytesPerSec <= 0) return "0.0 Mbps";
        let mbps = (bytesPerSec * 8) / 1000000; 
        return mbps.toFixed(1) + " Mbps";
    }

    GridLayout {
        id: statsGrid
        anchors.fill: parent
        anchors.margins: 8
        columns: 2
        rowSpacing: 4
        columnSpacing: 10

        Text { text: "IP Adres:"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text { text: root.netStats.ip || "-"; color: "white"; font.pixelSize: 11; font.bold: true; font.family: "jetbrains mono"; Layout.fillWidth: true }
        
        Text { text: "Gateway:"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text { text: root.netStats.gw || "-"; color: "white"; font.pixelSize: 11; font.bold: true; font.family: "jetbrains mono"; Layout.fillWidth: true }
        
        Text { text: "Download:"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text { text: root.formatSpeed(root.downSpeed); color: "#a6e3a1"; font.pixelSize: 11; font.bold: true; font.family: "jetbrains mono"; Layout.fillWidth: true }
        
        Text { text: "Upload:"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text { text: root.formatSpeed(root.upSpeed); color: "#89b4fa"; font.pixelSize: 11; font.bold: true; font.family: "jetbrains mono"; Layout.fillWidth: true }
        
        Text { text: "Ontvangen:"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text { text: root.formatBytes(root.netStats.rx || 0); color: "#cdd6f4"; font.pixelSize: 11; font.family: "jetbrains mono"; Layout.fillWidth: true }
        
        Text { text: "Verstuurd:"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text { text: root.formatBytes(root.netStats.tx || 0); color: "#cdd6f4"; font.pixelSize: 11; font.family: "jetbrains mono"; Layout.fillWidth: true }
        
        Text { text: "Ping (DNS):"; color: "#a0a0a0"; font.pixelSize: 11; font.family: "jetbrains mono" }
        Text {
            text: (root.netStats.ping || "0") + " ms  (" + (root.netStats.loss || "0") + "% loss)"
            color: (root.netStats.loss > 0) ? "#f38ba8" : ((root.netStats.ping > 50) ? "#f9e2af" : "#a6e3a1")
            font.pixelSize: 11
            font.bold: true
            font.family: "jetbrains mono"
            Layout.fillWidth: true
        }
    }
}
