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
        Settings {
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
            Task {
                await self?.stateMachine?.send(.quitRequested(force: force))
            }
        }
        
        // Wire overlay callbacks
        overlayController.onSnooze = { [weak self] in
            Task {
                await self?.handleSnooze()
            }
        }
        
        // Wire settings callbacks
        settingsWindowController.onSettingsSaved = { [weak self] newSettings in
            Task {
                await self?.stateMachine?.send(.settingsSaved(newSettings))
            }
        }
        
        // Set terminate handler
        Task {
            await stateMachine.setTerminateHandler { [weak self] in
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
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
        // Check if quit is deferred
        guard let machine = stateMachine else {
            return .terminateNow
        }
        
        Task {
            let isDeferred = await machine.isDeferredQuitPending
            if isDeferred {
                // Quit is deferred during active break
                return
            }
        }
        
        // Check current state
        Task {
            let state = await machine.state
            if case .brewing = state {
                // Defer termination during active break
                menuBarController.setDeferredQuitPending(true)
                await machine.send(.quitRequested(force: false))
            }
        }
        
        return .terminateLater
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
        // Update menu bar
        menuBarController.update(state: state, snoozeCount: dailySnoozeCounter.remaining)
        
        // Handle overlay presentation
        switch state {
        case .brewing:
            // Show overlay on the focused screen
            let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main
            if let targetScreen = screen {
                overlayController.show(on: targetScreen)
            }
            
        case .idle, .paused:
            // Dismiss overlay
            overlayController.dismiss()
            
        case .walkingIn, .walkingOut:
            // Animation states - overlay may or may not be visible
            break
        }
        
        // Handle timer state
        switch state {
        case .idle:
            // Restart timer with current settings
            let settings = settingsStore.load()
            await timerService.start(interval: settings.breakIntervalDuration)
            
        case .paused:
            // Cancel timer
            await timerService.cancel()
            
        default:
            break
        }
    }
    
    // MARK: - Event Handlers
    
    private func handlePauseToggle() async {
        let state = await stateMachine.state
        
        switch state {
        case .paused:
            await stateMachine.send(.resumeFromPause)
            
        case .idle, .walkingIn, .brewing, .walkingOut:
            await stateMachine.send(.userPaused)
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
