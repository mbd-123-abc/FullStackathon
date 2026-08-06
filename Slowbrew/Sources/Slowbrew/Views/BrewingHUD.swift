// BrewingHUD.swift
// Slowbrew
//
// SwiftUI HUD displaying countdown timer and Snooze button during break overlay.

import SwiftUI

/// A SwiftUI view displaying the break countdown timer and optional Snooze button.
///
/// **UI Components:**
/// - Countdown display in MM:SS format (Requirement 4.3)
/// - Snooze button with remaining snooze count (Requirements 6.1, 6.4)
/// - Button is hidden when `snoozeRemaining == 0` (Requirement 6.4)
///
/// **Layout:**
/// Centered on screen with countdown above the snooze button.
///
/// - Validates: Requirements 4.3, 6.1, 6.4
struct BrewingHUD: View {
    
    // MARK: - Properties
    
    /// Remaining break time in seconds.
    ///
    /// Used to display the countdown via `CountdownFormatter`.
    /// Should never be negative (Requirements 4.3 states "Do not show negative countdown values").
    let remainingSeconds: Int
    
    /// Number of snoozes remaining for today.
    ///
    /// When `0`, the Snooze button is hidden per Requirement 6.4.
    let snoozeRemaining: Int
    
    /// Callback invoked when the user taps the Snooze button.
    ///
    /// The HUD does not manage snooze logic; it notifies the controller
    /// (which forwards to the `StateMachine`) that a snooze was requested.
    let onSnooze: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 32) {
            // Countdown display
            Text(countdownText)
                .font(.system(size: 72, weight: .light, design: .monospaced))
                .foregroundColor(.white)
            
            // Snooze button (only shown when snoozes remain)
            if snoozeRemaining > 0 {
                Button(action: onSnooze) {
                    HStack(spacing: 12) {
                        Text("Snooze")
                            .font(.system(size: 20, weight: .medium))
                        
                        // Snooze count badge
                        Text("\(snoozeRemaining)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.white)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(SnoozeButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.01)) // Nearly transparent to allow sprite view beneath
    }
    
    // MARK: - Computed Properties
    
    /// The formatted countdown string (MM:SS).
    ///
    /// Uses `CountdownFormatter` to ensure the output matches `^\d{2}:\d{2}$`.
    /// Clamps negative values to 0 per Requirement 4.3 ("Do not show negative countdown values").
    private var countdownText: String {
        let clamped = max(0, remainingSeconds)
        return CountdownFormatter.format(clamped)
    }
}

// MARK: - SnoozeButtonStyle

/// Custom button style for the Snooze button.
///
/// Provides a semi-transparent white background with rounded corners.
private struct SnoozeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.15 : 0.25))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct BrewingHUD_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with snoozes remaining
            BrewingHUD(
                remainingSeconds: 300,
                snoozeRemaining: 3,
                onSnooze: { print("Snooze tapped") }
            )
            .previewDisplayName("With Snooze (300s)")
            
            // Preview with no snoozes
            BrewingHUD(
                remainingSeconds: 120,
                snoozeRemaining: 0,
                onSnooze: { print("Snooze tapped") }
            )
            .previewDisplayName("No Snooze (120s)")
            
            // Preview at zero
            BrewingHUD(
                remainingSeconds: 0,
                snoozeRemaining: 1,
                onSnooze: { print("Snooze tapped") }
            )
            .previewDisplayName("Zero (0s)")
        }
    }
}
#endif
