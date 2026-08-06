// BrewingStage.swift
// Slowbrew
//
// Defines the ordered stages of the brewing animation sequence.
// Stages play in strictly ascending rawValue order and loop back to
// heatingWater after presentingCup (Property 11).

/// An ordered stage in Slowbrew's tea/coffee brewing animation sequence.
///
/// Stages must be played in ascending `rawValue` order:
/// `heatingWater → steeping → pouring → presentingCup`, then loop.
///
/// Each stage has a `minimumDuration` and maps to an `SKTextureAtlas`
/// asset name via `atlasName`.
///
/// - Note: `CaseIterable` conformance is relied upon by `SpriteAnimator`
///   to iterate stages in declared order, which matches ascending `rawValue`.
enum BrewingStage: Int, CaseIterable, Equatable {

    /// Stage 1 — Slowbrew heats the water.
    case heatingWater  = 1

    /// Stage 2 — The tea or coffee is steeping.
    case steeping      = 2

    /// Stage 3 — Slowbrew pours the brew into a cup.
    case pouring       = 3

    /// Stage 4 — Slowbrew presents the finished cup.
    case presentingCup = 4

    // MARK: - Computed Properties

    /// The minimum time this stage must play before the next stage may begin.
    ///
    /// Per Requirement 5.5 each stage lasts at least 1 second.
    var minimumDuration: Duration {
        .seconds(1)
    }

    /// The name of the `SKTextureAtlas` bundle for this stage.
    ///
    /// Matches the asset directory layout:
    /// ```
    /// Slowbrew.app/Contents/Resources/Sprites/BrewStage1.atlas/
    /// Slowbrew.app/Contents/Resources/Sprites/BrewStage2.atlas/
    /// ...
    /// ```
    var atlasName: String {
        "BrewStage\(rawValue)"
    }
}

// MARK: - CustomStringConvertible

extension BrewingStage: CustomStringConvertible {
    var description: String {
        switch self {
        case .heatingWater:  return "heatingWater"
        case .steeping:      return "steeping"
        case .pouring:       return "pouring"
        case .presentingCup: return "presentingCup"
        }
    }
}
