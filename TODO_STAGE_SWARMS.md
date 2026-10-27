# Stage themes, physical swarms and exploration rewards

Active specification: user-uploaded Stage Themes, Physical Enemy Swarms, Shrines, Rewards and Boss Multipliers (27 October 2026). Preserve existing systems and implement in this order.

Baseline: Godot 4.7.2, branch megaclonk-menu-loadouts, starting source 042813f. Existing player: scripts/player/controller.gd; batched enemies: game.gd + EnemySimulation/Encounters/EnemyTraversal; 8m combat grid; terrain/placement: ForestMap/ForestPlacement/ForestWorld; rewards: shared Rarity/RewardCatalog/RewardScreens; exports: tools/export.sh and Windows workflow. Current enemies use logical terrain collision but have no mutual bodies; contact damage shares attack cooldowns. Boss death currently opens the portal after the first boss, grants an item immediately and has no pickup-chest queue. Shrines still require E. World defaults are two shops/two chests/one elite statue.

- [x] Baseline import, fifteen suites and recorded timings.
- [x] 1. Configured green/violet/crimson material themes, explicit cycling and non-repeating animated stage banner; screenshots and tests.
- [x] 2. Independent per-enemy contact damage interval; preserve explosions, invulnerability and feedback.
- [x] 3. Spatial local collision, player obstruction and bounded supported crowd climbing; 50/100/250/500 profiling and terrain regression.
- [x] 4. One free chest per elite/miniboss/boss; safe placement, automatic collection, queued roulette, save compatibility and no duplicate rewards.
- [x] 5. Automatic 5m/8s proximity shrines; progress retention, readable orb and exactly one real stat reward.
- [x] 6. At least fifteen ordinary chests, rare free chests, three shops, two elite statues and one boss statue; deterministic reachable placement across 200 seeds.
- [x] 7. Run-persistent additional bosses, encounter snapshots, independently selected variants/valid positions, all-boss completion and safe summons.
- [ ] 8. Integrated regression/performance/visual checks, committed source and verified Windows publication.

Do not mark the full update complete until all acceptance criteria have evidence. Native Windows execution and gaming-GPU timings require appropriate hardware; Linux pack checks do not establish them.

Final source verification: all 22 suites pass, 761 named checks, 200 layouts, 200 decorated worlds, 104,353 collision rays, 400 enemy traversals, 1,000 live interactions, 73 cliff drops and 200 expanded-object layouts. Actual source renders were inspected for all three palettes, supported swarms, shrine before/after completion, boss statue, multiple boss health bars and the dropped chest.

Performance limitation: comparable dense baseline 50/100/250/500 CPU means were 1.08/2.09/5.08/10.08ms; new full AI/contact/crowd/grid/FX/HUD means were 2.04/4.45/11.81/23.99ms, worst 53.89ms at 500. Bounded collision solving alone averaged 5.23ms at 500 in the final regression. This is a material regression, not verified 60FPS. See docs/STAGE_SWARMS.md and raw release reports. Gaming-PC validation and further stress optimization remain open.

Delivery blocker: GitHub rejects the cloud GH_TOKEN with HTTP 401 Bad credentials. The user has been asked to reconnect GitHub. Git pushes work through the environment’s separate Git integration. Source 29ab593 is pushed and its clean local Windows export passed all three compiled smoke gates. The workflow now publishes gated development-branch pushes without requiring API dispatch. Hosted publication remains pending verification.
