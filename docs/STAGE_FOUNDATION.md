# Stage-loop foundation — October 23, 2026

This is milestone 1 of the new core gameplay specification, not the completed overhaul.

Each forest stage starts at 10:00. At 08:00 and 04:00, a 30-second mob rush
increases bounded spawn pressure. At 00:00, the display stops at zero and ordinary
enemy pressure/health continue increasing. Dedicated endless ghosts are pending.
The 07:00/03:00 miniboss thresholds are recorded by the scheduler, but actual
miniboss encounters are pending; no ordinary enemy is presented as a miniboss.

Find the purple portal at a ruin clearing away from spawn. Press E to summon the
existing Warden at any time, including endless mode. The countdown keeps running.
The red portal cannot transport the player until the Warden dies. It then turns
mint green. Press E to advance when ready; boss death itself does not end the stage.
Stage travel generates a new seeded forest, resets the countdown/events and readies
the ultimate while preserving weapons/levels, tomes, items, stats, XP/level, gold,
trait/ultimate selection, and the run's enemy variants. Stage difficulty increases.
Checkpoints preserve event history, portal state and stage number. The old
three-minute automatic-boss rule is removed.

Spawns now use an accrual budget (2.4 enemies/sec at opening pressure), bounded
catch-up, a 500-entity cap and initial 78% basic/15% fast/7% ranged composition.
Each kill automatically adds gold; this avoids thousands of coin physics objects.
Minimap ordinary-enemy dots are removed and a facing line is added.

Default run speed is 8m/s (previously 9), acceleration 55, deceleration 45,
gravity 34m/s², jump impulse 10, air acceleration 9 and slide friction 3.
Crouching, ceiling clearance, slope slides and air-carried momentum remain.
The outer cliff boundary cannot be climbed. Full movement modifiers are pending.

Jacob replaces the original Scout at runtime. The supplied Idle animation is
retained; original additive skeleton poses cover running/turning/jumping/falling/
crouching/sliding/hit/death. The demonstration ground/rocks/grass and claymore
are hidden. Visuals remain independent from player collision. Kurland is now the
UI font. The supplied five ability demo icons are used, with some reuse across
eight abilities; existing animated gold frames remain.

The previous economy, trait/ultimate values, shops, terrain and weapon upgrades
remain functional but do not yet meet the new specification. See TODO_STAGE_LOOP.md.
