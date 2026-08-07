// SettingsWindowController.swift
// Slowbrew
//
// Manages the Settings window with SwiftUI-based settings panel.

import AppKit
import SwiftUI
import ServiceManagement

/// Manages the settings window displaying user preferences.
///
/// **Settings:**
/// - Break Interval (15-180 minutes)
/// - Break Duration (1-30 minutes)
/// - Launch at Login toggle
/// - Sound Effects toggle
///
/// **Behavior:**
/// - Save button validates and persists settings
/// - Cancel/close discards unsaved changes
/// - Inline validation errors prevent saving
///
/// - Validates: Requirements 7.1–7.10
final class SettingsWindowController: NSWindowController {
    
    // MARK: - Properties
    
    /// Callback invoked when settings are successfully saved.
    ///
    /// The new settings are passed to the handler so the app can apply them.
    var onSettingsSaved: ((Settings) -> Void)?
    
    /// The settings store for loading and saving settings.
    private let settingsStore: SettingsStore
    
    /// The SwiftUI hosting controller.
    private var hostingController: NSHostingController<SettingsView>?
    
    // MARK: - Initialization
    
    /// Creates a `SettingsWindowController` with the given settings store.
    ///
    /// - Parameter settingsStore: The `SettingsStore` to use for loading and saving settings.
    init(settingsStore: SettingsStore = .shared) {
        self.settingsStore = settingsStore
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Slowbrew Settings"
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 480, height: 450)
        window.maxSize = NSSize(width: 800, height: 600)
        window.center()
        
        super.init(window: window)
        
        // Create and set the SwiftUI view
        let settingsView = SettingsView(
            settingsStore: settingsStore,
            onSave: { [weak self] settings in
                self?.handleSave(settings)
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        
        let hosting = NSHostingController(rootView: settingsView)
        window.contentViewController = hosting
        self.hostingController = hosting
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    /// Handles the save action from the SwiftUI view.
    ///
    /// Attempts to save the settings; on success, notifies the callback.
    /// On failure, the error is already displayed inline in the SwiftUI view.
    private func handleSave(_ settings: Settings) {
        do {
            try settingsStore.save(settings)
            print("[SettingsWindowController] Settings saved successfully: \(settings)")
            onSettingsSaved?(settings)
            close()
        } catch {
            // Error is already displayed in the SwiftUI view's inline alert
            print("[SettingsWindowController] Failed to save settings: \(error)")
        }
    }
}

// MARK: - SettingsView

/// SwiftUI view displaying the settings panel.
///
/// **Fields:**
/// - Break Interval slider (15-180 minutes)
/// - Break Duration slider (1-30 minutes)
/// - Launch at Login toggle
/// - Sound Effects toggle
///
/// **Buttons:**
/// - Save (validates and persists)
/// - Cancel (discards changes)
struct SettingsView: View {
    
    // MARK: - Properties
    
    /// The settings store for loading and saving settings.
    let settingsStore: SettingsStore
    
    /// Callback invoked when the user clicks Save.
    let onSave: (Settings) -> Void
    
    /// Callback invoked when the user clicks Cancel or closes the window.
    let onCancel: () -> Void
    
    /// The current settings being edited (local state).
    @State private var editedSettings: Settings
    
    /// Validation error message (displayed inline).
    @State private var errorMessage: String?
    
    // MARK: - Initialization
    
    init(settingsStore: SettingsStore, onSave: @escaping (Settings) -> Void, onCancel: @escaping () -> Void) {
        self.settingsStore = settingsStore
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Load initial settings
        _editedSettings = State(initialValue: settingsStore.load())
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            // Break Interval
            VStack(alignment: .leading, spacing: 6) {
                Text("Break Interval: \(editedSettings.breakInterval) minutes")
                    .font(.headline)
                Slider(
                    value: Binding(
                        get: { Double(editedSettings.breakInterval) },
                        set: { editedSettings.breakInterval = Int($0) }
                    ),
                    in: Double(Settings.breakIntervalMin)...Double(Settings.breakIntervalMax),
                    step: 1
                )
                Text("Time between breaks (15-180 minutes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Break Duration
            VStack(alignment: .leading, spacing: 6) {
                Text("Break Duration: \(editedSettings.breakDuration) minutes")
                    .font(.headline)
                Slider(
                    value: Binding(
                        get: { Double(editedSettings.breakDuration) },
                        set: { editedSettings.breakDuration = Int($0) }
                    ),
                    in: Double(Settings.breakDurationMin)...Double(Settings.breakDurationMax),
                    step: 1
                )
                Text("Length of each break (1-30 minutes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Launch at Login
            Toggle("Launch at Login", isOn: $editedSettings.launchAtLogin)
                .font(.headline)
            
            // Sound Effects
            Toggle("Sound Effects", isOn: $editedSettings.soundEnabled)
                .font(.headline)
            
            // Error message (inline validation alert)
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            Divider()
            
            // Buttons (always at bottom)
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    handleSave()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 450)
    }
    
    // MARK: - Private Methods
    
    /// Validates and saves the edited settings.
    ///
    /// On validation failure, displays an inline error message.
    private func handleSave() {
        // Clear any previous error
        errorMessage = nil
        
        // Validate ranges (this should always pass since sliders constrain the values)
        guard (Settings.breakIntervalMin...Settings.breakIntervalMax).contains(editedSettings.breakInterval) else {
            errorMessage = "Break interval must be between \(Settings.breakIntervalMin) and \(Settings.breakIntervalMax) minutes."
            return
        }
        
        guard (Settings.breakDurationMin...Settings.breakDurationMax).contains(editedSettings.breakDuration) else {
            errorMessage = "Break duration must be between \(Settings.breakDurationMin) and \(Settings.breakDurationMax) minutes."
            return
        }
        
        // Handle Launch at Login registration
        if editedSettings.launchAtLogin {
            do {
                try SMAppService.mainApp.register()
            } catch {
                errorMessage = "Failed to register for launch at login: \(error.localizedDescription)"
                return
            }
        } else {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                // Unregistration failure is not critical; just log it
            }
        }
        
        // Attempt to save via the store
        do {
            try settingsStore.save(editedSettings)
            onSave(editedSettings)
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }
    }
}
