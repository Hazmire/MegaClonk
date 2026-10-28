# MEGACLONK asset credits

- **Jacob – Game Ready OC v1.00**, Jupifox: https://jupifox.itch.io/jacob-game-ready-character.
  CC BY4.0: https://creativecommons.org/licenses/by/4.0/. Supplied Jacob.zip;
  assets/vendor/jacob. Changes: demo props/sword hidden, atlas references rebound,
  original additive movement/glide/hit/death poses over supplied Idle. NPCs reuse this model.
- **Kurland**, GGBotNet: https://ggbot.itch.io/kurland-font. SIL OFL1.1,
  Reserved Font Name Kurland. Unmodified regular TTF in assets/fonts; full licence retained.
- **Buffs and Ability Icons demo**, GandalfHardcore:
  https://gandalfhardcore.itch.io/buffs-and-ability-icons-pixel-art-pack.
  Contained terms permit free/commercial game use and editing, prohibit standalone
  resale/redistribution. Five supplied icons reused across eight abilities. Gold frames are original.
- **Undead Skill / Undead Loot Pixel Art Icons**, Free Game Assets / CraftPix:
  https://free-game-assets.itch.io/free-undead-skill-pixel-art-icons,
  https://free-game-assets.itch.io/free-undead-loot-pixel-art-icons.
  CraftPix free-asset terms: https://craftpix.net/file-licenses/; text supplied by user.
  Game use/modification/distribution permitted. No artwork-export feature or standalone
  asset product. Weapon/item icons selected from supplied packs; included loot scrolls
  also serve as tome icons. Paths assets/vendor/weapons and assets/vendor/items.
- **Lowpoly Environment Pack**, k0rveen: https://k0rveen.itch.io/lowpoly-environment-pack.
  Publisher metadata specifies CC BY4.0: https://creativecommons.org/licenses/by/4.0/.
  assets/vendor/environment; meshes recentered/resized and batched, with simplified collisions.
- **200+ Free RPG Sounds**, Clutch Assets: https://clutch-assets.itch.io/200-free-rpg-sounds.
  Publisher permits commercial/non-commercial project use; no claiming authorship or
  reselling the sounds. assets/vendor/audio; filenames normalized, selected clips wired
  to gameplay and ambient audio. Original-name manifest retained. Not labelled CC0.
- **Ancient Reliques**, user-supplied Ancient Reliques.zip. Creator/URL not identified
  inside archive; user confirms permission for personal game use. assets/vendor/relics;
  head-totem landmark resized and batched. No unrelated licence is attributed.
- **Electric FX Free**, Binbun3D / bun3d.com. Included licence: CC0,
  https://creativecommons.org/publicdomain/zero/1.0/. assets/vendor/electric.
  Adapted zap shader clamps its vertex mask before square root; custom bounded GPU emitter.
- **PSX FX Free by heyheythere - https://heyheythere.itch.io/psx-fx-free - CC BY 4.0**
  https://creativecommons.org/licenses/by/4.0/. assets/vendor/psx_fx; supplied sheets/metadata
  used by a custom cached, pooled flipbook player, scaled for combat. Full licence retained.
- **Pixelated Elegance**, GGBotNet, https://github.com/ggbotnet/fonts-cc0, CC0.
  Retained fallback font; assets/fonts/LICENSE-CC0.txt.

Original project code, procedural enemy/boss geometry/poses, terrain generation,
shaders, weapon geometry and supplemental effects were created for MEGACLONK.
The Quaternius Bestiary and paid 48 Scroll packs are not integrated; see docs/ASSET_ACCESS.md.
Godot engine notices are bundled separately in GODOT_COPYRIGHT.txt.

## Quaternius assets-v1 Forest integration

Creator: Quaternius. Source release: https://github.com/Hazmire/MegaClonk/releases/tag/assets-v1
Publisher: https://quaternius.com/

