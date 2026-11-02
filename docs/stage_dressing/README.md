# Megaclonk — stage dressing pack (Calvary Run)

Everything needed to re-dress the four stages. The terrain generator does not change: every stage keeps
the same farmland arena. Only the textures, fog, light, sky, fog wall, weather and the out-of-bounds
backdrop rings change.

- `stage_dressing.json`: one entry per stage, with every value used in the reference renders.
- `textures/`: 128 px seamless ground textures (PSX, nearest filter). They cover the top, side, low ground and torn edge, plus a stage 3 emission mask.
- `skies/`: the sky-only panoramas, 2048×1024 (use these) and 1024×512. They are equirectangular, filter off, sky rotated 180°.
- `backdrops/`: 12 strips, `s{1-4}_{far,mid,near}.png`, 2048×256 RGBA with a hard alpha cut-out.
- `shaders/backdrop.gdshader`: the ring shader (mirrored lap, own haze, lights punch through, fog disabled).
- `shaders/veil.gdshader`: the fog wall shader from the map-edge design.
- `reference/oob.gd`: a standalone Godot 4.7 scene script that renders exactly what's on the canvas board. Its
  `backdrop_ring()` builds the ring mesh with correct UVs. Godot's CylinderMesh maps only part of the texture to its side,
  so don't use it.
- `reference/renders/`: the four target shots and the parallax clip.
