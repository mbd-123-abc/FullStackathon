// DailySnoozeCounter.swift
// Slowbrew
//
// Tracks how many snooze actions have been used in the current calendar day
// and persists the count to UserDefaults. Automatically resets when the
// calendar day changes (Requirement 6.6).

import Foundation

/// Tracks and persists the daily snooze usage count.
///
/// `DailySnoozeCounter` wraps a `DailySnoozeState` value stored in
/// `UserDefaults` under the key `"com.slowbrew.dailySnooze"` in the
/// `"com.slowbrew.app"` suite. On every call to `increment()` or access of
/// `remaining`, the counter first checks whether the stored date matches
/// today's date and resets the count to zero if a new calendar day has begun.
///
/// - Note: The date string uses `"yyyy-MM-dd"` in the device's local
///   timezone to match Requirement 6.3 and 6.6.
struct DailySnoozeCounter {

    // MARK: - Constants

    static let maxPerDay = 3

    // MARK: - Private persistence helpers

    private static let userDefaultsKey = "com.slowbrew.dailySnooze"
    private static let suiteName = "com.slowbrew.app"

    private var defaults: UserDefaults {
        // Falls back to `.standard` if the suite is unavailable (e.g., in
        // unit-test targets that don't have the entitlement).
        UserDefaults(suiteName: DailySnoozeCounter.suiteName) ?? .standard
    }

    // MARK: - In-memory state

    private var state: DailySnoozeState

    // MARK: - Init

    init() {
        // Load persisted state; if nothing is stored yet, create a fresh state
        // for today's date.
        if let data = (UserDefaults(suiteName: DailySnoozeCounter.suiteName) ?? .standard)
                        .data(forKey: DailySnoozeCounter.userDefaultsKey),
           let decoded = try? JSONDecoder().decode(DailySnoozeState.self, from: data) {
            state = decoded
        } else {
            state = DailySnoozeState.fresh(for: DailySnoozeCounter.todayDateString())
        }
    }

    // MARK: - Date helper

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        return formatter.string(from: Date())
    }

    // MARK: - Persistence

    private mutating func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: DailySnoozeCounter.userDefaultsKey)
    }

    // MARK: - Public API

    /// Resets `usedCount` to 0 when the current calendar day differs from the
    /// date stored in `state`. Updates the stored date to today.
    ///
    /// - Note: This is called automatically by `increment()` and `remaining`
    ///   before their respective operations.
    mutating func resetIfNewDay() {
        let today = DailySnoozeCounter.todayDateString()
        guard state.date != today else { return }
        state = DailySnoozeState.fresh(for: today)
        persist()
    }

    /// Attempts to record one more snooze usage for today.
    ///
    /// 1. Calls `resetIfNewDay()` to ensure the count belongs to today.
    /// 2. If `usedCount >= maxPerDay`, returns `false` without mutating state.
    /// 3. Otherwise, increments `usedCount`, persists, and returns `true`.
    ///
    /// - Returns: `true` if the snooze was successfully recorded; `false` if
    ///   the daily limit has already been reached (Requirement 6.3).
    @discardableResult
    mutating func increment() -> Bool {
        resetIfNewDay()
        guard state.usedCount < DailySnoozeCounter.maxPerDay else {
            return false
        }
        state.usedCount += 1
        persist()
        return true
    }

    /// How many snooze actions remain for today.
    ///
    /// Calls `resetIfNewDay()` before computing the value so the count is
    /// always relative to the current calendar day.
    var remaining: Int {
        mutating get {
            resetIfNewDay()
            return DailySnoozeCounter.maxPerDay - state.usedCount
        }
    }

    /// The current number of snoozes used today (read-only, no side-effects).
    var usedCount: Int { state.usedCount }
}
