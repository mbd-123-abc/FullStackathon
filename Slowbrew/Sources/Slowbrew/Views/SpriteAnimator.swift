// SpriteAnimator.swift
// Slowbrew
//
// Wraps SpriteKit to play walk-in, brewing, and walk-out animations using sprite sheets.

import SpriteKit
import AppKit
import os.log

/// Manages SpriteKit-based character animations for Slowbrew.
///
/// **Responsibilities:**
/// - Load sprite sheets from `SKTextureAtlas` bundles
/// - Play walk-in animation (3 seconds, left or right edge)
/// - Loop brewing animation seamlessly (4 stages, 1 second minimum each)
/// - Play walk-out animation (3 seconds, opposite edge)
/// - Fall back to static image on atlas load failure
///
/// - Validates: Requirements 3.1, 3.4, 3.5, 3.6, 5.1, 5.2, 5.3, 5.4, 5.6
final class SpriteAnimator {
    
    // MARK: - Properties
    
    /// The `SKView` hosting the sprite scene.
    private let skView: SKView
    
    /// The `SKScene` containing the sprite node.
    private let scene: SKScene
    
    /// The main sprite node displaying the character.
    private let spriteNode: SKSpriteNode
    
    /// The current brewing stage index (for looping through stages).
    private var currentBrewingStageIndex: Int = 0
    
    /// Timer for advancing brewing stages.
    private var brewingStageTimer: Timer?
    
    // MARK: - Initialization
    
    /// Creates a `SpriteAnimator` with an `SKView` to render animations.
    ///
    /// - Parameter skView: The `SKView` instance to host the sprite scene.
    init(skView: SKView) {
        self.skView = skView
        
        // Create a scene matching the view's bounds
        let scene = SKScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        self.scene = scene
        
        // Create the sprite node (initially empty texture)
        self.spriteNode = SKSpriteNode()
        spriteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(spriteNode)
        
        // Present the scene
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
    }
    
    // MARK: - Public API
    
    /// Plays the walk-in animation from the specified edge.
    ///
    /// - Parameters:
    ///   - direction: The horizontal edge (`.left` or `.right`) from which the character walks in.
    ///   - completion: Called when the animation completes (after 3 seconds).
    ///
    /// **Animation: 3 seconds, 2 PNGs, character animates in place at full visibility.**
    func playWalkIn(direction: HorizontalEdge, completion: @escaping () -> Void) {
        // Load the walk-in atlas
        guard let textures = loadAtlas(named: "WalkIn") else {
            // Fallback: show static image and complete immediately
            showFallbackImage()
            completion()
            return
        }
        
        // Position sprite at center (character animates in place)
        spriteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        // Flip horizontally based on direction
        spriteNode.xScale = direction == .left ? 1.0 : -1.0
        
        // Full visibility immediately - no fade
        spriteNode.alpha = 1.0
        
        // Walk-in: 3 seconds total for 2 PNGs
        let duration: TimeInterval = 3.0
        let timePerFrame = duration / Double(textures.count)
        
        // Just animate frames, no fade effects
        let animateAction = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: true, restore: false)
        
