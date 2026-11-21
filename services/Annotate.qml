// Annotate.qml
// Which screenshot is open in the editor (modules/capture/Annotator.qml).
//   Annotate.edit("/path/to/shot.png")  opens it
//   `qs ipc call capture edit <file>` does the same; capture.sh calls it
//   from the "Edit" action on its notification, or right after a shot when
//   "Edit" is on in the capture toolbar.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  property string file: ""
  readonly property bool open: file !== ""

  // `qs ipc call capture editSave` / `editCopy`: the editor's Save and Copy
  signal finishRequested(bool copy)

  function edit(path: string): void {
    // A new edit always starts fresh, even for the same file
    file = "";
    file = path.replace(/^file:\/\//, "");
  }

  function close(): void {
    file = "";
  }
}
