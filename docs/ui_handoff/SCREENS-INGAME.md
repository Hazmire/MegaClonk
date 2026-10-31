# In-run screens — addendum (30 Oct 2026)

This pack replaces the in-run mockups in `docs/ui_handoff/mockups/` with their latest versions and
adds two new boards. Read it together with the in-run sections of `SCREENS.md`.

**Rule: where `SCREENS.md` and the economy rework disagree, the economy rework wins.** The specific
conflicts are listed at the end.

## New: gem pickup notification — `RunGemPickup` (interactive)

A socket gem pickup plays a 4-beat sequence, about 4 s in total. It must never block input or pause
the game.

1. **Burst (0.5 s)**
   - The gem pops up out of the ground where it dropped: it scales to 125% and settles, with a
     drop shadow glowing in the element colour.
   - Two expanding rings (0.6 s and 0.7 s) and 10 pixel sparks fly out in the element's light and
     mid colours.
   - The screen edges glow in the element colour for 1.1 s, so the player notices it mid-fight.
2. **Fly (0.42 s):** the gem flies to the toast's socket, growing to 160% on the way.
3. **Toast (2.6 s)**
   - **Layout:** a 660×136 card centred under the timer, near the top of the screen.
     - It has a 4px strip in the element colour along the top and a glow in the element colour.
     - It opens horizontally with a bounce, then a shine sweeps across it.
   - **Socket:** the gem sits in a 92px socket that pulses with glow, and spins slowly (on the X axis).
   - **Text:**
     - "SOCKET GEM FOUND" in small caps;
     - then "OWNED ×n", or a gold "NEW ELEMENT" stamp for the first gem of that element this run;
     - then the gem's name in serif at 38px;
     - then a one-line description of the element;
     - then the hint "Socket it at an Imbue Station · Tab view build".
4. **Collect (0.45 s)**
   - The toast shrinks and fades.
   - A gem flies into the new **Socket gems** row on the HUD. That slot bumps up to 135% and shows a
     "+1", and its count goes up.

**Rules for the game:**
- **Queueing:** if several gems drop close together, queue the toasts. Show each for at least 1.2 s,
  and merge pickups of the same element into one toast that reads "×2".
- **Descriptions:** take the description line from the element data, not from the mockup. Only the
  Corrosive line in the mockup uses the real numbers.
- **Imbued Amulet:** an Amulet pickup uses the same sequence with the Legendary gold palette and the
  Amulet's icon, and it lands in an Amulet counter beside the gem row.

**New HUD element:** a "SOCKET GEMS" row sits under ITEMS on the HUD (top-left).
- It shows four 44px slots: Corrosive, Ice, Fire, Electricity.
- Each slot has a pixel gem and a count badge. Empty slots are dimmed to 28%.
- Add the Imbued Amulet count here as a fifth slot. The economy report noted the HUD doesn't show it
  yet.

## New: boss health bars — `RunBossBars` (interactive)

**Stage bosses**
- **Size:** 920px wide, centred under the timer, and stacked when there's more than one.
- **Header:**
  - A pixel skull, then the name in IM Fell English SC at 34px.
  - An optional italic epithet. Add an epithet field to the boss data, or leave it empty.
  - A rust "STAGE BOSS" tag, then "hp / max" on the right.
- **Bar:**
  - A 24px dithered rust bar between riveted iron end caps, split into 10 segments.
  - Phase notches at ⅔ and ⅓. Show them only if the boss actually has phases.
- **Status row:** under the bar, showing the boss's active statuses in their gem colours.

**Minibosses**
- **Size:** 440px wide, in a row under the stage bosses, up to two side by side.
- **Header:** an amber diamond, the name in IM Fell English at 24px, an outlined "MINIBOSS" tag,
  then "hp / max" in small numbers.
- **Bar:** a 12px amber (`#D9963A`) bar split into 5 segments.

**On hit, for both kinds:**
- **Damage trail:** the fill drops at once. A bone-coloured strip shows the damage just dealt and
  drains after a 0.45 s delay, over 0.55 s.
- **Hit flash:** the bar flashes white for 0.14 s.
- **Low health:** at 25% HP or below, stage bosses turn `#B3363F`, pulse, and show a flashing
  "ENRAGED" tag. Minibosses pulse gold.
- **Kill:** a "SLAIN" stamp slams onto the bar (rust for stage bosses, gold for minibosses), and the
  bar leaves after about 1.5 s.

**Off-screen pointer**
- When a boss is outside the camera, a tab sits on the nearest screen edge, pointing towards it.
- It shows the boss's name and distance in metres and bobs gently.
- Clamp it clear of the minimap and the HUD corners.

**Limits:** show at most 2 stage bars and 2 miniboss bars. If there are more, add a small
"+n more" line.

## Conflicts with `SCREENS.md` after the economy rework (follow the economy rework)

- **There are no Uniques any more.**
  - Every item stacks; there are 61 items, including the Imbued Amulet.
  - Remove the "Unique · once per run" stamp and the "ITEM · UNIQUE" label from the chest card.
  - Show stack counts everywhere.
- **Shops come in three types: Standard, Rare and Legendary.**
  - The title and framing follow the type: "Standard shop", "Rare shop" (Rare frame and glow), and
    "Legendary shop" (Legendary frame and shimmer).
  - Rows can be any tier the shop type allows, including socket gems as Rare rows.
  - Prices come from `Economy.item_price(tier, stage)`.
- **HUD "CHEST COST"** is the live `15 × 1.2^chests_opened` from `Economy`.
- **Level-up cards** each roll their own tier.
  - The card frame, glow and stat step come from that tier.
  - Levels go up to 80 for tomes and 40 for weapons, so show "LV n → n+1" with room for two digits.
- **Shrines** are tier-sized and respond to luck. The card frames follow the rolled tier.
- **The Stats panel** shows Luck, and every stat the game actually has. Generate the rows from the
  stats data, not the mockup's fixed list.
