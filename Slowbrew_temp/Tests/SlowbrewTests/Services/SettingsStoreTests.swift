// SettingsStoreTests.swift
// SlowbrewTests
//
// Property-based tests for SettingsStore.
// Property 15 from the design document.

import XCTest
import SwiftCheck
@testable import Slowbrew

// MARK: - Property-Based Tests

// Feature: slowbrew, Property 15: Settings persistence is a round-trip

final class SettingsStorePropertyTests: XCTestCase {

    // MARK: - Property 15

    /// **Validates: Requirements 7.7**
    ///
    /// For any valid `Settings` value, calling `save(s)` followed by `load()`
    /// must return a value equal to `s` (serialization and deserialization are
    /// inverse operations with no data loss).
    func testProperty15_settingsPersistenceIsRoundTrip() {
        let iterations = 50
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<iterations {
            let settings = Settings(
                breakInterval: Int.random(in: Settings.breakIntervalMin...Settings.breakIntervalMax, using: &rng),
                breakDuration: Int.random(in: Settings.breakDurationMin...Settings.breakDurationMax, using: &rng),
                launchAtLogin: Bool.random(using: &rng),
                soundEnabled: Bool.random(using: &rng)
            )

            let suiteName = "test.slowbrew.settings.\(UUID().uuidString)"
            let testDefaults = UserDefaults(suiteName: suiteName)!
            let store = SettingsStore(defaults: testDefaults)

            do {
                try store.save(settings)
            } catch {
                testDefaults.removePersistentDomain(forName: suiteName)
                XCTFail("Expected save to succeed for settings \(settings), got error \(error)")
                return
            }

            let loaded = store.load()
            testDefaults.removePersistentDomain(forName: suiteName)
            XCTAssertEqual(loaded, settings, "Round-trip persistence should preserve settings")
        }
    }
    
    /// **Validates: Requirements 7.7**
    ///
    /// For any sequence of valid Settings values, the last saved value
    /// is always the one returned by load() (demonstrating proper overwriting).
    func testProperty15_lastSavedSettingsAlwaysWins() {
        let iterations = 25
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<iterations {
            let settingsArray = (0..<Int.random(in: 1...10, using: &rng)).map { _ in
                Settings(
                    breakInterval: Int.random(in: Settings.breakIntervalMin...Settings.breakIntervalMax, using: &rng),
                    breakDuration: Int.random(in: Settings.breakDurationMin...Settings.breakDurationMax, using: &rng),
                    launchAtLogin: Bool.random(using: &rng),
                    soundEnabled: Bool.random(using: &rng)
                )
            }

            let suiteName = "test.slowbrew.settings.\(UUID().uuidString)"
            let testDefaults = UserDefaults(suiteName: suiteName)!
            let store = SettingsStore(defaults: testDefaults)

            for settings in settingsArray {
                do {
                    try store.save(settings)
                } catch {
                    testDefaults.removePersistentDomain(forName: suiteName)
                    XCTFail("Expected save to succeed for settings \(settings), got error \(error)")
                    return
                }
            }

            let loaded = store.load()
            let lastSaved = settingsArray.last!
            testDefaults.removePersistentDomain(forName: suiteName)

            XCTAssertEqual(loaded, lastSaved, "Load should return the most recently saved settings")
        }
    }
}

// MARK: - SwiftCheck Generators

/// Generates random valid `Settings` values with all fields within their valid ranges.
///
/// Ranges:
/// - `breakInterval`: 15–180
/// - `breakDuration`: 1–30
/// - `launchAtLogin`: any Bool
/// - `soundEnabled`: any Bool
private func genValidSettings() -> Gen<Settings> {
    Gen<Settings>.compose { c in
        Settings(
            breakInterval: c.generate(using: Gen<Int>.choose((Settings.breakIntervalMin, Settings.breakIntervalMax))),
            breakDuration: c.generate(using: Gen<Int>.choose((Settings.breakDurationMin, Settings.breakDurationMax))),
            launchAtLogin: c.generate(),
            soundEnabled: c.generate()
        )
    }
}
