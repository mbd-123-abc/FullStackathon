// MenuBarController.swift
// Slowbrew
//
// Manages the macOS menu bar status item and dropdown menu.

import AppKit

/// Manages the menu bar status item and dynamically builds the dropdown menu
/// based on the current `AppState` and snooze count.
///
/// **Menu Items:**
/// - "Pause" / "Resume" (depending on state)
/// - "Settings"
/// - "Skip Next Break"
/// - "Quit" / "Quit (confirm)" (when quit is deferred)
///
/// - Validates: Requirements 1.1, 1.2, 1.3, 1.4
final class MenuBarController {
    
    // MARK: - Properties
    
    /// The `NSStatusItem` displayed in the macOS menu bar.
    private var statusItem: NSStatusItem?
    
    /// Callback invoked when the user selects "Pause" or "Resume".
    var onPauseToggle: (() -> Void)?
    
    /// Callback invoked when the user selects "Settings".
    var onSettings: (() -> Void)?
    
    /// Callback invoked when the user selects "Skip Next Break".
    var onSkipNextBreak: (() -> Void)?
    
    /// Callback invoked when the user selects "Quit".
    ///
    /// - Parameter force: `true` if this is a second quit request (force quit).
    var onQuit: ((_ force: Bool) -> Void)?
    
    /// Whether a deferred quit is currently pending.
    ///
    /// When `true`, the "Quit" menu item label changes to "Quit (confirm)".
    private var isDeferredQuitPending: Bool = false
    
    // MARK: - Initialization
    
    /// Creates a `MenuBarController` and installs the status item.
    ///
    /// **Requirement 1.1:** The app displays a menu bar icon at all times while running.
    init() {
        setupStatusItem()
    }
    
    // MARK: - Public API
    
    /// Updates the menu based on the current `AppState` and snooze count.
    ///
    /// - Parameters:
    ///   - state: The current `AppState`.
    ///   - snoozeCount: The number of snoozes remaining for today.
    ///
    /// **Requirement 1.2:** Menu displays "Pause" or "Resume" depending on state.
    /// **Requirement 1.3:** "Quit (confirm)" label shown when quit is deferred.
    func update(state: AppState, snoozeCount: Int) {
        guard statusItem != nil else { return }
        
        // Build the menu dynamically
        let menu = NSMenu()
        
        // Pause / Resume item
        let pauseResumeTitle: String
        switch state {
        case .paused:
            pauseResumeTitle = "Resume"
        default:
            pauseResumeTitle = "Pause"
        }
        let pauseItem = menu.addItem(withTitle: pauseResumeTitle, action: #selector(pauseToggleTapped), keyEquivalent: "")
        pauseItem.target = self
        
        // Settings item
        let settingsItem = menu.addItem(withTitle: "Settings", action: #selector(settingsTapped), keyEquivalent: ",")
        settingsItem.target = self
        
        // Skip Next Break item
        let skipItem = menu.addItem(withTitle: "Skip Next Break", action: #selector(skipNextBreakTapped), keyEquivalent: "")
        skipItem.target = self
        
        // Separator
        menu.addItem(.separator())
        
        // Quit item
        let quitTitle = isDeferredQuitPending ? "Quit (confirm)" : "Quit"
        let quitItem = menu.addItem(withTitle: quitTitle, action: #selector(quitTapped), keyEquivalent: "q")
        quitItem.target = self
        
        statusItem?.menu = menu
    }
    
    /// Sets whether a deferred quit is currently pending.
    ///
    /// When `true`, the "Quit" menu item label changes to "Quit (confirm)".
    ///
    /// **Requirement 1.4:** Quit is deferred during active break; second request terminates immediately.
    func setDeferredQuitPending(_ pending: Bool) {
        isDeferredQuitPending = pending
    }
    
    // MARK: - Private Methods
    
    /// Sets up the status item in the menu bar.
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set the status item icon or title
        if let button = item.button {
            // Use SF Symbol or custom icon
            if let image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Slowbrew") {
                button.image = image
            } else {
                // Fallback to text if symbol not available
                button.title = "☕️"
            }
        }
        
        statusItem = item
    }
    
    // MARK: - Menu Actions
    
    @objc private func pauseToggleTapped() {
        onPauseToggle?()
    }
    
    @objc private func settingsTapped() {
        onSettings?()
    }
    
    @objc private func skipNextBreakTapped() {
        onSkipNextBreak?()
    }
    
    @objc private func quitTapped() {
        // If deferred quit is pending, this is a force quit (second request)
        let force = isDeferredQuitPending
        onQuit?(force)
    }
}
