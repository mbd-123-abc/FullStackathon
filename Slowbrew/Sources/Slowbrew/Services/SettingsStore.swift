// SettingsStore.swift
// Slowbrew
//
// Persists and validates user settings using a domain-scoped UserDefaults suite.

import Foundation

// MARK: - SettingsValidationError

/// Errors thrown by `SettingsStore.save(_:)` when a settings value falls
/// outside its accepted range.
enum SettingsValidationError: Error, Equatable {

    /// The break interval (in minutes) is outside the valid range 15–180.
    case breakIntervalOutOfRange(value: Int)

    /// The break duration (in minutes) is outside the valid range 1–30.
    case breakDurationOutOfRange(value: Int)
}

extension SettingsValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .breakIntervalOutOfRange(let value):
            return "Break interval \(value) is out of range [\(Settings.breakIntervalMin), \(Settings.breakIntervalMax)]."
        case .breakDurationOutOfRange(let value):
            return "Break duration \(value) is out of range [\(Settings.breakDurationMin), \(Settings.breakDurationMax)]."
        }
    }
}

// MARK: - SettingsStore

/// Reads and writes `Settings` to a domain-scoped `UserDefaults` suite.
///
/// All write operations validate field ranges before persisting. The store
/// exposes a shared singleton for use across the app.
///
/// ```swift
/// // Load persisted settings (falls back to Settings.default on first launch)
/// let settings = SettingsStore.shared.load()
///
/// // Persist updated settings (throws on invalid values)
/// try SettingsStore.shared.save(settings)
/// ```
final class SettingsStore {

    // MARK: - Singleton

    /// The shared `SettingsStore` instance used throughout the app.
    static let shared: SettingsStore = SettingsStore()

    // MARK: - Private constants

    private static let suiteName = "com.slowbrew.app"
    private static let defaultsKey = "com.slowbrew.settings"

    // MARK: - Private properties

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialisation

    /// Creates a new `SettingsStore` backed by the given `UserDefaults` suite.
    ///
    /// - Parameter defaults: The `UserDefaults` suite to use. Defaults to the
    ///   app's domain-scoped suite (`com.slowbrew.app`). Provide a different
    ///   suite (e.g. an in-memory one) in tests.
    init(defaults: UserDefaults? = nil) {
        if let provided = defaults {
            self.defaults = provided
        } else {
            // Fall back to standard defaults if the suite cannot be created
            // (e.g., in sandboxed test environments).
            self.defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
        }
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Returns the persisted `Settings`, or `Settings.default` if no settings
    /// have been saved yet or if the stored data cannot be decoded.
    ///
    /// - Returns: The stored `Settings` value, falling back to `Settings.default`.
    func load() -> Settings {
        guard
            let data = defaults.data(forKey: Self.defaultsKey),
            let settings = try? decoder.decode(Settings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    /// Validates `settings` and persists it to `UserDefaults`.
    ///
    /// Validation is performed before any write. If a value is out of range
    /// the method throws and **no** data is written.
    ///
    /// - Parameter settings: The `Settings` value to validate and persist.
    /// - Throws: `SettingsValidationError.breakIntervalOutOfRange` if
    ///   `settings.breakInterval` is outside `[15, 180]`.
    /// - Throws: `SettingsValidationError.breakDurationOutOfRange` if
    ///   `settings.breakDuration` is outside `[1, 30]`.
    func save(_ settings: Settings) throws {
        // Validate breakInterval first (checked before breakDuration).
        guard (Settings.breakIntervalMin...Settings.breakIntervalMax).contains(settings.breakInterval) else {
            throw SettingsValidationError.breakIntervalOutOfRange(value: settings.breakInterval)
        }

        // Validate breakDuration.
        guard (Settings.breakDurationMin...Settings.breakDurationMax).contains(settings.breakDuration) else {
            throw SettingsValidationError.breakDurationOutOfRange(value: settings.breakDuration)
        }

        // Encode and persist — only reached when both values are valid.
        let data = try encoder.encode(settings)
        defaults.set(data, forKey: Self.defaultsKey)
        defaults.synchronize()  // Force immediate write
        print("[SettingsStore] Saved settings to UserDefaults: \(settings)")
        print("[SettingsStore] UserDefaults suite: \(defaults.dictionaryRepresentation().keys.contains(Self.defaultsKey) ? "Key exists" : "Key missing")")
    }
}
