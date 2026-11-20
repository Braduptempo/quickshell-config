// Sound.qml

import QtQuick
import Quickshell.Services.Pipewire
import "../../config"

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
            // Up to 150% when allowed in Settings → Sound
            defaultSink.audio.volume = Math.max(0, Math.min(Config.sound.maxVolume, val));
        }
    }

    function toggleMute() {
        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.muted = !defaultSink.audio.muted;
        }
    }

    // --- Microfoon ---
    property var defaultSource: Pipewire.defaultAudioSource
    readonly property real micVolume: defaultSource && defaultSource.audio 
        ? Math.round(defaultSource.audio.volume * 100) 
        : 0
    readonly property bool isMicMuted: defaultSource && defaultSource.audio ? defaultSource.audio.muted : false

    function toggleMicMute() {
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.muted = !defaultSource.audio.muted;
        }
    }

    function setMicVolume(val) {
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.volume = Math.max(0, Math.min(1, val));
        }
    }

    property var tracker: PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // --- New devices ---
    // Outputs (not app streams); a new one after start-up becomes the default
    // when Settings → Sound says so
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    property var knownSinks: []
    property bool started: false

    onSinksChanged: {
        const ids = sinks.map(n => n.id);
        if (started && Config.sound.followNewDevices) {
            const fresh = sinks.find(n => root.knownSinks.indexOf(n.id) < 0);
            if (fresh) Pipewire.preferredDefaultAudioSink = fresh;
        }
        knownSinks = ids;
    }

    // Devices that already exist at start-up don't count as new
    property var startTimer: Timer {
        interval: 3000
        running: true
        onTriggered: root.started = true
    }
}
