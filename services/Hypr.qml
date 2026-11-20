// Hypr.qml
// Hyprland actions. Hyprland 0.57 with a Lua config only accepts Lua in
// `dispatch` (e.g. `hl.dsp.focus({ workspace = 2 })`); the old
// `workspace 2` syntax fails silently. This picks the right form.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
  // target: a workspace id (2), or a relative target such as "m+1" / "e-1"
  function focusWorkspace(target: var): void {
    if (Hyprland.usingLua) {
      const value = typeof target === "number" ? String(target) : JSON.stringify(String(target));
      Hyprland.dispatch("hl.dsp.focus({ workspace = " + value + " })");
    } else {
      Hyprland.dispatch("workspace " + target);
    }
  }

  // Lua dispatcher when Hyprland runs a Lua config, otherwise the classic one
  function run(lua: string, classic: string): void {
    Hyprland.dispatch(Hyprland.usingLua ? lua : classic);
  }

  // These act on the focused window
  function windowFloat(): void {
    run("hl.dsp.window.float({ action = \"toggle\" })", "togglefloating");
  }

  function windowPseudo(): void {
    run("hl.dsp.window.pseudo()", "pseudo");
  }

  function windowClose(): void {
    run("hl.dsp.window.close()", "killactive");
  }

  function windowToWorkspace(workspace: int): void {
    run("hl.dsp.window.move({ workspace = " + workspace + " })", "movetoworkspace " + workspace);
  }

  function exit(): void {
    run("hl.dsp.exit()", "exit");
  }
}
