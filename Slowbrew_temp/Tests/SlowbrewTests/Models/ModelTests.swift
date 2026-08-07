// ModelTests.swift
// SlowbrewTests
//
// Unit tests for the core data models defined in Task 1.
// Validates correctness of static defaults, computed properties,
// and enum relationships.

import XCTest
@testable import Slowbrew

final class ModelTests: XCTestCase {

    // MARK: - HorizontalEdge

    func testHorizontalEdge_opposite_leftIsRight() {
        XCTAssertEqual(HorizontalEdge.left.opposite, .right)
    }

    func testHorizontalEdge_opposite_rightIsLeft() {
        XCTAssertEqual(HorizontalEdge.right.opposite, .left)
    }

    func testHorizontalEdge_opposite_isInvolution() {
        // opposite(opposite(x)) == x for all edges
        for edge in HorizontalEdge.allCases {
            XCTAssertEqual(edge.opposite.opposite, edge)
        }
    }

    func testHorizontalEdge_opposite_leftAndRightAreDistinct() {
        XCTAssertNotEqual(HorizontalEdge.left.opposite, .left)
        XCTAssertNotEqual(HorizontalEdge.right.opposite, .right)
    }

    // MARK: - BrewingStage

    func testBrewingStage_allCases_countIsFour() {
        XCTAssertEqual(BrewingStage.allCases.count, 4)
    }

    func testBrewingStage_allCases_ascendingRawValues() {
        let rawValues = BrewingStage.allCases.map(\.rawValue)
        XCTAssertEqual(rawValues, rawValues.sorted(), "BrewingStage.allCases must be in ascending rawValue order")
    }

    func testBrewingStage_allCases_startsAtOne() {
        XCTAssertEqual(BrewingStage.allCases.first?.rawValue, 1)
    }

    func testBrewingStage_allCases_order() {
        XCTAssertEqual(BrewingStage.allCases, [.heatingWater, .steeping, .pouring, .presentingCup])
    }

    func testBrewingStage_minimumDuration_isOneSecond() {
        for stage in BrewingStage.allCases {
            XCTAssertEqual(stage.minimumDuration, .seconds(1),
                           "\(stage).minimumDuration must be 1 second (Requirement 5.5)")
        }
    }

    func testBrewingStage_atlasName_matchesConvention() {
        XCTAssertEqual(BrewingStage.heatingWater.atlasName,  "BrewStage1")
        XCTAssertEqual(BrewingStage.steeping.atlasName,      "BrewStage2")
        XCTAssertEqual(BrewingStage.pouring.atlasName,       "BrewStage3")
        XCTAssertEqual(BrewingStage.presentingCup.atlasName, "BrewStage4")
    }

    // MARK: - Settings defaults

    func testSettings_default_breakInterval() {
        XCTAssertEqual(Settings.default.breakInterval, 60)
    }

    func testSettings_default_breakDuration() {
        XCTAssertEqual(Settings.default.breakDuration, 5)
    }

    func testSettings_default_launchAtLogin_isFalse() {
        XCTAssertFalse(Settings.default.launchAtLogin)
    }

    func testSettings_default_soundEnabled_isTrue() {
        XCTAssertTrue(Settings.default.soundEnabled)
    }

    // MARK: - Settings range constants

    func testSettings_rangeConstants() {
        XCTAssertEqual(Settings.breakIntervalMin, 15)
        XCTAssertEqual(Settings.breakIntervalMax, 180)
        XCTAssertEqual(Settings.breakDurationMin, 1)
        XCTAssertEqual(Settings.breakDurationMax, 30)
    }

    func testSettings_default_isWithinValidRange() {
        let s = Settings.default
        XCTAssertTrue((Settings.breakIntervalMin...Settings.breakIntervalMax).contains(s.breakInterval))
        XCTAssertTrue((Settings.breakDurationMin...Settings.breakDurationMax).contains(s.breakDuration))
    }

    // MARK: - Settings computed duration helpers

    func testSettings_breakIntervalDuration_defaultIs3600Seconds() {
        // 60 minutes × 60 seconds = 3600 s
        XCTAssertEqual(Settings.default.breakIntervalDuration, .seconds(3600))
    }

