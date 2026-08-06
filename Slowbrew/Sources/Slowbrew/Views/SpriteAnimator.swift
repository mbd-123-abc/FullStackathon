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
    ///   - completion: Called when the animation completes (after 3 seconds max).
    ///
    /// **Requirement 3.4, 3.5:** Walk-in animation must complete within 3 seconds.
    func playWalkIn(direction: HorizontalEdge, completion: @escaping () -> Void) {
        // Load the walk-in atlas
        guard let textures = loadAtlas(named: "WalkIn") else {
            // Fallback: show static image and complete immediately
            showFallbackImage()
            completion()
            return
        }
        
        // Position sprite at the edge based on direction
        let startX: CGFloat
        let endX: CGFloat = scene.size.width / 2
        
        if direction == .left {
            startX = -spriteNode.size.width / 2
            spriteNode.xScale = 1.0 // Face right
        } else {
            startX = scene.size.width + spriteNode.size.width / 2
            spriteNode.xScale = -1.0 // Face left (flip horizontally)
        }
        
        spriteNode.position = CGPoint(x: startX, y: scene.size.height / 2)
        
        // Calculate time per frame to complete in 3 seconds
        let duration: TimeInterval = 3.0
        let timePerFrame = duration / Double(textures.count)
        
        // Create animation action
        let animateAction = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: true, restore: false)
        let moveAction = SKAction.moveTo(x: endX, duration: duration)
        let groupAction = SKAction.group([animateAction, moveAction])
        
        spriteNode.run(groupAction) {
            completion()
        }
    }
    
    /// Starts the looping brewing animation.
    ///
    /// Cycles through the 4 brewing stages in order:
    /// `heatingWater → steeping → pouring → presentingCup` → repeat
    ///
    /// Each stage lasts at least 1 second (Requirement 5.2, 5.5).
    func playBrewing() {
        currentBrewingStageIndex = 0
        playNextBrewingStage()
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
    ///   - completion: Called when the animation completes (after 3 seconds max).
    ///
    /// **Requirement 3.6:** Walk-out animation must complete within 3 seconds.
    func playWalkOut(direction: HorizontalEdge, completion: @escaping () -> Void) {
        // Load the walk-out atlas
        guard let textures = loadAtlas(named: "WalkOut") else {
            // Fallback: hide sprite and complete immediately
            spriteNode.alpha = 0
            completion()
            return
        }
        
        // Position sprite to walk out toward the edge
        let startX = scene.size.width / 2
        let endX: CGFloat
        
        if direction == .left {
            endX = -spriteNode.size.width / 2
            spriteNode.xScale = -1.0 // Face left
        } else {
            endX = scene.size.width + spriteNode.size.width / 2
            spriteNode.xScale = 1.0 // Face right
        }
        
        spriteNode.position = CGPoint(x: startX, y: scene.size.height / 2)
        
        // Calculate time per frame to complete in 3 seconds
        let duration: TimeInterval = 3.0
        let timePerFrame = duration / Double(textures.count)
        
        // Create animation action
        let animateAction = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: true, restore: false)
        let moveAction = SKAction.moveTo(x: endX, duration: duration)
        let groupAction = SKAction.group([animateAction, moveAction])
        
        spriteNode.run(groupAction) {
            completion()
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads an `SKTextureAtlas` by name and returns its textures sorted by name.
    ///
    /// - Parameter name: The atlas name (e.g., "WalkIn", "BrewStage1").
    /// - Returns: Array of `SKTexture` sorted alphabetically, or `nil` on failure.
    private func loadAtlas(named name: String) -> [SKTexture]? {
        let atlas = SKTextureAtlas(named: name)
        
        // Check if atlas contains textures
        guard atlas.textureNames.count > 0 else {
            os_log(.error, "Atlas '%{public}@' failed to load or contains no textures.", name)
            return nil
        }
        
        // Sort texture names alphabetically to ensure correct frame order
        let sortedNames = atlas.textureNames.sorted()
        return sortedNames.map { atlas.textureNamed($0) }
    }
    
    /// Plays the next brewing stage in the sequence.
    ///
    /// Advances through `BrewingStage.allCases` in order, looping back to the first
    /// stage after the last one completes (Requirement 5.2, 5.5).
    private func playNextBrewingStage() {
        let stages = BrewingStage.allCases
        let stage = stages[currentBrewingStageIndex]
        
        // Load the atlas for this stage
        guard let textures = loadAtlas(named: stage.atlasName) else {
            // Fallback: show static image and stop brewing
            showFallbackImage()
            stopBrewing()
            return
        }
        
        // Calculate time per frame (minimum 1 second per stage)
        let stageDurationSeconds = max(1.0, Double(stage.minimumDuration.components.seconds))
        let stageDuration: TimeInterval = stageDurationSeconds
        let timePerFrame = stageDuration / Double(textures.count)
        
        // Create animation action
        let animateAction = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: true, restore: false)
        
        spriteNode.run(animateAction)
        
        // Schedule next stage after this one completes
        brewingStageTimer = Timer.scheduledTimer(withTimeInterval: stageDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Advance to next stage (loop back to 0 after last stage)
            self.currentBrewingStageIndex = (self.currentBrewingStageIndex + 1) % stages.count
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
