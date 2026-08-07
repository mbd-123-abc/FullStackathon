// SettingsStoreDiscardTests.swift
// SlowbrewTests
//
// Unit tests for SettingsStore's discard-on-close and persistence-failure
// behaviour (Requirements 7.5 and 7.10).
//
// These tests exercise the SettingsStore API directly because
// SettingsWindowController (task 12.1) has not been implemented yet.
// The store's behaviour is the contract that the window controller must honour:
//   • Unsaved in-memory mutations do NOT affect the persisted value (discard).
//   • A failed save throws a LocalizedError the caller can catch and display.

import XCTest
@testable import Slowbrew

// MARK: - Helpers

/// Creates an isolated `UserDefaults` suite for a single test, guaranteeing no
/// cross-test pollution.  The caller is responsible for calling
/// `removePersistentDomain` in `tearDown` if needed, but since each call uses a
/// unique UUID the isolation is already complete without teardown.
private func makeFreshDefaults() -> UserDefaults {
    let suiteName = "com.slowbrew.test.\(UUID().uuidString)"
    // `UserDefaults(suiteName:)` can return `nil` only in extremely unusual
    // sandbox conditions; force-unwrapping is appropriate in test code.
    return UserDefaults(suiteName: suiteName)!
}

// MARK: - Discard Behaviour Tests

final class SettingsStoreDiscardTests: XCTestCase {

    // MARK: - Discard: unsaved mutations do NOT affect the store

    /// Load → mutate the returned struct → do NOT save → load again.
    /// The second load must return the same original value.
    ///
    /// **Validates: Requirements 7.5**
    func testDiscardOnClose_unmutatedLoadReturnsSameValue() {
        let store = SettingsStore(defaults: makeFreshDefaults())

        // First load (returns Settings.default on a clean suite).
        let first = store.load()

        // Mutate the local copy WITHOUT saving it back.
        var local = first
        local.breakInterval = first.breakInterval + 15
        local.soundEnabled = !first.soundEnabled

        // Second load must be identical to the first — the mutation was never persisted.
        let second = store.load()
        XCTAssertEqual(first, second,
                       "load() must return the persisted value; in-memory mutation must not change it")
    }

    /// Settings is a value type. Modifying a local copy must never affect what
    /// SettingsStore.load() returns because no `save()` was called.
    ///
    /// **Validates: Requirements 7.5**
    func testDiscardOnClose_localStructMutationDoesNotPersist() throws {
        let store = SettingsStore(defaults: makeFreshDefaults())

        // Persist a known-good value.
        let saved = Settings(breakInterval: 30, breakDuration: 3, launchAtLogin: false, soundEnabled: true)
        try store.save(saved)

        // Simulate a settings panel that modifies a local copy but is closed
        // without saving.
        var panelCopy = store.load()
        panelCopy.breakInterval = 90
        panelCopy.breakDuration = 10
        panelCopy.launchAtLogin = true
        panelCopy.soundEnabled = false
        // Deliberate: no `try store.save(panelCopy)` call here.

        // The store must still return the original saved value.
        let loaded = store.load()
        XCTAssertEqual(loaded, saved,
                       "Mutating a local copy without saving must not change the persisted settings")
    }

    /// Calling `load()` multiple times on the same store with no intervening
    /// `save()` must always return the same value (idempotent reads).
    ///
    /// **Validates: Requirements 7.5**
    func testLoad_isIdempotent() throws {
        let store = SettingsStore(defaults: makeFreshDefaults())

        let saved = Settings(breakInterval: 45, breakDuration: 7, launchAtLogin: true, soundEnabled: false)
        try store.save(saved)

        let results = (0..<5).map { _ in store.load() }
        for result in results {
            XCTAssertEqual(result, saved,
                           "Repeated load() calls must all return the same value with no side effects")
        }
    }

