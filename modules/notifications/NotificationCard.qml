// NotificationCard.qml
// One notification: app icon or image, app and time, title, text, the app's
// action buttons and (when the app supports it) an inline reply.
// Used for the pop-ups and for the history in the clock panel.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../config"
import "../../components"
import "../../services"

Rectangle {
  id: root

  required property Notification notification
  // Pop-ups show fewer lines of text than the history
  property int maxLines: 3
  property bool glass: true
  // Cards behind the top one in a pile only show their edge
  property bool contentVisible: true
  // Pop-ups float over anything, so they are less see-through than panels
  property real fill: Theme.glass

  readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
  readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")

  // A picture on disk (a screenshot from any tool): it gets an Edit button
  // that opens it in the drawing editor, unless the app has its own Edit
  readonly property string pictureFile: {
    const candidates = [notification?.image ?? "", (notification ? notification.hints["image-path"] : "") ?? "", notification?.appIcon ?? ""];
    for (const c of candidates) {
      const path = String(c).replace(/^file:\/\//, "");
      if (path.startsWith("/") && /\.(png|jpe?g|webp)$/i.test(path)) return path;
    }
    return "";
  }
  readonly property bool canEdit: pictureFile !== "" && !buttons.some(a => (a?.text ?? "").toLowerCase() === "edit")
  readonly property string iconSource: {
    const icon = notification?.appIcon ?? "";
    if (icon === "") return "";
    return icon.startsWith("/") || icon.startsWith("file:") ? icon : Quickshell.iconPath(icon, true);
  }

  signal activated()

  implicitHeight: layout.implicitHeight + 24
  radius: Theme.radiusPanel
  color: glass ? Theme.alpha(Theme.base, fill) : Theme.item
  border.width: 1
  border.color: critical ? Theme.error : glass ? Theme.border : "transparent"

  Accessible.role: Accessible.Notification
  Accessible.name: (notification?.appName ?? "") + ": " + (notification?.summary ?? "") + ". " + (notification?.body ?? "")

  // Click on the card: the app's default action, or the clock panel
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }

  RowLayout {
    id: layout
    x: 12
    y: 12
    width: parent.width - 24
    spacing: 12
    opacity: root.contentVisible ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

    // --- Icon: notification image, app icon, or the app's first letter ---
    Item {
      Layout.alignment: Qt.AlignTop
      implicitWidth: 40
      implicitHeight: 40

      ClippingRectangle {
        anchors.fill: parent
        radius: Theme.r(20)
        color: root.critical ? Theme.error : Theme.accent

        Label {
          anchors.centerIn: parent
          visible: image.status !== Image.Ready && appIcon.status !== Image.Ready
          text: (root.notification?.appName ?? "?").charAt(0).toUpperCase()
          kind: "title"
          color: Theme.onAccent
        }

        Image {
          id: image
          anchors.fill: parent
          source: root.notification?.image ?? ""
          fillMode: Image.PreserveAspectCrop
          visible: status === Image.Ready
          asynchronous: true
        }
      }

      IconImage {
        id: appIcon
        visible: image.status !== Image.Ready && status === Image.Ready
        anchors.centerIn: parent
        implicitSize: 40
        source: root.iconSource
        asynchronous: true
      }

      // Small app icon on top of a picture (e.g. a contact photo)
      IconImage {
        visible: image.status === Image.Ready && root.iconSource !== ""
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -2
        implicitSize: 16
        source: root.iconSource
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3

      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Label {
          text: root.notification?.appName || "Notification"
          kind: "muted"
          font.pixelSize: Theme.font.label
          color: root.critical ? Theme.error : Theme.subtext
          Layout.fillWidth: true
        }

        Label {
          text: Notifications.timeOf(root.notification)
          kind: "muted"
          font.pixelSize: Theme.font.label
        }

        IconButton {
          icon: "close"
          size: 24
          variant: "plain"
          accessibleName: "Dismiss notification"
          onClicked: Notifications.dismiss(root.notification)
        }
      }

      Label {
        visible: text !== ""
        text: root.notification?.summary ?? ""
        font.weight: Font.Bold
        wrapMode: Text.Wrap
        maximumLineCount: 2
        Layout.fillWidth: true
      }

      Label {
        visible: text !== ""
        text: root.notification?.body ?? ""
        kind: "muted"
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: root.maxLines
        elide: Text.ElideRight
        linkColor: Theme.accent
        onLinkActivated: link => Qt.openUrlExternally(link)
        Layout.fillWidth: true
      }

      // Progress the app reports (downloads, copies): the "value" hint, 0 … 100
      Rectangle {
        readonly property var value: root.notification?.hints?.value
        visible: value !== undefined && value !== null && !isNaN(value)
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 6
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.text, 0.1)
        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, parent.value ?? 0)) / 100
          height: parent.height
          radius: parent.radius
          color: Theme.accent
        }
      }

      // The app's own buttons ("Reply", "Mark as read", "Open"…)
      Flow {
        visible: root.buttons.length > 0 || root.canEdit
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 6

        Button {
          visible: root.canEdit
          text: "Edit"
          icon: "pencil"
          size: Theme.size.buttonList
          variant: "ghost"
          onClicked: {
            Annotate.edit(root.pictureFile);
            Notifications.hidePopup(root.notification);
          }
        }

        Repeater {
          model: root.buttons

          Button {
            required property NotificationAction modelData
            // The action can disappear for a moment while the app closes it
            text: modelData?.text ?? ""
            size: Theme.size.buttonList
            variant: "ghost"
            onClicked: modelData?.invoke()
          }
        }
      }

      // Inline reply, e.g. chat apps
      RowLayout {
        visible: root.notification?.hasInlineReply ?? false
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 6

        TextField {
          id: reply
          Layout.fillWidth: true
          placeholder: root.notification?.inlineReplyPlaceholder || "Reply"
          onAccepted: sendButton.clicked()
        }

        IconButton {
          id: sendButton
          icon: "arrow-right"
          size: Theme.size.input
          variant: "primary"
          accessibleName: "Send reply"
          onClicked: {
            if (reply.text === "") return;
            root.notification.sendInlineReply(reply.text);
            reply.text = "";
          }
        }
      }
    }
  }
}
