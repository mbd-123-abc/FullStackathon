# CRITICAL FIXES NEEDED FOR SLOWBREW

## Priority 1: SAFETY - Prevent Permanent Lockout

### Issue
The overlay locked the user out permanently, requiring a computer restart. **This is unacceptable.**

### Required Fixes

1. **Auto-Dismiss Timer** ✅ CRITICAL
   - Add a Timer in OverlayWindowController that automatically dismisses the overlay after the break duration
   - Default: 5 minutes
   - Must fire `.countdownExpired` event to state machine
   - Add logging: "⏰ Break duration elapsed! Auto-dismissing..."

2. **Emergency Escape Hatch** ⚠️ CRITICAL
   - Add key event handler to OverlayWindowController
   - Cmd+Q or Escape key should force-dismiss the overlay
   - Log: "🚨 Emergency escape activated!"

3. **Countdown Display** ⚠️ HIGH PRIORITY
   - Show remaining time in MM:SS format
   - User can see how long until auto-dismiss
   - Prevents panic

## Priority 2: Core Functionality

4. **Brewing Animation** ⚠️ HIGH PRIORITY
   - Add SKView to overlay window
   - Create SpriteAnimator instance
   - Play brewing loop animation
   - Falls back to static image if sprites missing

5. **Countdown HUD** ⚠️ HIGH PRIORITY
   - Add SwiftUI BrewingHUD to overlay
   - Show MM:SS countdown
   - Show Snooze button with remaining count
   - Update every second

## Priority 3: Menu Bar Functionality

6. **Verify Pause Works**
   - Test: Click menu bar → Pause
   - Expected: Timer stops, state → .paused
   - Expected: Menu shows "Resume" instead of "Pause"

7. **Verify Skip Next Break Works**
   - Test: Click menu bar → Skip Next Break
   - Expected: Timer restarts from zero
   - Expected: Next break delayed by full interval

8. **Verify Quit Works**
   - Test: Click menu bar → Quit
   - Expected: App terminates immediately
   - Status: FIXED ✅

## Current Status (from logs)

### Working ✅
- Settings save and persist
- Timer restarts when settings change
- Overlay shows (but gets stuck)
- Menu bar icon appears
- Quit button works

### Broken ❌
- **Overlay never auto-dismisses** (CRITICAL BUG)
- No brewing animation shown
- No countdown timer shown
- No emergency escape
- Pause/Skip not verified

## Implementation Plan

1. Fix OverlayWindowController.show() to accept duration parameter
2. Start auto-dismiss timer when overlay shows
3. Add emergency key handler (Cmd+Q, Escape)
4. Add SKView + SpriteAnimator
5. Add SwiftUI HUD with countdown
6. Test Pause and Skip Next Break
7. Add comprehensive logging

## Test Plan

1. Set break interval to 1 minute, break duration to 10 seconds
2. Wait for overlay to show
3. Verify countdown displays and counts down
4. Verify brewing animation plays
5. Verify overlay auto-dismisses after 10 seconds
6. Test emergency escape (Cmd+Q)
7. Test Pause (timer should stop)
8. Test Skip Next Break (timer should restart)
9. Test Snooze button (if snoozes remain)
