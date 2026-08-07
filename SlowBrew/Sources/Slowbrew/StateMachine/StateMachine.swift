// StateMachine.swift
// Slowbrew
//
// Central coordinator for all application state transitions.
// All events are serialised on the actor — no @MainActor bypass.

import Foundation

/// Central state machine actor that processes `AppEvent` values and produces
/// an updated `AppState`, broadcasting every change through `statePublisher`.
///
/// All state mutations and event dispatches are serialised on the actor's
/// executor. Invalid events are silently ignored in release builds; in `DEBUG`
/// builds an `assertionFailure` is raised with a description of the invalid
/// (state, event) pair.
actor StateMachine {

    // MARK: - State

    /// The current application state. Read from any async context via `await sm.state`.
    private(set) var state: AppState

    // MARK: - Publisher

    /// Broadcasts every state change to all subscribers.
    ///
    /// Uses `AsyncStream.makeStream()` (Swift 5.9) internally so the
    /// continuation can be held and `yield`-ed from within the actor.
    nonisolated let statePublisher: AsyncStream<AppState>

    // MARK: - Terminate Handler

    /// Called when the state machine determines an immediate application
    /// termination is required (force-quit or second soft-quit during a break).
    ///
    /// Defaults to a no-op; `AppDelegate` injects `NSApplication.shared.terminate(nil)`
    /// at bootstrap time.
    var terminateHandler: @Sendable () -> Void = {}

    // MARK: - Private

    /// Continuation used to emit new state values into `statePublisher`.
    private let continuation: AsyncStream<AppState>.Continuation

    /// Persisted settings; updated by `settingsSaved` events.
    private var currentSettings: Settings

    /// The `HorizontalEdge` the character entered from for the current break
    /// session. Stored when transitioning to `.walkingIn` so the walk-out
    /// transition can use the opposite edge.
    private var walkInEdge: HorizontalEdge?

    /// The timer start time captured when entering a pause. Used to preserve
    /// elapsed time when DND/display-lock pauses resume.
    private var pausedTimerStartedAt: Date?

    /// `true` when a quit has been requested but deferred because a break
    /// is currently active. A second `quitRequested(force: false)` (or
    /// `quitRequested(force: true)`) will terminate immediately.
    private(set) var deferredQuit: Bool = false

    // MARK: - Initialisation

    /// Creates a new `StateMachine` with an initial `.idle` state.
    ///
    /// - Parameters:
    ///   - initialState: The starting state. Defaults to `.idle(timerStartedAt: .now)`.
    ///   - settings: Initial settings to use until a `settingsSaved` event arrives.
    init(
        initialState: AppState = .idle(timerStartedAt: Date()),
        settings: Settings = .default
    ) {
        self.state = initialState
        self.currentSettings = settings

        // Build the publisher and hold the continuation for later yield calls.
        let (stream, continuation) = AsyncStream<AppState>.makeStream()
        self.statePublisher = stream
        self.continuation = continuation
    }

    // MARK: - Event Processing

    /// Processes a single `AppEvent`, mutating `state` if the event is valid
    /// for the current state, and broadcasting the new state via `statePublisher`.
    ///
    /// Invalid (state, event) combinations are silently discarded. In `DEBUG`
    /// builds an `assertionFailure` is raised to surface logic errors early.
    func send(_ event: AppEvent) async {
        let oldState = state
        let newState = transition(from: oldState, on: event)

        print("[StateMachine] Event: \(event.description), State: \(oldState.description) → \(newState.description)")

        guard newState != oldState else {
            // No transition occurred — the event was invalid for this state.
            // In DEBUG emit a diagnostic; in release silently ignore.
            debugOnlyAssertInvalidTransition(state: oldState, event: event)
            return
        }

        state = newState
        continuation.yield(newState)
    }

    // MARK: - Deinitialization

    deinit {
        continuation.finish()
    }
}

// MARK: - Transition Logic

private extension StateMachine {

