// OverlayWindowController.swift
// Slowbrew
//
// Manages the full-screen break overlay window that locks the display during breaks.
// The window is presented at `.screenSaver + 1` level to ensure it covers all other content.

import AppKit
import SpriteKit
import os.log

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the user presses Escape to emergency dismiss the overlay
    static let emergencyDismissOverlay = Notification.Name("com.slowbrew.emergencyDismissOverlay")
}

/// A window controller responsible for presenting and managing the full-screen
/// break overlay that locks the display during a Slowbrew break session.
///
/// **Key Responsibilities:**
/// - Creates and manages an `NSWindow` at window level `.screenSaver + 1`
/// - Ensures the window covers the entire target display (Requirements 4.1, 4.2)
/// - Blocks all keyboard and mouse input except for HUD controls (Requirement 4.6)
/// - Provides a callback for snooze actions
///
/// **Window Properties:**
/// - `styleMask: .borderless` — No title bar or chrome
/// - `level: .screenSaver + 1` — Above all other windows including Dock and menu bar
/// - `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]` — Present on all spaces
/// - Frame exactly matches `screen.frame` for the target display
///
/// **Input Blocking Strategy:**
/// A transparent `NSView` sits at the bottom of the view hierarchy and intercepts
/// all mouse and keyboard events that are not directed at the HUD controls.
///
/// - Validates: Requirements 4.1, 4.2, 4.6
final class OverlayWindowController: NSWindowController {
    
    // MARK: - Properties
    
    /// Callback invoked when the user activates the snooze button in the HUD.
    ///
    /// The controller does not manage snooze logic; it simply notifies the
    /// `StateMachine` (via this closure) that a snooze was requested.
    var onSnooze: (() -> Void)?
    
    /// Callback invoked when the break countdown expires.
    ///
    /// The controller will call this after the break duration elapses.
    var onCountdownExpired: (() -> Void)?
    
    /// The screen on which the overlay is currently displayed.
    ///
    /// Stored so we can re-present the overlay on the same screen if it's
    /// unexpectedly dismissed (Requirement 6.5).
    private var targetScreen: NSScreen?
    
    /// Timer for the break countdown.
    ///
    /// Fires when the break duration elapses, triggering dismissal.
    private var countdownTimer: Timer?
    
    /// Number of times the overlay has been re-asserted after force-dismiss.
    ///
    /// Resets to 0 when `show(on:)` is called. Increments on each re-assertion.
    /// If this reaches `maxReassertAttempts`, we log a critical error and stop
    /// re-asserting (Requirement 6.5).
    private var reassertAttemptCount: Int = 0
    
    /// Maximum number of re-assertion attempts before giving up.
    ///
    /// Per Requirement 6.5: "maximum 5 attempts before logging critical error
    /// and transitioning to `.idle`".
    private let maxReassertAttempts: Int = 5
    
    /// Debounced timer for re-asserting the overlay after unexpected dismissal.
    ///
    /// Scheduled when `NSWindow.willCloseNotification` fires while the overlay
    /// should still be active. Cancelled when `dismiss()` is called intentionally.
    private var reassertTimer: Timer?
    
    /// The sprite animator for playing brewing animations
    private var spriteAnimator: SpriteAnimator?
    
    // MARK: - Initialization
    
    /// Initializes the controller with no window.
    ///
    /// Call `show(on:)` to create and present the overlay window on a specific screen.
    override init(window: NSWindow? = nil) {
        super.init(window: window)
        
        // Register for emergency dismiss notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEmergencyDismiss),
            name: .emergencyDismissOverlay,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Clean up notification observers and timers
        NotificationCenter.default.removeObserver(self)
        reassertTimer?.invalidate()
        countdownTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Shows the overlay and plays the walk-in animation.
    ///
    /// - Parameters:
    ///   - screen: The `NSScreen` on which to present the overlay.
    ///   - edge: The edge from which the character walks in.
    ///   - completion: Called when the walk-in animation completes.
    func showWalkIn(on screen: NSScreen, from edge: HorizontalEdge, completion: @escaping () -> Void) {
        // Store the target screen for potential re-assertion
        targetScreen = screen
        
        // Reset re-assertion count for this new overlay session
        reassertAttemptCount = 0
        
        // Cancel any pending re-assertion timer from a previous session
        reassertTimer?.invalidate()
        reassertTimer = nil
        
        // Create the overlay window with exact screen dimensions
        let overlayWindow = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        // Configure window properties for full-screen overlay
        overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.isOpaque = true
        overlayWindow.backgroundColor = .black
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.hasShadow = false
        
        // Create input-blocking view that sits at the bottom of the view hierarchy
        let inputBlockingView = InputBlockingView(frame: screen.frame)
        inputBlockingView.autoresizingMask = [.width, .height]
        
        // Add input-blocking view to the content view
        if let contentView = overlayWindow.contentView {
            // Insert at index 0 to ensure it's at the bottom of the view hierarchy
            contentView.addSubview(inputBlockingView, positioned: .below, relativeTo: nil)
            
            // Add SKView for sprite animations (full screen)
            let skView = SKView(frame: screen.frame)
            skView.autoresizingMask = [.width, .height]
            skView.ignoresSiblingOrder = true
            skView.showsFPS = false
            skView.showsNodeCount = false
            skView.wantsLayer = true
            skView.layer?.backgroundColor = NSColor.clear.cgColor
            contentView.addSubview(skView)
            
            print("[OverlayWindowController] 🎨 Creating full-screen SKView: \(screen.frame)")
            
            // Create sprite animator and start walk-in animation
            let animator = SpriteAnimator(skView: skView)
            self.spriteAnimator = animator
            print("[OverlayWindowController] 🚶 Starting walk-in animation from \(edge)...")
            animator.playWalkIn(direction: edge) {
                print("[OverlayWindowController] ✅ Walk-in animation completed")
                completion()
            }
        }
        
        // Register for window close notifications to detect force-dismiss
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: overlayWindow
        )
        
        // Set the window and make it key to receive events
        self.window = overlayWindow
        overlayWindow.makeKeyAndOrderFront(nil)
        
        os_log(.info, "Overlay window presented on screen: %{public}@", screen.localizedName)
    }
    
