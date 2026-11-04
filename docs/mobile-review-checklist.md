# Mobile UX and release review checklist

## Phone and portrait
- [ ] Bottom navigation remains visible and all six destinations are tappable.
- [ ] No horizontal overflow at 320, 360, 390 and 430 CSS-pixel widths.
- [ ] Buttons and answer controls meet comfortable touch sizing.
- [ ] Browser zoom remains enabled.
- [ ] Keyboard focus remains visible.
- [ ] Install/update controls do not overlap network status.
- [ ] Safe-area padding keeps controls clear of device edges.
- [ ] Inputs do not trigger unwanted mobile viewport zoom.

## Tablet and landscape
- [ ] Sidebar and cards adapt to available screen width.
- [ ] Child play view occupies the viewport without assessor chrome.
- [ ] Kannada stimulus and answer controls remain large and centered.
- [ ] The tablet orientation matches the approved protocol.

## Child-play mode
- [ ] Only the child-facing task is visible while a trial is active.
- [ ] Five practice items precede the scored block, per the PI-approved protocol.
- [ ] Progress advances only after local persistence succeeds.
- [ ] Rewards appear after every five completed scored items, independent of accuracy.
- [ ] No correctness feedback or spoken stimulus is exposed in scored trials unless approved.
- [ ] A failed local write must not silently advance the next stimulus.

## PWA and data
- [ ] Install prompt works on the actual supported Android browser.
- [ ] Service worker caches app shell, fonts and required assets.
- [ ] Cold offline launch succeeds after first online setup.
- [ ] App update does not interrupt an active session.
- [ ] Exports open correctly and preserve Kannada Unicode.
- [ ] Export does not delete original local records.
- [ ] Browser storage persistence, device loss and retention are reviewed with the institution.

## Research release guardrails
- [ ] Final 540-item bank is approved and versioned by the research team.
- [ ] Five-practice-vs-90-scored interpretation is approved by the PI.
- [ ] Kannada instruction script and native-speaker recordings are approved.
- [ ] REDCap import field mapping is signed off.
- [ ] Ethics, device-security, local-storage and data-retention approvals are complete.
- [ ] Do not enter real participant data in Vercel preview deployments.
