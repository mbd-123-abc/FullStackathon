// SlowbrewApp.swift
// Slowbrew
//
// Main entry point for the Slowbrew macOS menu bar application.
// The app runs as LSUIElement (no Dock icon); all UI surfaces through
// the system menu bar via MenuBarController.

import AppKit
import SwiftUI

@main
struct SlowbrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Services
    
    private var stateMachine: StateMachine!
    private var timerService: LiveTimerService!
    private var settingsStore: SettingsStore!
    private var dailySnoozeCounter: DailySnoozeCounter!
    
    // MARK: - Controllers
    
    private var menuBarController: MenuBarController!
    private var overlayController: OverlayWindowController!
    private var settingsWindowController: SettingsWindowController!
    
    // MARK: - Monitors
    
    private var systemEventMonitor: SystemEventMonitor!
    
    // MARK: - State Subscription
    
    private var stateSubscriptionTask: Task<Void, Never>?
    
    // MARK: - Break Countdown
    
    /// Timer that fires when the break duration elapses
    private var breakCountdownTimer: Timer?
    
    /// When the current break started (for countdown calculation)
    private var breakStartTime: Date?
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services
        settingsStore = SettingsStore.shared
        let settings = settingsStore.load()
        
        dailySnoozeCounter = DailySnoozeCounter()
        dailySnoozeCounter.resetIfNewDay()
        
        stateMachine = StateMachine()
        
        timerService = LiveTimerService { [weak self] in
            await self?.stateMachine?.send(.timerFired)
        }
        
        // Initialize controllers
        menuBarController = MenuBarController()
        overlayController = OverlayWindowController()
        settingsWindowController = SettingsWindowController(settingsStore: settingsStore)
        
        // Initialize system event monitor
        systemEventMonitor = SystemEventMonitor()
        systemEventMonitor.start { [weak self] event in
            Task {
                await self?.stateMachine?.send(event)
            }
        }
        
        // Wire menu bar callbacks
        menuBarController.onPauseToggle = { [weak self] in
            Task {
                await self?.handlePauseToggle()
            }
        }
        
        menuBarController.onSettings = { [weak self] in
            self?.showSettings()
        }
        
        menuBarController.onSkipNextBreak = { [weak self] in
            Task {
                await self?.stateMachine?.send(.skipNextBreak)
            }
        }
        
        menuBarController.onQuit = { [weak self] force in
            // Directly terminate the app when Quit is clicked
            NSApplication.shared.terminate(nil)
        }
        
        // Wire overlay callbacks
        overlayController.onSnooze = { [weak self] in
            Task {
                await self?.handleSnooze()
            }
        }
        
        overlayController.onCountdownExpired = { [weak self] in
            Task {
                print("[AppDelegate] Countdown expired, sending countdownExpired event")
                await self?.stateMachine?.send(.countdownExpired)
            }
        }
        
        // Wire settings callbacks
        settingsWindowController.onSettingsSaved = { [weak self] newSettings in
            Task {
                await self?.stateMachine?.send(.settingsSaved(newSettings))
            }
        }
        
        // Set terminate handler
        stateMachine.terminateHandler = { [weak self] in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
        
        // Subscribe to state changes
        subscribeToStateChanges()
        
        // Start the initial timer
        Task {
            await timerService.start(interval: settings.breakIntervalDuration)
        }
        
        // Update menu bar with initial state
        Task {
            let state = await stateMachine.state
            menuBarController.update(state: state, snoozeCount: dailySnoozeCounter.remaining)
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Check if quit is deferred by checking current state synchronously
        // For now, just allow immediate termination
        return .terminateNow
    }
    
    // MARK: - State Subscription
    
    private func subscribeToStateChanges() {
        stateSubscriptionTask = Task { [weak self] in
            guard let self = self, let machine = self.stateMachine else { return }
            
            for await state in await machine.statePublisher {
                await self.handleStateChange(state)
            }
        }
    }
    
    @MainActor
    private func handleStateChange(_ state: AppState) async {
        print("[AppDelegate] State changed to: \(state)")
        
        // Update menu bar
        menuBarController.update(state: state, snoozeCount: dailySnoozeCounter.remaining)
        
        // Handle overlay presentation
        switch state {
        case .walkingIn(let edge, _):
            // Show overlay on the focused screen and start walk-in animation
            let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main
            if let targetScreen = screen {
                print("[AppDelegate] Starting walk-in animation from \(edge)")
                overlayController.showWalkIn(on: targetScreen, from: edge) { [weak self] in
                    guard let self = self else { return }
                    Task {
                        await self.stateMachine?.send(.walkInCompleted)
                    }
                }
            }
            
        case .brewing:
            // Overlay should already be visible from walk-in; start brewing animation
            let settings = settingsStore.load()
            let durationSeconds = TimeInterval(settings.breakDuration * 60)
            print("[AppDelegate] Starting brewing animation for \(settings.breakDuration) minutes (\(durationSeconds) seconds)")
            overlayController.startBrewing(duration: durationSeconds)
            
        case .walkingOut(let edge, _):
            // Start walk-out animation
            print("[AppDelegate] Starting walk-out animation toward \(edge)")
            overlayController.startWalkOut(toward: edge) { [weak self] in
                guard let self = self else { return }
                Task {
                    await self.stateMachine?.send(.walkOutCompleted)
                }
            }
            
        case .idle:
            // Dismiss overlay and restart timer
            overlayController.dismiss()
            let settings = settingsStore.load()
            await timerService.start(interval: settings.breakIntervalDuration)
            
        case .paused:
            // Cancel timer
            await timerService.cancel()
        }
    }
    
    // MARK: - Event Handlers
    
    private func handlePauseToggle() async {
        let state = await stateMachine.state
        
        switch state {
        case .paused:
            await stateMachine.send(.pauseToggled)
            
        case .idle, .walkingIn, .brewing, .walkingOut:
            await stateMachine.send(.pauseToggled)
        }
    }
    
    private func handleSnooze() async {
        // Check if snooze is available
        guard dailySnoozeCounter.increment() else {
            // No snoozes remaining - don't send event
            return
        }
        
        await stateMachine.send(.snoozeTapped)
    }
    
    @MainActor
    private func showSettings() {
        settingsWindowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
