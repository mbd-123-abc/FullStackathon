// CountdownFormatter.swift
// Slowbrew
//
// Converts seconds to MM:SS countdown string format.

import Foundation

/// Converts integer seconds to MM:SS countdown string format.
///
/// Used by the BrewingHUD to display the remaining break time in a
/// human-readable format.
///
/// **Format guarantee:** All outputs match the regex `^\d{2}:\d{2}$`
/// (exactly two digits, colon, two digits) for inputs in `0...1800`.
///
/// **Examples:**
/// ```swift
/// CountdownFormatter.format(0)    // → "00:00"
/// CountdownFormatter.format(59)   // → "00:59"
/// CountdownFormatter.format(330)  // → "05:30"
/// CountdownFormatter.format(1800) // → "30:00"
/// ```
///
/// **Requirement:** 4.3 — Countdown display in MM:SS format.
enum CountdownFormatter {

    /// Formats the given number of seconds as a MM:SS string.
    ///
    /// - Parameter seconds: The remaining time in seconds (0...1800).
    /// - Returns: A string in the format `MM:SS` where MM and SS are
    ///   zero-padded to two digits.
    ///
    /// **Precondition:** `seconds >= 0`. Negative values are clamped to 0.
    static func format(_ seconds: Int) -> String {
        // Clamp negative values to 0 for safety
        let clampedSeconds = max(0, seconds)
        
        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60
        
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
