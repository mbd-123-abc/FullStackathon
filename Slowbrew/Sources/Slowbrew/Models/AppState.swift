// AppState.swift
// Slowbrew
//
// The single source of truth for the application's runtime state.
// All mutations flow through StateMachine actor to ensure serialised access.

import Foundation

/// The complete set of states the Slowbrew application can be in at any point.
///
/// `AppState` is the single source of truth fed through the unidirectional
/// state machine. Every field is immutable — new states are produced by the
/// `StateMachine` actor in response to `AppEvent` values.
enum AppState: Equatable {

    /// The timer is running and no break is in progress.
    ///
    /// - Parameter timerStartedAt: The wall-clock time at which the current
    ///   break-interval timer was (re)started. Used to calculate elapsed time
    ///   when a pause or skip event occurs.
    case idle(timerStartedAt: Date)

    /// Slowbrew is walking onto the screen from the given edge.
    ///
    /// The break overlay has not yet been presented; the state machine waits
    /// for the `walkInCompleted` event before advancing to `.brewing`.
    ///
    /// - Parameters:
    ///   - edge: The horizontal edge from which Slowbrew enters.
    ///   - startedAt: When the walk-in animation began.
    case walkingIn(edge: HorizontalEdge, startedAt: Date)

    /// The full-screen break overlay is active and the countdown is running.
    ///
    /// - Parameters:
    ///   - startedAt: When the overlay became visible (walk-in completed).
    ///   - snoozeRemaining: How many snooze actions the user can still
    ///     activate today (0–3). When this reaches 0 the snooze button
    ///     is hidden.
    case brewing(startedAt: Date, snoozeRemaining: Int)

    /// Slowbrew is walking off the screen toward the given edge.
    ///
    /// The overlay is in the process of being dismissed; the state machine
    /// waits for the `walkOutCompleted` event before returning to `.idle`.
    ///
    /// - Parameters:
    ///   - edge: The horizontal edge Slowbrew exits toward.
    ///     Must always be `walkingIn.edge.opposite` for the same session.
    ///   - startedAt: When the walk-out animation began.
    case walkingOut(edge: HorizontalEdge, startedAt: Date)

    /// The break-interval timer is suspended.
    ///
    /// - Parameters:
    ///   - reason: Why the timer was paused.
    ///   - since: When the pause began (used to restore elapsed time on resume
    ///     for DND/display-lock reasons; discarded on system-wake resume).
    case paused(reason: PauseReason, since: Date)
}

// MARK: - CustomStringConvertible

extension AppState: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle(let t):
            return "idle(timerStartedAt: \(t))"
        case .walkingIn(let edge, let t):
            return "walkingIn(edge: \(edge), startedAt: \(t))"
        case .brewing(let t, let snooze):
            return "brewing(startedAt: \(t), snoozeRemaining: \(snooze))"
        case .walkingOut(let edge, let t):
            return "walkingOut(edge: \(edge), startedAt: \(t))"
        case .paused(let reason, let since):
            return "paused(reason: \(reason), since: \(since))"
        }
    }
}