    /// A fresh store (no prior save) must return `Settings.default` every time.
    ///
    /// **Validates: Requirements 7.5**
    func testLoad_freshStore_returnsDefault() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertEqual(store.load(), .default,
                       "load() on a fresh suite must return Settings.default")
    }

    // MARK: - Persistence Failure / Inline Alert Tests

    /// Saving with `breakInterval = 0` must throw
    /// `.breakIntervalOutOfRange(value: 0)`.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_breakIntervalZero_throwsBreakIntervalOutOfRange() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let invalid = Settings(breakInterval: 0, breakDuration: 5, launchAtLogin: false, soundEnabled: true)

        XCTAssertThrowsError(try store.save(invalid)) { error in
            XCTAssertEqual(error as? SettingsValidationError,
                           .breakIntervalOutOfRange(value: 0))
        }
    }

    /// Saving with `breakDuration = 31` must throw
    /// `.breakDurationOutOfRange(value: 31)`.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_breakDuration31_throwsBreakDurationOutOfRange() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let invalid = Settings(breakInterval: 60, breakDuration: 31, launchAtLogin: false, soundEnabled: true)

        XCTAssertThrowsError(try store.save(invalid)) { error in
            XCTAssertEqual(error as? SettingsValidationError,
                           .breakDurationOutOfRange(value: 31))
        }
    }

    /// After a failed save (validation error), `load()` must still return the
    /// previously valid settings — the failed write must be a no-op.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_failureDoesNotOverwritePreviousValidSettings() throws {
        let store = SettingsStore(defaults: makeFreshDefaults())

        // Persist valid settings first.
        let validSettings = Settings(breakInterval: 60, breakDuration: 5, launchAtLogin: false, soundEnabled: true)
        try store.save(validSettings)

        // Attempt to save invalid settings — must throw.
        let invalidSettings = Settings(breakInterval: 0, breakDuration: 5, launchAtLogin: false, soundEnabled: true)
        XCTAssertThrowsError(try store.save(invalidSettings))

        // The previously valid settings must still be intact.
        let loaded = store.load()
        XCTAssertEqual(loaded, validSettings,
                       "A failed save must leave previously persisted settings unchanged")
    }

    /// The error thrown by `save(_:)` must conform to `LocalizedError` and
    /// provide a non-empty `errorDescription` suitable for display in the UI.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_errorIsLocalizedError_withNonEmptyDescription() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let invalid = Settings(breakInterval: 0, breakDuration: 5, launchAtLogin: false, soundEnabled: true)

        do {
            try store.save(invalid)
            XCTFail("Expected save to throw but it did not")
        } catch let error as LocalizedError {
            let description = error.errorDescription ?? ""
            XCTAssertFalse(description.isEmpty,
                           "errorDescription must be non-empty so the UI can show it")
        } catch {
            XCTFail("Expected a LocalizedError but got \(type(of: error)): \(error)")
        }
    }

    /// The break-interval error message must be non-empty and suitable for the
    /// user to read.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_breakIntervalError_messageIsDisplayable() {
        let error = SettingsValidationError.breakIntervalOutOfRange(value: 0)
        let description = error.errorDescription ?? ""

        XCTAssertFalse(description.isEmpty,
                       "breakIntervalOutOfRange errorDescription must not be empty")
        // The description should mention the out-of-range value for clarity.
        XCTAssertTrue(description.contains("0"),
                      "errorDescription should include the invalid value for context")
    }

    /// The break-duration error message must be non-empty and suitable for the
    /// user to read.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_breakDurationError_messageIsDisplayable() {
        let error = SettingsValidationError.breakDurationOutOfRange(value: 31)
        let description = error.errorDescription ?? ""

        XCTAssertFalse(description.isEmpty,
                       "breakDurationOutOfRange errorDescription must not be empty")
        XCTAssertTrue(description.contains("31"),
                      "errorDescription should include the invalid value for context")
    }

    /// Callers must be able to catch the error and extract a message to show
    /// inline — verifies the full catch-and-display pattern used by the UI.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_callerCanCatchAndDisplayError() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let invalid = Settings(breakInterval: 200, breakDuration: 5, launchAtLogin: false, soundEnabled: true)

        var displayedMessage: String?

        do {
            try store.save(invalid)
        } catch let validationError as SettingsValidationError {
            // This is the pattern a settings panel would use to show an inline
            // alert rather than crashing.
            displayedMessage = validationError.errorDescription
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertNotNil(displayedMessage,
                        "Caller must be able to catch SettingsValidationError and read its message")
        XCTAssertFalse(displayedMessage?.isEmpty ?? true,
                       "The displayed message must not be empty")
    }

    // MARK: - Boundary values

    /// Minimum valid values must save and reload without error.
    ///
    /// **Validates: Requirements 7.5, 7.10**
    func testSave_minimumValidValues_succeeds() throws {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let min = Settings(
            breakInterval: Settings.breakIntervalMin,
            breakDuration: Settings.breakDurationMin,
            launchAtLogin: false,
            soundEnabled: true
        )
        XCTAssertNoThrow(try store.save(min))
        XCTAssertEqual(store.load(), min)
    }

    /// Maximum valid values must save and reload without error.
    ///
    /// **Validates: Requirements 7.5, 7.10**
    func testSave_maximumValidValues_succeeds() throws {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let max = Settings(
            breakInterval: Settings.breakIntervalMax,
            breakDuration: Settings.breakDurationMax,
            launchAtLogin: true,
            soundEnabled: false
        )
        XCTAssertNoThrow(try store.save(max))
        XCTAssertEqual(store.load(), max)
    }

    /// One below the minimum break interval must throw.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_oneBelowMinBreakInterval_throws() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let belowMin = Settings(
            breakInterval: Settings.breakIntervalMin - 1,
            breakDuration: 5,
            launchAtLogin: false,
            soundEnabled: true
        )
        XCTAssertThrowsError(try store.save(belowMin)) { error in
            XCTAssertEqual(error as? SettingsValidationError,
                           .breakIntervalOutOfRange(value: Settings.breakIntervalMin - 1))
        }
    }

    /// One above the maximum break duration must throw.
    ///
    /// **Validates: Requirements 7.10**
    func testSave_oneAboveMaxBreakDuration_throws() {
        let store = SettingsStore(defaults: makeFreshDefaults())
        let aboveMax = Settings(
            breakInterval: 60,
            breakDuration: Settings.breakDurationMax + 1,
            launchAtLogin: false,
            soundEnabled: true
        )
        XCTAssertThrowsError(try store.save(aboveMax)) { error in
            XCTAssertEqual(error as? SettingsValidationError,
                           .breakDurationOutOfRange(value: Settings.breakDurationMax + 1))
        }
    }
}
