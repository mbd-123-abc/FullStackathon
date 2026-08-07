// TimerService.swift
// Slowbrew
//
// Clock-injectable actor that counts down a break interval and fires a callback
// when the interval elapses. Supports cancellation and elapsed-time queries for
// pause/resume logic.

import Foundation

// MARK: - TimerService

/// A `Clock`-generic actor that sleeps for a configurable `interval` and then
/// invokes an `onTimerFired` callback.
///
/// Injecting a custom `Clock` (e.g. `TestClock`) makes the service fully
/// deterministic in unit tests without any real-time waiting.
///
/// ```swift
/// let timer = TimerService(clock: ContinuousClock()) {
///     await stateMachine.send(.timerFired)
/// }
///
/// // Start a 60-minute countdown:
/// await timer.start(interval: .seconds(3600))
///
/// // Later, read how much time has passed:
/// let soFar = await timer.elapsed   // e.g. Duration.seconds(120)
///
/// // Cancel without firing the callback:
/// await timer.cancel()
/// ```
///
/// ## Thread safety
/// All state is isolated to the actor's executor. `onTimerFired` is `@Sendable`
/// so it can be called from the internal `Task` without data races.
///
/// ## Requirements
/// Implements requirements 2.1 (timer fires break), 2.4 (pausing suspends timer),
/// and 2.5 (sleep/wake resets timer to zero).
actor TimerService<C: Clock> where C.Duration == Duration {

    // MARK: - Types

    /// The instant type exposed by the injected clock.
    private typealias Instant = C.Instant

    // MARK: - Callback

    /// Called on successful timer completion (i.e. the full `interval` elapsed
    /// without cancellation). Not called when `cancel()` is invoked.
    let onTimerFired: @Sendable () async -> Void

    // MARK: - Injected clock

    private let clock: C

    // MARK: - Mutable state

    /// The clock instant at which the most recent `start(interval:)` was called.
    /// `nil` when no timer is active (before first start or after cancellation).
    private var startInstant: Instant?

    /// The active background `Task` sleeping until the interval elapses.
    /// `nil` when idle or cancelled.
    private var activeTask: Task<Void, Never>?

    // MARK: - Initialisation

    /// Creates a `TimerService` backed by the given `clock`.
    ///
    /// - Parameters:
    ///   - clock: The `Clock` implementation to use for time measurement and
    ///     sleeping. Defaults to `ContinuousClock()`.
    ///   - onTimerFired: Async closure invoked when the interval elapses without
    ///     cancellation. Must be `@Sendable`.
    init(
        clock: C,
        onTimerFired: @escaping @Sendable () async -> Void
    ) {
        self.clock = clock
        self.onTimerFired = onTimerFired
    }

    // MARK: - Public API

    /// Starts a new countdown for `interval`.
    ///
    /// If a previous timer task is already running it is cancelled first
    /// (without invoking the callback). `elapsed` is reset to `.zero` because
    /// `startInstant` is updated to `clock.now`.
    ///
    /// - Parameter interval: The `Duration` to sleep before firing `onTimerFired`.
    func start(interval: Duration) async {
        // Cancel any already-running task (no callback).
        cancelActiveTask()

        // Record the start instant so `elapsed` computes correctly.
        let now = clock.now
        startInstant = now

        print("[TimerService] Starting timer for interval: \(interval)")

        // Capture `self` weakly-equivalent via unowned actor reference.
        // The Task holds an unstructured reference; we clean it up on completion.
        let fireCallback = onTimerFired
        let deadline = now.advanced(by: interval)

        activeTask = Task { [self] in
            do {
                // Sleep until the deadline. `CancellationError` is thrown if
                // `cancel()` is called before the deadline.
                try await clock.sleep(until: deadline, tolerance: nil)
                // Interval elapsed normally — fire the callback.
                print("[TimerService] Timer fired! Invoking callback.")
                await fireCallback()
            } catch {
                // Task was cancelled (CancellationError) — do NOT fire callback.
                print("[TimerService] Timer cancelled before firing.")
            }

            // Clear the active-task reference so `elapsed` returns .zero
            // once the countdown is complete or cancelled.
            await clearActiveTask()
        }
    }

    /// Cancels the currently running timer task without invoking `onTimerFired`.
    ///
    /// Safe to call when no timer is active (no-op in that case).
    func cancel() {
        cancelActiveTask()
        startInstant = nil
    }

    /// The duration elapsed since the last `start(interval:)` call.
    ///
    /// Returns `.zero` when no timer is active (i.e. before the first `start`,
    /// after a `cancel()`, or after the callback has fired).
    var elapsed: Duration {
        guard let start = startInstant, activeTask != nil else {
            return .zero
        }
        return start.duration(to: clock.now)
    }

    // MARK: - Private helpers

    /// Cancels and clears `activeTask` without touching `startInstant`.
    private func cancelActiveTask() {
        activeTask?.cancel()
        activeTask = nil
    }

    /// Called by the internal `Task` upon completion (successful or cancelled)
    /// to reset internal state.
    private func clearActiveTask() {
        activeTask = nil
        startInstant = nil
    }
}

// MARK: - Convenience initialiser for ContinuousClock

extension TimerService where C == ContinuousClock {

    /// Creates a `TimerService` using the system `ContinuousClock`.
    ///
    /// - Parameter onTimerFired: Async closure invoked when the interval elapses.
    init(onTimerFired: @escaping @Sendable () async -> Void) {
        self.init(clock: ContinuousClock(), onTimerFired: onTimerFired)
    }
}

// MARK: - Type alias

/// A `TimerService` backed by the live system `ContinuousClock`.
///
/// Use this alias in production code; inject `TimerService<SomeMockClock>` in tests.
typealias LiveTimerService = TimerService<ContinuousClock>
