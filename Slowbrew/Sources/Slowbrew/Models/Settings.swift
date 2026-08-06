// Settings.swift
// Slowbrew
//
// User-configurable preferences for Slowbrew, persisted via SettingsStore.

import Foundation

/// User-configurable preferences for Slowbrew.
///
/// `Settings` is a value type (`struct`) conforming to `Codable` and
/// `Equatable`. All mutation goes through `SettingsStore.save(_:)`, which
/// validates ranges before persisting.
///
/// Range rules (enforced by `SettingsStore`):
/// - `breakInterval`: 15 – 180 (whole minutes)
/// - `breakDuration`: 1 – 30 (whole minutes)
struct Settings: Codable, Equatable {

    // MARK: - Range Constants

    /// The minimum allowed break interval in minutes.
    static let breakIntervalMin: Int = 15

    /// The maximum allowed break interval in minutes.
    static let breakIntervalMax: Int = 180

    /// The minimum allowed break duration in minutes.
    static let breakDurationMin: Int = 1

    /// The maximum allowed break duration in minutes.
    static let breakDurationMax: Int = 30

    // MARK: - Stored Properties

    /// How often a break should occur, in whole minutes.
    ///
    /// Valid range: `breakIntervalMin...breakIntervalMax` (15 – 180).
    var breakInterval: Int

    /// How long each break lasts, in whole minutes.
    ///
    /// Valid range: `breakDurationMin...breakDurationMax` (1 – 30).
    var breakDuration: Int

    /// Whether the app should launch automatically at macOS login.
    ///
    /// Default: `false`. Wired to `SMAppService` registration.
    var launchAtLogin: Bool

    /// Whether sound effects (chimes and ambient audio) are enabled.
    ///
    /// Default: `true`. When `false`, `AudioEngine` suppresses all output.
    var soundEnabled: Bool

    // MARK: - Default

    /// Factory-default settings used on first launch.
    static let `default` = Settings(
        breakInterval: 60,
        breakDuration: 5,
        launchAtLogin: false,
        soundEnabled: true
    )

    // MARK: - Computed Duration Helpers

    /// The break interval expressed as a `Duration` (seconds).
    ///
    /// Used by `TimerService` to configure the sleep interval.
    ///
    /// ```swift
    /// Settings.default.breakIntervalDuration // → .seconds(3600)
    /// ```
    var breakIntervalDuration: Duration {
        .seconds(breakInterval * 60)
    }

    /// The break duration expressed as a `Duration` (seconds).
    ///
    /// Used by the countdown HUD and `StateMachine` to know when to fire
    /// `countdownExpired`.
    ///
    /// ```swift
    /// Settings.default.breakDurationDuration // → .seconds(300)
    /// ```
    var breakDurationDuration: Duration {
        .seconds(breakDuration * 60)
    }
}

// MARK: - CustomStringConvertible

extension Settings: CustomStringConvertible {
    var description: String {
        "Settings(breakInterval: \(breakInterval)min, breakDuration: \(breakDuration)min, " +
        "launchAtLogin: \(launchAtLogin), soundEnabled: \(soundEnabled))"
    }
}