    /// Starts the brewing animation and countdown timer.
    ///
    /// - Parameter duration: The break duration in seconds. Brewing loops until 5 seconds before end, then triggers walk-out.
    func startBrewing(duration: TimeInterval) {
        // Add "Break Time! ☕️" label in center
        if let contentView = window?.contentView {
            let label = NSTextField(labelWithString: "Break Time! ☕️")
            label.font = NSFont.systemFont(ofSize: 72, weight: .bold)
            label.textColor = .white
            label.alignment = .center
            label.sizeToFit()
            label.frame = CGRect(
                x: (contentView.frame.width - label.frame.width) / 2,
                y: (contentView.frame.height - label.frame.height) / 2,
                width: label.frame.width,
                height: label.frame.height
            )
            label.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
            contentView.addSubview(label)
        }
        
        print("[OverlayWindowController] 🎬 Starting brewing animation...")
        spriteAnimator?.playBrewing()
        print("[OverlayWindowController] ✅ Brewing animation started")
        
        // Calculate when to trigger walk-out (5 seconds before end)
        let walkOutTriggerTime = max(5.0, duration - 5.0)
        
        // Start countdown timer to trigger walk-out before end
        print("[OverlayWindowController] Starting countdown timer for \(duration) seconds, walk-out at \(walkOutTriggerTime)s")
        countdownTimer = Timer.scheduledTimer(withTimeInterval: walkOutTriggerTime, repeats: false) { [weak self] _ in
            print("[OverlayWindowController] ⏰ \(walkOutTriggerTime)s elapsed! Triggering walk-out")
            self?.onCountdownExpired?()
        }
    }
    
    /// Starts the walk-out animation.
    ///
    /// - Parameters:
    ///   - edge: The edge toward which the character walks out.
    ///   - completion: Called when the walk-out animation completes.
    func startWalkOut(toward edge: HorizontalEdge, completion: @escaping () -> Void) {
        // Cancel countdown timer
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Remove the "Break Time!" label
        window?.contentView?.subviews.forEach { view in
            if view is NSTextField {
                view.removeFromSuperview()
            }
        }
        
        print("[OverlayWindowController] 🚶 Starting walk-out animation toward \(edge)...")
        spriteAnimator?.playWalkOut(direction: edge) {
            print("[OverlayWindowController] ✅ Walk-out animation completed")
            completion()
        }
    }
    
    /// Dismisses the overlay window.
    ///
    /// Closes and releases the overlay window, removing it from the screen.
    /// Safe to call even if no window is currently presented.
    ///
    /// **Note:** This is an intentional dismissal (user completed the break or snoozed).
    /// The re-assertion logic is disabled by cancelling the timer and removing observers.
    func dismiss() {
        // Stop brewing animation
        spriteAnimator?.stopBrewing()
        spriteAnimator = nil
        print("[OverlayWindowController] 🛑 Stopped brewing animation")
        
        // Cancel countdown timer
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Cancel any pending re-assertion timer — this is an intentional dismiss
        reassertTimer?.invalidate()
        reassertTimer = nil
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        
        // Close and clear the window
        window?.close()
        window = nil
        targetScreen = nil
        
        print("[OverlayWindowController] Overlay dismissed")
    }
    
    // MARK: - Private Methods
    
