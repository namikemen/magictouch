/**
 * MagicTouch — Complete 41-Gesture Catalog Dataset
 * Corresponds to GestureType and default ActionTargets in the native Swift engine.
 */

window.GESTURES_DATA = [
  // --- 1-Finger Gestures ---
  {
    id: 'oneFingerTapLeft',
    name: '1-Finger Tap Left',
    fingerCount: 1,
    category: 'tap',
    icon: '👆',
    description: 'Light single tap on the left upper surface',
    defaultAction: 'Primary Mouse Click',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerTapRight',
    name: '1-Finger Tap Right',
    fingerCount: 1,
    category: 'tap',
    icon: '👆',
    description: 'Light single tap on the right upper surface',
    defaultAction: 'Secondary Click (Right Click)',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerDoubleTap',
    name: '1-Finger Double Tap',
    fingerCount: 1,
    category: 'tap',
    icon: '✌️',
    description: 'Two quick taps anywhere on the active capacitive surface',
    defaultAction: 'Smart Zoom (2x Scale)',
    actionType: 'system'
  },
  {
    id: 'oneFingerDoubleTapLeft',
    name: '1-Finger Double Tap Left',
    fingerCount: 1,
    category: 'tap',
    icon: '✌️',
    description: 'Two quick successive taps in the upper-left quadrant',
    defaultAction: 'Double Click (Select Word)',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerDoubleTapRight',
    name: '1-Finger Double Tap Right',
    fingerCount: 1,
    category: 'tap',
    icon: '✌️',
    description: 'Two quick successive taps in the upper-right quadrant',
    defaultAction: 'Look Up & Data Detectors',
    actionType: 'system'
  },
  {
    id: 'oneFingerTripleTap',
    name: '1-Finger Triple Tap',
    fingerCount: 1,
    category: 'tap',
    icon: '🖐️',
    description: 'Three rapid fingertip taps anywhere on the touch zone',
    defaultAction: 'Triple Click (Select Paragraph)',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerTripleTapLeft',
    name: '1-Finger Triple Tap Left',
    fingerCount: 1,
    category: 'tap',
    icon: '🖐️',
    description: 'Three rapid fingertip taps on the left upper zone',
    defaultAction: 'Select Entire Line',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerTripleTapRight',
    name: '1-Finger Triple Tap Right',
    fingerCount: 1,
    category: 'tap',
    icon: '🖐️',
    description: 'Three rapid fingertip taps on the right upper zone',
    defaultAction: 'Show Contextual Menu',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerClick',
    name: '1-Finger Click',
    fingerCount: 1,
    category: 'click',
    icon: '🖱️',
    description: 'Mechanical switch depression with single contact point',
    defaultAction: 'Standard Left Click',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerSwipeLeft',
    name: '1-Finger Swipe Left',
    fingerCount: 1,
    category: 'swipe',
    icon: '👈',
    description: 'Single finger gliding horizontally towards the left',
    defaultAction: 'Navigate Back (History)',
    actionType: 'system'
  },
  {
    id: 'oneFingerSwipeRight',
    name: '1-Finger Swipe Right',
    fingerCount: 1,
    category: 'swipe',
    icon: '👉',
    description: 'Single finger gliding horizontally towards the right',
    defaultAction: 'Navigate Forward (History)',
    actionType: 'system'
  },
  {
    id: 'oneFingerSwipeUp',
    name: '1-Finger Swipe Up',
    fingerCount: 1,
    category: 'swipe',
    icon: '☝️',
    description: 'Vertical single-finger glide towards the top edge',
    defaultAction: 'Smooth Inertial Scroll Up',
    actionType: 'mouse'
  },
  {
    id: 'oneFingerSwipeDown',
    name: '1-Finger Swipe Down',
    fingerCount: 1,
    category: 'swipe',
    icon: '👇',
    description: 'Vertical single-finger glide towards the bottom edge',
    defaultAction: 'Smooth Inertial Scroll Down',
    actionType: 'mouse'
  },

  // --- 2-Finger Gestures ---
  {
    id: 'twoFingerTap',
    name: '2-Finger Tap',
    fingerCount: 2,
    category: 'tap',
    icon: '✌️',
    description: 'Two simultaneous finger taps across the active surface',
    defaultAction: 'Secondary Click (Right Click)',
    actionType: 'mouse'
  },
  {
    id: 'twoFingerDoubleTap',
    name: '2-Finger Double Tap',
    fingerCount: 2,
    category: 'tap',
    icon: '✌️',
    description: 'Two fingers double-tapping in quick succession',
    defaultAction: 'Mission Control',
    actionType: 'system'
  },
  {
    id: 'twoFingerTripleTap',
    name: '2-Finger Triple Tap',
    fingerCount: 2,
    category: 'tap',
    icon: '✌️',
    description: 'Two fingers triple-tapping in rapid sequence',
    defaultAction: 'Launchpad Toggle',
    actionType: 'system'
  },
  {
    id: 'twoFingerClick',
    name: '2-Finger Click',
    fingerCount: 2,
    category: 'click',
    icon: '🖱️',
    description: 'Physical mouse click with two fingers resting on glass',
    defaultAction: 'Right Click (Customizable)',
    actionType: 'mouse'
  },
  {
    id: 'twoFingerSwipeLeft',
    name: '2-Finger Swipe Left',
    fingerCount: 2,
    category: 'swipe',
    icon: '👈',
    description: 'Two parallel fingers swiping horizontally to the left',
    defaultAction: 'Swipe Between Full-Screen Apps',
    actionType: 'system'
  },
  {
    id: 'twoFingerSwipeRight',
    name: '2-Finger Swipe Right',
    fingerCount: 2,
    category: 'swipe',
    icon: '👉',
    description: 'Two parallel fingers swiping horizontally to the right',
    defaultAction: 'Swipe Between Full-Screen Apps',
    actionType: 'system'
  },
  {
    id: 'twoFingerSwipeUp',
    name: '2-Finger Swipe Up',
    fingerCount: 2,
    category: 'swipe',
    icon: '☝️',
    description: 'Two parallel fingers gliding upwards',
    defaultAction: 'Mission Control / Desktop Preview',
    actionType: 'system'
  },
  {
    id: 'twoFingerSwipeDown',
    name: '2-Finger Swipe Down',
    fingerCount: 2,
    category: 'swipe',
    icon: '👇',
    description: 'Two parallel fingers gliding downwards',
    defaultAction: 'App Exposé',
    actionType: 'system'
  },
  {
    id: 'twoFingerPinchIn',
    name: '2-Finger Pinch In',
    fingerCount: 2,
    category: 'pinch',
    icon: '🤏',
    description: 'Two fingers moving inwards towards one another',
    defaultAction: 'Zoom Out (⌘-)',
    actionType: 'hotkey'
  },
  {
    id: 'twoFingerPinchOut',
    name: '2-Finger Pinch Out',
    fingerCount: 2,
    category: 'pinch',
    icon: '👐',
    description: 'Two fingers moving outwards away from one another',
    defaultAction: 'Zoom In (⌘+)',
    actionType: 'hotkey'
  },
  {
    id: 'tipTapLeft',
    name: 'Tip-Tap Left',
    fingerCount: 2,
    category: 'tip-tap',
    icon: '👈',
    description: 'Right finger rests as anchor while left finger taps',
    defaultAction: 'Previous Browser Tab (⌘⇧[)',
    actionType: 'hotkey'
  },
  {
    id: 'tipTapRight',
    name: 'Tip-Tap Right',
    fingerCount: 2,
    category: 'tip-tap',
    icon: '👉',
    description: 'Left finger rests as anchor while right finger taps',
    defaultAction: 'Next Browser Tab (⌘⇧])',
    actionType: 'hotkey'
  },

  // --- 3-Finger Gestures ---
  {
    id: 'threeFingerTap',
    name: '3-Finger Tap',
    fingerCount: 3,
    category: 'tap',
    icon: '🖐️',
    description: 'Three fingers tapping lightly on the upper surface',
    defaultAction: 'Quick Look Preview (Space)',
    actionType: 'hotkey'
  },
  {
    id: 'threeFingerDoubleTap',
    name: '3-Finger Double Tap',
    fingerCount: 3,
    category: 'tap',
    icon: '🖐️',
    description: 'Three fingers double-tapping in quick succession',
    defaultAction: 'Toggle Focus / Do Not Disturb',
    actionType: 'system'
  },
  {
    id: 'threeFingerTripleTap',
    name: '3-Finger Triple Tap',
    fingerCount: 3,
    category: 'tap',
    icon: '🖐️',
    description: 'Three fingers triple-tapping in rapid succession',
    defaultAction: 'Lock Screen (⌃⌘Q)',
    actionType: 'hotkey'
  },
  {
    id: 'threeFingerClick',
    name: '3-Finger Click (Middle Click)',
    fingerCount: 3,
    category: 'click',
    icon: '🖱️',
    description: 'Hardware click with three fingers resting on the surface',
    defaultAction: 'Middle Click (Mouse Button 3)',
    actionType: 'mouse'
  },
  {
    id: 'threeFingerSwipeLeft',
    name: '3-Finger Swipe Left',
    fingerCount: 3,
    category: 'swipe',
    icon: '👈',
    description: 'Three fingers gliding horizontally to the left',
    defaultAction: 'Move Left a Space (Virtual Desktop)',
    actionType: 'system'
  },
  {
    id: 'threeFingerSwipeRight',
    name: '3-Finger Swipe Right',
    fingerCount: 3,
    category: 'swipe',
    icon: '👉',
    description: 'Three fingers gliding horizontally to the right',
    defaultAction: 'Move Right a Space (Virtual Desktop)',
    actionType: 'system'
  },
  {
    id: 'threeFingerSwipeUp',
    name: '3-Finger Swipe Up',
    fingerCount: 3,
    category: 'swipe',
    icon: '☝️',
    description: 'Three fingers gliding vertically upwards',
    defaultAction: 'Mission Control',
    actionType: 'system'
  },
  {
    id: 'threeFingerSwipeDown',
    name: '3-Finger Swipe Down',
    fingerCount: 3,
    category: 'swipe',
    icon: '👇',
    description: 'Three fingers gliding vertically downwards',
    defaultAction: 'Application Windows (Exposé)',
    actionType: 'system'
  },
  {
    id: 'threeFingerPinchIn',
    name: '3-Finger Pinch In',
    fingerCount: 3,
    category: 'pinch',
    icon: '🤏',
    description: 'Three fingers pinching inwards towards center',
    defaultAction: 'Show Desktop (⌘F3)',
    actionType: 'hotkey'
  },
  {
    id: 'threeFingerPinchOut',
    name: '3-Finger Pinch Out',
    fingerCount: 3,
    category: 'pinch',
    icon: '👐',
    description: 'Three fingers expanding outwards from center',
    defaultAction: 'Launchpad',
    actionType: 'system'
  },

  // --- 4-Finger Gestures ---
  {
    id: 'fourFingerTap',
    name: '4-Finger Tap',
    fingerCount: 4,
    category: 'tap',
    icon: '🖐️',
    description: 'Four fingers tapping down simultaneously',
    defaultAction: 'Mission Control Overview',
    actionType: 'system'
  },
  {
    id: 'fourFingerClick',
    name: '4-Finger Click',
    fingerCount: 4,
    category: 'click',
    icon: '🖱️',
    description: 'Mechanical click with four fingers resting on surface',
    defaultAction: 'Application Switcher (⌘Tab)',
    actionType: 'hotkey'
  },
  {
    id: 'fourFingerSwipeLeft',
    name: '4-Finger Swipe Left',
    fingerCount: 4,
    category: 'swipe',
    icon: '👈',
    description: 'Four fingers gliding horizontally to the left',
    defaultAction: 'Switch Space Left',
    actionType: 'system'
  },
  {
    id: 'fourFingerSwipeRight',
    name: '4-Finger Swipe Right',
    fingerCount: 4,
    category: 'swipe',
    icon: '👉',
    description: 'Four fingers gliding horizontally to the right',
    defaultAction: 'Switch Space Right',
    actionType: 'system'
  },
  {
    id: 'fourFingerSwipeUp',
    name: '4-Finger Swipe Up',
    fingerCount: 4,
    category: 'swipe',
    icon: '☝️',
    description: 'Four fingers gliding vertically upwards',
    defaultAction: 'Mission Control',
    actionType: 'system'
  },
  {
    id: 'fourFingerSwipeDown',
    name: '4-Finger Swipe Down',
    fingerCount: 4,
    category: 'swipe',
    icon: '👇',
    description: 'Four fingers gliding vertically downwards',
    defaultAction: 'Show Desktop',
    actionType: 'system'
  }
];
