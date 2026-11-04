# Megaclonk — Fusion weapon effects (two gems, Imbued Amulet)

Built and recorded in Godot 4.7.2. Sits on top of the weapon effect pack and the gem
element layer you already have.

## Install
Copy `vfx/` and `preview/` into the project root (merge with the existing folders).
`element_layer.gd` and `preview/preview.gd` are included because the Fusion scripts extend them; they are unchanged from the gem pack.

## The six Fusions (gem order does not matter)
| Fusion | Gems | Combo it fuses | Signature |
|---|---|---|---|
| Steamforged | Fire + Ice | Thermal Shock | ice shell snaps shut, then cracks into a steam cloud with embers |
| Plasma | Fire + Electricity | Overcharge | white-hot core, violet corona, crackle line that detonates |
| Aurora | Ice + Electricity | Cryoshock | hanging crystals that zap each other into a net |
| Livewire | Corrosive + Electricity | Toxic Conduction | dripping green lightning, fizzing puddle, tethers between enemies |
| Pyrebile | Corrosive + Fire | Caustic Combustion | sticky burning globs, black smoke, puddle that ignites |
| Rimerot | Corrosive + Ice | Blightfrost | black ice spikes grow from the ground, frost-rot spreads |

## Using it in weapon code
```gdscript
const FusionLayer := preload("res://vfx/weapons/scripts/fusion_layer.gd")
var fx := FusionLayer.new()
add_child(fx)
fx.setup_fusion(weapon.gems[0], weapon.gems[1])   # e.g. "fire", "ice"
fx.display_name("Bow")                            # "Steamforged Bow"
fx.tint(effect_instance)     # two-tone recolour of the weapon's own effect
fx.trail(projectile)         # fused trail on anything that travels
fx.impact(hit_position)      # the Fusion's signature hit
fx.status(enemy_mesh)        # fused status look on the enemy
fx.motes(player)             # two gem motes orbiting the player while it's held
```
Building blocks the fused attack forms use (any Fusion can call them):
`tether(a, b, time)`, `plasma_line(a, b, fuse, size)`, `crystals(pos, n, time)`,
`spikes(ground_pos, n, radius)`, `steam(pos, scale)`.

## Fused attack forms
`preview/fusion_preview.gd` contains one reference implementation per weapon — copy the
relevant function into the weapon script:

| Weapon | Form | Function |
|---|---|---|
| Lightning Staff | storm cloud above the player strikes on its own; pack gets tethered | `_lightning` |
| Bow | arrow splits into three fused shards on its first pierce | `_bow` |
| Revolver | every 6th shot is a judgement round + detonating line | `_revolver` |
| Aura | twin counter-rotating rings; every 3rd pulse erupts | `_aura` |
| Scythes | rot vortex + black ice where the blade turns back | `_scythes` / `_vortex` |
| Shotgun | burning wall across the cone | `_shotgun` / `_wall` |
| Sword | every 3rd slash throws a crescent wave | `_sword` / `_crescent` |
| Firestaff | comet that splits into a meteor shower | `_firestaff` |
| Forging moment | darken, gems orbit + collide, shatter, re-form, name card | `_forge` / `_name_card` |

Run any combination:
```
godot --path . res://preview/fusion_preview.tscn -- weapon=bow gems=fire,ice
godot --path . res://preview/fusion_preview.tscn -- mode=forge weapon=bow gems=fire,ice
godot --path . res://preview/fusion_preview.tscn -- mode=impacts
```

## Notes
- Smoke uses a 16×16 ordered-dithered puff generated in code (no texture files).
- Every impact is a few one-shot emitters and at most ~10 meshes that free themselves. Route
  Fusion impacts through the 24/s combo budget and fall back to `status()` only above it.
- The name card uses DejaVu as a stand-in; swap in IM Fell English / Overpass from `ui/fonts`.
- The forging moment shows the darkening with the environment; in game, pause hostile time
  (not `Engine.time_scale`) for the ~3 s, and play the bell sting.
- Clips were recorded with the Compatibility renderer; glow will be a little stronger in Forward+.
