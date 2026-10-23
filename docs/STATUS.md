# Current status — MEGACLONK menu/loadout update

The functional menu, loadout and progression update is implemented on top of the previous movement/enemy overhaul. The exact requested third-party asset integration is **blocked and incomplete**.

Implemented: four-button menu with orbiting forest and four unlock progress cards; one adventurer with independently selected starting weapon/trait/ultimate; personal loadout leaderboard; collection tabs, disabled drop pools and locked-detail privacy; twelve tracked/claimable quests; credits, quest gold, account levels and permanent 2→4 weapon/tome slots. Display/Graphics/Audio/Gameplay settings, shops, rewards, level-up cards and stats/items have separate layouts.

Five traits and three cooldown ultimates have real effects, HUD states and run-save persistence. The HUD has bottom-wide XP, loadout/ability icons with animated gold frames, chest prices, countdown/overtime and fogged minimap. One cliff-bounded forest replaces the map-selection/multi-biome flow. The previous crouch/slide controller, 16 enemy variants, 36 weapon patterns, instancing and effect pools remain.

Profile V2 migrates lifetime data/settings and retains a non-overwriting V1 backup. Active-run V2 retains loadout/cooldowns/fog/shop stock. Old active runs may retain grandfathered slot capacity for that run; new profiles/runs follow purchased capacity. See MENU_UPDATE.md for precise rules.

## Unfinished and unverified

- **Jacob, Kurland and the requested icon/audio/enemy/environment packs are not imported.** All supplied itch.io pages returned proxy 403. Their licences/prices/files could not be verified. Existing original Scout/environment/audio and original temporary icon glyphs are used. A separately verified GGBotNet CC0 font temporarily supplies headings. See ASSET_ACCESS.md; apply the saved network settings to unblock the next integration pass.
- Native Windows execution, target-GPU Forward+ rendering, human movement/balance playtesting and 60 FPS on target hardware remain unverified.
- Further art/animation polish, richer navigation/separation and boss choreography remain from the previous milestone. Enemy animation is simplified instanced body/limb poses.
- Exact Megabonk formulas/items/progression are not claimed. Current quest targets, trait values, economy, map scale and timing are original configurable choices.
- Transient projectiles/fields restart on active-run resume. Manually edited corrupt active-run JSON is not a supported import format. V1 profile backup supports rollback to older executables.

Validation/publication evidence is in VALIDATION.md and releases/BUILD_INFO.md. Remaining asset work is tracked in TODO_MENU.md.
