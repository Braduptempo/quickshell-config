// AnimationsPage.qml
// How fast things move, and how panels open.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"

SettingsPage {
  id: page
  title: "Animations"
  description: "Off makes everything appear at once, which is also easier on the eyes."
  resetAction: () => {
    Config.animations.speed = 2;
    Config.animations.rate = 1;
    Config.animations.panelStyle = "slide";
  }

  // The slider runs 0.25× … 2×; 1× (normal) sits at 0.43
  function toRate(v: real): real {
    return Math.round((0.25 + v * 1.75) * 20) / 20;
  }
  function fromRate(rate: real): real {
    return (rate - 0.25) / 1.75;
  }

  SettingRow {
    title: "Animations"
    subtitle: "For panels, pop-ups, the bar, sliders and the workspaces."
    Toggle {
      checked: Config.animations.speed !== 0
      accessibleName: "Animations"
      onToggled: value => Config.animations.speed = value ? 2 : 0
    }
  }

  SettingRow {
    visible: Config.animations.speed !== 0
    title: "Speed"
    subtitle: "Slower to the left, faster to the right. 1× is normal."
    PillSlider {
      width: 240
      icon: "clock"
      label: "Animation speed"
      // The old Slow / Fast steps show where they were
      value: page.fromRate(Theme.speed > 0 ? 1 / Theme.speed : 1)
      step: 0.05
      throttle: 60
      formatValue: v => page.toRate(v).toFixed(2).replace(/0$/, "") + "×"
      onMoved: v => {
        Config.animations.speed = 2;
        Config.animations.rate = page.toRate(v);
      }
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
