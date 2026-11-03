# Prompt: Endless mode — the ghosts come at 10:00

Before you paste this:
- Unzip `megaclonk_endless_mode.zip` into `docs/endless_mode/` and commit it. It contains:
  - `mockup/`: the endless timer board, as standalone HTML plus the canvas file;
  - `godot/ui/endless/`: a starter `EndlessTimer` control and its style data, tested in Godot 4.7.2;
  - `ghosts/`: the ghost mesh, shader, node and renders;
  - `reference/`: the board and the starter's rendered states.
- Add your sound file `endless_begins_banshee` (.ogg or .wav) to the repo, next to the other world or boss
  sounds.
- Then paste everything below the line into Claude Code.

---

We're adding **endless mode**. When the 10:00 run timer runs out, the normal enemies stop coming and the
ghosts take over. They fly straight at the player and escalate without limit, so every run ends in death.
The only question is how long you last.

At 10:00 the run timer **becomes the endless timer**. It glitches, turns blood red, resets to 00:00 and counts
how long the player has survived endless mode. There's no second timer and no announcement text. That number
is the score for the end of the run.

Work the way the earlier passes did:
- one source of truth for the numbers;
- seeded runs stay deterministic;
- no per-frame allocations, and hard-capped pools;
- tests and real captures;
- an honest report.

Read these first:
- `docs/endless_mode/README.md`;
- `docs/endless_mode/ghosts/README.md`: tiers, look, and how to wire them in;
- `docs/ingame-ui-overhaul-report.md`: the HUD, `RunData`, `StageBanner`, `NoticeLabel` and `RunResults`;
- `docs/audio-integration-report.md`;
- the items, economy and stage-dressing reports.

Respect their rules:
- `Game.hit()` is the only damage entry point;
- the Stopwatch and Hourglass use hostile time, never `Engine.time_scale`;
- `RunData` is the single data layer for the UI.

## Step 0 — Survey, then wait
Tell me:
1. **The timer.**
   - Where the run timer lives.
   - Whether it counts up or down.
   - Whether it's per stage or for the whole run.
   - What happens at 10:00 today, if anything.
   - How it behaves during pause, level-up and the other reward screens, and with the Stopwatch.
2. **Stages.**
   - How stages advance (the portal, `advance_stage`).
   - Whether a player can still be on a stage when its timer runs out.
   - What the "endless stages" from the stage-dressing report actually are today.
3. **Spawning.**
   - The spawner and its data: how spawn rate, enemy HP, damage and speed are set over time.
   - Where the enemy cap and pools live.
4. **Enemies.**
   - How an enemy moves and hits the player: contact damage, hitboxes and ground snapping.
   - Whether a flying, terrain-ignoring enemy fits the existing system or needs its own small path.
5. **The end of a run.**
   - How death ends a run.
   - What `RunResults` shows.
   - Where personal bests are stored (`MetaProgress`).
   - Whether Save & quit serialises the timer and spawner state.
6. **Conflicts.**
   - Anything that conflicts with the rules below.
   - Your proposal if the timer is per stage: does endless start when the current stage's timer runs out,
     or at a whole-run 10:00?

Send me that and wait for my go-ahead.

## Step 1 — The endless state
Add one run state, `endless`.

**Starting it:**
- It starts the moment the run timer reaches 10:00.
- It starts exactly once per run.
- It is saved and restored by Save & quit.

**When it starts:**
- **Normal spawning stops for good,** including waves, elites and minibosses. Enemies already alive stay,
  and die normally.
- **The ghost spawner takes over** (Step 2).
- **Stage bosses:** if a stage boss is alive, it stays, but no new ones spawn.
- **The portal closes.** If it's open it seals, and it can't open again, so you can't leave once the ghosts
  come. Put this behind one constant (`Endless.LOCK_PORTAL = true`) so I can change it.
- **Level-ups, chests, shops, shrines, items and gems keep working.** The player can still get stronger; it
  just won't be enough.
- **The run timer becomes the endless timer** (Step 3).

**The endless timer:**
- `endless_time` counts seconds survived since endless began.
- It advances with the run simulation:
  - it **stops** for pause, level-up and every other reward or menu screen, exactly like the main timer;
  - it **keeps counting** during the Stopwatch or Hourglass freeze, because the player is still alive and
    surviving.
- It is serialised, and deterministic for a seed.

## Step 2 — The ghosts
Use the visuals from `docs/endless_mode/ghosts/`: `ghost_mesh.gd`, built once and shared; the tier materials from `ghost.gdshader`;
and `set_fade()` to materialise them in about 0.6 s and dissipate them in about 0.25 s. If the game's enemy
system already moves enemies, use it, and drop the movement code in `ghost.gd`.

