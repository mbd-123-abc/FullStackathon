// HorizontalEdge.swift
// Slowbrew
//
// Represents the horizontal edge of the display from which Slowbrew
// enters and to which she exits.

/// The horizontal edge of the display used for walk-on / walk-off animations.
///
/// The walk-out direction is always the `opposite` of the walk-in direction
/// for a given break session (Property 7).
enum HorizontalEdge: String, CaseIterable, Equatable, Codable {

    /// The left edge of the display.
    case left

    /// The right edge of the display.
    case right

    // MARK: - Computed Properties

    /// The edge directly across from this edge.
    ///
    /// ```swift
    /// HorizontalEdge.left.opposite  // → .right
    /// HorizontalEdge.right.opposite // → .left
    /// ```
    var opposite: HorizontalEdge {
        switch self {
        case .left:  return .right
        case .right: return .left
        }
    }
}

// MARK: - CustomStringConvertible

extension HorizontalEdge: CustomStringConvertible {
    var description: String { rawValue }
}
