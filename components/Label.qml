// Label.qml
// Text with the theme's font and colours. `kind` picks the style:
// "body", "small", "title", "section", "label" (caps) or "muted".
import QtQuick
import "../config"

Text {
  property string kind: "body"

  color: kind === "muted" || kind === "label" ? Theme.subtext : Theme.text
  font.family: Theme.font.family
  font.pixelSize: {
    switch (kind) {
    case "label": return Theme.font.label;
    case "small":
    case "muted": return Theme.font.small;
    case "title": return Theme.font.title;
    case "section": return Theme.font.section;
    default: return Theme.font.body;
    }
  }
  font.weight: kind === "title" || kind === "section" || kind === "label" ? Font.Bold : Font.Normal
  font.letterSpacing: kind === "label" ? 1 : 0
  font.capitalization: kind === "label" ? Font.AllUppercase : Font.MixedCase
  // Clock and percentages keep the same width
  font.features: ({ "tnum": 1 })
  elide: Text.ElideRight
  verticalAlignment: Text.AlignVCenter

  Behavior on color {
    ColorAnimation { duration: Theme.anim.fast }
  }
}
