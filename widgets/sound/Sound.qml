// Sound.qml

import QtQuick
import Quickshell.Services.Pipewire

pragma Singleton

QtObject {
    id: root

    // --- Luidspreker ---
    property var defaultSink: Pipewire.defaultAudioSink
    readonly property real volume: defaultSink && defaultSink.audio 
        ? Math.round(defaultSink.audio.volume * 100) 
        : 0
    readonly property bool isMuted: defaultSink && defaultSink.audio ? defaultSink.audio.muted : false

    function setVolume(val) {
        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.volume = Math.max(0, Math.min(1, val));
        }
    }

    // --- Microfoon ---
    property var defaultSource: Pipewire.defaultAudioSource
    readonly property real micVolume: defaultSource && defaultSource.audio 
        ? Math.round(defaultSource.audio.volume * 100) 
        : 0
    readonly property bool isMicMuted: defaultSource && defaultSource.audio ? defaultSource.audio.muted : false

    function setMicVolume(val) {
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.volume = Math.max(0, Math.min(1, val));
        }
    }

    property var tracker: PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}
