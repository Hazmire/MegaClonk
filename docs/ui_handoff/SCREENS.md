# Screens

Each section names its mockup in `mockups/`, what it shows, where the data comes from, the states
to support and anything still undecided. All screens share these rules (see `tokens/tokens.json`):

- **Look:** square corners, hard 3px ink text shadows, a dithered background, and the
  `fog_overlay` scanlines and vignette on top of everything.
- **Fonts:** IM Fell English for titles, menu entries and names. Overpass for labels and numbers.
  Special Elite only on paper memo cards.
- **Selection:** a rust-red fill with a small bone square cursor. Unselected entries are ash-grey
  text indented 56px.
- **Rarity** sets border colour and thickness and how much glow there is. Legendary is the only tier
  with the gold shimmer (`legendary_shimmer.gdshader`).
- **Key hints** sit bottom-right in Overpass 600 at 15px with 0.18em letter spacing. The key is in
  bone and the action in ash.

---

## Shared panels — `RunInventory`, `RunStats` (420×870)

These are built once as scenes and reused by Pause, Shop, Level up and Imbue.

**Inventory** has these sections, top to bottom:
- **Weapons:** 4 slots. A filled slot shows the icon and an `LV n` tag; an empty slot has a dashed border.
- **Tomes:** 4 slots, shown as `TOMES · n/4`.
- **Socket gems:** 4 counters coloured by element. An empty counter is outlined grey.
- **Items:** a grid of items, each with a ×n stack count.
- **Trait & ultimate:** the ultimate tile has a red border and a "Q READY" chip when ready.

**Stats** lists five groups: Survival, Combat, Movement, Rewards and Other modifiers.
- Values are dim when neutral (`0`, `+0%`, `×1.00`) and bold bone when changed.
- When an upgrade is being previewed, its row fills rust and shows `old  →  new`.

**Data:** the player's build, inventory and stats scripts, plus the `GemInventory` from the sockets work.

## In-run HUD — `RunHUD`

**Top-left: build**
- **Weapons:** 4 slots at 84px. A weapon in use has a red border, an `LV` tag and its empty
  socket diamonds.
- **Tomes:** 4 slots at 56px.
- **Items:** a strip of 44px tiles. Each has a strip in its rarity colour along the bottom and a
  stack badge.

**Top-centre: timer**
- The time in serif at 68px.
- Below it, the stage name in Overpass small caps between two rust rules.
- An elite warning banner can appear under the timer. It reads "The radio crackles… something
  large approaches." It suits the Pocket Radio relic.

**Top-right**
- KILLS, CHEST COST and GOLD as label-over-number pairs. Only GOLD is in gold colour.
- When gold arrives, a small "+n" ticks in under the GOLD counter (`hudTick`, 2.4 s).

**Bottom-left: combat**
- **Health bar:** 480×30 with a dithered rust fill. It turns `#B3363F` at or below 30% HP, and the
  overlay's `low_hp` pulse switches on.
- **Hint:** "TAB build & stats".
- **Ultimate tile:** 96px with a Q keycap and a "READY" chip. A red glow pulses at 1.6 s while it's ready.
- **Trait tile:** 64px.

**Bottom-right: minimap**
- Drawn as a paper map: memo paper frame, a tape strip, rotated 1.2°.
- Markers:
  - You: a bone arrow.
  - Portal: a rust ring.
  - Chests: gold squares.
  - Shops: bone squares with a green border.
  - Imbue Station: a purple diamond.
  - Enemies: pink 4px specks.
- A legend runs along the bottom.

**Bottom: experience**
- "Level n" in serif, then a blue XP bar split into 10 segments, then "x / y XP".
- A "+n XP" tick appears above the bar end when XP is gained.

**World pop-ups (`PickupPopup`)**
- **Look:**
  - Gold is a coin square plus "+n" in Overpass 800 at 30px.
  - XP is a blue diamond plus "+n" at 22px.
  - Both have a 2px ink outline.
- **Animation:** scale to 115%, settle, hold, then rise 46px and fade, 2.4 s in total.
- **Merging:** pickups of the same kind that arrive quickly update the live pop-up (+4 → +12)
  instead of spawning new ones.

**States:**
- Low HP: overlay `low_hp = 1`.
- Stopwatch active: overlay `stopwatch = 1`, and the world desaturates to about 0.5.
- Elite incoming: the banner shows.

**Removed from the old HUD:** the FPS counter (keep it as a debug toggle) and the duplicate
HP/LV/KILLS text line.

## Pause — `RunPause`

- **Background:** the frozen gameplay frame, blurred 6px, desaturated and darkened to 72%.
- **Side panels:** the Inventory panel on the left and the Stats panel on the right.
- **Header:** "Paused" in serif at 104px, then the stage line, then a strip of four counters:
  Level, Time, Kills and Gold.
- **Menu:**
  - Entries: Resume (Esc), Map (M), Inspect build (Tab), Settings, Save & quit, Restart run.
  - **Abandon run** sits apart under a dashed rule, in red text with a dashed red border, labelled
    "Hold to confirm".
  - When Abandon run is selected, it fills `#5A1418` and reads "Hold Enter · run is lost".
  - Abandoning should need a 1 s hold.
- **Decision:** the old menu said "Save run". The mockup uses "Save & quit"; pick one.

## Level up — `RunLevelUp`

- **Entrance:** a fanfare with screen shake, a ring burst, rays and the "The bell tolls" banner.
  Then three cards are dealt in.