**Behaviour:**
- **Movement.** Ghosts fly straight at the player's chest and bank into turns. They ignore terrain,
  navigation and ground snapping, and pass through terraces and walls.
- **Hitbox.** A sphere of about 0.5 m radius around the head and body.
- **Spawning.** They spawn just outside the camera view, at a spread of heights, and never inside the
  player's immediate radius.
- **Damage.** Contact damage goes through `Game.hurt`, like other enemies.
- **Taking damage.** They can be hit and killed normally through `Game.hit()`.
- **Drops.** They give a small amount of XP and no gold. Put both in data.
- **Time.** They obey hostile time, so the Stopwatch and Hourglass freeze them.

**Tiers and escalation.** Put every number in the enemy data, not in code. Times are endless time, so 0:00
is the 10:00 mark.

| Tier | Joins at | Character |
|---|---|---|
| Mourner | 0:00 | the base ghost; the most numerous |
| Drowned | 3:00 | more HP |
| Wrathful | 6:00 | more damage, faster |
| Hollow | 10:00 (20:00 on the run clock) | 1.3× size; the final ghosts |

- **New tiers join the mix.** They don't replace earlier ones.
- **Every minute, with no ceiling:** spawn rate, contact damage, HP and flight speed all rise.
- **Speed curve:** flight speed passes the player's base run speed at about endless 10:00, and passes the
  best realistic speed build (the items-report stress build) by about 13:00.
- **Damage curve:** by about endless 15:00, a single contact must kill the stress build outright.

That's what guarantees death. Choose the curves, explain them in the report, and show a table of spawn rate,
HP, damage and speed per tier at 0, 5, 10, 15 and 20 minutes.

**Performance:**
- Hard-cap live ghosts at 600. When the cap is reached, keep escalating damage and speed instead of count.
- Pool them.
- Profile at the cap: give ms per frame and draw calls.

**Revives:** the Hourglass and any revive still work. Escalation still climbs while they're active, so they
buy time but not safety.

## Step 3 — HUD: the timer becomes the endless timer
Follow the mockup `docs/endless_mode/mockup/RunEndlessTimer.html` exactly. Open it in a browser to see the
animation; every colour and timing is in its inline styles and keyframes. Start from the tested starter in
`docs/endless_mode/godot/ui/endless/`:
- `endless_timer.gd` (`EndlessTimer`), with `set_run_time()`, `start_endless()` and `set_endless_time()`;
- `endless_timer_style.json`, which becomes the `EndlessTimerStyle` data.

Fold it into the existing HUD timer rather than adding a second node. Restyle it with the real fonts and
`FogTheme`, and wire it to `RunData`. There's **no second timer and no banner or announcement text.** The existing
top-centre timer turns into the endless timer.

**At 10:00:**
1. **Glitch (0.5 s):** the timer tears like a bad signal.
   - It shakes with `hudStatic` (0.18 s, 2 steps).
   - A blood-red copy of the digits bleeds through, offset about 5 px right and 2 px up.
   - The cream digits split across a band through the middle.
   - A dashed red scanline runs across them.
2. **Reset:** it comes back as **00:00** in blood red and settles in 0.5 s (from 1.18× scale and double
   brightness down to 1×).
3. **Count:** from then on it counts up `endless_time`.

**While endless:**
- **Digits:** same position, font and size as the run timer (IM Fell English 68 px), so nothing on the HUD
  moves.
  - Colour `#D8333E`, with the HUD's 3 px ink shadow and a faint red glow (`0 0 22px rgba(179,54,63,.55)`).
  - Add the colour to `FogPalette` as the endless or danger red rather than hard-coding it.
  - The format is MM:SS, and H:MM:SS after an hour. It never rolls over.
- **The line underneath:** "STAGE n" is replaced by **ENDLESS** in the alert pink `#E07B83`, then
  " · <stage title>" as before. The rust rules either side stay.
- **No "+" prefix**, and no 10:00 shown anywhere on the HUD.
- **Data:** driven by `RunData`, updating on a once-per-second signal, not by rebuilding nodes.
- **Sound:** when endless begins, play the new **`endless_begins_banshee`** sound once, at the start of the
  glitch.
  - **Find the file:** search the repo for `endless_begins_banshee.*`. If it isn't there, stop and tell me
    rather than substituting another sound.
  - **Register it** in the audio manifest as `world.endless_begins_banshee`, following the audio report's
    conventions:
    - SFX bus, not affected by hostile time;
    - high priority, so a full swarm can't steal its voice;
    - `max_voices` 1.
  - **Level:** measure its loudness the way section 8 of the audio report did, and set `gain_db` so it sits
    about level with `world.boss_enrage_*`. Report the measured level.
  - **Music:** duck the music by about 6 dB for the length of the sound, then restore it.
  - **Tier changes:** these replay the glitch without the banshee. Add no other new sounds.

