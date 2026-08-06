// AppEvent.swift
// Slowbrew
//
// All inputs to the StateMachine actor. Events are produced by timers,
// UI controls, and system notifications, then dispatched to StateMachine.send(_:).

import Foundation

/// Every event that can be delivered to the `StateMachine` actor.
///
/// Events that are invalid for the current `AppState` are silently ignored
/// in release builds. In `DEBUG` builds an `assertionFailure` is raised
/// to surface logic errors during development.
enum AppEvent {

    // MARK: Timer events

    /// Fired by `TimerService` when the break-interval countdown reaches zero.
    case timerFired

    // MARK: Animation completion events

    /// Fired by `SpriteAnimator` when the walk-in animation finishes playing.
    case walkInCompleted

    /// Fired by `SpriteAnimator` when the walk-out animation finishes playing.
    case walkOutCompleted

    // MARK: Break lifecycle events

    /// Fired by the countdown HUD when the break duration reaches zero.
    case countdownExpired

    /// Fired when the user taps the Snooze button during a break.
    case snoozeTapped

    // MARK: User control events

    /// Fired when the user selects Pause or Resume from the menu bar dropdown.
    case pauseToggled

    /// Fired when the user selects "Skip Next Break" from the menu bar dropdown.
    case skipNextBreak

    /// Fired when the user selects Quit from the menu bar dropdown.
    ///
    /// - Parameter force: `false` for the first quit request (deferred if a
    ///   break is active), `true` for an immediate unconditional quit.
    case quitRequested(force: Bool)

    // MARK: System events

    /// Fired by `SystemEventMonitor` when the system is about to sleep.
    case systemSleep

    /// Fired by `SystemEventMonitor` when the system wakes from sleep.
    case systemWake

    /// Fired by `SystemEventMonitor` when the display is locked.
    case displayLocked

    /// Fired by `SystemEventMonitor` when the display is unlocked.
    case displayUnlocked

    /// Fired by `SystemEventMonitor` when Do Not Disturb mode activates.
    case dndBegan

    /// Fired by `SystemEventMonitor` when Do Not Disturb mode deactivates.
    case dndEnded

    // MARK: Settings events

    /// Fired by `SettingsWindowController` when the user saves new settings.
    ///
    /// The new `Settings` value takes effect for the *next* scheduled break;
    /// any currently running timer continues unaffected.
    case settingsSaved(Settings)
}

// MARK: - CustomStringConvertible

extension AppEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .timerFired:           return "timerFired"
        case .walkInCompleted:      return "walkInCompleted"
        case .walkOutCompleted:     return "walkOutCompleted"
        case .countdownExpired:     return "countdownExpired"
        case .snoozeTapped:         return "snoozeTapped"
        case .pauseToggled:         return "pauseToggled"
        case .skipNextBreak:        return "skipNextBreak"
        case .quitRequested(let f): return "quitRequested(force: \(f))"
        case .systemSleep:          return "systemSleep"
        case .systemWake:           return "systemWake"
        case .displayLocked:        return "displayLocked"
        case .displayUnlocked:      return "displayUnlocked"
        case .dndBegan:             return "dndBegan"
        case .dndEnded:             return "dndEnded"
        case .settingsSaved(let s): return "settingsSaved(\(s))"
        }
    }
}

// MARK: - PauseReason

/// The reason the break-interval timer was suspended.
///
/// The reason determines how the timer resumes:
/// - `.dnd` and `.displayLocked` resume from the elapsed time recorded at
///   the moment the pause began (timer continues from where it left off).
/// - `.sleep` always resets the timer to zero on resume.
/// - `.userPaused` resets the timer to zero on resume (requirement 2.5).
enum PauseReason: Equatable, CaseIterable {

    /// The user explicitly paused via the menu bar dropdown.
    case userPaused

    /// The system entered Do Not Disturb mode.
    case dnd

    /// The display was locked or the user reached the login screen.
    case displayLocked

    /// The system went to sleep.
    case sleep
}

// MARK: - CustomStringConvertible

extension PauseReason: CustomStringConvertible {
    var description: String {
        switch self {
        case .userPaused:     return "userPaused"
        case .dnd:            return "dnd"
        case .displayLocked:  return "displayLocked"
        case .sleep:          return "sleep"
        }
    }
}