        spriteNode.run(animateAction) {
            completion()
        }
    }
    
    /// Starts the looping brewing animation with smart timing.
    ///
    /// Timing strategy to avoid vertigo:
    /// - Stage 1 (heatingWater): Quick intro (3 seconds)
    /// - Stage 2 (steeping): Main activity (30 seconds)
    /// - Stage 3 (pouring): Main activity (30 seconds)  
    /// - Stage 4 (presentingCup): Quick outro (3 seconds)
    /// Total: 66 seconds, then loops
    func playBrewing() {
        currentBrewingStageIndex = 0
        playNextBrewingStage()
    }
    
    /// Gets the duration for a specific brewing stage.
    private func getDurationForStage(_ stage: BrewingStage) -> TimeInterval {
        switch stage {
        case .heatingWater:
            return 30.0  // Main activity - 30 seconds
        case .steeping:
            return 30.0  // Main activity - 30 seconds
        case .pouring:
            return 30.0  // Main activity - 30 seconds
        case .presentingCup:
            return 0.0  // Skip this stage - not used
        }
    }
    
    /// Stops the brewing animation.
    ///
    /// Called when the break ends or the user snoozes.
    func stopBrewing() {
        brewingStageTimer?.invalidate()
        brewingStageTimer = nil
        spriteNode.removeAllActions()
    }
    
    /// Plays the walk-out animation toward the specified edge.
    ///
    /// - Parameters:
    ///   - direction: The horizontal edge (`.left` or `.right`) toward which the character walks out.
    ///   - completion: Called when the animation completes (after 5 seconds).
    ///
    /// **Animation: 5 seconds, 3 PNGs, character animates in place at full visibility.**
    func playWalkOut(direction: HorizontalEdge, completion: @escaping () -> Void) {
        // Load the walk-out atlas
        guard let textures = loadAtlas(named: "WalkOut") else {
            // Fallback: hide sprite and complete immediately
            spriteNode.alpha = 0
            completion()
            return
        }
        
        // Character stays at center (animates in place)
        spriteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        // Flip horizontally based on direction
        spriteNode.xScale = direction == .left ? -1.0 : 1.0
        
        // Full visibility - no fade out
        spriteNode.alpha = 1.0
        
        // Walk-out: 5 seconds total for 3 PNGs
        let duration: TimeInterval = 5.0
        let timePerFrame = duration / Double(textures.count)
        
        // Just animate frames, no fade effects
        let animateAction = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: true, restore: false)
        
        spriteNode.run(animateAction) {
            completion()
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads an `SKTextureAtlas` by name and returns its textures sorted by name.
    ///
    /// - Parameter name: The atlas name (e.g., "WalkIn", "BrewStage1").
    /// - Returns: Array of `SKTexture` sorted alphabetically, or `nil` on failure.
    private func loadAtlas(named name: String) -> [SKTexture]? {
        print("[SpriteAnimator] 📦 Loading atlas: \(name)")
        
        // Try to find the atlas in the resource bundle
        guard let resourceBundle = Bundle.main.url(forResource: "Slowbrew_Slowbrew", withExtension: "bundle"),
              let bundle = Bundle(url: resourceBundle) else {
            print("[SpriteAnimator] ❌ Could not find resource bundle")
            // Try main bundle as fallback
            let atlas = SKTextureAtlas(named: name)
            print("[SpriteAnimator] 📦 Atlas '\(name)' has \(atlas.textureNames.count) texture names (from main bundle)")
            guard atlas.textureNames.count > 0 else {
                os_log(.error, "Atlas '%{public}@' failed to load or contains no textures.", name)
                return nil
            }
            let sortedNames = atlas.textureNames.sorted()
            print("[SpriteAnimator] 📦 Texture names in '\(name)': \(sortedNames)")
            return sortedNames.map { atlas.textureNamed($0) }
        }
        
        // Check if the atlas directory exists in the bundle
        let atlasPath = "Sprites/\(name).atlas"
        guard let atlasURL = bundle.url(forResource: atlasPath, withExtension: nil) else {
            print("[SpriteAnimator] ❌ Could not find atlas at path: \(atlasPath)")
            return nil
        }
        
        print("[SpriteAnimator] 📦 Found atlas at: \(atlasURL.path)")
        
        // List all PNG files in the atlas directory
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: atlasURL, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "png" })
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) else {
            print("[SpriteAnimator] ❌ Could not read contents of atlas directory")
            return nil
        }
        
        print("[SpriteAnimator] 📦 Found \(files.count) PNG files in atlas")
        
        // Load textures directly from image files
        let textures = files.compactMap { url -> SKTexture? in
            guard let image = NSImage(contentsOf: url) else {
                print("[SpriteAnimator] ⚠️ Failed to load image: \(url.lastPathComponent)")
                return nil
            }
            return SKTexture(image: image)
        }
        
        print("[SpriteAnimator] ✅ Loaded \(textures.count) textures from '\(name)'")
        return textures.isEmpty ? nil : textures
    }
    
    /// Plays the next brewing stage in the sequence with smart timing.
    ///
    /// Only uses first 3 stages (heatingWater, steeping, pouring), then loops back.
    /// Stage 4 (presentingCup) is skipped.
    private func playNextBrewingStage() {
        let stages = BrewingStage.allCases
        
        // Only use first 3 stages
        let usedStages = Array(stages.prefix(3))
        let stage = usedStages[currentBrewingStageIndex]
        
        print("[SpriteAnimator] 🎭 Attempting to load brewing stage \(currentBrewingStageIndex + 1)/\(usedStages.count): \(stage.atlasName)")
        
        // Load the atlas for this stage
        guard let textures = loadAtlas(named: stage.atlasName) else {
            // Fallback: show static image and stop brewing
            print("[SpriteAnimator] ❌ Failed to load atlas '\(stage.atlasName)', showing fallback")
            showFallbackImage()
            stopBrewing()
            return
        }
        
        print("[SpriteAnimator] ✅ Loaded \(textures.count) textures from '\(stage.atlasName)'")
        
        // Get custom duration for this stage
        let stageDuration = getDurationForStage(stage)
        let timePerFrame = stageDuration / Double(textures.count)
        
        // Create animation action
        let animateAction = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: true, restore: false)
        
        spriteNode.run(animateAction)
        print("[SpriteAnimator] ▶️ Playing stage \(stage) for \(stageDuration)s (\(textures.count) frames at \(timePerFrame)s per frame)")
        
        // Schedule next stage after this one completes
        brewingStageTimer = Timer.scheduledTimer(withTimeInterval: stageDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Advance to next stage (loop back to 0 after stage 3)
            self.currentBrewingStageIndex = (self.currentBrewingStageIndex + 1) % usedStages.count
            self.playNextBrewingStage()
        }
    }
    
    /// Shows a static fallback image when atlas loading fails.
    ///
    /// **Requirement 5.6:** Display static fallback image on atlas load failure.
    private func showFallbackImage() {
        // Try to load fallback.png from the bundle
        if let fallbackImage = NSImage(named: "fallback") {
            let texture = SKTexture(image: fallbackImage)
            spriteNode.texture = texture
            spriteNode.size = texture.size()
            spriteNode.alpha = 1.0
        } else {
            os_log(.fault, "Fallback image 'fallback.png' not found in bundle.")
            // Hide sprite as last resort
            spriteNode.alpha = 0
        }
    }
}
