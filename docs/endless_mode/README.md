# Megaclonk: endless mode

At 10:00 the run timer becomes the endless timer, the ghosts take over, and every run ends in death.

| Folder | What it is |
|---|---|
| `mockup/RunEndlessTimer.html` | The timer design, standalone. Open it in a browser: the loop shows 09:57 → 10:00 → glitch → red 00:00, and the four tier cards are animated. `RunEndlessTimer.dc.html` is the design-canvas source. |
| `godot/ui/endless/endless_timer.gd` | `EndlessTimer`, a starter Control tested in Godot 4.7.2 (Compatibility renderer). It is one node for the whole run: `set_run_time(sec)`, `start_endless()` once at 10:00, `set_endless_time(sec)`. It handles the glitch, the tier escalation, the smoulder flicker, the twitch, and embers and smoke drawn behind the text. It has a `reduce_motion` flag. |
| `godot/ui/endless/endless_timer_style.json` | Every colour, timing, tier threshold and particle cap. The source of truth for the look. |
| `godot/endless_timer_preview.gd` | Renders each state to PNG. Run it with `godot --path . --script res://endless_timer_preview.gd -- state=t3 out=res://x.png`. It needs a `bg.jpg`. |
| `ghosts/` | The ghost mesh, shader and node, with renders. The same as the earlier ghost pack. |
| `reference/` | `mockup_board.png` (the design) and `godot_states.png` (the starter's output, with fallback fonts). |

The starter loads `res://ui/fonts/IMFellEnglish-Regular.ttf` and `Overpass-VariableFont_wght.ttf` if they exist, and falls back to system fonts otherwise. Point it at the game's real font paths and `FogTheme`.

Sound: the game needs `endless_begins_banshee` (supplied separately) for the switch.
