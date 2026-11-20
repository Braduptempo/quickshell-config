// SettingsWindow.qml
// Settings (Super + ,): sections on the left, the chosen page on the right.
// Everything is saved to settings.json (or the shell's state folder) and
// applies right away. Esc or the cross closes it.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Panels.settingsOpen

  // [key, label, icon, section]; pages without a file yet show "coming soon"
  readonly property var sections: [
    { key: "theme", label: "Theme", icon: "palette", group: "Appearance" },
    { key: "wallpaper", label: "Wallpaper", icon: "image", group: "Appearance" },
    { key: "font", label: "Font", icon: "text", group: "Appearance" },
    { key: "bar", label: "Bar & panels", icon: "window", group: "Appearance" },
    { key: "animations", label: "Animations", icon: "activity", group: "Appearance" },
    { key: "sound", label: "Sound", icon: "volume", group: "System", soon: "Devices, per-app volume and sounds. Quick settings has the volume sliders already." },
    { key: "network", label: "Network & Bluetooth", icon: "wifi", group: "System", soon: "Saved networks and devices. Quick settings handles connecting for now." },
    { key: "notifications", label: "Notifications", icon: "bell", group: "System" },
    { key: "calendars", label: "Calendars", icon: "calendar", group: "System", soon: "Syncing online calendars into the clock panel." },
    { key: "displays", label: "Displays", icon: "monitor", group: "System", soon: "Resolution, scale and arrangement of your monitors." },
    { key: "nightlight", label: "Night light", icon: "moon", group: "System", soon: "Schedule and colour temperature. Quick settings can turn it on already." },
    { key: "input", label: "Keyboard & mouse", icon: "keyboard", group: "System", soon: "Layouts, repeat rate and pointer speed." },
    { key: "power", label: "Power & idle", icon: "power", group: "System" },
    { key: "privacy", label: "Privacy & lock", icon: "shield", group: "System" },
    { key: "keybinds", label: "Keybinds", icon: "keyboard", group: "System", soon: "A list of every shortcut, and changing them." },
    { key: "apps", label: "Default apps", icon: "window", group: "System", soon: "Browser, terminal, file manager and editor." },
    { key: "about", label: "About", icon: "info", group: "System" }
  ]
  readonly property var current: sections.find(s => s.key === Panels.settingsPage) ?? sections[0]
  // The loaded page (a SettingsPage), for its reset action
  readonly property var page: pageLoader.item

  screen: Panels.settingsScreen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-settings"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // No anchors: the compositor centres it
  implicitWidth: 1120 + 24
  implicitHeight: 740 + 24

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.settingsOpen = false
  }

  onShownChanged: if (shown) card.forceActiveFocus()

  GlassPanel {
    id: card

    x: 12
    width: 1120
    height: 740
    radius: 20
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.86))
    clip: true
    focus: true

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown ? 0 : 10)
    scale: window.shown ? 1 : 0.98

    Accessible.role: Accessible.Dialog
    Accessible.name: "Settings"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on color { ColorAnimation { duration: Theme.anim.toggle } }

    Keys.onEscapePressed: Panels.settingsOpen = false
    Keys.onUpPressed: window.step(-1)
    Keys.onDownPressed: window.step(1)

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // --- Sections ----------------------------------------------------------------------
      Rectangle {
        Layout.preferredWidth: 220
        Layout.fillHeight: true
        color: Theme.alpha(Theme.crust, 0.35)

        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 12
          anchors.topMargin: 16
          spacing: 1

          Label { text: "Settings"; kind: "title"; font.pixelSize: Theme.font.title + 1; Layout.leftMargin: 10; Layout.bottomMargin: 8 }

          Repeater {
            model: window.sections

            ColumnLayout {
              id: entry
              required property var modelData
              required property int index
              readonly property bool active: window.current.key === modelData.key
              readonly property bool firstOfGroup: index === 0 || window.sections[index - 1].group !== modelData.group

              Layout.fillWidth: true
              spacing: 0

              Label {
                visible: entry.firstOfGroup
                text: entry.modelData.group
                kind: "label"
                Layout.leftMargin: 10
                Layout.topMargin: entry.index === 0 ? 0 : 10
                Layout.bottomMargin: 4
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.pill(height)
                color: entry.active ? Theme.alpha(Theme.text, 0.09) : entryMouse.containsMouse ? Theme.item : "transparent"

                Accessible.role: Accessible.PageTab
                Accessible.name: entry.modelData.label
                Accessible.selected: entry.active

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10
                  Icon { name: entry.modelData.icon; size: 15; color: entry.active ? Theme.accent : Theme.subtext }
                  Label {
                    Layout.fillWidth: true
                    text: entry.modelData.label
                    font.pixelSize: Theme.font.small + 1
                    font.weight: entry.active ? Font.Bold : Font.Normal
                    color: entry.modelData.soon ? Theme.subtext : Theme.text
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: entryMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Panels.settingsPage = entry.modelData.key
                }
              }
            }
          }

          Item { Layout.fillHeight: true }

          Row {
            Layout.leftMargin: 10
            spacing: 8
            Kbd { text: "Super + ," }
            Label { text: "opens Settings"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter }
          }
        }
      }

      // --- The page ------------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Loader {
          id: pageLoader
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.margins: 24
          Layout.bottomMargin: 12
          sourceComponent: {
            switch (window.current.key) {
            case "theme": return themePage;
            case "wallpaper": return wallpaperPage;
            case "font": return fontPage;
            case "animations": return animationsPage;
            case "bar": return barPage;
            case "notifications": return notificationsPage;
            case "power": return powerPage;
            case "privacy": return privacyPage;
            case "about": return aboutPage;
            default: return soonPage;
            }
          }
        }

        // Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 60
          color: "transparent"

          Rectangle { width: parent.width; height: 1; color: Theme.hairline }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 16
            spacing: 10

            Label {
              Layout.fillWidth: true
              text: "Saved to " + Quickshell.shellPath("settings.json").replace(Quickshell.env("HOME"), "~") + " · changes apply right away"
              kind: "muted"
              font.pixelSize: Theme.font.small
              elide: Text.ElideRight
            }
            Button {
              visible: window.page?.resetAction ? true : false
              text: "Reset this page"
              variant: "ghost"
              size: Theme.size.buttonList
              onClicked: window.page.resetAction()
            }
            IconButton {
              icon: "close"
              size: 34
              accessibleName: "Close settings"
              onClicked: Panels.settingsOpen = false
            }
          }
        }
      }
    }
  }

  function step(direction: int): void {
    const index = sections.findIndex(s => s.key === current.key);
    const next = (index + direction + sections.length) % sections.length;
    Panels.settingsPage = sections[next].key;
  }

  Component { id: themePage; ThemePage {} }
  Component { id: wallpaperPage; WallpaperPage {} }
  Component { id: fontPage; FontPage {} }
  Component { id: animationsPage; AnimationsPage {} }
  Component { id: barPage; BarPage {} }
  Component { id: notificationsPage; NotificationsPage {} }
  Component { id: powerPage; PowerPage {} }
  Component { id: privacyPage; PrivacyPage {} }
  Component { id: aboutPage; AboutPage {} }
  Component {
    id: soonPage
    SoonPage {
      title: window.current.label
      hint: window.current.soon ?? ""
    }
  }
}
