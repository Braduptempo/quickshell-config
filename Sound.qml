import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

pragma Singleton

QtObject {
    id: root

    property PwNodeAudio audio
    property bool ismuted: false
    
   readonly property real volume: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100)
        : 0 
    

    property var tracker: PwObjectTracker { 
        objects: [Pipewire.defaultAudioSink]
    }

}