- Modular Character Outfits – Fantasy Standard: Male_Ranger outfit/rig/textures, CC0. Texture import capped at 2K; retargeted UAL2 clips and mannequin head added. `assets/quaternius/ranger/`.
- Universal Animation Library 2 Standard: non-root-motion clips and mannequin head geometry, CC0. Rest-space retargeting, movement arm adaptation, reversed lay/death and original crouch stepping. `assets/quaternius/animations/`.
- Bestiary – Dungeon Monsters Kit Standard: Imp/Puglin, Quaternius Asset License v1.0 (2026-08-28). Retargeted idle/walk baked into instanced meshes; tints/scales/damage shader. `assets/quaternius/bestiary/` and `baked/`.
- Stylized Nature MegaKit Standard: nine trees/foliage/rock models, CC0. Instanced seeded placement and simplified colliders. `assets/quaternius/nature/`.

Complete licences are retained in each pack directory and Windows distribution. Bestiary is not CC0. See `docs/ASSETS_V1_INVENTORY.md` for verified archive hashes and limitations.

## Dynamic Forest update

- KayKit Character Pack: Skeletons1.1 FREE, Kay Lousberg, https://kaylousberg.com/ . Uploaded `KayKit_Skeletons_1.1_FREE.zip`, licence CC0 (included). Selected Skeleton_Minion, Skeleton_Warrior, skeleton_texture, Rig_Medium_MovementBasic and General. `assets/kaykit/skeletons/`; idle/walk baked into `assets/quaternius/baked/Skeleton_*` and `Knight_*`. Naming of the shared bake folder does not imply Quaternius authorship.
- Original Ranger two-bone stride fitted to the existing supplied65-bone rig; original articulated Goblin frames. `scripts/art/ranger_stride.gd`, `tools/bake_original_encounters.gd`.
- Rock Golem and lesser golems: original assembly/animation using Quaternius Nature MegaKit Rock_Medium_1 (CC0), shared baked frames `assets/quaternius/baked/Golem_*`.
- Standout7 `Skeletons_Free.zip` inspected; its included licence allows game use and prohibits standalone redistribution. Not selected: KayKit provides compatible walking clips. The Wrapper V2 is not integrated; it is not needed by this roster.

## Combat / atmosphere polish

- User-supplied `SourceCode.zip` / BinbunGrass shaders, mask textures and palette: selected source under `assets/BinbunGrass/`. No licence text is present in the archive; integrated for the user's explicitly authorized personal project, without claiming CC0. Adapted cutout/light/sampler handling; the dense demo is excluded.
- Original procedural forest noise and digit atlas: `tools/generate_forest_texture.gd`, `tools/generate_number_atlas.gd`, `assets/config/forest_variation.png`, `combat_digits.png`. Original forest floor / number billboard shaders.
- Player core motion: KayKit General Idle_A, MovementBasic Running_A / Jump_Idle and Quaternius UAL2 Slide (all supplied CC0 packs). Rest-space retargeting and baked Ranger library in `assets/config/player_core.res`; original player rig/outfit and head credits above remain.
- Chunkers: Quaternius Nature MegaKit Rock_Medium_1, CC0, centered and instanced for weapon/debris. Original shield/blade/bone/banana/axe/dice meshes in WeaponArt. Stone audio uses the existing Clutch RPG stone-footfall sample, not a claimed dedicated new recording.

## Vertical Forest increment

The static cloud/gradient sky (`shaders/forest_sky.gdshader`), region/placement algorithms, and map-preview captures (`docs/images/vertical/`) are original project work. No additional external assets were downloaded. Existing trees, rocks, vegetation, characters and materials retain the licences recorded above. The overview montage combines actual renders; individual unaltered captures are included.

## Original reward presentation (2026-10-26)
- Faceted XP gemstone geometry: original procedural double-cone mesh in `scripts/rewards/xp_gems.gd`, using existing ModelBuilder primitives; shared blue/red materials.
- Metal-corner frames, roulette composition, rainbow/confetti/flying-gem draws: original project code in `scripts/ui/reward_frame.gd`, `reward_screens.gd` and `reward_celebration.gd`. User screenshots are layout references, not redistributed artwork.
- Existing project icons, Kurland font and menu/level audio are reused under the licences recorded above; no additional third-party asset download is introduced.

