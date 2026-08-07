// SystemEventMonitor.swift
// Slowbrew
//
// Monitors system events (sleep/wake, display lock/unlock, DND) and forwards them
// as AppEvent values to the StateMachine.

import Foundation
import AppKit

/// Monitors macOS system events and translates them into `AppEvent` values.
///
/// **Monitored Events:**
/// - `NSWorkspace.willSleepNotification` → `.systemSleep`
/// - `NSWorkspace.didWakeNotification` → `.systemWake`
/// - Screen lock distributed notification → `.displayLocked`
/// - Screen unlock distributed notification → `.displayUnlocked`
/// - DND prefs changed notification → `.dndBegan` / `.dndEnded`
///
/// - Validates: Requirements 9.2, 9.3, 9.4
final class SystemEventMonitor {
    
    // MARK: - Properties
    
    /// Callback invoked when a system event occurs.
    ///
    /// The handler receives the corresponding `AppEvent` and is responsible for
    /// forwarding it to the `StateMachine`.
    private var eventHandler: ((AppEvent) -> Void)?
    
    /// Notification observers for cleanup.
    private var observers: [NSObjectProtocol] = []
    
    // MARK: - Public API
    
    /// Starts monitoring system events and calls the handler for each event.
    ///
    /// - Parameter handler: Closure called with the corresponding `AppEvent` when a system event occurs.
    ///
    /// **Requirement 9.2:** DND mode pauses/resumes the timer.
    /// **Requirement 9.3:** Display lock pauses/resumes the timer.
    /// **Requirement 9.4:** System sleep/wake resets the timer.
    func start(handler: @escaping (AppEvent) -> Void) {
        self.eventHandler = handler
        
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()
        
        // Sleep notification
        let sleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.eventHandler?(.systemSleep)
        }
        observers.append(sleepObserver)
        
        // Wake notification
        let wakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.eventHandler?(.systemWake)
        }
        observers.append(wakeObserver)
        
        // Screen lock notification
        // The distributed notification name for screen lock is "com.apple.screenIsLocked"
        let lockObserver = distributedCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.eventHandler?(.displayLocked)
        }
        observers.append(lockObserver)
        
        // Screen unlock notification
        // The distributed notification name for screen unlock is "com.apple.screenIsUnlocked"
        let unlockObserver = distributedCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.eventHandler?(.displayUnlocked)
        }
        observers.append(unlockObserver)
        
        // DND (Focus) notifications
        // macOS 13+ uses "com.apple.notificationcenterui.dndprefs" distributed notification
        let dndObserver = distributedCenter.addObserver(
            forName: NSNotification.Name("com.apple.notificationcenterui.dndprefs"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // The notification userInfo contains the DND state
            // We need to check if DND is enabled or disabled
            if let userInfo = notification.userInfo as? [String: Any],
               let enabled = userInfo["enabled"] as? Bool {
                if enabled {
                    self?.eventHandler?(.dndBegan)
                } else {
                    self?.eventHandler?(.dndEnded)
                }
            }
        }
        observers.append(dndObserver)
    }
    
    /// Stops monitoring system events and unregisters all observers.
    ///
    /// Safe to call even if `start(handler:)` was never called.
    func stop() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()
        
        for observer in observers {
            notificationCenter.removeObserver(observer)
            distributedCenter.removeObserver(observer)
        }
        
        observers.removeAll()
        eventHandler = nil
    }
    
    deinit {
        stop()
    }
}
