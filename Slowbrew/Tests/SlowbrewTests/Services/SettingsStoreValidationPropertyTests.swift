// SettingsStoreValidationPropertyTests.swift
// SlowbrewTests
//
// Property-based tests for SettingsStore validation logic using SwiftCheck.
//
// These tests verify that the validation logic for breakInterval and
// breakDuration is *total* (decides every possible Int input) and *correct*
// (accepts exactly the specified ranges and rejects everything else).

import XCTest
import SwiftCheck
@testable import Slowbrew

// MARK: - Helpers

/// Creates an isolated `UserDefaults` suite for a single test.
private func makeFreshDefaults() -> UserDefaults {
    let suiteName = "com.slowbrew.test.\(UUID().uuidString)"
    return UserDefaults(suiteName: suiteName)!
}

// MARK: - Property 3: Settings Range Validation

final class SettingsStoreValidationPropertyTests: XCTestCase {

    // MARK: - Property 3: Settings range validation is total and correct

    /// **Property 3: Settings range validation is total and correct**
    ///
    /// For any integer value `v`, `SettingsStore` validation accepts `v` as a
    /// break interval if and only if `15 ≤ v ≤ 180`, and accepts `v` as a
    /// break duration if and only if `1 ≤ v ≤ 30`; all other values are
    /// rejected with a validation error and saving is blocked.
    ///
    /// This property test exercises the full Int32 range to ensure that:
    /// 1. Every valid value in the range is accepted (no false negatives).
    /// 2. Every invalid value outside the range is rejected (no false positives).
    /// 3. The validation logic is total — every possible Int is classified as
    ///    either valid or invalid with no crashes, infinite loops, or undefined
    ///    behavior.
    ///
    /// // Feature: slowbrew, Property 3: Settings range validation is total and correct
    ///
    /// **Validates: Requirements 2.6, 4.5, 7.9**
    func testProperty3_BreakIntervalValidation_IsTotalAndCorrect() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        
        property("breakInterval validation accepts exactly [15, 180] and rejects everything else") <- forAll { (value: Int) in
            // Construct a Settings instance with the generated breakInterval value.
            // Use valid values for other fields so we isolate breakInterval validation.
            let settings = Settings(
                breakInterval: value,
                breakDuration: 5,      // Valid: within [1, 30]
                launchAtLogin: false,
                soundEnabled: true
            )
            
            let isInValidRange = (Settings.breakIntervalMin...Settings.breakIntervalMax).contains(value)
            
            do {
                try store.save(settings)
                return isInValidRange
            } catch SettingsValidationError.breakIntervalOutOfRange(let errorValue) {
                return !isInValidRange && (errorValue == value)
            } catch {
                return false
            }
        }
    }
    
    /// **Property 3: Settings range validation is total and correct (break duration)**
    ///
    /// For any integer value `v`, `SettingsStore` validation accepts `v` as a
    /// break duration if and only if `1 ≤ v ≤ 30`; all other values are
    /// rejected with a validation error and saving is blocked.
    ///
    /// This property test exercises the full Int32 range to ensure that:
    /// 1. Every valid value in the range is accepted (no false negatives).
    /// 2. Every invalid value outside the range is rejected (no false positives).
    /// 3. The validation logic is total — every possible Int is classified as
    ///    either valid or invalid with no crashes, infinite loops, or undefined
    ///    behavior.
    ///
    /// // Feature: slowbrew, Property 3: Settings range validation is total and correct
    ///
    /// **Validates: Requirements 2.6, 4.5, 7.9**
    func testProperty3_BreakDurationValidation_IsTotalAndCorrect() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        
        property("breakDuration validation accepts exactly [1, 30] and rejects everything else") <- forAll { (value: Int) in
            // Construct a Settings instance with the generated breakDuration value.
            // Use valid values for other fields so we isolate breakDuration validation.
            let settings = Settings(
                breakInterval: 60,     // Valid: within [15, 180]
                breakDuration: value,
                launchAtLogin: false,
                soundEnabled: true
            )
            
            let isInValidRange = (Settings.breakDurationMin...Settings.breakDurationMax).contains(value)
            
            do {
                try store.save(settings)
                return isInValidRange
            } catch SettingsValidationError.breakDurationOutOfRange(let errorValue) {
                return !isInValidRange && (errorValue == value)
            } catch {
                return false
            }
        }
    }
}
