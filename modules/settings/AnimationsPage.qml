// AnimationsPage.qml
// How fast things move, and how panels open.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"

SettingsPage {
  title: "Animations"
  description: "Off makes everything appear at once, which is also easier on the eyes."
  resetAction: () => {
    Config.animations.speed = 2;
    Config.animations.panelStyle = "slide";
  }

  SettingRow {
    title: "Speed"
    subtitle: "For panels, pop-ups, sliders and the workspaces."
    Segmented {
      model: ["Off", "Slow", "Normal", "Fast"]
      currentIndex: Config.animations.speed
      accessibleName: "Animation speed"
      onActivated: index => Config.animations.speed = index
    }
  }

  SettingRow {
    title: "Panels open with"
    subtitle: "Quick settings, the media menu and other dropdowns."
    Segmented {
      model: ["Slide", "Fade", "Scale"]
      currentIndex: Math.max(0, ["slide", "fade", "scale"].indexOf(Config.animations.panelStyle))
      accessibleName: "Panel animation"
      onActivated: index => Config.animations.panelStyle = ["slide", "fade", "scale"][index]
    }
  }
}
