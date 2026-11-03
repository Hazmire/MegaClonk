# Stage dressing report (Calvary Run)

Branch: `feature/stage-dressing`. Visual pass only. Terrain generator, collision, movement, spawning, navigation, balance and seeded determinism are unchanged (checked by tests). Full `tools/validate.sh` passes. New suite `tests/stage_dressing.gd`: 75 checks.

## What changed per stage
Mapping: stage 1 Calvary Run Hollow, 2 Route 9 & the Tipple, 3 Downtown Calvary Run, 4 The No. 9 Sinkhole. Endless stages cycle 2 -> 3 -> 4 (5 = Route 9, 6 = Downtown, 7 = Sinkhole, 8 = Route 9 ...).

| Stage | Weather | Footsteps | Fog | Ground (top / side / low) |
|---|---|---|---|---|
| 1 Hollow | rain | grass | #9AA093, 0.005 | grass / soil wall / brown creek |
| 2 Route 9 | dust | dirt | #A8713C, 0.005 | dead grass / clay wall / coal slag |
| 3 Downtown | ash | dirt | #6A2014, 0.0055 | scorched / charred wall + emission / wet street |
| 4 Sinkhole | blood rain | dirt | #1E1414, 0.006 | mud / coal rock / brown creek |

All values come from `docs/stage_dressing/stage_dressing.json` via `tools/build_stage_dressings.gd`, which generates `assets/stage_dressing/stage_{1-4}.tres` and `rules.tres`.

- **Ground:** `shaders/stage_ground.gdshader`, world-space triplanar, nearest filtering. Flat cells use top, cells at the lowest terrain level use low, vertical faces use side. Mesh and collision are untouched.
- **Sky, light, fog:** panorama sky (filter off, rotated 180 degrees), ambient, sun, fog with `fog_sky_affect = 0`, linear tonemap.
- **PSX fog removed:** per-vertex PSX fog code, its globals and project settings are gone; the world Environment fog is the only fog.
- **Border:** the old rock cliff props are removed. Two veil layers on each side (8 quads), plus a render-only torn-edge skirt. Collision is the existing perimeter wall, so no new wall was needed.
- **Rings:** three open cylinders built in code, unshaded, no shadows, no collision, centred on the arena.
- **Weather:** one GPU particle system per stage riding on the player, hard-capped (3000 rain / 900 dust and ash), halved in reduced mode, with a new Weather toggle in Settings > Graphics.
- **Footsteps:** now read from the dressing.
- **Props:** follow the dressing (Hollow living, Route 9 withering, Downtown and Sinkhole dead). The stage name in the HUD, banner, pause and map comes from the dressing.

## Judgement calls
- **Ring scale:** the reference arena is 96 m across, the game's is 192 m. Ring radii and base heights are scaled by 2 (`arena_scale` in the rules): 480 / 300 / 180 m, so the near ring clears the arena corners (136 m). Haze values are unchanged.
- **Veil offsets:** 9 m and 15 m beyond the real edge (96 m).
- **Grass colour:** grass blades take the top texture's average colour.
- **Fixed on the way:** `combos_amulet` was flaky from random critical hits; it now pins crit to 0.

## Tests
- 75 checks: each stage applies its look; terrain mesh, collision mesh and planes identical across dressings for a fixed seed; the live collision shape equals the generator's; spawn points do not depend on dressing history; applying a dressing draws no RNG; the player cannot leave the arena from the highest plateau even launched at 90 m/s; rings are unshaded, shadow-free, collision-free and centred; textures import without mipmaps and use nearest filtering; endless stages cycle.
- Updated stale tests: `stage_themes`, `art_reset_world`, `polish`, `visual_corrections`, `ingame_ui_regression`, `combos_amulet`.

## Screenshots
`docs/images/stages/`: `stage{1-4}_{A_edge,B_gameplay,C_plateau}.png` at 1920x1080, `contact_sheet.png`, and `compare_{1-4}.png` (ours left, reference right). Captured with `tools/stage_capture.gd`.

## Performance
500 enemies, 1280x720, software GL under xvfb (`tools/stage_perf.gd`). Absolute milliseconds are meaningless here (about 1000 ms per frame), so only draw calls are reliable.

| Stage | Draw calls before | After |
|---|---|---|
| 1 | 562 | 562 |
| 2 | 671 | 667 |
| 3 | 653 | 650 |
| 4 | 655 | 613 |

The three rings add 3 draw calls and the fog wall and torn edge add about 9 more, offset by removing the cliff prop batches. Frame times were within noise of each other on software GL.

## Edge void fix

Visual only. Terrain, collision, the perimeter wall, movement, spawning and determinism are unchanged (tests compare digests for a fixed seed).

- **Skies:** the four panoramas are replaced (below the horizon they are the stage fog colour). Imports are still nearest, no mipmaps, panorama `filter=false`.
- **Outer ground:** one flat render-only ring, square hole 2 m x `arena_scale` outside the arena edge, outer edge 1.1x the far ring radius, `outer_ground_drop` (4 m x `arena_scale`, new rules field) below the lowest terrain. The dressing's `low` texture, world triplanar, nearest, 60% tint, normal fog. No collision, no shadows.
- **Rings:** mid and near rings are anchored to the outer ground, so their bottom edge sits 0.5 m below it. The far ring keeps its base.
- **Fence:** inset 1 m from the perimeter wall. Posts every `gap` m snapped to the terrain height; wires, rails and panels join only posts at the same height (step under 0.2 m). Per-stage `fence` block in `StageDressing` and the JSON (wood and barbed wire; steel and chain-link; sawhorse barricade; leaning timbers with red rope and a candle every third post). MultiMesh, no collision, no shadows: 3 draw calls on stages 1 and 3, 4 on stages 2 and 4 (wires, posts, plus panels or candles; stage 1 and 3 have posts and wires only, the counts the tests assert are 2 + panels + candles).
- **Backdrop shader:** silhouettes are floored just above black. Stage 4's backdrop art contains true black, which the horizon band showed as a dark strip.

### Draw calls (software GL, 500 enemies)
| Stage | Before | After |
|---|---|---|
| 1 | 562 | 565 |
| 2 | 668 | 672 |
| 3 | 650 | 653 |
| 4 | 613 | 617 |

Fence plus the outer ground add 3 to 4 draw calls per stage. Frame times are within noise.

### Black-band check
Capture shot D (`stage{1-4}_D_lowest.png`) stands on the lowest terrain cell nearest the north edge at eye height, looking out. `tools/stage_capture.gd` samples rows 50-60% of the frame and fails if any row has more than 0.5% pure-black pixels. Result: stages 1-3 have 0 black pixels, stage 4 has 2 (worst row 0.2%). Shots A and C were re-shot.

### Tests (`tests/stage_dressing.gd`, 108 checks)
Outer ground has no collision, is flat, sits below the lowest terrain and has a clear hole; rings end 0.5 m under it; every post stands on the terrain; wires join equal heights only; fence has no collision; collision and spawns are unchanged for a fixed seed. Headless renderers do not keep MultiMesh buffers, so fence nodes carry their transforms as `transforms` metadata for the tests to read.


## Outstanding / unverified
- Nothing was seen on a real GPU, monitor or Windows; captures are software rendering. Frame cost on real hardware is not measured.
- Stages 3 and 4 are very dark in gameplay views (manifest fog and ambient values); the HUD stays legible but this wants a look on a real display.
- Stage 2 on screen still shows the previous stage's banner text in the captures; this is a capture artefact.
- Props are still the existing tree, rock and grass models recoloured per style. Stage-specific props (see the asset list in the chat) would complete the look.
