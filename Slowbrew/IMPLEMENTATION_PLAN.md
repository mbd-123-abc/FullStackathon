# Slowbrew - Complete Implementation Plan

## Current Status Analysis

### What Works ✅
- Menu bar icon appears
- Settings window opens and saves
- Timer starts (but uses wrong duration)
- Overlay shows (but never dismisses automatically)
- Quit button works
- State machine has countdown expiry logic

### Critical Issues ❌

1. **Overlay has NO visible countdown** - user can't see time remaining
2. **Overlay has NO brewing animation** - just black screen with text
3. **Overlay has NO auto-dismiss** - locks user out forever
4. **Pause doesn't preserve elapsed time** - timer resets instead of resuming
5. **Skip Next Break behavior unclear** - needs to just skip ONE break

## Implementation Requirements

### 1. Auto-Dismiss Overlay (CRITICAL)
**Status:** Partially implemented, needs testing
- OverlayWindowController has `autoDismissTimer` property ✅
- Timer set to fire after duration ✅
- Calls `onCountdownExpired` callback ✅
- AppDelegate wires callback to send `.countdownExpired` ✅
- StateMachine transitions brewing → idle on countdownExpired ✅
- **NEEDS:** Testing with short duration (10 seconds)

### 2. Countdown Display (HIGH PRIORITY)
**Location:** Top-right corner of overlay
**Format:** MM:SS (e.g., "04:37")
**Implementation:**
- Add NSTextField to overlay window
- Position at top-right with padding (20px from edges)
- Large, white, monospaced font (SF Mono, 48pt)
- Update every second using Timer
- Calculate: `remaining = breakDuration - elapsed`

### 3. Brewing Animation (HIGH PRIORITY)
**Status:** SpriteAnimator implemented, not wired
**Implementation:**
- Add SKView to overlay window (centered, 400x400)
- Create SpriteAnimator instance
- Call `playBrewing()` when overlay shows
- Call `stopBrewing()` when overlay dismisses
- Handle missing sprites gracefully (show fallback)

### 4. Fix Pause/Resume Timer Preservation
**Current Behavior:** Pause → Resume resets timer to zero ❌
**Required Behavior:** Pause → Resume continues from where it left off ✅

**Implementation:**
- StateMachine stores `pausedTimerStartedAt` when entering pause
- On resume from user pause: calculate elapsed = (pause time - start time)
- New timer start = now - elapsed
- This preserves the "virtual start time"

**State Machine Changes:**
```swift
case (.idle(let timerStartedAt), .pauseToggled):
    pausedTimerStartedAt = timerStartedAt  // Preserve start time
    return .paused(reason: .userPaused, since: now)

case (.paused(.userPaused, let pausedAt), .pauseToggled):
    // Calculate how long we were paused
    let pauseDuration = pausedAt.distance(to: now)
    // Restore the original start time adjusted for pause duration
    let restoredStart = (pausedTimerStartedAt ?? now).addingTimeInterval(-pauseDuration)
    pausedTimerStartedAt = nil
    return .idle(timerStartedAt: restoredStart)
```

### 5. Fix Skip Next Break
**Current Behavior:** Unknown ❌
**Required Behavior:** Skip ONLY the next break, then resume normal schedule ✅

**Implementation Option 1 (Recommended):**
When "Skip Next Break" clicked:
- Get current timer's start time
- Add one full interval to it
- Restart timer with new start time
- This effectively delays the next break by one interval

```swift
case (.idle(let timerStartedAt), .skipNextBreak):
    let settings = currentSettings
    let oneInterval = TimeInterval(settings.breakInterval * 60)
    let newStartTime = timerStartedAt.addingTimeInterval(oneInterval)
    return .idle(timerStartedAt: newStartTime)
```

## Testing Plan

### Phase 1: Safety Testing (10-second breaks)
1. Set break interval = 1 minute, break duration = 10 seconds
2. Wait 1 minute for overlay
3. Verify countdown shows and counts down from 00:10
4. Verify overlay auto-dismisses after 10 seconds
5. Verify timer restarts automatically

### Phase 2: Animation Testing
1. Verify brewing animation plays (or fallback image shows)
2. Verify countdown updates every second
3. Verify overlay is black with centered animation

### Phase 3: Pause/Resume Testing
1. Start app, note timer start
2. Wait 30 seconds
3. Click Pause
4. Wait 10 seconds
5. Click Resume
6. Timer should fire 30 seconds later (not 60)

### Phase 4: Skip Next Break Testing
1. Start app
2. Immediately click "Skip Next Break"
3. Next break should be delayed by one full interval
4. Break after that should be on normal schedule

## Priority Order

1. **[CRITICAL]** Verify auto-dismiss works (test with 10-second duration)
2. **[HIGH]** Add countdown display (top-right corner, MM:SS)
3. **[HIGH]** Wire brewing animation (centered character)
4. **[MEDIUM]** Fix pause/resume to preserve elapsed time
5. **[MEDIUM]** Implement skip next break correctly
6. **[LOW]** Add snooze button (already in BrewingHUD)

## Code Files to Modify

1. `OverlayWindowController.swift` - Add countdown label, SKView, update timer
2. `AppDelegate.swift` - Already wired, verify countdown callback
3. `StateMachine.swift` - Fix pause/resume, fix skip next break
4. `TimerService.swift` - (No changes needed)

## Next Steps

1. Test current auto-dismiss (is it working?)
2. Add countdown label to overlay
3. Wire sprite animator to overlay
4. Fix pause/resume logic
5. Implement skip next break
6. Test everything with short durations
7. Increase to production durations (15 min / 5 min)
