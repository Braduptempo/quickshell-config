//SoundWidget.qml

import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    implicitWidth: soundLayout.implicitWidth + 20
    implicitHeight: soundLayout.implicitHeight + 10

    Rectangle {
        anchors.fill: parent
        color: "#2a2a2c"
        border.color: "blue"
        border.width: 3
        radius: 15
    }

    RowLayout {
        id: soundLayout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        spacing: 8

        Text {
            font.family: "jetbrains mono"
            font.pixelSize: 11
            color: "#ffffff"
            text: (Sound.isMuted ? "󰖁 " : "󰕾 ") + Sound.volume + "%"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            soundMenu.visible = !soundMenu.visible;
        }
    }

    SoundDropdown {
        id: soundMenu
        visible: false
        anchor.window: panel
        anchor.item: root
        anchor.edges: panel.Edges.Bottom | panel.Edges.Right
        anchor.rect.y: 35 
        anchor.rect.x: -10
    }
}
