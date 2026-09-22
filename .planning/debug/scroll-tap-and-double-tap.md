# Debug Session: Scroll Tap and Double Tap Issues

## Symptoms
- **Expected:**
  1. Scrolling with 1 finger on the Magic Mouse surface should NOT trigger an accidental 1-finger tap (left click).
  2. Rapid 1-finger double tapping should work naturally (registering as two rapid single taps when 1-Finger Double Tap is not explicitly mapped), and single taps should never be swallowed/eaten.
- **Actual:**
  1. Unintended 1-finger tap (left click) is triggered when scrolling.
  2. Cannot double-tap 1 finger; sometimes user needs to double-tap just to get a single tap registered.
- **Errors:** None in logs (logic/threshold issue).
- **Reproduction:**
  1. Scroll with 1 finger on Magic Mouse surface: at end of scroll or on short flick, a 1-finger tap is detected.
  2. Tap 1 finger quickly twice: second tap is swallowed by `consecutiveTapCount == 2` dispatching unmapped `.oneFingerDoubleTap`. If prior scroll flick registered as tap 1, the user's actual single tap registers as tap 2 (swallowed), requiring another tap to work.

## Root Cause Analysis
1. **Accidental Tap During Scrolling:**
   - In `GestureRecognizer.swift`, `isTap` only measures net displacement `sqrt(avgDx^2 + avgDy^2) < 0.065`. During scrolling, especially with momentum or quick flicks, the finger may travel along the surface, slow down or reverse, or end with a small displacement between initial touch and lift-off.
   - Crucially, `GestureRecognizer` has no tracking of *total path length* or *peak velocity* during a touch. If a finger moved 0.20 down during a scroll but ended near its start, or if a short scroll flick traveled $< 0.065$, it was classified as a tap!
   - Furthermore, macOS native scrolling sends scroll wheel events (`CGEventType.scrollWheel`) via CGEvent. If a scroll event was just actively generated or if finger traveled with continuous trajectory, it is scrolling, not a tap!
   - In `TouchPoint`, we should track total accumulated path distance (`totalTraveledDistance`), not just net displacement from initial to final. A tap has minimal total traveled distance ($< 0.045$), whereas scrolling accumulates continuous movement along the Y axis ($> 0.05$).
2. **Double Tap Swallowing & Tap Dropping:**
   - `consecutiveTapCount` in `evaluateCompletedGesture` unconditionally promotes the 2nd tap to `dispatchDoubleTap(fingerCount: 1)`.
   - When the user does NOT have `oneFingerDoubleTap` mapped (as confirmed in `gestures.json`), the second tap is completely eaten because `actionForGesture(.oneFingerDoubleTap)` is nil!
   - Even worse: if a scroll flick falsely triggered tap 1 (`consecutiveTapCount = 1`), the user's subsequent intentional tap within 350ms becomes `consecutiveTapCount = 2`, triggering unmapped double tap and doing nothing! The user was forced to tap AGAIN to get a tap.
   - Also, in `main.swift`, the 150ms debounce `if gesture == lastDispatchedGesture && (now - lastDispatchedTime) < 0.15` would block a real second single-tap if both dispatched `.oneFingerTapLeft`!

## Hypotheses
- **H1:** Tracking accumulated path distance (or maximum distance from origin across all frames) during a 1-finger contact will immediately distinguish scrolling from a tap. If max deviation or total path $> 0.045$, it is scrolling/movement, not a tap.
- **H2:** If `oneFingerDoubleTap` (or multi-tap) is not enabled/mapped in `ConfigurationStore`, rapid consecutive taps should fall back to dispatching `oneFingerTapLeft` / `oneFingerTapRight` so double-clicking/tapping works seamlessly without dropping taps.
- **H3:** Adjust the identical-gesture debounce in `main.swift` to allow consecutive single taps (at intervals $\ge 0.08\text{s}$), only blocking true micro-bounces ($< 0.07\text{s}$).

## Resolution & Verification
1. **Accidental Tap During Scrolling:**
   - Added `maxExcursionFromStart` and `totalPathDistance` tracking to `GestureRecognizer.swift`. Any touch that deviates $> 0.045$ from its initial touchdown point or accumulates $> 0.050$ total path length is classified as scrolling/movement and rejected from tap detection.
   - Added native `CGEventType.scrollWheel` event interception in `MultitouchManager.swift` to notify `GestureRecognizer.notifyScrollActivity()`, establishing a 250ms cooldown where finger release after scrolling cannot trigger a tap.
2. **Double Tap & Dropped Single Taps:**
   - In `main.swift`, added fallback in `multitouchManagerDidDetect`: if `oneFingerDoubleTap` is not explicitly mapped by the user, it automatically falls back to `lastSingleTapGesture` action (`Left Click` / `Right Click`), preserving native macOS double-clicking without eating the second tap.
   - Reduced identical-gesture debounce to 50ms so rapid deliberate taps/double clicks are never dropped.
   - Eliminating the false tap from scroll flicks ensures `consecutiveTapCount` starts at 0 for real user taps, eliminating the "need to double tap to get single tap" issue.
3. **Automated Tests:**
   - Added `testScrollDoesNotTriggerTap` (testing 1-finger vertical scroll trajectory).
   - Added `testScrollNotificationSuppressesTap` (testing native scroll activity suppression).
   - All 30 MagicTouch test suites pass successfully.

