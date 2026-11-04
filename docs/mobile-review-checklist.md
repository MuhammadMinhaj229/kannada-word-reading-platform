# Mobile UX review checklist

Use the Vercel preview for visual review with synthetic data only.

## Phone and portrait
- Bottom navigation remains visible and all six destinations are tappable.
- Main content has no horizontal overflow at 320, 360, 390 and 430 CSS-pixel widths.
- Buttons, inputs and select controls remain comfortably touchable.
- Browser zoom remains enabled.
- Keyboard focus remains visible.
- Install control does not overlap the connection indicator.
- Safe-area padding keeps content clear of device edges.

## Tablet and landscape
- Sidebar remains readable or switches to bottom navigation in portrait.
- Dashboard cards and forms adapt without clipped text.
- Child play view occupies the screen without assessor chrome.
- Kannada stimulus and answer controls remain large and centered.

## Child-play mode
- No assessor navigation or workspace details are visible while a trial is active.
- Five practice examples precede the ten-item visual demo.
- Demo progress advances one item at a time.
- Rewards appear after every five completed scored demo trials, independent of accuracy.
- A failed local write must not silently advance to the next stimulus.

## Research and release guardrails
- Visible demo stimuli are fictional and must not be used as study stimuli.
- Do not enter production participant data in the preview.
- Complete offline/device validation and PI approval before field use.
