// StateMachineTests.swift
// SlowbrewTests
//
// Unit tests for StateMachine invalid-event handling and quit-during-break logic.
// Validates Requirements 1.3 (invalid events silently ignored) and
// 1.4 (deferred quit during active break).

import XCTest
@testable import Slowbrew

// MARK: - Helpers

extension StateMachineTests {

    /// Builds a `StateMachine` that has already reached the `.brewing` state
    /// by replaying: idle → timerFired → walkInCompleted.
    ///
    /// Starting state is always `.idle`; the two events produce the canonical
    /// path to `.brewing` without any mock clocks.
    func makeMachineInBrewingState() async -> StateMachine {
        let machine = StateMachine()
        await machine.send(.timerFired)       // idle → walkingIn
        await machine.send(.walkInCompleted)  // walkingIn → brewing
        return machine
    }

    /// Extracts the case label from an `AppState` for assertion messages.
    func stateName(_ state: AppState) -> String {
        switch state {
        case .idle:       return "idle"
        case .walkingIn:  return "walkingIn"
        case .brewing:    return "brewing"
        case .walkingOut: return "walkingOut"
        case .paused:     return "paused"
        }
    }
}

// MARK: - StateMachineTests

/// Tests are run with `--configuration release` so that `#if DEBUG`
/// assertionFailure guards in `StateMachine` are inactive.  This lets
/// invalid (state, event) pairs return the same state without crashing.
final class StateMachineTests: XCTestCase {

    // MARK: - Invalid Events in .idle State

    /// `.idle` + `.walkInCompleted` — no valid transition, state unchanged.
    func testIdle_walkInCompleted_isIgnored() async {
        let machine = StateMachine()
        let before = await machine.state
        await machine.send(.walkInCompleted)
        let after = await machine.state
        XCTAssertEqual(after, before, "walkInCompleted in .idle must be silently ignored")
    }

    /// `.idle` + `.walkOutCompleted` — no valid transition, state unchanged.
    func testIdle_walkOutCompleted_isIgnored() async {
        let machine = StateMachine()
        let before = await machine.state
        await machine.send(.walkOutCompleted)
        let after = await machine.state
        XCTAssertEqual(after, before, "walkOutCompleted in .idle must be silently ignored")
    }

    /// `.idle` + `.countdownExpired` — no valid transition, state unchanged.
    func testIdle_countdownExpired_isIgnored() async {
        let machine = StateMachine()
        let before = await machine.state
        await machine.send(.countdownExpired)
        let after = await machine.state
        XCTAssertEqual(after, before, "countdownExpired in .idle must be silently ignored")
    }

    /// `.idle` + `.snoozeTapped` — no valid transition, state unchanged.
    func testIdle_snoozeTapped_isIgnored() async {
        let machine = StateMachine()
        let before = await machine.state
        await machine.send(.snoozeTapped)
        let after = await machine.state
        XCTAssertEqual(after, before, "snoozeTapped in .idle must be silently ignored")
    }

    // MARK: - Invalid Events in .paused State

    /// `.paused` + `.timerFired` — no valid transition, state unchanged.
    func testPaused_timerFired_isIgnored() async {
        let machine = StateMachine()
        // Transition to paused via a legitimate event
        await machine.send(.pauseToggled)   // idle → paused(userPaused)

        let before = await machine.state
        await machine.send(.timerFired)
        let after = await machine.state
        XCTAssertEqual(after, before, "timerFired in .paused must be silently ignored")
    }

    /// `.paused` + `.walkInCompleted` — no valid transition, state unchanged.
    func testPaused_walkInCompleted_isIgnored() async {
        let machine = StateMachine()
        await machine.send(.pauseToggled)

        let before = await machine.state
        await machine.send(.walkInCompleted)
        let after = await machine.state
        XCTAssertEqual(after, before, "walkInCompleted in .paused must be silently ignored")
    }

    // MARK: - Invalid Events in .walkingIn State

    /// `.walkingIn` + `.timerFired` — no valid transition, state unchanged.
    func testWalkingIn_timerFired_isIgnored() async {
        let machine = StateMachine()
        await machine.send(.timerFired)   // idle → walkingIn
        // Confirm we are in .walkingIn
        guard case .walkingIn = await machine.state else {
            XCTFail("Expected .walkingIn state after timerFired")
            return
        }

        let before = await machine.state
        await machine.send(.timerFired)
        let after = await machine.state
        XCTAssertEqual(after, before, "timerFired in .walkingIn must be silently ignored")
    }

