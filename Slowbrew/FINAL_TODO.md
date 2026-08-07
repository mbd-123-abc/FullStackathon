# Slowbrew - Final Implementation TODO

## Current Status
- ✅ Auto-dismiss timer works (5 minutes default)
- ✅ Overlay shows black screen with "Break Time! ☕️" text
- ✅ Quit button works
- ✅ Settings save and load
- ❌ NO brewing animation visible
- ❌ Pause doesn't preserve elapsed time
- ❌ Skip Next Break behavior unknown

## Task 1: Add Brewing Animation (Bottom-Right Corner)

### File: `OverlayWindowController.swift`

**Add properties:**
```swift
private var spriteAnimator: SpriteAnimator?
private var spriteView: SKView?
```

**In `show(on:duration:)` method, after adding the label, add:**
```swift
// Create SKView for sprite animation (bottom-right corner)
let animationSize: CGFloat = 300
let padding: CGFloat = 40
let spriteFrame = CGRect(
    x: screen.frame.width - animationSize - padding,
    y: padding,
    width: animationSize,
    height: animationSize
)

let skView = SKView(frame: spriteFrame)
skView.ignoresSiblingOrder = true
skView.showsFPS = false
skView.showsNodeCount = false
skView.backgroundColor = .clear
skView.autoresizingMask = [.minXMargin, .maxYMargin]

// Create sprite animator
let animator = SpriteAnimator(skView: skView)
self.spriteView = skView
self.spriteAnimator = animator

// Add to window
contentView.addSubview(skView)

// Start brewing animation
animator.playBrewing()
print("[OverlayWindowController] Started brewing animation")
```

**In `dismiss()` method, add:**
```swift
// Stop brewing animation
spriteAnimator?.stopBrewing()
spriteView?.removeFromSuperview()
spriteAnimator = nil
spriteView = nil
```

## Task 2: Fix Pause/Resume to Preserve Elapsed Time

### File: `StateMachine.swift`

**Find this code:**
```swift
case (.idle(let timerStartedAt), .pauseToggled):
    pausedTimerStartedAt = timerStartedAt
    return .paused(reason: .userPaused, since: now)
```

**Find this code:**
```swift
case (.paused, .pauseToggled):
    pausedTimerStartedAt = nil
    return .idle(timerStartedAt: now)
```

**Replace with:**
```swift
case (.paused(let reason, let pausedAt), .pauseToggled) where reason == .userPaused:
    // Calculate elapsed time before pause
    guard let originalStart = pausedTimerStartedAt else {
        // No stored start time, just resume from now
        pausedTimerStartedAt = nil
        return .idle(timerStartedAt: now)
    }
    
    // Calculate how long we were paused
    let pauseDuration = pausedAt.distance(to: now)
    
    // Adjust start time to preserve elapsed progress
    // If we had progressed 10 minutes before pause, and paused for 5 minutes,
    // the new start time should be (now - 10 minutes)
    let elapsedBeforePause = originalStart.distance(to: pausedAt)
    let adjustedStart = now.addingTimeInterval(-elapsedBeforePause)
    
    pausedTimerStartedAt = nil
    print("[StateMachine] Resuming from pause. Elapsed before pause: \(elapsedBeforePause)s, Pause duration: \(pauseDuration)s")
    return .idle(timerStartedAt: adjustedStart)
```

## Task 3: Fix Skip Next Break

### File: `StateMachine.swift`

**Find this code:**
```swift
case (.idle, .skipNextBreak):
    return .idle(timerStartedAt: now)
```

**Replace with:**
```swift
case (.idle(let timerStartedAt), .skipNextBreak):
    // Add one full interval to the current timer
    // This delays the next break but keeps subsequent breaks on schedule
    let oneInterval = TimeInterval(currentSettings.breakInterval * 60)
    let delayedStart = timerStartedAt.addingTimeInterval(oneInterval)
    print("[StateMachine] Skipping next break. Original start: \(timerStartedAt), Delayed start: \(delayedStart)")
    return .idle(timerStartedAt: delayedStart)
```

## Task 4: Test Everything

### Test Script:
1. Set break interval = 1 minute, break duration = 10 seconds
2. Start app, wait 1 minute
3. Verify overlay shows with "Break Time!" text
4. Verify brewing animation plays in bottom-right corner
5. Verify overlay auto-dismisses after 10 seconds
6. Test Pause:
   - Wait 30 seconds after app starts
   - Click Pause
   - Wait 10 seconds  
   - Click Resume
   - Break should fire 30 seconds later (not 60)
7. Test Skip Next Break:
   - Start app
   - Immediately click "Skip Next Break"
   - Next break should be in 2 minutes (not 1)
   - Break after that should be 1 minute later (normal schedule)

## Build and Run

```bash
cd /Users/arpitabagri/Downloads/Code/FullStackathon/Slowbrew
swift build
pkill -9 Slowbrew 2>/dev/null
.build/x86_64-apple-macosx/debug/Slowbrew > /tmp/slowbrew.log 2>&1 &
```

Check logs:
```bash
tail -f /tmp/slowbrew.log
```

## Expected Log Output

When working correctly:
```
[TimerService] Starting timer for interval: 60.0 seconds
[StateMachine] ⏰ TIMER FIRED! Transitioning to brewing state
[AppDelegate] Showing overlay for 10 seconds
[OverlayWindowController] Starting countdown timer for 10.0 seconds
[OverlayWindowController] Started brewing animation
... wait 10 seconds ...
[OverlayWindowController] ⏰ Countdown expired! Dismissing overlay
[StateMachine] Countdown expired, returning to idle
[AppDelegate] State changed to: idle
[TimerService] Starting timer for interval: 60.0 seconds
```

## Files to Modify
1. `/Users/arpitabagri/Downloads/Code/FullStackathon/Slowbrew/Sources/Slowbrew/Controllers/OverlayWindowController.swift`
2. `/Users/arpitabagri/Downloads/Code/FullStackathon/Slowbrew/Sources/Slowbrew/StateMachine/StateMachine.swift`

## Priority
1. **CRITICAL**: Add brewing animation (Task 1)
2. **HIGH**: Fix pause/resume (Task 2)
3. **MEDIUM**: Fix skip next break (Task 3)
4. **LOW**: Test everything (Task 4)
