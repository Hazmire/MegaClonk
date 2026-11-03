# Megaclonk — endless-mode ghosts

Built and rendered in Godot 4.7.2 (Compatibility renderer).

## Install
Copy `ghost/` into the project root, so the paths read `res://ghost/...`.

| File | What it is |
|---|---|
| `ghost/ghost_mesh.gd` | Builds the ghost mesh in code (~2k tris, faces −Z: gaunt lolling skull, drooping sockets, over-long jaw, tattered shroud, hooked fingers). Call `build()` once and share it. |
| `ghost/ghost.gdshader` | The ethereal look and all of the animation. |
| `ghost/ghost.gd` + `ghost.tscn` | A ghost node: `tier`, `speed`, `turn_rate`, `target`, `set_fade(0..1)`. It flies straight at the target's chest and banks into turns. |
| `preview/ghosts_preview.gd` | The scene used for the renders: `mode=lineup` or `mode=swarm`. It needs the stage dressing pack and `hero.gd` to run as-is. |

## Tiers and escalation
| Tier | Colour | Suggested start | Notes |
|---|---|---|---|
| mourner | grey-white, see-through except the skull | 10:00 | the base ghost, the most numerous |
| drowned | creek-water green | ~13:00 | more health |
| wrathful | blood red, half-solid | ~16:00 | more damage, faster |
| hollow | near-black, red edge, white eyes, 1.3× size | ~20:00 | the final ghosts |

Escalation should guarantee death: spawn rate, contact damage and flight speed all climb every minute after
10:00 with no ceiling, and flight speed rises past the player's run speed around 20:00. New tiers join the mix
rather than replacing earlier ones. Keep the actual curves in the enemy data.

## How it looks ethereal without being expensive
- **No alpha blending:** the shader uses an ordered 4×4 dither discard (screen-door transparency), so ghosts render in the opaque pass with no sorting problems at 500+ on screen.
- **Rim:** the rim of the shroud is solid; the body centre is see-through (`core`), and the tail fades out.
- **Animation:** the vertex shader animates, stepped at 12 fps with occasional head twitches, the body bob, a ripple running down the tail, grasping fingers and PSX vertex snapping. Each ghost gets its own phase from its world position, so a swarm never moves in step. No per-ghost particles or scripts are needed for animation.
- **Fade:** `set_fade()` is for materialising on spawn (~0.6 s) and dissipating on death or contact (~0.25 s). While fading, a ghost holds a material copy; at 1.0 it returns to the shared tier material.

## Wiring it into the game
- If the game's enemy system already moves enemies, use only the visuals: the shared mesh, the tier material and `set_fade`. Drop the movement in `ghost.gd`.
- Ghosts fly, so skip ground snapping and navigation and give them a sphere hitbox around the head and body (~0.5 m radius).
