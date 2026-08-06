// AudioEngine.swift
// Slowbrew
//
// Audio playback disabled - placeholder implementation for future audio support.

import Foundation
import os.log

/// Placeholder audio engine (audio functionality disabled).
///
/// To enable audio:
/// 1. Add audio files to Resources/Audio/
/// 2. Uncomment AVFoundation implementation
/// 3. Wire to state machine events
final class AudioEngine {
    
    /// Whether sound effects are enabled (currently always false).
    var isMuted: Bool = true
    
    init() {
        os_log(.info, "AudioEngine initialized (audio disabled)")
    }
    
    /// Plays a one-shot chime sound (no-op).
    func playChime(_ chime: ChimeType) {
        // Audio disabled
    }
    
    /// Starts playing ambient sound loop (no-op).
    func startAmbient() {
        // Audio disabled
    }
    
    /// Stops ambient sound loop (no-op).
    func stopAmbient() {
        // Audio disabled
    }
    
    /// Stops all audio playback (no-op).
    func stopAll() {
        // Audio disabled
    }
}

// MARK: - ChimeType

/// The type of chime sound to play.
enum ChimeType {
    /// Played when the walk-in animation begins.
    case walkIn
    
    /// Played when the break ends and walk-out animation begins.
    case walkOut
}