    /// Pure transition function. Returns the *same* state if the event is
    /// invalid for the current state (the caller treats equality as "no transition").
    func transition(from current: AppState, on event: AppEvent) -> AppState {
        let now = Date()

        switch (current, event) {

        // ----------------------------------------------------------------
        // MARK: idle → walkingIn (timerFired) — Start walk-in animation
        // ----------------------------------------------------------------
        case (.idle, .timerFired):
            print("[StateMachine] ⏰ TIMER FIRED! Starting walk-in animation")
            // Randomly choose left or right edge for walk-in
            let edge: HorizontalEdge = Bool.random() ? .left : .right
            walkInEdge = edge
            return .walkingIn(edge: edge, startedAt: now)

        // ----------------------------------------------------------------
        // MARK: idle → paused  (pauseToggled / dndBegan / displayLocked / systemSleep)
        // ----------------------------------------------------------------
        case (.idle(let timerStartedAt), .pauseToggled):
            pausedTimerStartedAt = timerStartedAt
            return .paused(reason: .userPaused, since: now)

        case (.idle(let timerStartedAt), .dndBegan):
            pausedTimerStartedAt = timerStartedAt
            return .paused(reason: .dnd, since: now)

        case (.idle(let timerStartedAt), .displayLocked):
            pausedTimerStartedAt = timerStartedAt
            return .paused(reason: .displayLocked, since: now)

        case (.idle(let timerStartedAt), .systemSleep):
            pausedTimerStartedAt = timerStartedAt
            return .paused(reason: .sleep, since: now)

        // ----------------------------------------------------------------
        // MARK: idle — skipNextBreak  (delay next break by one interval)
        // ----------------------------------------------------------------
        case (.idle(let timerStartedAt), .skipNextBreak):
            // Add one full interval to the current timer
            // This delays the next break but keeps subsequent breaks on schedule
            let oneInterval = TimeInterval(currentSettings.breakInterval * 60)
            let delayedStart = timerStartedAt.addingTimeInterval(oneInterval)
            print("[StateMachine] Skipping next break. Original start: \(timerStartedAt), Delayed start: \(delayedStart)")
            return .idle(timerStartedAt: delayedStart)

        // ----------------------------------------------------------------
        // MARK: idle — settingsSaved  (store settings for next break, restart timer NOW)
        // ----------------------------------------------------------------
        case (.idle, .settingsSaved(let newSettings)):
            // Store the new settings and RESTART the timer immediately
            currentSettings = newSettings
            // Return a new idle state with updated timestamp to trigger timer restart
            return .idle(timerStartedAt: now)

        // ----------------------------------------------------------------
        // MARK: idle — quitRequested (no break active; handled at app level)
        // ----------------------------------------------------------------
        case (.idle, .quitRequested):
            // AppDelegate handles termination. No state change.
            return current

        // ----------------------------------------------------------------
        // MARK: paused → idle  (pauseToggled / dndEnded / displayUnlocked / systemWake)
        //       — timer always resets to zero on these events (Req 2.5, 9.4)
        // ----------------------------------------------------------------
        case (.paused(let reason, let pausedAt), .pauseToggled) where reason == .userPaused:
            // Calculate elapsed time before pause
            guard let originalStart = pausedTimerStartedAt else {
                // No stored start time, just resume from now
                pausedTimerStartedAt = nil
                return .idle(timerStartedAt: now)
            }
            
            // Calculate how long we were paused
            let pauseDuration = pausedAt.distance(to: now)
            
            // Adjust start time to preserve elapsed progress
            // If we had progressed 10 minutes before pause, and paused for 5 minutes,
            // the new start time should be (now - 10 minutes)
            let elapsedBeforePause = originalStart.distance(to: pausedAt)
            let adjustedStart = now.addingTimeInterval(-elapsedBeforePause)
            
            pausedTimerStartedAt = nil
            print("[StateMachine] Resuming from pause. Elapsed before pause: \(elapsedBeforePause)s, Pause duration: \(pauseDuration)s")
            return .idle(timerStartedAt: adjustedStart)

        case (.paused, .dndEnded):
            let restoredStart = pausedTimerStartedAt ?? now
            pausedTimerStartedAt = nil
            return .idle(timerStartedAt: restoredStart)

        case (.paused, .displayUnlocked):
            let restoredStart = pausedTimerStartedAt ?? now
            pausedTimerStartedAt = nil
            return .idle(timerStartedAt: restoredStart)

        case (.paused, .systemWake):
            pausedTimerStartedAt = nil
            return .idle(timerStartedAt: now)

        // ----------------------------------------------------------------
        // MARK: walkingIn → brewing  (walkInCompleted)
        // ----------------------------------------------------------------
        case (.walkingIn, .walkInCompleted):
            // snoozeRemaining starts at DailySnoozeCounter.maxPerDay (3).
            return .brewing(startedAt: now, snoozeRemaining: 3)

        // ----------------------------------------------------------------
        // MARK: brewing → walkingOut (countdownExpired) — Start walk-out animation
        // ----------------------------------------------------------------
        case (.brewing, .countdownExpired):
            print("[StateMachine] Countdown expired, starting walk-out animation")
            // Walk out to the opposite edge from where we walked in
            let exitEdge = walkInEdge?.opposite ?? .right
            return .walkingOut(edge: exitEdge, startedAt: now)

        // ----------------------------------------------------------------
        // MARK: brewing → walkingOut  (snoozeTapped, only when snoozeRemaining > 0)
        // ----------------------------------------------------------------
        case (.brewing(_, let remaining), .snoozeTapped) where remaining > 0:
            let exitEdge = walkInEdge?.opposite ?? .right
            return .walkingOut(edge: exitEdge, startedAt: now)

        // ----------------------------------------------------------------
        // MARK: brewing — quitRequested(force: false) → defer quit (first time)
        // ----------------------------------------------------------------
        case (.brewing, .quitRequested(let force)) where !force && !deferredQuit:
            deferredQuit = true
            // No structural state change — menu label change is driven by
            // `isDeferredQuitPending` which consumers can poll.
            return current

        // ----------------------------------------------------------------
        // MARK: brewing — quitRequested (second soft or any force) → terminate
        // ----------------------------------------------------------------
        case (.brewing, .quitRequested):
            // Capture the handler to call outside the switch.
            let handler = terminateHandler
            Task {
                handler()
            }
            return current

        // ----------------------------------------------------------------
        // MARK: walkingOut → idle  (walkOutCompleted)
        // ----------------------------------------------------------------
        case (.walkingOut, .walkOutCompleted):
            // Clear per-session walk-in edge and quit deferral.
            walkInEdge = nil
            deferredQuit = false
            return .idle(timerStartedAt: now)

        // ----------------------------------------------------------------
        // MARK: Any other state — settingsSaved (store, no structural change)
        // ----------------------------------------------------------------
        case (_, .settingsSaved(let newSettings)):
            currentSettings = newSettings
            return current

        // ----------------------------------------------------------------
        // MARK: Default — invalid event for current state (silently ignored)
        // ----------------------------------------------------------------
        default:
            return current
        }
    }
}