**It gets worse the longer they last.** The timer escalates with the ghost tiers, following the four tier
cards in the mockup. At each step it replays the 0.5 s glitch. Never let it calm down again within a run.

| Endless time | Digits | Glow / motion | Effects |
|---|---|---|---|
| 0:00 | `#D8333E` | faint red glow, steady | none |
| 3:00 | `#A81E28` | stronger glow, slow pulse (2.4 s) | none |
| 6:00 | `#7E1218` with a hot `#FF5A4A` edge | pulse 1.4 s | embers lift off the digits |
| 10:00 | near-black `#22060A`, outlined in red light | smoulder: the edge glow flickers between red and coal orange (`#FF7A2A`) in 8 steps over 1.6 s, plus a brief twitch every ~3 s | more embers, plus dark smoke curling up behind the digits |

- **Data:** put the tier thresholds and styles in one data table (`EndlessTimerStyle`), not in code branches.
- **Embers and smoke:**
  - one `CPUParticles2D` (or `GPUParticles2D`) each, parented to the timer, as in the starter;
  - embers are untextured pixel squares, and smoke uses a small radial gradient;
  - hard-capped at about 30 embers and 12 smoke puffs;
  - **drawn behind the digits and the ENDLESS line, never over them;**
  - they stay within about 150 px of the timer and never fall onto the play area.
- **No blood drips.** That idea was dropped because it covered the text.
- **Pausing:** the effects pause with the game.
- **Settings:** if Settings has a reduce-motion or effects toggle, the pulse, twitch and particles obey it.

**Other screens:**
- **Pause:** in the Level / Time / Kills / Gold strip, **Time** becomes **ENDLESS** with the value in the
  same red.
- **Results:** lead with the endless time large, in red, labelled "SURVIVED IN ENDLESS", next to the
  existing run figures.

**Low-HP overlay and the rest of the HUD:** unchanged.

## Step 4 — End of run and records
- **The only ending.** Death during endless is the only way the run ends: no victory screen. Results say how
  long you lasted.
- **A death before 10:00** shows Results exactly as today, with no endless line.
- **New record.** Store the best endless time in `MetaProgress` as `best_endless_time`, overall and per
  starting loadout if bests are already tracked per loadout. Results show **"NEW RECORD"** with the existing
  stamp when it's beaten.
- **The main menu** shows the best endless time wherever personal bests are already shown. If there's no
  such place, say so; don't add a new screen.

## Step 5 — Checks
**Tests** in `tests/endless_mode.gd`:
- endless starts exactly once at 10:00, including after Save & quit and reload mid-endless;
- normal spawns stop, ghosts start, and the portal is sealed (with `LOCK_PORTAL`);
- `endless_time` stops during pause and reward screens, and counts during the Stopwatch;
- tiers join at their times and earlier tiers keep spawning;
- every escalation value rises monotonically with no cap;
- a seeded run reproduces the same ghost spawns and the same `endless_time` at death;
- the live-ghost cap is never exceeded;
- with the stress build and god mode off, simulated survival ends before endless 20:00;
- `best_endless_time` updates only when beaten;
- a pre-10:00 death shows no endless UI;
- the timer node is the same before and after the switch (no second timer node);
- the timer style changes at endless 3, 6 and 10 minutes, and the particle counts never exceed their caps;
- `world.endless_begins_banshee` plays exactly once per run, at the switch, and never on tier changes.

**Captures** at 1920×1080 into `docs/images/endless/`:
- the HUD at 09:58 (before);
- the switch: the glitch frame and the red 00:00;
- the HUD at endless 01:00, 04:00, 07:00 and 12:00 (one per timer stage);
- the pause strip;
- Results with **NEW RECORD**;
- a swarm at 0, 10 and 20 minutes;
- a contact sheet of all of the above.

**Then:**
- run `tools/validate.sh`;
- write `docs/endless-mode-report.md`. Include the curves table, your judgement calls, performance, the
  capture paths, and an honest "Outstanding / unverified" list. That list must say it hasn't been playtested
  by a human or seen on real hardware.

Commit each step separately on `feature/endless-mode`.
