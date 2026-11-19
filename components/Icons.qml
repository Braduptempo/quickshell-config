// Icons.qml
// Stroke icons on a 24×24 grid, the same paths as in the design.
// Use them through Icon { name: "wifi" }.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  readonly property var paths: ({
    // network and devices
    "wifi": "M2 8.5a15 15 0 0 1 20 0M5 12a10 10 0 0 1 14 0M8.5 15.5a5 5 0 0 1 7 0M12 19h.01",
    "wifi-off": "M2 8.5a15 15 0 0 1 20 0M5 12a10 10 0 0 1 14 0M8.5 15.5a5 5 0 0 1 7 0M3 3l18 18",
    "ethernet": "M4 8h16v10H4zM8 8V5h8v3M8 18v2M16 18v2",
    "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
    "headphones": "M3 14v-2a9 9 0 0 1 18 0v2M3 14h3v6H3zM18 14h3v6h-3z",
    "monitor": "M3 4h18v12H3zM8 20h8M12 16v4",
    "usb": "M8 2h8v6H8zM6 8h12v12a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2z",
    "keyboard": "M2 6h20v12H2zM6 10h.01M10 10h.01M14 10h.01M18 10h.01M7 14h10",
    // audio
    "volume": "M11 5 6 9H2v6h4l5 4zM15.5 8.5a5 5 0 0 1 0 7",
    "volume-high": "M11 5 6 9H2v6h4l5 4zM15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14",
    "volume-off": "M11 5 6 9H2v6h4l5 4zM22 9l-6 6M16 9l6 6",
    "mic": "M9 2h6v12H9zM5 10a7 7 0 0 0 14 0M12 17v4",
    "mic-off": "M9 2h6v12H9zM5 10a7 7 0 0 0 14 0M12 17v4M3 3l18 18",
    "music": "M9 18V5l12-2v13M9 18a3 3 0 1 1-6 0a3 3 0 1 1 6 0M21 16a3 3 0 1 1-6 0a3 3 0 1 1 6 0",
    "play": "M7 4v16l13-8z",
    "pause": "M6 4h4v16H6zM14 4h4v16h-4z",
    "next": "M5 4l10 8-10 8zM17 4h2v16h-2z",
    "previous": "M19 20 9 12l10-8zM5 4h2v16H5z",
    // system
    "power": "M12 2v10M18.4 6.6a9 9 0 1 1-12.8 0",
    "lock": "M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4",
    "logout": "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9",
    "restart": "M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5",
    "moon": "M21 13A9 9 0 1 1 11 3a7 7 0 0 0 10 10z",
    "sun": "M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
    "activity": "M3 12h4l3-8 4 16 3-8h4",
    "settings": "M4 7h10M18 7h2M4 17h4M12 17h8M16 5v4M10 15v4",
    "shield": "M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6zM9 12l2 2 4-4",
    "bell": "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.94 1.94 0 0 0 3.4 0",
    "calendar": "M3 5h18v16H3zM3 10h18M8 3v4M16 3v4",
    "clock": "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 7v5l3 2",
    "download": "M12 3v12M7 10l5 5 5-5M5 21h14",
    "clipboard": "M8 4h8v4H8zM16 6h2a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h2",
    "search": "M11 4a7 7 0 1 0 0 14a7 7 0 1 0 0-14M20 20l-3.5-3.5",
    "user": "M12 4a4 4 0 1 0 0 8a4 4 0 1 0 0-8M4 21a8 8 0 0 1 16 0",
    "camera": "M15 10l5-3v10l-5-3zM3 6h12v12H3z",
    "palette": "M12 2a10 10 0 1 0 0 20c1 0 2-1 2-2 0-.5-.2-1-.5-1.3-.3-.4-.5-.8-.5-1.2 0-1 .8-2 2-2h2a6 6 0 0 0 6-6c0-4.4-4.5-7.5-11-7.5z",
    "image": "M3 5h18v14H3zM21 16l-5-5-9 8",
    // generic
    "chevron-left": "M15 6l-6 6 6 6",
    "chevron-right": "M9 6l6 6-6 6",
    "chevron-down": "M6 9l6 6 6-6",
    "chevron-up": "M6 15l6-6 6 6",
    "close": "M6 6l12 12M18 6 6 18",
    "check": "M5 12l5 5 9-10",
    "plus": "M12 5v14M5 12h14",
    "minus": "M5 12h14",
    "arrow-right": "M5 12h14M13 6l6 6-6 6",
    "shuffle": "M16 3h5v5M4 20 21 3M21 16v5h-5M15 15l6 6M4 4l5 5",
    "star": "M12 3l2.8 5.7 6.2.9-4.5 4.4 1 6.2-5.5-2.9-5.5 2.9 1-6.2L3 9.6l6.2-.9z",
    "warning": "M12 3 2 20h20zM12 10v4M12 17h.01",
    "info": "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 11v5M12 8h.01"
  })

  readonly property var names: Object.keys(paths)
}
