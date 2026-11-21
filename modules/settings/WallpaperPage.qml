// WallpaperPage.qml
// The wallpaper and how it's shown. Super + W picks one quickly.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  title: "Wallpaper"
  description: "Images from ~/Pictures/wallpapers, set with " + Wallpapers.tool + ". Videos aren't supported."
  resetAction: () => {
    Wallpapers.fit = "crop";
    Wallpapers.transition = "fade";
    Wallpapers.output = "";
    Wallpapers.rotate = false;
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 220
    radius: Theme.radiusCard
    color: Theme.item
    clip: true

    Image {
      anchors.fill: parent
      source: Wallpapers.currentPath !== "" ? "file://" + Wallpapers.currentPath : ""
      sourceSize.width: 1280
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Rectangle {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: 12
      implicitWidth: nameLabel.implicitWidth + 24
      implicitHeight: 30
      radius: Theme.r(15)
      color: Theme.alpha(Theme.crust, 0.75)
      Label { id: nameLabel; anchors.centerIn: parent; text: Wallpapers.currentPath.split("/").pop() || "No wallpaper"; font.pixelSize: Theme.font.small }
    }

    Button {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 12
      text: "Change… (Super + W)"
      variant: "primary"
      size: Theme.size.buttonList
      onClicked: {
        Panels.settingsOpen = false;
        Wallpapers.toggle(null);
      }
    }
  }

  SettingRow {
    title: "Screen"
    subtitle: "Where a new wallpaper goes."
    Segmented {
      model: ["All"].concat(Quickshell.screens.map(s => s.name))
      currentIndex: Math.max(0, ["", ...Quickshell.screens.map(s => s.name)].indexOf(Wallpapers.output))
      accessibleName: "Screen"
      onActivated: index => Wallpapers.output = index === 0 ? "" : Quickshell.screens[index - 1].name
    }
  }

  SettingRow {
    title: "Fit"
    subtitle: "Fill crops the edges; Fit shows the whole image."
    Segmented {
      model: ["Fill", "Fit"]
      currentIndex: Wallpapers.fit === "fit" ? 1 : 0
      accessibleName: "Fit"
      onActivated: index => Wallpapers.fit = index === 1 ? "fit" : "crop"
    }
  }

  SettingRow {
    title: "Transition"
    Segmented {
      model: ["Fade", "Wipe", "Grow"]
      currentIndex: Math.max(0, ["fade", "wipe", "grow"].indexOf(Wallpapers.transition))
      accessibleName: "Transition"
      onActivated: index => Wallpapers.transition = ["fade", "wipe", "grow"][index]
    }
  }

  SettingRow {
    title: "Videos pause on battery"
    subtitle: "Video wallpapers (mp4, webm, mkv) play muted and pause behind fullscreen windows and the lock screen; on battery they can pause too."
    Toggle {
      checked: Config.appearance.videoPauseOnBattery
      accessibleName: "Videos pause on battery"
      onToggled: value => Config.appearance.videoPauseOnBattery = value
    }
  }

  SettingRow {
    title: "Change every 30 minutes"
    subtitle: "Picks from your favourites first (Ctrl + F in the picker)."
    Toggle {
      checked: Wallpapers.rotate
      accessibleName: "Change every 30 minutes"
      onToggled: value => Wallpapers.rotate = value
    }
  }
}
