# Prompt: Fill the void past the arena edge + boundary fence

Before you paste this:
- Unzip `megaclonk_edge_void_fix.zip` into `docs/stage_dressing/edge_fix/` and commit it.
- Then paste everything below the line into Claude Code.

---

From the lowest terrain, players see a black band below the horizon outside the arena. This happens because the
sky panoramas are near-black below the horizon, `fog_sky_affect` is 0, and nothing fills the space between the
torn edge and the bottom of the backdrop rings.

**This is a visual pass only.** Terrain, collision, the perimeter wall, movement, spawning and determinism must
not change.

Inputs:
- `docs/stage_dressing/edge_fix/skies/`: replacement sky-only panoramas with the same names. Below the horizon
  they are now the stage fog colour.
- `reference/oob.gd`: see its `outer_ground()`, `boundary_fence()` and `shot == "low"`.
- `reference/renders/`: the target look from the lowest ground, before and after.

Respect `docs/stage-dressing-report.md`. In particular, the game arena is 2× the reference, so scale reference
distances by `arena_scale`.

## Step 1: Skies
Replace the four sky-only panoramas in `assets/stage_dressing/` (or wherever the dressing points) with the new
files. Keep the import settings: nearest filter, no mipmaps, panorama `filter = false`.

## Step 2: Outer ground
Add a render-only flat ring mesh around the arena:
- **Inner edge:** a square hole 2 m outside the arena edge (× arena_scale), so it never shows through the
  playable ground.
- **Outer edge:** 1.1 × the far ring radius.
- **Height:** `outer_ground_drop` (4 m × arena_scale) below the **lowest terrain level**, so the torn edge
  still shows a drop.
- **Material:** the dressing's `low` texture, world triplanar, nearest filter, tinted to about 60%, with normal
  scene fog.
- **Cost:** no collision, no shadows, one draw call.

Add `outer_ground_drop` to the rules resource.

## Step 3: Backdrop rings
Lower the mid and near rings' base so their bottom edge sits 0.5 m below the outer ground. Keep the far ring's
base, which is already below it. Ring heights are unchanged.

## Step 4: Boundary fence (visual only)
Place a low fence along the existing perimeter collision wall, inset about 1 m.
- **Posts:** every `gap` metres, each snapped to the terrain height under it, so the fence steps with the
  terraces at every elevation.
- **Rails and wires:** join neighbouring posts only when they're at the same height.
- **Style per stage:** add a `fence` block to `StageDressing` and the JSON.

| Stage | Fence | Post colour | Height | Gap | Extras |
|---|---|---|---|---|---|
| 1 Hollow | wooden posts, 3 barbed wires | #3A2E24 | 1.3 m | 3 m | – |
| 2 Route 9 | steel posts, chain-link panels (cut-out texture), 2 rails | #5A5A56 | 2.0 m | 3 m | – |
| 3 Downtown | sawhorse barricade line, red/white boards | #6A5A48 / #C8401F | 1.1 m | 2.6 m | – |
| 4 Sinkhole | leaning mine timbers, red rope | #2A2018 / #8A1E1A | 1.5 m | 3.4 m | a candle at every third post |

- **No collision.** The perimeter wall already blocks the player. The fence only shows where it is.
- **Batching:** use MultiMesh or merged meshes, so all fence parts together cost a few draw calls. Report the
  count.
- **Readability:** keep it low enough not to block the view of the backdrop from the low ground.

## Step 5: Checks
- **New capture.** Add `stage{1-4}_D_lowest.png` from the lowest terrain cell nearest the north edge, eye height,
  looking out. Find the spot the way the reference's `shot == "low"` does.
  - No pure-black pixels may appear in the band below the horizon in any stage. Test this by sampling the frame.
  - Also re-shoot shots A and C.
- **Tests:**
  - the outer ground has no collision and sits below the lowest terrain;
  - the fence has no collision, and every post stands on the terrain under it;
  - collision and spawn points are unchanged for a fixed seed.
- **Report.** Draw calls before and after, then update `docs/stage-dressing-report.md`.

Commit on `feature/stage-dressing` (or a follow-up branch) in small steps.
