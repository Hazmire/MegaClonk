# Rarity-first rewards and world overhaul

The user's new specification requires Gate 1 before terrain or UI work. The published rarity-foundation-v5 playtest remains available while the Vertical Forest publication is verified.

- [x] Audit inventory, upgrades, chest/shop probabilities, unlocks and saves.
- [x] Implement five-tier registry, shared catalog adapter and weighted selection.
- [x] Test seeded distribution, eligibility, upgrades, prices and run saves.
- [x] Full existing regression suite passes; final rarity suite passes 143 checks.
- [x] Windows release/artifact verified from clean source 321f177. Downloaded ZIP size/SHA256/CRCs match; embedded game data passes 180-frame headless smoke. Native Windows execution remains untested.
- [x] Gate 2: substantially more vertical, irregular connected terrain, configurable bands/coverage/ramps; 200-seed metrics and 12 rendered seed previews.
- [x] Gate 3: layered fantasy sky/clouds and constrained, reachable randomized objects; 200-seed placement records.
- [ ] Gate 4: blue gemstone XP, rare red exact-level gems, stacked level-up UI and chest roulette.
- [ ] Gate 5: shared rarity cards/effects, shop and actual-data build screen; 720p/1080p/1440p/controller verification.
- [ ] Gate 6: full integration/performance measurements and verified final Windows release.

The Vertical Forest increment completes Milestones 2–4 / Gates 2–3. Local evidence: 605 assertions, 200 deterministic layouts, 200 decorated worlds, 9,914 collision rays, 1,000 live interactions, 70 cliff-drop cases and 12 rendered seed previews. Terrain-version-3 saves keep the legacy generator; new runs use version 4.

- [ ] Verify the Vertical Forest Windows publication and downloaded archive.

XP gems, level-up/chest/shop/build UI and the final full-overhaul release gate remain pending. See docs/VERTICAL_FOREST.md and docs/VERTICAL_PERFORMANCE.md.
