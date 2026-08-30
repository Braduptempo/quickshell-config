// NetworkRowDelegate.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Networking

ColumnLayout {
    id: delegateRoot
    Layout.fillWidth: true

    // Deze properties worden vanuit de lijst doorgegeven
    required property var modelData
    property var networkData

    property bool isExpanded: false
    property bool isEditing: false

    opacity: 0
    scale: 0.95
    NumberAnimation on opacity { to: 1; duration: 300 }
    NumberAnimation on scale { to: 1; duration: 300; easing.type: Easing.OutCubic }

    // Zichtbare rij van het netwerk
    Item {
        Layout.fillWidth: true
        implicitHeight: topRow.implicitHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 4
            color: itemMouseArea.containsMouse ? "#20ffffff" : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        RowLayout {
            id: topRow
            anchors.fill: parent

            Text {
                text: networkData ? networkData.getWifiIcon(modelData.strength) : ""
                color: modelData.connected ? "#a6e3a1" : "#a0a0a0"
                font.family: "jetbrains mono"
                font.pixelSize: 13
            }

            Text {
                text: modelData.name !== "" ? modelData.name : "Hidden Network"
                color: modelData.connected ? "#a6e3a1" : "#ffffff"
                font.bold: modelData.connected
            }

            Item { Layout.fillWidth: true }

            Text {
                text: {
                    if (modelData.connected) return "Verbonden";
                    if (modelData.state === ConnectionState.Activating) return "Verbinden...";
                    if (modelData.state === ConnectionState.Failed) return "Fout!";
                    return modelData.known ? "Opgeslagen" : "";
                }
                color: {
                    if (modelData.connected) return "#a6e3a1";
                    if (modelData.state === ConnectionState.Activating) return "#f9e2af";
                    if (modelData.state === ConnectionState.Failed) return "#f38ba8";
                    return "#a0a0a0";
                }
                font.pixelSize: 10
            }

            Text {
                text: modelData.securityType !== undefined ? WifiSecurityType.toString(modelData.securityType) : ""
                color: "#606060"
                font.pixelSize: 9
            }
        }

        MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                delegateRoot.isExpanded = !delegateRoot.isExpanded;
                delegateRoot.isEditing = false;
                if (delegateRoot.isExpanded && !modelData.known){
                    passwordInput.forceActiveFocus();
                }
            }
        }
    }

    // Uitklapmenu
    ColumnLayout {
        Layout.fillWidth: true
        visible: delegateRoot.isExpanded
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        spacing: 6

        TextField {
            id: passwordInput
            visible: !modelData.known && !modelData.connected
            Layout.fillWidth: true
            placeholderText: "Password..."
            echoMode: TextInput.Password
            color: "#ffffff"
            background: Rectangle { color: "#1a1a1c"; border.color: "#505050"; radius: 4 }

            onAccepted: {
                modelData.connectWithPsk(passwordInput.text);
                delegateRoot.isExpanded = false;
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: delegateRoot.isEditing
            
            TextField {
                id: editPasswordInput
                Layout.fillWidth: true
                placeholderText: "Nieuw wachtwoord..."
                echoMode: TextInput.Password
                color: "#ffffff"
                background: Rectangle { color: "#1a1a1c"; border.color: "#505050"; radius: 4 }
                onAccepted: saveBtn.clicked()
            }
            
            Button {
                id: saveBtn
                text: "Opslaan"
                onClicked: {
                    if (modelData.nmSettings && modelData.nmSettings.length > 0) {
                        modelData.nmSettings[0].write({ "802-11-wireless-security": { "psk": editPasswordInput.text } });
                    }
                    delegateRoot.isEditing = false;
                    delegateRoot.isExpanded = false;
                    editPasswordInput.text = "";
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            visible: !delegateRoot.isEditing

            Button {
                text: "Connect"
                visible: !modelData.connected
                Layout.fillWidth: true
                onClicked: {
                    if (modelData.known) modelData.connect();
                    else modelData.connectWithPsk(passwordInput.text);
                    delegateRoot.isExpanded = false;
                }
            }

            Button {
                text: "Verbreek"
                visible: modelData.connected
                Layout.fillWidth: true
                onClicked: {
                    modelData.disconnect();
                    delegateRoot.isExpanded = false;
                }
            }

            Button {
                text: "Bewerk"
                visible: modelData.known
                Layout.fillWidth: true
                onClicked: {
                    delegateRoot.isEditing = true;
                    editPasswordInput.forceActiveFocus();
                }
            }

            Button {
                text: "Vergeet"
                visible: modelData.known
                Layout.fillWidth: true
                onClicked: {
                    if (modelData.nmSettings && modelData.nmSettings.length > 0) modelData.nmSettings[0].forget();
                    delegateRoot.isExpanded = false;
                }
            }
        }
    }
}
