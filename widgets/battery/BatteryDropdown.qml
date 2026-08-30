// BatteryDropdown.qml
import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick.Controls

PopupWindow {
    id: popup

    color: "transparent"
    implicitWidth: 180
    implicitHeight: contentColumn.implicitHeight + 20

    // Eigenschappen om power profiles bij te houden
    property string activeProfile: "balanced"

    Process {
        id: getProfileProcess
        command: ["powerprofilesctl", "get"]
        running: popup.visible
        stdout: SplitParser {
            onRead: (data) => {
                activeProfile = data.trim();
            }
        }
    }

    Process {
        id: setProfileProcess
        command: ["powerprofilesctl", "set", targetProfile]
        property string targetProfile: ""
    }

    Timer {
        interval: 3000
        running: popup.visible
        repeat: true
        onTriggered: getProfileProcess.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: "#2a2a2c" 
        border.color: "#ffffff"
        border.width: 2
        radius: 8
        clip: true
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: Battery.hasBattery ? (Battery.charging ? "Charging" : "Discharging") : "Desktop (No Battery)"
            font.bold: true
            color: "white"
        }

        Text {
            visible: Battery.hasBattery
            text: Battery.timeRemainingStr
            color: "#ffffff"
            font.pixelSize: 12
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#404040"
        }

        // --- POWER PROFILES SECTIE ---
        Text {
            text: "Power Profile"
            font.bold: true
            font.pixelSize: 10
            color: "#a0a0a0"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Button {
                text: "Eco"
                Layout.fillWidth: true
                background: Rectangle { color: activeProfile === "power-saver" ? "#89b4fa" : "#1a1a1c"; radius: 4 }
                onClicked: {
                    setProfileProcess.targetProfile = "power-saver";
                    setProfileProcess.running = true;
                    activeProfile = "power-saver";
                }
            }

            Button {
                text: "Bal"
                Layout.fillWidth: true
                background: Rectangle { color: activeProfile === "balanced" ? "#89b4fa" : "#1a1a1c"; radius: 4 }
                onClicked: {
                    setProfileProcess.targetProfile = "balanced";
                    setProfileProcess.running = true;
                    activeProfile = "balanced";
                }
            }

            Button {
                text: "Perf"
                Layout.fillWidth: true
                background: Rectangle { color: activeProfile === "performance" ? "#89b4fa" : "#1a1a1c"; radius: 4 }
                onClicked: {
                    setProfileProcess.targetProfile = "performance";
                    setProfileProcess.running = true;
                    activeProfile = "performance";
                }
            }
        }

        Rectangle {
            visible: Battery.hasBattery
            Layout.fillWidth: true
            height: 1
            color: "#404040"
        }

        // Lijst met batterijen (indien aanwezig)
        Repeater {
            model: Battery.hasBattery ? Battery.allDevices : []

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: modelData.type === UPowerDeviceType.Battery

                Text {
                    text: `Battery (${modelData.model})`
                    font.pixelSize: 11
                    color: "#ffffff"
                }

                Text {
                    text: `${Math.floor(modelData.percentage * 100)}%`
                    font.pixelSize: 11
                    color: "#a0a0a0"
                }
            }
        }
    }
}
