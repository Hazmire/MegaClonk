# Megaclonk: layered backdrops (Calvary Run)

Replaces the backdrop strips and `backdrop.gdshader` from the stage-dressing pack.

- `strips/`: 12 strips (s1–s4 × near/mid/far). Each is 2048×512 RGBA with hard alpha. Every strip has 200 px of solid hillside under its ground line. `strips.json` gives each strip's measured ground line in px from the bottom.
- `shaders/backdrop.gdshader`: the ring shader. It mirrors the strip once per lap. It also has new `fog_floor`/`fog_band` uniforms that dissolve the lower part of each ring into the stage fog colour, based on world height.
- `layers.json`: radius, ground-line height, haze and fog bank for each layer, at reference scale.
- `reference/oob.gd`: the Godot 4.7 reference scene. See `backdrop_ring()`, `LAYERS` and the `plateau` shot. `backdrop_gen.py` is the strip generator.
- `reference/renders/`: target shots for every stage from the lowest ground, the edge and the top plateau, plus a strafe clip each.

The lightning reveals are not part of this pack and must not be added.
