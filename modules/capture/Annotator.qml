// Annotator.qml
// Draw on a screenshot before saving or copying it (Annotate.file): arrows,
// boxes, the pen, text, numbered steps, a highlighter, blur over private
// details, and crop. Undo / redo; Save overwrites the shot (or saves a new
// one for a copied-only shot), Copy puts the result on the clipboard.
// Keys: A R P T N H B C pick a tool · Ctrl+Z / Ctrl+Shift+Z · Enter copies ·
// Esc discards (or cancels the text being typed).
// Everything is drawn in the image's own pixels, so the result stays sharp
// at any zoom; the view only scales it to fit the screen.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Annotate.open

  // --- Tools ------------------------------------------------------------------------------
  readonly property var tools: [
    { key: "arrow", label: "Arrow", icon: "arrow-diag", shortcut: Qt.Key_A, hint: "drag to draw an arrow" },
    { key: "rect", label: "Rectangle", icon: "square", shortcut: Qt.Key_R, hint: "drag to draw a box" },
    { key: "pen", label: "Pen", icon: "pencil", shortcut: Qt.Key_P, hint: "draw freely" },
    { key: "text", label: "Text", icon: "text", shortcut: Qt.Key_T, hint: "click to add text, Enter to place it" },
    { key: "step", label: "Numbered step", icon: "step", shortcut: Qt.Key_N, hint: "click to add 1, 2, 3…" },
    { key: "highlight", label: "Highlight", icon: "highlight", shortcut: Qt.Key_H, hint: "drag to highlight" },
    { key: "blur", label: "Blur", icon: "pixels", shortcut: Qt.Key_B, hint: "drag over private info" },
    { key: "crop", label: "Crop", icon: "crop", shortcut: Qt.Key_C, hint: "drag the part to keep" }
  ]
  readonly property var colors: [
    { label: "Red", value: Theme.palette.error },
    { label: "Yellow", value: Theme.palette.warn },
    { label: "Green", value: Theme.palette.good },
    { label: "Blue", value: Theme.palette.accent },
    { label: "White", value: "#f5f5f5" }
  ]
  readonly property var sizes: [{ label: "Thin", dot: 4 }, { label: "Medium", dot: 7 }, { label: "Thick", dot: 10 }]

  property string tool: "arrow"
  property int colorIndex: 0
  property int sizeIndex: 1
  readonly property color penColor: colors[colorIndex].value

  // Annotations, in image pixels: { type, color, size, x1, y1, x2, y2, points, text, n }
  property var items: []
  property var redoStack: []
  // The one being drawn
  property var current: null

  readonly property var crop: {
    for (let i = items.length - 1; i >= 0; i--) if (items[i].type === "crop") return items[i];
    return null;
  }
  readonly property rect cropRect: crop ? Qt.rect(Math.min(crop.x1, crop.x2), Math.min(crop.y1, crop.y2),
                                                    Math.abs(crop.x2 - crop.x1), Math.abs(crop.y2 - crop.y1))
                                        : Qt.rect(0, 0, image.sourceSize.width, image.sourceSize.height)

  // On screen a stroke always looks thin / medium / thick, whatever the zoom
  readonly property real zoom: view.scaleFactor
  function stroke(size: int): real {
    return [3, 5, 8][size] / zoom;
  }
  function fontPx(size: int): real {
    return [16, 22, 30][size] / zoom;
  }

  function add(item: var): void {
    items = items.concat([item]);
    redoStack = [];
  }
  function undo(): void {
    if (items.length === 0) return;
    redoStack = redoStack.concat([items[items.length - 1]]);
    items = items.slice(0, -1);
  }
  function redo(): void {
    if (redoStack.length === 0) return;
    items = items.concat([redoStack[redoStack.length - 1]]);
    redoStack = redoStack.slice(0, -1);
  }

  onShownChanged: {
    items = [];
    redoStack = [];
    current = null;
    textInput.visible = false;
    if (shown) keys.forceActiveFocus();
    // QS_FAKE=annotate-demo: one of each, for testing without a mouse
    if (shown && Fake.has("annotate-demo")) demo.start();
  }

  Timer {
    id: demo
    interval: 300
    onTriggered: {
      const w = image.sourceSize.width, h = image.sourceSize.height;
      const c = window.colors.map(c => c.value.toString());
      window.items = [
        { type: "blur", x1: w * 0.55, y1: h * 0.1, x2: w * 0.9, y2: h * 0.3 },
        { type: "highlight", color: c[1], size: 1, x1: w * 0.08, y1: h * 0.62, x2: w * 0.5, y2: h * 0.72 },
        { type: "rect", color: c[0], size: 1, x1: w * 0.05, y1: h * 0.1, x2: w * 0.42, y2: h * 0.45 },
        { type: "arrow", color: c[0], size: 2, x1: w * 0.7, y1: h * 0.8, x2: w * 0.45, y2: h * 0.48 },
        { type: "step", color: c[3], size: 1, n: 1, x1: w * 0.05, y1: h * 0.1, x2: 0, y2: 0 },
        { type: "text", color: c[4], size: 2, x1: w * 0.52, y1: h * 0.82, x2: 0, y2: 0, text: "Click here first" },
        { type: "pen", color: c[2], size: 1, x1: 0, y1: 0, x2: 0, y2: 0,
          points: [0, 1, 2, 3, 4, 5, 6, 7, 8].map(i => ({ x: w * (0.1 + i * 0.03), y: h * (0.88 - (i % 2) * 0.04) })) }
      ];
    }
  }

  screen: Panels.focusedScreen()
  visible: shown
  color: Theme.alpha(Theme.crust, 0.72)

  WlrLayershell.namespace: "quickshell-annotate"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true
    Keys.onPressed: event => {
      const ctrl = event.modifiers & Qt.ControlModifier;
      if (ctrl && event.key === Qt.Key_Z) {
        if (event.modifiers & Qt.ShiftModifier) window.redo();
        else window.undo();
      } else if (ctrl && event.key === Qt.Key_Y) {
        window.redo();
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        window.finish(true);
      } else if (event.key === Qt.Key_Escape) {
        Annotate.close();
      } else {
        const t = window.tools.find(t => t.shortcut === event.key);
        if (!t) return;
        window.tool = t.key;
      }
      event.accepted = true;
    }
  }

  // --- Saving ------------------------------------------------------------------------------
  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
  property bool copyAfter: false

  // Copy (Enter) or Save: render the picture (cropped) and write it
  function finish(copy: bool): void {
    if (textInput.visible) commitText();
    copyAfter = copy;
    const r = cropRect;
    exportView.width = r.width;
    exportView.height = r.height;
    exportView.grabToImage(result => {
      const inTemp = Annotate.file.startsWith(window.runtimeDir);
      const target = copy ? window.runtimeDir + "/quickshell-annotated.png"
                   : inTemp ? "" : Annotate.file;
      if (target !== "") {
        result.saveToFile(target);
        window.done(target, copy);
      } else {
        // A copied-only shot has no place yet: a new one in Screenshots
        saveProc.result = result;
        saveProc.running = true;
      }
    }, Qt.size(r.width, r.height));
  }

  Connections {
    target: Annotate
    function onFinishRequested(copy: bool) { if (window.shown) window.finish(copy); }
  }

  function done(file: string, copy: bool): void {
    if (copy) Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < \"$1\"", "sh", file]);
    Quickshell.execDetached(["notify-send", "-a", "Screenshot", "-i", file, copy ? "Copied with your drawing" : "Saved with your drawing", copy ? "Paste it anywhere" : file.split("/").pop()]);
    Annotate.close();
  }

  Process {
    id: saveProc
    property var result: null
    command: ["sh", "-c", "d=\"${QS_CAPTURE_DIR:-$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots}\"; mkdir -p \"$d\"; echo \"$d/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png\""]
    stdout: StdioCollector {
      onStreamFinished: {
        const path = text.trim();
        if (path === "" || !saveProc.result) return;
        saveProc.result.saveToFile(path);
        window.done(path, false);
      }
    }
  }

  // The finished picture for saving: the annotated image, cropped. Off the
  // visible card, but rendered, so grabToImage has something to grab.
  Item {
    id: exportView
    x: -width - 100
    ShaderEffectSource {
      anchors.fill: parent
      sourceItem: paperContent
      sourceRect: window.cropRect
      hideSource: false
      live: true
    }
  }

  // --- The editor ---------------------------------------------------------------------------
  GlassPanel {
    id: card
    color: Theme.panelSolid
    anchors.centerIn: parent
    width: column.implicitWidth + 32
    height: column.implicitHeight + 32
    radius: Theme.radiusPanel

    Accessible.role: Accessible.Dialog
    Accessible.name: "Screenshot editor"

    ColumnLayout {
      id: column
      x: 16
      y: 16
      spacing: 12

      // Tools · colours · sizes · undo / redo
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
          model: window.tools
          IconButton {
            required property var modelData
            icon: modelData.icon
            size: 34
            checked: window.tool === modelData.key
            accessibleName: modelData.label + " (" + String.fromCharCode(modelData.shortcut) + ")"
            onClicked: window.tool = modelData.key
          }
        }

        Rectangle { implicitWidth: 1; implicitHeight: 24; color: Theme.border; Layout.leftMargin: 4; Layout.rightMargin: 4 }

        Repeater {
          model: window.penColors
          Rectangle {
            id: swatch
            required property var modelData
            required property int index
            implicitWidth: 22
            implicitHeight: 22
            radius: Theme.pill(height)
            color: modelData.value
            border.width: window.penColorIndex === index ? 2 : 0
            border.color: Theme.text
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData.label
            Accessible.checked: window.penColorIndex === index
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: window.penColorIndex = swatch.index }
          }
        }

        Rectangle { implicitWidth: 1; implicitHeight: 24; color: Theme.border; Layout.leftMargin: 4; Layout.rightMargin: 4 }

        Repeater {
          model: window.sizes
          Rectangle {
            id: sizeButton
            required property var modelData
            required property int index
            implicitWidth: 30
            implicitHeight: 30
            radius: Theme.pill(height)
            color: window.sizeIndex === index ? Theme.overlay : "transparent"
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData.label
            Accessible.checked: window.sizeIndex === index
            Rectangle { anchors.centerIn: parent; width: sizeButton.modelData.dot; height: width; radius: width / 2; color: Theme.text }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: window.sizeIndex = sizeButton.index }
          }
        }

        Item { Layout.fillWidth: true }

        IconButton { icon: "undo"; size: 34; accessibleName: "Undo (Ctrl+Z)"; opacity: window.items.length > 0 ? 1 : 0.4; onClicked: window.undo() }
        IconButton { icon: "redo"; size: 34; accessibleName: "Redo (Ctrl+Shift+Z)"; opacity: window.redoStack.length > 0 ? 1 : 0.4; onClicked: window.redo() }
      }

      // --- The picture --------------------------------------------------------------------
      Item {
        id: view
        readonly property real maxW: (window.screen ? window.screen.width : 1920) - 160
        readonly property real maxH: (window.screen ? window.screen.height : 1080) - 240
        readonly property real scaleFactor: image.sourceSize.width > 0
          ? Math.min(1, maxW / image.sourceSize.width, maxH / image.sourceSize.height) : 1
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Math.max(560, image.sourceSize.width * scaleFactor)
        implicitHeight: Math.max(120, image.sourceSize.height * scaleFactor)
        clip: true

        // The picture at its own size, scaled to fit
        Item {
          id: paper
          width: image.sourceSize.width
          height: image.sourceSize.height
          anchors.centerIn: parent
          transform: Scale {
            origin.x: paper.width / 2
            origin.y: paper.height / 2
            xScale: view.scaleFactor
            yScale: view.scaleFactor
          }

          // What gets saved: the image, the blurs and the drawing
          Item {
            id: paperContent
            anchors.fill: parent

            Image {
              id: image
              anchors.fill: parent
              source: Annotate.file !== "" ? "file://" + Annotate.file : ""
              cache: false
              smooth: true
            }

            // Blur: the image under it, at a fraction of its size
            Repeater {
              model: window.items.filter(i => i.type === "blur").concat(window.current && window.current.type === "blur" ? [window.current] : [])
              ShaderEffectSource {
                id: pixelated
                required property var modelData
                readonly property real bx: Math.min(modelData.x1, modelData.x2)
                readonly property real by: Math.min(modelData.y1, modelData.y2)
                readonly property real bw: Math.max(1, Math.abs(modelData.x2 - modelData.x1))
                readonly property real bh: Math.max(1, Math.abs(modelData.y2 - modelData.y1))
                x: bx
                y: by
                width: bw
                height: bh
                sourceItem: image
                sourceRect: Qt.rect(bx, by, bw, bh)
                textureSize: Qt.size(Math.max(1, Math.round(bw / 14)), Math.max(1, Math.round(bh / 14)))
                smooth: false
                hideSource: false
              }
            }

            Canvas {
              id: ink
              anchors.fill: parent
              renderStrategy: Canvas.Cooperative

              function arrow(ctx: var, a: var): void {
                const w = window.stroke(a.size);
                const ang = Math.atan2(a.y2 - a.y1, a.x2 - a.x1);
                const head = w * 4;
                ctx.lineWidth = w;
                ctx.beginPath();
                ctx.moveTo(a.x1, a.y1);
                ctx.lineTo(a.x2 - Math.cos(ang) * head * 0.6, a.y2 - Math.sin(ang) * head * 0.6);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(a.x2, a.y2);
                ctx.lineTo(a.x2 - head * Math.cos(ang - 0.45), a.y2 - head * Math.sin(ang - 0.45));
                ctx.lineTo(a.x2 - head * Math.cos(ang + 0.45), a.y2 - head * Math.sin(ang + 0.45));
                ctx.closePath();
                ctx.fill();
              }

              function draw(ctx: var, a: var): void {
                ctx.strokeStyle = a.color;
                ctx.fillStyle = a.color;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                const x = Math.min(a.x1, a.x2), y = Math.min(a.y1, a.y2);
                const w = Math.abs(a.x2 - a.x1), h = Math.abs(a.y2 - a.y1);
                switch (a.type) {
                case "arrow": arrow(ctx, a); break;
                case "rect":
                  ctx.lineWidth = window.stroke(a.size);
                  ctx.strokeRect(x, y, w, h);
                  break;
                case "highlight":
                  ctx.globalAlpha = 0.35;
                  ctx.fillRect(x, y, w, h);
                  ctx.globalAlpha = 1;
                  break;
                case "pen":
                  ctx.lineWidth = window.stroke(a.size);
                  ctx.beginPath();
                  for (let i = 0; i < a.points.length; i++) {
                    if (i === 0) ctx.moveTo(a.points[i].x, a.points[i].y);
                    else ctx.lineTo(a.points[i].x, a.points[i].y);
                  }
                  ctx.stroke();
                  break;
                case "step": {
                  const r = window.fontPx(a.size) * 0.85;
                  ctx.beginPath();
                  ctx.arc(a.x1, a.y1, r, 0, Math.PI * 2);
                  ctx.fill();
                  ctx.fillStyle = "#11111b";
                  ctx.font = "bold " + Math.round(r * 1.1) + "px '" + Theme.font.family + "'";
                  ctx.textAlign = "center";
                  ctx.textBaseline = "middle";
                  ctx.fillText(String(a.n), a.x1, a.y1 + 1);
                  break;
                }
                case "text": {
                  const px = window.fontPx(a.size);
                  ctx.font = "bold " + Math.round(px) + "px '" + Theme.font.family + "'";
                  ctx.textAlign = "left";
                  ctx.textBaseline = "top";
                  // A dark edge, so text reads on any background
                  ctx.lineWidth = px / 6;
                  ctx.strokeStyle = "rgba(0, 0, 0, 0.65)";
                  ctx.strokeText(a.text, a.x1, a.y1);
                  ctx.fillText(a.text, a.x1, a.y1);
                  break;
                }
                }
              }

              onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                for (const a of window.items) if (a.type !== "blur" && a.type !== "crop") draw(ctx, a);
                if (window.current && window.current.type !== "blur" && window.current.type !== "crop") draw(ctx, window.current);
              }

              Connections {
                target: window
                function onItemsChanged() { ink.requestPaint(); }
                function onCurrentChanged() { ink.requestPaint(); }
                function onZoomChanged() { ink.requestPaint(); }
              }
            }
          }

          // Crop: dims what's left out (not saved, it's only a guide)
          Item {
            anchors.fill: parent
            visible: window.crop !== null || (window.current !== null && window.current.type === "crop")
            readonly property rect r: window.current && window.current.type === "crop"
              ? Qt.rect(Math.min(window.current.x1, window.current.x2), Math.min(window.current.y1, window.current.y2),
                        Math.abs(window.current.x2 - window.current.x1), Math.abs(window.current.y2 - window.current.y1))
              : window.cropRect
            Rectangle { x: 0; y: 0; width: parent.width; height: parent.r.y; color: "#99000000" }
            Rectangle { x: 0; y: parent.r.y + parent.r.height; width: parent.width; height: parent.height - y; color: "#99000000" }
            Rectangle { x: 0; y: parent.r.y; width: parent.r.x; height: parent.r.height; color: "#99000000" }
            Rectangle { x: parent.r.x + parent.r.width; y: parent.r.y; width: parent.width - x; height: parent.r.height; color: "#99000000" }
            Rectangle {
              x: parent.r.x
              y: parent.r.y
              width: parent.r.width
              height: parent.r.height
              color: "transparent"
              border.width: 2 / window.zoom
              border.color: "white"
            }
          }

          // Text being typed, where it will go
          TextInput {
            id: textInput
            visible: false
            color: window.penColor
            font.family: Theme.font.family
            font.bold: true
            font.pixelSize: window.fontPx(window.sizeIndex)
            Keys.onReturnPressed: window.commitText()
            Keys.onEnterPressed: window.commitText()
            Keys.onEscapePressed: {
              visible = false;
              text = "";
              keys.forceActiveFocus();
            }
            Rectangle {
              anchors.fill: parent
              anchors.margins: -4 / window.zoom
              z: -1
              color: "#66000000"
              border.width: 1 / window.zoom
              border.color: window.penColor
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: window.tool === "text" ? Qt.IBeamCursor : Qt.CrossCursor
            onPressed: mouse => {
              if (textInput.visible) window.commitText();
              const base = { type: window.tool, color: window.penColor.toString(), size: window.sizeIndex, x1: mouse.x, y1: mouse.y, x2: mouse.x, y2: mouse.y };
              if (window.tool === "step") {
                base.n = window.items.filter(i => i.type === "step").length + 1;
                window.add(base);
              } else if (window.tool === "text") {
                textInput.x = mouse.x;
                textInput.y = mouse.y;
                textInput.text = "";
                textInput.visible = true;
                textInput.forceActiveFocus();
              } else {
                if (window.tool === "pen") base.points = [{ x: mouse.x, y: mouse.y }];
                window.current = base;
              }
            }
            onPositionChanged: mouse => {
              if (!window.current) return;
              const c = Object.assign({}, window.current, { x2: mouse.x, y2: mouse.y });
              if (c.type === "pen") {
                const last = c.points[c.points.length - 1];
                if (Math.hypot(mouse.x - last.x, mouse.y - last.y) < 2 / window.zoom) return;
                c.points = c.points.concat([{ x: mouse.x, y: mouse.y }]);
              }
              window.current = c;
            }
            onReleased: {
              const c = window.current;
              window.current = null;
              if (!c) return;
              // A click without dragging draws nothing
              if (c.type !== "pen" && Math.abs(c.x2 - c.x1) < 3 && Math.abs(c.y2 - c.y1) < 3) return;
              window.add(c);
            }
          }
        }
      }

      // --- Footer -------------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Label {
          Layout.fillWidth: true
          text: Math.round(window.cropRect.width) + " × " + Math.round(window.cropRect.height) + " · "
                + (window.tools.find(t => t.key === window.tool)?.label ?? "") + ": " + (window.tools.find(t => t.key === window.tool)?.hint ?? "")
          kind: "muted"
          font.pixelSize: Theme.font.small
          elide: Text.ElideRight
        }
        Button { text: "Discard"; variant: "ghost"; onClicked: Annotate.close() }
        Button { text: "Save"; variant: "secondary"; onClicked: window.finish(false) }
        Button { text: "Copy ↵"; variant: "primary"; onClicked: window.finish(true) }
      }
    }
  }

  function commitText(): void {
    const t = textInput.text.trim();
    textInput.visible = false;
    textInput.text = "";
    keys.forceActiveFocus();
    if (t === "") return;
    add({ type: "text", color: penColor.toString(), size: sizeIndex, x1: textInput.x, y1: textInput.y, x2: textInput.x, y2: textInput.y, text: t });
  }
}