    /// Called when the overlay window is about to close.
    ///
    /// If the close is unexpected (i.e., not triggered by `dismiss()`), this
    /// schedules a re-assertion after 2 seconds (Requirement 6.5).
    ///
    /// After `maxReassertAttempts` (5), logs a critical error and stops re-asserting.
    @objc private func windowWillClose(_ notification: Notification) {
        // Check if we still have re-assertion attempts remaining
        guard reassertAttemptCount < maxReassertAttempts else {
            os_log(.fault, "Overlay window force-dismissed %d times; giving up re-assertion.", reassertAttemptCount)
            // TODO: Transition StateMachine to `.idle` via callback
            return
        }
        
        // Schedule re-assertion after 2 seconds (debounced)
        reassertTimer?.invalidate()
        reassertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.reassertOverlay()
        }
    }
    
    /// Re-presents the overlay on the stored `targetScreen` after unexpected dismissal.
    ///
    /// Increments `reassertAttemptCount` and logs the re-assertion.
    private func reassertOverlay() {
        guard let screen = targetScreen else {
            os_log(.error, "Cannot re-assert overlay: targetScreen is nil.")
            return
        }
        
        reassertAttemptCount += 1
        os_log(.info, "Re-asserting overlay (attempt %d/%d).", reassertAttemptCount, maxReassertAttempts)
        
        // Re-show with walk-in animation
        showWalkIn(on: screen, from: .right) { }
    }
    
    /// Handles emergency dismiss notification (Escape key pressed).
    @objc private func handleEmergencyDismiss() {
        os_log(.info, "🚨 Emergency dismiss triggered!")
        dismiss()
        // Notify state machine to transition to idle
        // This will be wired up via callback in AppDelegate
    }
}

// MARK: - BreakOverlayWindow

/// A custom `NSWindow` subclass that can become key and main window.
///
/// By default, borderless windows cannot become key or main. This subclass
/// overrides those behaviors to ensure the overlay can capture keyboard focus
/// and block input from reaching applications beneath it.
private final class BreakOverlayWindow: NSWindow {
    
    /// Returns `true` to allow this borderless window to become the key window.
    ///
    /// This is required for the overlay to capture keyboard focus and block
    /// keyboard shortcuts from reaching underlying applications (Requirement 4.6).
    override var canBecomeKey: Bool {
        return true
    }
    
    /// Returns `true` to allow this borderless window to become the main window.
    ///
    /// This ensures the overlay is treated as the active window by the system,
    /// further reinforcing input blocking.
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - InputBlockingView

/// A transparent view that intercepts and consumes all mouse and keyboard events
/// not directed at HUD controls.
///
/// This view sits at the bottom of the overlay window's view hierarchy and acts
/// as a catch-all for input events. Views added above it (like the HUD with the
/// snooze button) will receive their events normally; everything else is blocked.
///
/// - Validates: Requirement 4.6
private final class InputBlockingView: NSView {
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        // Make the view transparent but still receive events
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    // MARK: - Event Handling
    
    /// Accepts first responder to capture keyboard events.
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    /// Intercepts mouse-down events and consumes them (no further propagation).
    override func mouseDown(with event: NSEvent) {
        // Consume the event — do not pass to super or other responders
    }
    
    /// Intercepts mouse-up events and consumes them.
    override func mouseUp(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts mouse-dragged events and consumes them.
    override func mouseDragged(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts right-mouse-down events and consumes them.
    override func rightMouseDown(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts right-mouse-up events and consumes them.
    override func rightMouseUp(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts right-mouse-dragged events and consumes them.
    override func rightMouseDragged(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts other-mouse-down events and consumes them.
    override func otherMouseDown(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts other-mouse-up events and consumes them.
    override func otherMouseUp(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts other-mouse-dragged events and consumes them.
    override func otherMouseDragged(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts scroll-wheel events and consumes them.
    override func scrollWheel(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts key-down events and consumes them.
    override func keyDown(with event: NSEvent) {
        // EMERGENCY ESCAPE: Escape key or Cmd+Q force dismisses the overlay
        if event.keyCode == 53 { // Escape key
            print("[InputBlockingView] 🚨 EMERGENCY ESCAPE: Escape key pressed!")
            NotificationCenter.default.post(name: .emergencyDismissOverlay, object: nil)
            return
        }
        
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
            print("[InputBlockingView] 🚨 EMERGENCY ESCAPE: Cmd+Q pressed!")
            NSApplication.shared.terminate(nil)
            return
        }
        
        // Block Control+Arrow keys (Mission Control shortcuts)
        if event.modifierFlags.contains(.control) {
            let arrowKeys: [UInt16] = [123, 124, 125, 126] // Left, Right, Down, Up
            if arrowKeys.contains(event.keyCode) {
                print("[InputBlockingView] 🚫 Blocked Control+Arrow key")
                return
            }
        }
        
        // Consume all other keyboard events
    }
    
    /// Intercepts key-up events and consumes them.
    override func keyUp(with event: NSEvent) {
        // Consume the event
    }
    
    /// Intercepts flags-changed events (modifier keys) and consumes them.
    override func flagsChanged(with event: NSEvent) {
        // Consume the event — blocks Cmd+Tab, Cmd+Q, etc.
    }
}
