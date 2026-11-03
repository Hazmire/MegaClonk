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
- **Fence:** inset 1 m from the perimeter wall. Posts every `gap` m snapped to the terrain height; wires, rails and panels join only posts at the same height (step under 0.2 m). Per-stage `fence` block in `StageDressing` and the JSON (wood and barbed wire; steel and chain-link; sawhorse barricade; leaning timbers with red rope and a candle every third post). MultiMesh, no collision, no shadows: posts and wires (2 draw calls) plus panels on stage 2 and candles on stage 4 (3 draw calls).
- **Backdrop shader:** silhouettes are floored just above black. Stage 4's backdrop art contains true black, which the horizon band showed as a dark strip.

### Draw calls (software GL, 500 enemies)
| Stage | Before | After |
|---|---|---|
| 1 | 562 | 565 |
| 2 | 668 | 672 |
| 3 | 650 | 653 |
| 4 | 613 | 617 |

Fence plus the outer ground add 3 to 4 draw calls per stage (2-3 fence, 1 outer ground). Frame times are within noise.

### Black-band check
Capture shot D (`stage{1-4}_D_lowest.png`) stands on the lowest terrain cell nearest the north edge at eye height, looking out. `tools/stage_capture.gd` samples rows 50-60% of the frame and fails if any row has more than 0.5% pure-black pixels. Result: stages 1-3 have 0 black pixels, stage 4 has 2 (worst row 0.2%). Shots A and C were re-shot.

### Tests (`tests/stage_dressing.gd`, 108 checks)
Outer ground has no collision, is flat, sits below the lowest terrain and has a clear hole; rings end 0.5 m under it; every post stands on the terrain; wires join equal heights only; fence has no collision; collision and spawns are unchanged for a fixed seed. Headless renderers do not keep MultiMesh buffers, so fence nodes carry their transforms as `transforms` metadata for the tests to read.


## Fog sea and backdrop layers

Visual only. Terrain, collision, the perimeter wall and fence, movement, spawning and determinism are unchanged (tests cover this for a fixed seed). No lightning or flash effects were added.

### Fog sea
- Two flat render-only layers outside the arena (`StageDressing.fog_sea_mesh`, `shaders/stage_fogsea.gdshader`). **The pack's fogsea shader was never supplied, so I wrote it from the spec** (unshaded, dithered cut-out, only outside `arena_half`, fades in over `edge_soft`, slow drift, 6 steps, solid at grazing angles). Swap yours in if you have it.
- The mesh is a square ring with its hole exactly at the arena edge, so it cannot draw inside the arena even if a uniform is wrong. The test asserts every face lies outside the arena square.
- Low: 0.6 m below the lowest terrain, density 1.0, edge softness 6 m x 2. High: 2.5 m above it, density 0.55, edge softness 26 m x 2. Size 560 m x `arena_scale`. Y offsets are not scaled. Colours: stage fog lightened 6% and darkened 18%. Data is in the JSON `fog_sea` block and the rules resource.
- Height fog: `fog_height` = lowest terrain level, `fog_height_density` 0.35. It did not fog up the low ground in the captures, so no 1 m lowering was needed.
- Not changed: veils, torn-edge skirt, outer ground, fence. I did not lower the veil density; the captures still read well.

### Backdrop layers
- 12 strips (2048x512) and the pack's ring shader replace the old ones. Nearest filter, no mipmaps. Ground lines from `strips.json` are baked into each dressing by `tools/build_stage_dressings.gd`.
- Ring height = circumference x strip_h / (2 x strip_w) (was circumference / 16). The strip's ground line is placed exactly at `ground_y`. `fog_floor`, `fog_band`, `haze` and the stage fog colour go to the shader. Still 3 unshaded, shadow-free, collision-free draw calls. Player camera far plane set to 1500 m.
- **Judgement call (you approved it):** radii scale by `arena_scale` (x2); `ground_y`, `fog_floor` and `fog_band` scale by (the layout's real top plateau / 12) = x3 at the default 36 m. A raised `maximum_elevation` (up to 48 m) scales them further. Scaling by `arena_scale` only would put the near ground line (30 m) below the 36 m plateau.

| Layer | radius | ground_y | fog_floor | fog_band | ring height | ring bottom (stages 1-4) |
|---|---|---|---|---|---|---|
| near | 180 | 45 | 12 | 33 | 141.4 | -13.8 to -11.9 |
| mid | 300 | 90 | 39 | 51 | 235.6 | -28.7 to -13.1 |
| far | 480 | 156 | 78 | 78 | 377.0 | -98.8 to -56.1 |

Outer ground is at -8 m, so every ring bottom is below it. Elevation angle to the ground lines from the top plateau at the north edge (eye 41.5 m) is 2.3 / 13.2 / 16.5 degrees (near, mid, far), increasing outward; looking south 0.7 / 7.0 / 11.3.

### Captures
`docs/images/stages/layers/layers_<stage>_<low|edge|plateau>.png` (1920x1080) and `compare_<stage>_<view>.jpg` (ours left, reference right). Shot D (`docs/images/stages/stageN_D_lowest.png`) still passes the black-band check (stage 4 has 2 black pixels). No strip bottom edge, floating building or sky below a ridge is visible in the 12 captures.

### Tests (`tests/stage_dressing.gd`, 124 checks)
Ground line within 0.1 m of `ground_y`, ring height from the texture aspect, every ring bottom below the outer ground, ground lines rise near to far and clear the top plateau, fog sea has no collision or shadows and never lies inside the arena, height fog starts at the lowest level. The full `tools/validate.sh` suite passes.

### Draw calls (software GL, 500 enemies)
| Stage | Before | After |
|---|---|---|
| 1 | 565 | 567 |
| 2 | 672 | 673 |
| 3 | 653 | 655 |
| 4 | 617 | 619 |

+2 as expected (one on stage 2 from culling). Frame times (about 900-1000 ms under llvmpipe) are within noise of each other.

### Outstanding / unverified
- Nothing was seen on a real GPU; captures are software rendering.
- The fog sea shader is my own, not the pack's.
- From the lowest ground the ridges sit high overhead (the near ground line is about 26 degrees up). That follows from scaling heights by 3 against radii by 2; the reference ratio would be gentler but would put the near ridge below the plateau.
- Stage 3 and 4 remain very dark in gameplay views.
- Fog sea and ring foot were judged by eye only; there is no pixel metric for a seam between them.

## Outstanding / unverified
- Nothing was seen on a real GPU, monitor or Windows; captures are software rendering. Frame cost on real hardware is not measured.
- Stages 3 and 4 are very dark in gameplay views (manifest fog and ambient values); the HUD stays legible but this wants a look on a real display.
- Stage 2 on screen still shows the previous stage's banner text in the captures; this is a capture artefact.
- Props are still the existing tree, rock and grass models recoloured per style. Stage-specific props (see the asset list in the chat) would complete the look.