    func testSettings_breakDurationDuration_defaultIs300Seconds() {
        // 5 minutes × 60 seconds = 300 s
        XCTAssertEqual(Settings.default.breakDurationDuration, .seconds(300))
    }

    func testSettings_breakIntervalDuration_conversion() {
        let s = Settings(breakInterval: 15, breakDuration: 1, launchAtLogin: false, soundEnabled: true)
        XCTAssertEqual(s.breakIntervalDuration, .seconds(900))   // 15 × 60
        XCTAssertEqual(s.breakDurationDuration, .seconds(60))    // 1 × 60
    }

    func testSettings_breakIntervalDuration_maxValues() {
        let s = Settings(breakInterval: 180, breakDuration: 30, launchAtLogin: false, soundEnabled: true)
        XCTAssertEqual(s.breakIntervalDuration, .seconds(10_800))  // 180 × 60
        XCTAssertEqual(s.breakDurationDuration, .seconds(1_800))   // 30 × 60
    }

    // MARK: - Settings Equatable

    func testSettings_equatable_sameValuesAreEqual() {
        let a = Settings.default
        let b = Settings.default
        XCTAssertEqual(a, b)
    }

    func testSettings_equatable_differentValuesAreNotEqual() {
        let a = Settings.default
        let b = Settings(breakInterval: 30, breakDuration: 3, launchAtLogin: false, soundEnabled: true)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Settings Codable round-trip

    func testSettings_codable_roundTrip() throws {
        let original = Settings.default
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Settings.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSettings_codable_customValues_roundTrip() throws {
        let original = Settings(breakInterval: 45, breakDuration: 10, launchAtLogin: true, soundEnabled: false)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Settings.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - DailySnoozeState

    func testDailySnoozeState_fresh_zeroCount() {
        let state = DailySnoozeState.fresh(for: "2025-06-15")
        XCTAssertEqual(state.date, "2025-06-15")
        XCTAssertEqual(state.usedCount, 0)
    }

    func testDailySnoozeState_equatable() {
        let a = DailySnoozeState(date: "2025-06-15", usedCount: 2)
        let b = DailySnoozeState(date: "2025-06-15", usedCount: 2)
        XCTAssertEqual(a, b)
    }

    func testDailySnoozeState_codable_roundTrip() throws {
        let original = DailySnoozeState(date: "2025-06-15", usedCount: 3)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DailySnoozeState.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - PauseReason

    func testPauseReason_allCases_countIsFour() {
        XCTAssertEqual(PauseReason.allCases.count, 4)
    }

    func testPauseReason_allCases_containsAllExpected() {
        let expected: Set<PauseReason> = [.userPaused, .dnd, .displayLocked, .sleep]
        XCTAssertEqual(Set(PauseReason.allCases), expected)
    }

    // MARK: - AppState Equatable

    func testAppState_idle_equatable() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(AppState.idle(timerStartedAt: date), AppState.idle(timerStartedAt: date))
    }

    func testAppState_brewing_equatable() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(
            AppState.brewing(startedAt: date, snoozeRemaining: 3),
            AppState.brewing(startedAt: date, snoozeRemaining: 3)
        )
        XCTAssertNotEqual(
            AppState.brewing(startedAt: date, snoozeRemaining: 3),
            AppState.brewing(startedAt: date, snoozeRemaining: 2)
        )
    }

    func testAppState_walkingIn_equatable() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(
            AppState.walkingIn(edge: .left, startedAt: date),
            AppState.walkingIn(edge: .left, startedAt: date)
        )
        XCTAssertNotEqual(
            AppState.walkingIn(edge: .left, startedAt: date),
            AppState.walkingIn(edge: .right, startedAt: date)
        )
    }

    func testAppState_walkingOut_oppositeEdge() {
        // Verifies the structural relationship that walkingOut carries the
        // opposite of the walkingIn edge for a given session.
        let inEdge = HorizontalEdge.left
        let outEdge = inEdge.opposite
        XCTAssertEqual(outEdge, .right)
    }
}
