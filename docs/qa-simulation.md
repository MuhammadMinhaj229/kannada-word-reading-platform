# Child task QA simulation

The **Task preview** navigation entry launches a fully interactive, non-participant simulation of the child-facing choice task.

## Run it

- On Android: install the engineering-preview APK, open **Task preview**, and tap **ಪ್ರಾರಂಭಿಸೋಣ**.
- In the browser review build: open the app and select **Task preview** from the navigation rail or bottom navigation.
- Select **ಪದ** or **ಪದವಲ್ಲ** for each card.
- Complete five practice cards, then ten scored QA cards.
- At ten responses, continue past the neutral milestone.
- Finish the flow, then open **Assessor results** to inspect the synthetic response key and reaction times.
- Use **Run again** to reset the simulation.

## Data boundary

This simulation is deliberately isolated from the participant workflow:

- All stimuli are synthetic interface fixtures, not approved Kannada lexical materials.
- QA answer keys are arbitrary fixture values and do not claim linguistic validity.
- Responses and elapsed response times exist only in the screen's in-memory state.
- No participant or assessor identifiers are requested.
- No SQLCipher database, frozen session manifest, item-bank importer, export or network endpoint is called.
- The production participant-release gate remains closed.

The simulation is suitable for testing navigation, large touch targets, Kannada font rendering, trial progression, neutral milestone behavior, reaction-time capture logic and assessor-only result presentation. It is **not** suitable for cognitive piloting, timing validation, linguistic review, protocol validation, or participant data collection.

## Before a field assessment can be enabled

The PI/statistician must approve the session arithmetic and schedule; the linguistic lead must approve the non-word bank and Kannada instructions; and ethics/data-governance, assessor authorization, recovery, export, target-tablet acceptance and institutional signing requirements must be completed. See [protocol decisions](protocol-decisions.md) and [field readiness status](STATUS.md).
