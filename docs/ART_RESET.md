# Art reset 10: implementation and playtest evidence

This update builds on the existing v9 gameplay and imports supplied archives from Full-Release df625e2. Godot remains 4.7.2. The concrete inventory and asset-to-system mapping are in [ART_RESET_ASSET_AUDIT.md](ART_RESET_ASSET_AUDIT.md); attribution is in ASSET_CREDITS.md.

## Ten active weapons

| Weapon | Existing ID | Identity |
| --- | --- | --- |
| Sword | 0 | Close-range sweeping attacks |
| Firestaff | 1 | Fire projectiles and impact flame |
| Lightning Staff | 2 | Chained electrical hits |
| Bow | 6 | Long-range piercing arrows |
| Revolver | 7 | Direct bullets, muzzle flashes and original shot audio |
| Scythes | 9 | Spinning blades that return to the player (temporary placeholder mesh) |
| Aura | 10 | Pulsing dark-green occult circle |
| Shotgun | 15 | Single blast of independent pellets |

These are existing MEGACLONK equivalents, not a claim of verified original Megabonk naming or balance. The public weapons reference was unavailable (HTTP503). Weapon Overhaul 2.0 removed Chunkers, Mines, Bone and the other retired weapons entirely: old saves drop them (socketed gems are refunded) and they never enter loadouts, unlock browsers, sandbox selection or upgrade pools. See WEAPON_OVERHAUL_REPORT.md. Chests and shops remain item rewards.

First-time weapon/tome level-up rewards are Common in generated metadata, stored ownership state and card/HUD presentation. Existing-item upgrades retain the established supported registry tier. Weapon and tome ownership rarity is saved. Legacy saves without rarity fields keep compatible derived display defaults. Item/shrine rarity probabilities are unchanged.

Traits retain mechanics and icons with neutral framing. Ultimates retain their separate gold presentation.

## World and atmosphere

Both supplied portal meshes and all three texture maps are used. Imported PSX trees, trunks and rocks share the existing procedural forest; source transforms, UVs and alpha-bearing textures are preserved. Seeded overlapping large rocks replace visible outer walls; original watertight simplified terrain collision remains. Internal terrace cliffs and ramps remain procedural. Rocky boundaries do not obstruct the validated required routes.

Only **two** source panoramas were supplied: day and night. Three cached sky resources use day/natural, night/violet and night/crimson treatments. This is explicitly a derived third treatment, not a newly discovered third texture.

Wind has three independent layers: player-relative subtle GPU ambience; red instanced wisps following a portal-specific terrain flow field; and an inward spiral attached to the actual portal. The shared field targets the current procedural portal, respects existing ramp/obstacle connectivity, and does not overwrite enemy navigation. No straight-line fallback through cliffs is used. Density, brightness and speed vary smoothly with proximity; activation surges and completion fades preserve ambient wind. Settings: assets/config/wind.tres. Simulation runs at 30Hz with 64 guidance and 96 vortex instances; materials are shared. The effect is visual and applies no movement force.

Exploding bugs anticipate, detonate once, apply damage/launch, then enter ordinary death/reward cleanup once. Launch combines momentum with configurable horizontal18/up13 impulses, bounded horizontal24/vertical18 speed. CharacterBody physics retains collision and normal movement recovery. Ghost immunity is preserved.

Native supplied StatusFX shatter and aura components supplement existing PSX/Electric effects. Eight prewarmed effects, two per type, bound added particle cost. Exhaustion skips decorative emissions while preserving damage and boss abilities. Existing attack telegraphs and timing remain. Original mine geometry replaces its plain field marker.

## Validation

The complete 25-suite regression run passed **911 named checks**, plus 200-layout/decorated/physical/placement audits, 104,353 collision rays, 400 enemy traversal probes and 1,000 interaction checks. Dedicated art-reset gameplay tests passed 27 checks, including 1,000 acquisition rolls, archived saves, distinct icons, no trait gold shaders, exactly-once explosion cleanup, bounded repeated impulses, actual airborne CharacterBody movement and a safe landing with controls retained.

Portal tests passed 77 checks over 20 procedural positions: 7 above, 10 below, 5 near boundaries, 19 with a direct path crossing a cliff. Tests also cover valleys/high plateaus, portal relocation, actual particle travel down route costs, proximity, activation, fade and ambient independence. Raw cases: releases/ART_RESET_GUIDANCE.json. Export additionally gates compiled resources through existing UI/stage/v9 smokes and an art-reset smoke. Source tests alone are not treated as export proof.

Actual software-rendered captures are under docs/images/art-reset: three stage environments, outer rocky boundaries, distinct weapon icons, Common offers, far/medium/close guidance, portal vortex, explosion launch and combat effects. The guidance GIF samples deterministic simulation at fixed intervals; it is not an FPS benchmark. These captures establish rendered content, not native Windows execution or human navigation success.

Performance measurements and limitations are in ART_RESET_PERFORMANCE.md. Native Windows execution, gaming-GPU rendering, speaker audio, physical controller input and human no-minimap wayfinding remain local playtest gates. The existing high-density horde CPU limit is not declared solved. The rectangular underlying arena and preserved internal terrace cliffs can still be recognized from some elevated viewpoints despite irregular visible outer rocks.

## Rendered gallery

| Evidence | Capture |
| --- | --- |
| Green forest / supplied day panorama | [Stage1](images/art-reset/stage_1.png) |
| Violet forest / night treatment | [Stage2](images/art-reset/stage_2.png) |
| Crimson forest / night treatment | [Stage3](images/art-reset/stage_3.png) |
| Rocky outer boundary | [Cliffs](images/art-reset/rocky_boundary.png) |
| Ten distinct weapon icons | [Collection](images/art-reset/weapon_icons.png) |
| Actual Common acquisition cards | [Offers](images/art-reset/common_acquisitions.png) |
| Far / medium / close red guidance | [Far](images/art-reset/guidance_far.png), [medium](images/art-reset/guidance_medium.png), [close](images/art-reset/guidance_close.png) |
| Inward portal swirl / activation | [Portal](images/art-reset/portal_vortex.png) |
| Directional wind in motion | [Fixed-step recording](images/art-reset/guidance_motion.gif) |
| Airborne explosion launch | [Launch](images/art-reset/explosion_launch.png) |
| Imported combat particles | [Combat](images/art-reset/combat_effects.png) |