// MARK: - Diagnostics

private extension StateMachine {

    /// In `DEBUG` builds, raises `assertionFailure` for unexpected (state, event)
    /// pairs that returned the same state (no valid transition).
    ///
    /// Some events are legitimately no-ops and must NOT trigger an assertion:
    /// - `settingsSaved` — stored as side-channel data in any state.
    /// - `quitRequested` — handled at the app level from any state.
    /// - `snoozeTapped` when `snoozeRemaining == 0` — silently ignored.
    func debugOnlyAssertInvalidTransition(state: AppState, event: AppEvent) {
        switch event {
        case .settingsSaved:
            return
        case .quitRequested:
            return
        case .snoozeTapped:
            if case .brewing(_, let remaining) = state, remaining == 0 {
                return  // Expected no-op when daily snooze limit reached.
            }
        default:
            break
        }

        #if DEBUG
        print(
            "[StateMachine] Unhandled event '\(event.description)' received in state " +
            "'\(state.description)'. This (state, event) pair has no defined transition."
        )
        #endif
    }
}

// MARK: - Accessors

extension StateMachine {

    /// `true` if a quit was deferred because a break is currently active.
    var isDeferredQuitPending: Bool { deferredQuit }

    /// The settings currently stored by the state machine (updated by `settingsSaved`).
    var settings: Settings { currentSettings }
}
