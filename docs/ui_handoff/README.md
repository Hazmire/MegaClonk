# Megaclonk — Fog County UI handoff

Everything Claude Code (or you) needs to rebuild the Fog County UI in the Godot 4.7.2 project.
The design source is the Claude Design canvas; this pack is a frozen copy of it.

## What's here

| Folder | What it is |
|---|---|
| `SCREENS.md` | One section per screen: what it shows, where the data comes from, states, open decisions. **Start here.** |
| `mockups/` | The canvas boards as HTML (`*.dc.html`). Open them in a text editor — the exact colours, sizes, spacing and animation timings are in the inline styles. Image paths point at this pack's `icons_4x/`. |
| `icons/` | Every icon at native pixel size: 32×32 for weapons, tomes, items, traits and ultimates; 64×64 for the chest. **Use these in-game.** |
| `icons_4x/` | The same art at 4× for previews, docs and store pages. |
| `data/items.json` | All 60 relics: id, name, tier, short and full effect, required gem, Unique flag, icon path. |
| `tokens/tokens.json` | Colours, rarity tiers, elements, fonts, type scale and effect rules. |
| `godot/ui/` | Starter GDScript + shaders, compiled and rendered in Godot 4.7.2 (Compatibility renderer): `FogPalette`, `FogTheme`, `PickupPopup`, and `fog_overlay`, `dither_fill` and `legendary_shimmer` shaders. |
| `reference/` | The cleaned gameplay screenshot used behind the HUD and pause mockups, plus the stand-in sprites from the weapon boards. |

## Fonts (download once)

All four are free under the SIL Open Font Licence. They weren't downloadable from this sandbox,
so grab them from Google Fonts and drop the `.ttf` files into `res://ui/fonts/`:

- IM Fell English — https://fonts.google.com/specimen/IM+Fell+English
- IM Fell English SC — https://fonts.google.com/specimen/IM+Fell+English+SC
- Overpass (variable) — https://fonts.google.com/specimen/Overpass
- Special Elite — https://fonts.google.com/specimen/Special+Elite

`FogTheme` looks for these names (it tries each and falls back to Godot's default font):
`IMFellEnglish-Regular.ttf`, `IMFellEnglishSC-Regular.ttf`, `Overpass-VariableFont_wght.ttf`, `SpecialElite-Regular.ttf`.
Turn **off** antialiasing-heavy hinting if the text looks too smooth next to the pixel art.

## Importing icons

Select the icon folders in the FileSystem dock → Import tab → set **Filter: Nearest** (or set
*Rendering → Textures → Default Texture Filter* to Nearest project-wide), **Mipmaps off**, then
Reimport. Always scale icons by whole numbers (2×, 3×, 4×) so pixels stay square.

## Suggested order (one Claude Code session or branch each)

1. **Foundation** — copy `godot/ui/` to `res://ui/`, add the fonts, set the theme on the root
   UI node, add a `fog_overlay` ColorRect on top. Check one screen renders before going on.
2. **In-run HUD** (`RunHUD`) — biggest player-facing win.
3. **Pause** (`RunPause`) + the shared **Inventory** and **Stats** panels — these panels are
   reused by Pause, Shop, Level up and Imbue, so build them once as scenes.
4. **Level up**, **Shop**, **Shrine**, **Treasure chest**, **Imbue Station**.
5. **Main menu**, **Prepare your run**, **Unlocks** (Tomes, Weapons, Items).

## Prompt to give Claude Code for each step

> We're rebuilding Megaclonk's UI to the Fog County design. The handoff pack is in
> `docs/ui_handoff/`. Read `README.md` and the `<Screen>` section of `SCREENS.md`, then read
> `mockups/<Board>.dc.html` for exact values. Use `FogPalette`/`FogTheme` from `res://ui/`
> instead of hard-coded colours. Build `<Screen>` as its own scene, wire it to the existing
> game state (list the scripts it reads), keep gameplay logic unchanged, and run the existing
> validate script. Then give me the steps to see it in-game so I can send you a screenshot.

**Always look at the result yourself and send a screenshot back.** Claude can build and test
headlessly but can't judge text fit, font rendering or overlap without seeing a frame.

## Notes and limits

- The mockups are 1920×1080. Build at that reference size with anchors/containers and let Godot's
  `canvas_items` stretch mode scale it; don't hard-code pixel positions from the HTML.
- HTML-only tricks to translate: CSS `text-shadow` → Label shadow constants or outline;
  `box-shadow` glows → a soft-edged NinePatch or shader; `transform: rotate()` on memo cards → the
  Control's `rotation`; CSS keyframes → Tweens or AnimationPlayer (timings are in each file's `<style>`).
- Placeholders still to decide: unlock conditions and silver costs, which items start locked,
  tome effect text, the menu tagline, weapon stats shown as `[STATS]`.
- The 60 relics in `data/items.json` are a **design list**. Showing them in the UI is UI work;
  making each effect work in gameplay is a separate, larger job.
