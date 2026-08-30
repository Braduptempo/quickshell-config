// SoundDropdown.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Io

PopupWindow {
  id: popup
  color: "transparent"
  implicitWidth: 260
  implicitHeight: contentColumn.implicitHeight + 20

  HyprlandFocusGrab {
    active: popup.visible
    windows: [popup]
    onCleared: popup.visible = false
  }

  // Dit ene proces kan zowel luidsprekers als microfoons veranderen!
  Process {
    id: changeDeviceProcess
    property string targetId: ""
    command: ["wpctl", "set-default", targetId]
  }

  Item {
    width: parent.width
    height: parent.height
    opacity: popup.visible ? 1 : 0
    y: popup.visible ? 0 : -20

    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

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
      anchors.margins: 12
      spacing: 12

      Text {
        text: "Audio Instellingen"
        font.bold: true
        font.pixelSize: 14
        color: "white"
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: "#404040" }

      // LUIDSPREKER SLIDER
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
          Layout.fillWidth: true
          Text { text: "󰕾 Volume"; color: "#a0a0a0"; font.pixelSize: 11; Layout.fillWidth: true }
          Text { text: Sound.volume + "%"; color: "white"; font.pixelSize: 11; font.bold: true }
        }

        Slider {
          Layout.fillWidth: true
          from: 0; to: 100; value: Sound.volume
          onMoved: Sound.setVolume(value / 100)
        }
      }

      // MICROFOON SLIDER
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
          Layout.fillWidth: true
          Text { text: "󰍬 Microfoon"; color: "#a0a0a0"; font.pixelSize: 11; Layout.fillWidth: true }
          Text { text: Sound.micVolume + "%"; color: "white"; font.pixelSize: 11; font.bold: true }
        }

        Slider {
          Layout.fillWidth: true
          from: 0; to: 100; value: Sound.micVolume
          onMoved: Sound.setMicVolume(value / 100)
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: "#404040" }

      // --- UITVOER APPARATEN (SINKS) ---
      Text {
        text: "Uitvoer Apparaten"
        font.bold: true
        font.pixelSize: 11
        color: "#a0a0a0"
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: Pipewire.nodes.values.filter(n => n.audio && n.description !== "" && n.isSink)

          delegate: Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 4
            color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id) ? "#3b4252" : "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.margins: 6

              Text {
                text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id ? "󰓃 " : "  ") + modelData.description
                color: "white"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onEntered: parent.color = (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id) ? "#3b4252" : "#20ffffff"
              onExited: parent.color = (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id) ? "#3b4252" : "transparent"

              onClicked: {
                changeDeviceProcess.targetId = modelData.id.toString();
                changeDeviceProcess.running = true;
              }
            }
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: "#404040" }

      // --- INVOER APPARATEN (SOURCES/MICROFOONS) ---
      Text {
        text: "Invoer Apparaten"
        font.bold: true
        font.pixelSize: 11
        color: "#a0a0a0"
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          // GEFIXT: We pakken alles wat audio doet, géén luidspreker is (!n.isSink) en géén app is (!n.isStream)
          model: Pipewire.nodes.values.filter(n => n.audio && n.description !== "" && !n.isSink && !n.isStream)

          delegate: Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 4
            color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id) ? "#3b4252" : "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.margins: 6

              Text {
                text: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id ? "󰍬 " : "  ") + modelData.description
                color: "white"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onEntered: parent.color = (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id) ? "#3b4252" : "#20ffffff"
              onExited: parent.color = (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id) ? "#3b4252" : "transparent"

              onClicked: {
                // Werkt exact hetzelfde als bij luidsprekers!
                changeDeviceProcess.targetId = modelData.id.toString();
                changeDeviceProcess.running = true;
              }
            }
          }
        }
      }
    }
  }
}