## GitHub UI references (2026-10-26)
The five root-level `Megabonk_*` / `firefox_WjCOcSAmyE.png` screenshots uploaded by the user are layout references only. Original frames, button styling and map markers are implemented in project code. Screenshots are excluded from playable exports; no reference-game icons or pixels are extracted. See docs/REFERENCE_UI.md for the reference-to-screen mapping.

## Stage themes and physical swarms (2026-10-27)
Original stage palette resources, atlas-preserving vegetation tint shader, shrine orb shader, shared procedural chest geometry and horned boss-statue assembly are project work. Existing supplied vegetation, enemies, icon art and fonts retain their previously recorded licences. No new third-party downloads were introduced. Actual rendered previews are in docs/images/stage-swarms/.

## Shrine and reward presentation v9 (2026-10-27)
Original procedural applause/claps and the four-note Legendary flourish are `assets/audio/reward_applause.wav` and `reward_legendary.wav`. No external recordings or asset downloads were used. Shrine gold materials/lighting, batched orb tinting, fixed-pool UI confetti/gems/sparkles and icon-cycle presentation are original project work. Existing icons, Kurland font, Clutch coin/level audio and imported models retain their previously recorded licences.

## Art reset 10 — newly supplied assets

User-supplied archives were inspected from Full-Release df625e2. Inventory, exact dependencies, import decisions and runtime mapping: [docs/ART_RESET_ASSET_AUDIT.md](docs/ART_RESET_ASSET_AUDIT.md).

| Asset / creator | Source and licence record | Runtime paths / modifications |
| --- | --- | --- |
| Fantasy Portal 3D LowPoly Model / creator not identified in archive | Repository assets/Fantasy Portal 3D LowPoly Model.rar; no separate licence file supplied; user-authorized personal project integration | assets/art_reset/portal; native FBX, both meshes, three original maps; 4.4m fitting and restrained rune-colour shader. |
| PSX Day/Night HDRI / creator not identified in archives | Repository PSX_Daysky_HDRI.zip and PSX_Nightsky_HDRI.zip; no separate licence files supplied; user-authorized personal project integration | assets/art_reset/sky/day.hdr and night.hdr; original panoramas, night reused with violet/crimson treatments. |
| PSX Forest Level / StarkCrafts | Repository assets/PSX_Forest_Level_byStarkCrafts.zip; no separate licence file supplied; user-authorized personal project integration | assets/art_reset/forest and baked; original ground/embedded textures, eleven named meshes baked with FBX transforms, ground alignment and foliage alpha scissoring. |
| StatusFXFree / Binbun3D | Repository assets/StatusFXFree.zip; explicit CC0 in assets/art_reset/status/StatusFX/license.txt | Relocated internal paths; native shatter scene, aura/noise shaders; bounded emitters, wind adaptation removes depth-buffer sampling. Copyright/licence preserved. |
| Eight weapon icon replacements / original project artwork generated with image generation | Original generated artwork, no third-party pack licence asserted | assets/art_reset/icons/weapons.png; eight regions used, supplied Sword/Fire icons retained. |
| Revolver shot / original deterministic synthesis | Original project audio, generated by tools/generate_weapon_audio.py | assets/audio/revolver.wav; short transient, no external samples. |
| Mine model, panorama/portal shader adaptations / project originals | Original implementation using credited source textures where indicated | scripts/combat/weapon_art.gd and shaders/portal_asset.gdshader, supplied_panorama.gdshader. |

The user supplied these archives for integration; missing publisher metadata is recorded transparently. No claim of a new blanket CC0 licence is made for archives without one. Original uploaded archives remain committed for provenance.

## Retro audio 11

