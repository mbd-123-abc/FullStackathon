// DailySnoozeState.swift
// Slowbrew
//
// Persisted snapshot of today's snooze usage, stored in UserDefaults.

import Foundation

/// A Codable snapshot of snooze usage for a single calendar day.
///
/// `DailySnoozeState` is persisted by `DailySnoozeCounter` in `UserDefaults`
/// under a stable key. On each app launch (and before each snooze action)
/// `DailySnoozeCounter.resetIfNewDay()` compares `date` to today's date
/// string and resets `usedCount` when a new calendar day has begun.
///
/// - Note: The `date` string uses `"yyyy-MM-dd"` format in the **device's
///   local calendar and timezone**, matching the behaviour specified in
///   Requirement 6.3 and 6.6.
struct DailySnoozeState: Codable, Equatable {

    // MARK: - Stored Properties

    /// Today's date formatted as `"yyyy-MM-dd"` in the device's local timezone.
    ///
    /// Example: `"2025-06-15"`
    var date: String

    /// How many snooze actions have been used today.
    ///
    /// Clamped to `DailySnoozeCounter.maxPerDay` (3) by `increment()`.
    /// Reset to `0` by `resetIfNewDay()` when the calendar day changes.
    var usedCount: Int

    // MARK: - Convenience

    /// A fresh state for a given date with zero uses.
    ///
    /// - Parameter dateString: The `"yyyy-MM-dd"` string for today.
    static func fresh(for dateString: String) -> DailySnoozeState {
        DailySnoozeState(date: dateString, usedCount: 0)
    }
}

// MARK: - CustomStringConvertible

extension DailySnoozeState: CustomStringConvertible {
    var description: String {
        "DailySnoozeState(date: \"\(date)\", usedCount: \(usedCount))"
    }
}