    /// `.walkingIn` + `.countdownExpired` — no valid transition, state unchanged.
    func testWalkingIn_countdownExpired_isIgnored() async {
        let machine = StateMachine()
        await machine.send(.timerFired)

        let before = await machine.state
        await machine.send(.countdownExpired)
        let after = await machine.state
        XCTAssertEqual(after, before, "countdownExpired in .walkingIn must be silently ignored")
    }

    // MARK: - Invalid Events in .brewing State

    /// `.brewing` + `.timerFired` — no valid transition, state unchanged.
    func testBrewing_timerFired_isIgnored() async {
        let machine = await makeMachineInBrewingState()
        let before = await machine.state
        await machine.send(.timerFired)
        let after = await machine.state
        XCTAssertEqual(after, before, "timerFired in .brewing must be silently ignored")
    }

    /// `.brewing` + `.walkInCompleted` — no valid transition, state unchanged.
    func testBrewing_walkInCompleted_isIgnored() async {
        let machine = await makeMachineInBrewingState()
        let before = await machine.state
        await machine.send(.walkInCompleted)
        let after = await machine.state
        XCTAssertEqual(after, before, "walkInCompleted in .brewing must be silently ignored")
    }

    // MARK: - Invalid Events in .walkingOut State

    /// `.walkingOut` + `.timerFired` — no valid transition, state unchanged.
    func testWalkingOut_timerFired_isIgnored() async {
        let machine = await makeMachineInBrewingState()
        await machine.send(.countdownExpired)  // brewing → walkingOut
        guard case .walkingOut = await machine.state else {
            XCTFail("Expected .walkingOut state after countdownExpired")
            return
        }

        let before = await machine.state
        await machine.send(.timerFired)
        let after = await machine.state
        XCTAssertEqual(after, before, "timerFired in .walkingOut must be silently ignored")
    }

    /// `.walkingOut` + `.countdownExpired` — no valid transition, state unchanged.
    func testWalkingOut_countdownExpired_isIgnored() async {
        let machine = await makeMachineInBrewingState()
        await machine.send(.countdownExpired)  // brewing → walkingOut

        let before = await machine.state
        await machine.send(.countdownExpired)
        let after = await machine.state
        XCTAssertEqual(after, before, "countdownExpired in .walkingOut must be silently ignored")
    }

    // MARK: - Deferred Quit Logic

    /// First `quitRequested(force: false)` during `.brewing` defers termination:
    /// `isDeferredQuitPending` becomes `true` but the state stays `.brewing`.
    func testBrewing_firstSoftQuit_defersThenKeepsBrewingState() async {
        let machine = await makeMachineInBrewingState()
        let stateBeforeQuit = await machine.state

        // Sanity: no deferred quit yet
        let pendingBefore = await machine.isDeferredQuitPending
        XCTAssertFalse(pendingBefore, "isDeferredQuitPending must start false")

        await machine.send(.quitRequested(force: false))

        let pendingAfter = await machine.isDeferredQuitPending
        XCTAssertTrue(pendingAfter, "isDeferredQuitPending must be true after first soft-quit in .brewing")

        let stateAfterQuit = await machine.state
        XCTAssertEqual(stateAfterQuit, stateBeforeQuit,
                       "State must remain .brewing after first soft-quit (quit is deferred, not immediate)")
    }