- **Pixel Combat — Helton Yan**, https://heltonyan.itch.io/pixelcombat. **CC BY4.0**, https://creativecommons.org/licenses/by/4.0/. Licence identification supplied by the project owner from that page; cloud access returned403 and the source archive had no terms file. Supplied through audio-assets-v1 release, asset682885354. Runtime paths assets/audio/sfx; attribution shipped in ATTRIBUTION.txt. Modified by variation extraction, stereo-to-mono conversion,96→32kHz/24→16bit conversion, conservative peak adjustment and short fades. Exact original filenames, source offsets and changes: docs/audio/CURATION.json. No endorsement implied. The full source archive is outside the project and excluded from exports.
- **Arcade Groove, Arcade Groove1, Arcade Rush, Pixelad Akcio** — original music supplied by the project owner through the same release. Paths assets/audio/music; original MP3 bytes retained. Menu/three-stage routing and crossfades added; no generated replacement soundtrack.
- Six existing **Clutch Assets** death/forest ambience samples copied from assets/vendor/audio to assets/audio/sfx/legacy so unused vendor audio can be excluded from Windows exports. Existing source credits and terms remain applicable. The original project reward_applause.wav is retained as the reveal clap bed.

## Dark feedback12

Pixel Combat remains CC BY4.0 / Helton Yan, with the same source and licence links above. Selected fire/lightning/aura/pickup source takes were changed; all106 short effects received restrained5kHz low-pass filtering, soft saturation/10bit grain and lower runtime pitches. Source offsets and processed hashes were updated in docs/audio/CURATION.json. Existing original music was retained. Unused enemy-death audio is archived and excluded from exports.

## Grimdark PSX supplied assets (integration in progress)

- **Knight armour texture**, Petr Kratochvil, CC0 / public domain, confirmed by the user: https://www.publicdomainpictures.net/en/view-image.php?image=377696&picture=suit-of-armor . Source notice retained in `assets/grimdark/knight/texture_source.txt`. This credit applies to the texture, not a blanket licence claim for the mesh.
- **Knight model and animations**, supplied `knight.zip` from https://github.com/Hazmire/MegaClonk/releases/tag/psx-assets . Geometry use authorized by the user for this personal game; no separate geometry licence found in the archive. Original Blender Mirror modifier applied to repair the half-mesh GLB, ground alignment/scale normalized, native idle/walk retained in `assets/grimdark/knight/Knight_ready.glb`. Supplemental visual movement states are original project code.
- **Characters PSX 1.2, Retro Tree Pack, PSX Modular Medieval, Stark Crafts PS1 Dark Fantasy Horror, The Wrapper V2.1**: user-supplied release above, use authorized by the user. Individual pack authorship retained where provided; no unsupported CC0 assertion. Selected textures/models and derived animation frames under `assets/grimdark/`; inventory in `docs/GRIMDARK_SELECTED.json`. Monster poses are baked for shared instanced animation; Wrapper idle/walk frames are baked from supplied native clips.
- **psx_visuals**, snotbane, https://github.com/snotbane/psx_visuals/tree/7dbba0d2ac598dda82984d3d1185e12805500fd3 , Unlicense verified at this commit; notice retained in `shaders/vendor_psx/LICENSE.txt`. Adapted shader entry-point includes, depth-dependent affine UV/fog, matte lighting and world-only Bayer compositing. Original supplied source retained under `assets/grimdark/psx_addon_source/`.

## Visual corrections14

- **Autopsy Zombie**, user-supplied AutopsyZombie.zip, uploaded in this repository. No separate creator/licence text is present; use follows the user's supplied-asset authorization for this personal game, without claiming CC0. Original90-bone mesh/texture retained, original skeletal idle/walk authored because the supplied animation is static. Derived GLB, diffuse and shared baked frames: assets/enemies_corrected/autopsy and assets/grimdark/baked/enemies/Autopsy_*; original FBX/normal retained in import-ignored source_only.
- **PSX Sea Horror Monsters Free Sampler — crab**, bitkiln, https://bitkiln.itch.io . Supplied licence permits personal/commercial game use and modifications, prohibits standalone asset-product redistribution; full terms retained in assets/enemies_corrected/crab/LICENSE.txt. Native crab_bone model/texture and Walk/Idle clips, normalized and frame-baked with the non-rendered helper sphere removed. Art by bitkiln.
- Existing masked/hooded monster meshes retain their prior supplied-pack credits; new original skeletal idle/walk cycles replace their earlier vertex-only poses, with facing corrected for runtime pursuit.
