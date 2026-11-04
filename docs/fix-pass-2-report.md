# Fix pass 2 report

Branch: `feature/fix-pass-2`. Full `tools/validate.sh` passes. New suite: `tests/fix_pass_2.gd` (18 checks).

## 1. Menu hover sounds
Cause: `ui.hover` had a 0.12 s cooldown and 3 voices against a 0.58 s clip. Now 0.03 s / 8 voices; card hover 0.02 s / 6 voices.

## 2. Gem socket hover silent
Cause: the sample is about 15 dB quieter than the other UI clips. Gain raised +6 dB.

## 3. Haste -> Attack speed
Label and help text changed in the UI and item text.

## 4. Armour is a percentage
Reduction = armour / (75 + armour). 75 armour = 50%, never reaches 100%. Shown as %. Sources rescaled (about x4): Iron tome 2 -> 8, character 1 +1.5 -> +6 per level, stat rewards [4,8,12,20,32], Grave Salt 1 -> 4, Witch-Hunter's Brand x4. Old saves keep their stored numbers.

## 5. Performance root cause
Cost is per-enemy GDScript work (contact, simulation, traversal, crowd physics, view). It was linear per enemy but crowding made it nonlinear, and every enemy ran at full rate regardless of distance. Measured with `tools/enemy_scale_profile.gd`.
Mitigations: distance LOD (near every frame, then every 2nd/3rd/4th frame with accumulated delta, redrawn from a cached pose), a cached terrain-height plane lookup, and a cheaper mesh lookup. At 500 enemies the frame cost fell from about 69 ms to about 45 ms in this headless sandbox. That is still above 16.6 ms, so 500 live enemies will not hold 60 fps here; real-hardware numbers are not measured. The main lever is keeping the live count down via the spawner.

## Spawner
Credit based. Starts at 0.25 enemies/s in stage 1 and grows to 3/s over the stage. Clearing the field earns up to 3x, falling to 1x as the living count nears a soft cap (25 -> 300 over the stage). Multiplied by Difficulty.

## 6. Difficulty
Raises enemy hp, damage, spawn rate and soft cap 1:1, and speed by 0.25 per point (capped at 1.6x).

## 7. Lifesteal
Chance per damaging hit to restore 1 HP. Each full 100% guarantees one more HP (250% = 2 HP, plus 1 more half the time). Rolls use the weapon RNG. Vampire tome +3% per level; character 17 +5% per level.

## Also fixed
A latent determinism leak: the crowd id counter and solve phase carried between runs in one process. Now reset per run.