    /// Second `quitRequested(force: false)` during `.brewing` calls the terminate handler.
    func testBrewing_secondSoftQuit_callsTerminateHandler() async {
        let machine = await makeMachineInBrewingState()

        let expectation = XCTestExpectation(description: "terminateHandler called on second soft-quit")
        await machine.setTerminateHandler { expectation.fulfill() }

        await machine.send(.quitRequested(force: false))  // first — defers
        await machine.send(.quitRequested(force: false))  // second — terminates

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    /// `quitRequested(force: true)` during `.brewing` calls the terminate handler immediately,
    /// even on the first request (no deferral).
    func testBrewing_forceQuit_callsTerminateHandlerImmediately() async {
        let machine = await makeMachineInBrewingState()

        let expectation = XCTestExpectation(description: "terminateHandler called on force-quit")
        await machine.setTerminateHandler { expectation.fulfill() }

        // No prior soft-quit — force should terminate on the very first call.
        await machine.send(.quitRequested(force: true))

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    /// `quitRequested(force: false)` during `.idle` produces no state change
    /// and does not set `isDeferredQuitPending`.
    ///
    /// Quit from `.idle` is handled at the app level; the state machine is a no-op.
    func testIdle_softQuit_noStateChangeAndNoDeferral() async {
        let machine = StateMachine()
        let before = await machine.state

        // Confirm we're in .idle
        guard case .idle = before else {
            XCTFail("Expected .idle initial state")
            return
        }

        await machine.send(.quitRequested(force: false))

        let after = await machine.state
        XCTAssertEqual(after, before, "State must not change when quitRequested in .idle")

        let pending = await machine.isDeferredQuitPending
        XCTAssertFalse(pending, "isDeferredQuitPending must remain false for quit from .idle")
    }

    // MARK: - Brewing State Helper Validation

    /// Validates the `makeMachineInBrewingState()` helper produces `.brewing`.
    func testHelper_makeMachineInBrewingState_producesBrewingState() async {
        let machine = await makeMachineInBrewingState()
        let state = await machine.state
        guard case .brewing = state else {
            XCTFail("Expected .brewing state from helper, got \(state.description)")
            return
        }
    }

    /// Validates the path to `.brewing` passes through `.walkingIn` (Property 2).
    func testHelper_pathToBrewingPassesThroughWalkingIn() async {
        let machine = StateMachine()

        // Step 1: idle → walkingIn
        await machine.send(.timerFired)
        guard case .walkingIn = await machine.state else {
            XCTFail("Expected .walkingIn after timerFired from .idle")
            return
        }

        // Step 2: walkingIn → brewing
        await machine.send(.walkInCompleted)
        guard case .brewing = await machine.state else {
            XCTFail("Expected .brewing after walkInCompleted from .walkingIn")
            return
        }
    }
}

// MARK: - StateMachine test helper extension

private extension StateMachine {
    /// Injects a terminate handler from async test code.
    func setTerminateHandler(_ handler: @escaping @Sendable () -> Void) {
        terminateHandler = handler
    }
}

// MARK: - Property-Based Tests

// Feature: slowbrew, Property 1: Timer expiry always triggers a break

import SwiftCheck

final class StateMachinePropertyTests: XCTestCase {

    // MARK: - Property 1

    /// **Validates: Requirements 2.1**
    ///
    /// **Property 1: For any valid break interval, timerFired from .idle → .walkingIn**
    ///
    /// For any valid break interval value (15–180 minutes), when the `TimerService`
    /// fires (i.e., `timerFired` event is delivered), the `StateMachine` must
    /// transition from `.idle` to `.walkingIn`.
    ///
    /// This property verifies that timer expiry **always** triggers a break
    /// regardless of the configured break interval duration. The break interval
    /// determines *when* the timer fires, but once it fires, the transition
    /// must always occur.
    func testProperty1_timerExpiryAlwaysTriggersBreak() async {
        // Feature: slowbrew, Property 1: Timer expiry always triggers a break
        
        // SwiftCheck properties don't support async/await directly, so we manually
        // iterate across random break intervals (15–180 minutes) to match the
        // SwiftCheck default of 100 test cases.
        
        let maxTests = 100
        var rng = SystemRandomNumberGenerator()
        var successCount = 0
        
        for _ in 0..<maxTests {
            // Generate a random valid break interval (15–180 minutes)
            let breakInterval = Int.random(in: 15...180, using: &rng)
            
            // Create a fresh StateMachine in .idle state with the generated interval.
            // The interval affects when the timer fires in production, but for this
            // property test we are verifying the state transition logic itself.
            let settings = Settings(
                breakInterval: breakInterval,
                breakDuration: 5,  // Duration doesn't affect this property
                launchAtLogin: false,
                soundEnabled: true
            )
            let machine = StateMachine(settings: settings)
            
            // Verify we start in .idle
            let initialState = await machine.state
            guard case .idle = initialState else {
                XCTFail("Test setup failure: expected .idle initial state, got \(initialState)")
                return
            }
            
            // Deliver the timerFired event (simulating timer expiry)
            await machine.send(.timerFired)
            
            // Capture the resulting state
            let resultState = await machine.state
            
            // Property: result must be .walkingIn (any edge is acceptable)
            guard case .walkingIn = resultState else {
                XCTFail("Property violation: timerFired from .idle with breakInterval=\(breakInterval) did not transition to .walkingIn. Got: \(resultState)")
                return
            }
            
            successCount += 1
        }
        
        XCTAssertEqual(successCount, maxTests,
                       "Property 1 verified across \(successCount) random break interval values")
    }
    
    // MARK: - Property 2
    
    /// **Validates: Requirements 2.2, 3.2**
    ///
    /// **Property 2: State sequence always contains .walkingIn before .brewing**
    ///
    /// For any break trigger event, the state sequence produced by the `StateMachine`
    /// must pass through `.walkingIn` before reaching `.brewing` — the overlay is
    /// never presented without the walk-in animation completing first.
    ///
    /// This property verifies that the walk-in animation **always** precedes the
    /// full-screen overlay, regardless of the break interval or any other configuration.
    func testProperty2_walkInAlwaysPrecedesOverlay() async {
        // Feature: slowbrew, Property 2: Walk-in animation always precedes the overlay
        
        let maxTests = 100
        var rng = SystemRandomNumberGenerator()
        var successCount = 0
        
        for _ in 0..<maxTests {
            // Generate random valid settings
            let breakInterval = Int.random(in: 15...180, using: &rng)
            let breakDuration = Int.random(in: 1...30, using: &rng)
            let launchAtLogin = Bool.random(using: &rng)
            let soundEnabled = Bool.random(using: &rng)
            
            let settings = Settings(
                breakInterval: breakInterval,
                breakDuration: breakDuration,
                launchAtLogin: launchAtLogin,
                soundEnabled: soundEnabled
            )
            let machine = StateMachine(settings: settings)
            
            // Verify we start in .idle
            let initialState = await machine.state
            guard case .idle = initialState else {
                XCTFail("Test setup failure: expected .idle initial state, got \(initialState)")
                return
            }
            
            // Track state sequence: we need to observe .walkingIn before .brewing
            var sawWalkingIn = false
            var sawBrewing = false
            
            // Step 1: Deliver timerFired event
            await machine.send(.timerFired)
            let stateAfterTimer = await machine.state
            
            // Check if we transitioned to .walkingIn
            if case .walkingIn = stateAfterTimer {
                sawWalkingIn = true
            }
            
            // Property violation check: we should be in .walkingIn, not .brewing
            if case .brewing = stateAfterTimer {
                XCTFail("Property violation: timerFired from .idle transitioned directly to .brewing without passing through .walkingIn")
                return
            }
            
            // Verify we're in .walkingIn (should always be true based on state machine logic)
            guard case .walkingIn = stateAfterTimer else {
                XCTFail("Property violation: timerFired from .idle did not transition to .walkingIn. Got: \(stateAfterTimer)")
                return
            }
            
            // Step 2: Complete the walk-in animation
            await machine.send(.walkInCompleted)
            let stateAfterWalkIn = await machine.state
            
            // Check if we transitioned to .brewing
            if case .brewing = stateAfterWalkIn {
                sawBrewing = true
            }
            
            // Verify the sequence: .walkingIn must have been seen before .brewing
            guard sawWalkingIn && sawBrewing else {
                XCTFail("Property violation: did not see complete sequence .walkingIn → .brewing")
                return
            }
            
            // Verify we're now in .brewing
            guard case .brewing = stateAfterWalkIn else {
                XCTFail("Expected .brewing state after walkInCompleted from .walkingIn. Got: \(stateAfterWalkIn)")
                return
            }
            
            successCount += 1
        }
        
        XCTAssertEqual(successCount, maxTests,
                       "Property 2 verified across \(successCount) random configurations: .walkingIn always precedes .brewing")
    }
    
    // MARK: - Property 4
    
    /// **Validates: Requirements 2.4, 9.2, 9.3**
    ///
    /// **Property 4: For any PauseReason, entering .paused cancels timer delivery**
    ///
    /// For any pause reason (`userPaused`, `dnd`, `displayLocked`, `sleep`), when
    /// the `StateMachine` enters a `.paused` state, no `timerFired` events should
    /// cause state transitions. The timer is effectively suspended.
    ///
    /// This property verifies that pausing **always** suspends the timer regardless
    /// of the pause reason, ensuring that breaks don't fire while the app is paused,
    /// the system is in Do Not Disturb mode, the display is locked, or the system
    /// is asleep.
    func testProperty4_pausingAlwaysSuspendsTimer() async {
        // Feature: slowbrew, Property 4: Pausing always suspends the timer
        
        let maxTests = 100
        var rng = SystemRandomNumberGenerator()
        var successCount = 0
        
        for _ in 0..<maxTests {
            // Generate a random PauseReason
            let allPauseReasons = PauseReason.allCases
            let pauseReason = allPauseReasons.randomElement()!
            
            // Create a fresh StateMachine in .idle state
            let machine = StateMachine()
            
            // Verify we start in .idle
            let initialState = await machine.state
            guard case .idle = initialState else {
                XCTFail("Test setup failure: expected .idle initial state, got \(initialState)")
                return
            }
            
            // Map the PauseReason to the corresponding AppEvent that triggers it
            let pauseEvent: AppEvent
            switch pauseReason {
            case .userPaused:
                pauseEvent = .pauseToggled
            case .dnd:
                pauseEvent = .dndBegan
            case .displayLocked:
                pauseEvent = .displayLocked
            case .sleep:
                pauseEvent = .systemSleep
            }
            
            // Deliver the pause event
            await machine.send(pauseEvent)
            
            // Verify we transitioned to .paused with the correct reason
            let pausedState = await machine.state
            guard case .paused(let reason, _) = pausedState else {
                XCTFail("Property violation: pause event \(pauseEvent) from .idle did not transition to .paused. Got: \(pausedState)")
                return
            }
            
            // Sanity check: verify the pause reason matches
            XCTAssertEqual(reason, pauseReason,
                          "Pause reason mismatch: expected \(pauseReason), got \(reason)")
            
            // Property test: deliver a timerFired event while in .paused state
            await machine.send(.timerFired)
            
            // Capture the state after the timerFired event
            let stateAfterTimerFired = await machine.state
            
            // Property: the state must remain .paused (timerFired must be ignored)
            guard case .paused(let reasonAfter, _) = stateAfterTimerFired else {
                XCTFail("Property violation: timerFired was not ignored in .paused(\(pauseReason)) state. State changed to: \(stateAfterTimerFired)")
                return
            }
            
            // Verify the pause reason is unchanged
            XCTAssertEqual(reasonAfter, pauseReason,
                          "Pause reason changed after timerFired: expected \(pauseReason), got \(reasonAfter)")
            
            // Additional verification: the state should be exactly the same
            // (timerFired should not mutate any part of the .paused state)
            XCTAssertEqual(stateAfterTimerFired, pausedState,
                          "State was mutated after timerFired in .paused state")
            
            successCount += 1
        }
        
        XCTAssertEqual(successCount, maxTests,
                       "Property 4 verified across \(successCount) random PauseReason values: .paused always ignores timerFired")
    }
    
    // MARK: - Property 10
    
    /// **Validates: Requirements 4.4, 3.3**
    ///
    /// **Property 10: countdownExpired from .brewing always → .walkingOut with opposite edge**
    ///
    /// For any `.brewing` state, delivering the `countdownExpired` event must
    /// transition the `StateMachine` to `.walkingOut`, and the walk-out edge must
    /// be the opposite of the walk-in edge recorded in the session.
    ///
    /// This property verifies that:
    /// 1. Countdown expiry **always** triggers the walk-out animation
    /// 2. The walk-out edge is **always** opposite to the walk-in edge (left → right, right → left)
    ///
    /// This ensures the character walks off in the opposite direction from which
    /// she entered, maintaining visual consistency.
    func testProperty10_countdownExpiryAlwaysTransitionsToWalkOut() async {
        // Feature: slowbrew, Property 10: Countdown expiry always transitions to walk-out
        
        let maxTests = 100
        var rng = SystemRandomNumberGenerator()
        var successCount = 0
        
        for _ in 0..<maxTests {
            // Generate random settings (they don't affect the transition logic,
            // but we test with varying configurations to ensure robustness)
            let breakInterval = Int.random(in: 15...180, using: &rng)
            let breakDuration = Int.random(in: 1...30, using: &rng)
            let launchAtLogin = Bool.random(using: &rng)
            let soundEnabled = Bool.random(using: &rng)
            
            let settings = Settings(
                breakInterval: breakInterval,
                breakDuration: breakDuration,
                launchAtLogin: launchAtLogin,
                soundEnabled: soundEnabled
            )
            let machine = StateMachine(settings: settings)
            
            // Path to .brewing: idle → timerFired → walkingIn → walkInCompleted → brewing
            
            // Step 1: Trigger break (idle → walkingIn)
            await machine.send(.timerFired)
            let walkingInState = await machine.state
            
            // Capture the walk-in edge
            guard case .walkingIn(let walkInEdge, _) = walkingInState else {
                XCTFail("Test setup failure: timerFired from .idle did not transition to .walkingIn. Got: \(walkingInState)")
                return
            }
            
            // Step 2: Complete walk-in animation (walkingIn → brewing)
            await machine.send(.walkInCompleted)
            let brewingState = await machine.state
            
            // Verify we're in .brewing state
            guard case .brewing = brewingState else {
                XCTFail("Test setup failure: walkInCompleted from .walkingIn did not transition to .brewing. Got: \(brewingState)")
                return
            }
            
            // Property test: Deliver countdownExpired event
            await machine.send(.countdownExpired)
            let resultState = await machine.state
            
            // Property assertion 1: State must be .walkingOut
            guard case .walkingOut(let walkOutEdge, _) = resultState else {
                XCTFail("Property violation: countdownExpired from .brewing did not transition to .walkingOut. Got: \(resultState)")
                return
            }
            
            // Property assertion 2: Walk-out edge must be opposite of walk-in edge
            let expectedWalkOutEdge = walkInEdge.opposite
            if walkOutEdge != expectedWalkOutEdge {
                XCTFail("Property violation: walk-out edge mismatch. Walk-in edge was \(walkInEdge), expected walk-out edge \(expectedWalkOutEdge), but got \(walkOutEdge)")
                return
            }
            
            // Verify the opposite relationship explicitly for clarity
            switch (walkInEdge, walkOutEdge) {
            case (.left, .right), (.right, .left):
                // Valid opposite pairs — property holds
                break
            default:
                XCTFail("Property violation: walk-in edge \(walkInEdge) and walk-out edge \(walkOutEdge) are not opposite")
                return
            }
            
            successCount += 1
        }
        
        XCTAssertEqual(successCount, maxTests,
                       "Property 10 verified across \(successCount) random configurations: countdownExpired from .brewing always → .walkingOut with opposite edge")
    }
    
    // MARK: - Property 5
    
    /// **Validates: Requirements 9.2, 9.3**
    ///
    /// **Property 5: Elapsed time is restored after DND or displayLocked pause ends**
    ///
    /// For any pause entered due to `dnd` or `displayLocked`, when the system event
    /// that caused the pause ends, the `StateMachine` transitions back to `.idle`
    /// with the timer resuming from the elapsed duration that was active before the
    /// pause began.
    ///
    /// This property verifies that DND and display-lock pauses **preserve elapsed time**
    /// (the timer continues from where it left off), as opposed to sleep/user-pause
    /// which reset the timer to zero. This ensures that breaks don't get artificially
    /// delayed when the system temporarily enters DND or the display locks.
    ///
    /// The property tests:
    /// 1. Start with .idle state with some elapsed time
    /// 2. Pause due to DND or displayLocked
    /// 3. Resume from the pause
    /// 4. Verify the timer continues from the elapsed time before the pause
    func testProperty5_dndOrLockResumeRestoresElapsedTime() async {
        // Feature: slowbrew, Property 5: Resuming from DND or display-lock restores elapsed time
        
        let maxTests = 100
        var rng = SystemRandomNumberGenerator()
        var successCount = 0
        
        for _ in 0..<maxTests {
            // Generate a random elapsed duration (0 to break interval - 1 minute)
            // We'll simulate this by creating an .idle state with a past timerStartedAt
            let elapsedSeconds = Int.random(in: 60...3600, using: &rng) // 1 minute to 1 hour
            let elapsedDuration = Duration.seconds(elapsedSeconds)
            
            // Generate a random pause reason from {dnd, displayLocked}
            let pauseReasons: [PauseReason] = [.dnd, .displayLocked]
            let pauseReason = pauseReasons.randomElement()!
            
            // Create a StateMachine with a backdated idle state to simulate elapsed time
            let now = Date()
            let timerStartedAt = now.addingTimeInterval(-Double(elapsedSeconds))
            let initialState = AppState.idle(timerStartedAt: timerStartedAt)
            let machine = StateMachine(initialState: initialState)
            
            // Verify we start in .idle with the correct timerStartedAt
            let stateBeforePause = await machine.state
            guard case .idle(let startTime) = stateBeforePause else {
                XCTFail("Test setup failure: expected .idle initial state, got \(stateBeforePause)")
                return
            }
            
            // Sanity check: verify the elapsed time calculation
            let actualElapsedBeforePause = now.timeIntervalSince(startTime)
            XCTAssertEqual(actualElapsedBeforePause, Double(elapsedSeconds), accuracy: 1.0,
                          "Test setup failure: elapsed time mismatch")
            
            // Map the PauseReason to the corresponding pause event
            let pauseEvent: AppEvent
            let resumeEvent: AppEvent
            switch pauseReason {
            case .dnd:
                pauseEvent = .dndBegan
                resumeEvent = .dndEnded
            case .displayLocked:
                pauseEvent = .displayLocked
                resumeEvent = .displayUnlocked
            default:
                XCTFail("Test setup failure: unexpected pause reason \(pauseReason)")
                return
            }
            
            // Step 1: Deliver the pause event
            await machine.send(pauseEvent)
            
            // Verify we transitioned to .paused with the correct reason
            let pausedState = await machine.state
            guard case .paused(let reason, let pausedSince) = pausedState else {
                XCTFail("Property violation: pause event \(pauseEvent) from .idle did not transition to .paused. Got: \(pausedState)")
                return
            }
            
            XCTAssertEqual(reason, pauseReason,
                          "Pause reason mismatch: expected \(pauseReason), got \(reason)")
            
            // Simulate some pause duration (random time between 1 second and 10 minutes)
            let pauseDurationSeconds = Int.random(in: 1...600, using: &rng)
            
            // Sleep for a small amount to simulate passage of time
            // (In a real test we'd use a mock clock, but for property testing we use minimal sleep)
            try? await Task.sleep(nanoseconds: 100_000) // 0.1 ms
            
            // Step 2: Deliver the resume event
            let resumeTime = Date()
            await machine.send(resumeEvent)
            
            // Capture the state after resume
            let resumedState = await machine.state
            
            // Property assertion: State must be .idle
            guard case .idle(let resumedTimerStartedAt) = resumedState else {
                XCTFail("Property violation: resume event \(resumeEvent) from .paused(\(pauseReason)) did not transition to .idle. Got: \(resumedState)")
                return
            }
            
            // Property assertion: The timer's elapsed time must be preserved
            // The resumed timerStartedAt should be adjusted backward by the original elapsed time
            //
            // Expected logic:
            //   - Before pause: timer had elapsed `elapsedSeconds` seconds
            //   - After resume: timer should continue from that point
            //   - Therefore: resumedTimerStartedAt should be approximately (resumeTime - elapsedSeconds)
            //
            // The elapsed time from the new timerStartedAt to resumeTime should equal
            // the original elapsed time (within a small tolerance for test execution time).
            
            let elapsedAfterResume = resumeTime.timeIntervalSince(resumedTimerStartedAt)
            
            // The elapsed time after resume should approximately equal the original elapsed time
            // We allow a tolerance of 2 seconds to account for test execution overhead
            let tolerance = 2.0
            
            if abs(elapsedAfterResume - Double(elapsedSeconds)) > tolerance {
                XCTFail(
                    "Property violation: elapsed time not restored after \(pauseReason) pause. " +
                    "Original elapsed: \(elapsedSeconds)s, elapsed after resume: \(elapsedAfterResume)s, " +
                    "difference: \(abs(elapsedAfterResume - Double(elapsedSeconds)))s (tolerance: \(tolerance)s). " +
                    "Timer was reset to zero instead of continuing from \(elapsedSeconds)s."
                )
                return
            }
            
            // Additional sanity check: verify the timer wasn't reset to zero
            // (i.e., resumedTimerStartedAt should NOT be approximately equal to resumeTime)
            let timeSinceResumeStart = resumeTime.timeIntervalSince(resumedTimerStartedAt)
            if timeSinceResumeStart < 1.0 {
                XCTFail(
                    "Property violation: timer was reset to zero after \(pauseReason) pause. " +
                    "Expected elapsed time ~\(elapsedSeconds)s, but got ~\(timeSinceResumeStart)s. " +
                    "The timer should have been restored to its pre-pause elapsed time, not reset."
                )
                return
            }
            
            successCount += 1
        }
        
        XCTAssertEqual(successCount, maxTests,
                       "Property 5 verified across \(successCount) random pause scenarios: DND/displayLocked resume restores elapsed time")
    }
}