- **Cards:** framed by rarity, each showing the weapon or tome, LV n → n+1, and stat changes with
  their before and after values. A Rare card gets an extra burst.
- **Footer:** Skip (heal 10) and Refresh (n left).
- **Hover:** the Stats panel previews the change.
- **Timings:** in the file's keyframes (`mcSlam`, `mcDeal`, `mcRareBurst` and others).

## Shop — `RunShop`

- **Layout:** the Inventory panel, the shop list, then the Stats panel.
- **Rows:**
  - Each row has a rarity-framed icon, a tier and type label, the name, the effect, and "Owned ×a → ×b".
  - The price is a tilted paper tag.
  - The buy button is rust when affordable. Otherwise it's a dashed "Need n more" in `#E07B83`.
- **Hover:** the Stats panel previews the row's stat change.
- **Data:** the shop inventory (socket gems at 250 g per the sockets report) and the player's gold.

## Shrine — `RunShrine`

- **Purpose:** choose 1 of 3 permanent stat boosts, each rolled at a rarity.
- **Cards:** Legendary and Rare cards use the rarity frames and glows from `Fog-Rarity`.
- **Accept:** the button reads "Accept: <stat> <value>".
- **Preview:** the change shows in the Stats panel.

## Treasure chest — `RunChest` (interactive)

- **Sequence:**
  1. The chest jumps and idles.
  2. "Open chest" (Enter) is pressed and the chest opens with a light beam (650 ms).
  3. A horizontal reel of item cards spins and slows (about 6.1 s), with blur at speed.
  4. A marker lands on the winning card (1 s).
  5. The reveal: a flash, rings, rays, the card flies in, a rarity stamp lands, and "Take it" appears.
- **Reel cards:** one item per card, framed by rarity.
- **Legendary landing:** gets the "A legendary find" line, the "The bells toll" headline, a gold
  flash and the shimmer.
- **Data:**
  - Pick the result *before* the reel starts, using the tier drop weights (50/28/15/5/2%).
  - Then build a reel that slows down and stops on that result.
  - Chests can also contain gems (12%). The Imbued Amulet is now a consumable Legendary item in the normal item pool.

## Imbue Station — `RunImbue` (interactive)

- **Choosing:** pick a weapon, then choose a gem from the tray to socket into it.
- **Socketing:** the gem pops in and the socket fills with the element colour (`mcFill`), with a burst.
- **Costs:** 500, 1000 and 1500 gold per the sockets report. The Imbued Amulet unlocks a second
  socket, which must hold a different element.
- **Gem counts:** owned gems are shown only once, in the tray.

## Main menu — `Fog-Menu`

- **Logo:** "Megaclonk" in IM Fell English SC at 150px.
- **Tagline:** a rust rule, then the tagline. The tagline is still a placeholder.
- **Menu:** Play (selected), Unlocks, Quests, Settings.
- **Silver:** top-right.
- **Within reach:** four quest memos showing either a progress bar or a NOT YET stamp.
- **Background:** a fog-and-ground scene. A character render or the in-game scene sits right of centre.

## Prepare your run — `Fog-Loadout`

- **Slots:** Weapon, Trait and Ultimate.
  - Each is a 104px row with an icon, name, short stats and a dropdown.
  - The weapon dropdown is shown open. It has a filter field, category tags, a ✓ on the picked
    weapon, and a "4 of N unlocked" footer.
- **Destination:** a green US-highway-style sign.
- **Buttons:** "Enter the Hollow" (rust) and Back.
- **Personal bests:** a memo card ranking the top 5 by kills.

## Unlocks — `Fog-Unlocks` (Tomes), `Fog-Unlocks-Weapons`, `Fog-Unlocks-Items`

- **Shared frame:** tabs Weapons / Tomes / Traits / Items / Ultimates, with the active tab
  underlined in rust. Silver and a Home (Esc) button sit top-right.
- **Tile states:**
  - On: a rust "ON" chip.
  - Off: an outlined "OFF" chip and a dimmed icon.
  - Locked: grey, with a padlock and a dashed border.
- **Detail memo card on the right:**
  - The memo card shows the big icon, name and description.
  - The On/Off toggle reads "Appears in runs".
  - Locked entries show "To unlock: …" instead.
- **Weapons tab:** the memo shows a Polaroid with a live preview of the weapon's effect (the Godot
  VFX clips are in the earlier `megaclonk_weapon_vfx.zip`) and the weapon's level-up option chips.
  Shotgun has a NEW badge.
- **Items tab:**
  - A rarity filter row: All 60, Common 19, Uncommon 17, Rare 13, Epic 7, Legendary 4.
  - A 10 × 6 icon grid. Each tile has a 4px strip along the bottom in its rarity colour.
  - The memo card shows the 152px icon, the tier chip, the drop weight and the full effect.
  - Gem relics add "Does nothing until you own the Fire socket gem" (or the matching element).
  - Uniques get a "Unique · once per run" stamp.
- **Decisions:** which entries start locked, plus the unlock conditions and silver costs.

## Reference boards (not screens)

- `Fog-Kit`: menu item, memo and HUD states.
- `Fog-Rarity`: the five rarity frames.
- `Unlock-Items`: the catalogue of all 60 relics.
- `Unlock-Icons`: trait and ultimate icons.
- `W-*`: the weapon VFX boards and their level-up option pools.
