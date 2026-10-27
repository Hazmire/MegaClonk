# Retro sound and visceral combat 11

The existing Godot4.7.2 game now uses a central audio event registry, preloaded variation resources and fixed native playback pools. Existing gameplay, rarity rules, contact pursuit, portal guidance and reward outcomes are retained.

## Source audit and curation

Release: https://github.com/Hazmire/MegaClonk/releases/tag/audio-assets-v1

Actual source attachment: **Helton.Yan.s.Pixel.Combat.zip**, release asset682885354, **2,039,321,430bytes**. It contains **350 WAV files**, with4,981,974,680 uncompressed bytes, predominantly96kHz/24bit stereo variation reels. Download and extraction took place in /tmp/megaclonk-audio-source, outside the Godot project. The full archive/library is neither committed nor exported.

The archive has no licence/readme. The project owner identified the publisher licence as **CC BY4.0** and supplied https://heltonyan.itch.io/pixelcombat. That page returned HTTP403 here, so the licence identification is explicitly owner-provided, not claimed as independently read online. The shipped PIXEL_COMBAT_ATTRIBUTION.txt credits Helton Yan, gives source/licence links and identifies the modifications. Existing Clutch effects retain the prior project credits. No endorsement is implied.

Selection used semantic categories and waveform screening: silence-separated takes, peak/RMS ratio, attack/transient shape and spectral centroid. Sources were compared within the relevant categories; recordings were converted to mono32kHz/16bit, conservatively peak-adjusted with short fades, and cropped into short reusable takes. No pitch-shifted duplicates were generated to pad variation counts. **Files were not listened to**; perceptual suitability, particularly the synthetic pistol/stone/sliding timbres, requires local listening. A source name alone is not auditory verification.

Selected Pixel Combat audio: **106 unique clips, 3,190,904bytes**. With six actively used legacy death/ambience recordings: **3,982,598bytes of SFX** (plus the existing short project applause bed). Original music: **16,163,247bytes**. Raw filenames, source offsets, duration, spectral/crest/peak data and hashes: [CURATION.json](audio/CURATION.json). Full source metadata: [SOURCE_INVENTORY.json](audio/SOURCE_INVENTORY.json). Unused pre-existing vendor audio stays archived in Git and is excluded from the Windows export.

## Original soundtrack

| Context | Supplied original track | Duration |
| --- | --- | --- |
| Main menu | Pixelad.Akcio.mp3 |184.848s |
| Green Forest | Arcade.Groove.mp3 |192.816s |
| Violet Forest | Arcade.Groove.1.mp3 |183.768s |
| Crimson Forest | Arcade.Rush.mp3 |138.840s |

Original MP3 bytes are retained. Assignments use the supplied titles and metadata, not a claimed listening session. All four streams preload at startup. Music starts automatically, loops through native stream settings, keeps playing through rewards/pause and avoids restarting the same current track. Stage/menu changes crossfade two reusable players over1.8 configurable seconds. Audible loop joins and subjective stage fit remain listening checks.

## Event registry and variations

The runtime registry is assets/audio/events.json. Each event has its own sample list, bus, gain, pitch range, cooldown, voice cap and priority. The following counts are actual configured files, not target promises.

| Event | Variations | Bus |
| --- | --- | --- |
| weapon.revolver.fire | 6 | SFX |
| weapon.sword.swing | 4 | SFX |
| weapon.firestaff.cast | 4 | SFX |
| weapon.lightning.zap | 5 | SFX |
| weapon.chunkers.impact | 5 | SFX |
| weapon.bone.throw | 3 | SFX |
| weapon.bow.fire | 3 | SFX |
| weapon.bananarang.throw | 3 | SFX |
| weapon.aura.pulse | 3 | SFX |
| weapon.mines.place | 3 | SFX |
| weapon.aegis.impact | 4 | SFX |
| enemy.explosion | 5 | SFX |
| player.damage | 4 | SFX |
| player.footstep.grass | 6 | SFX |
| player.footstep.rock | 6 | SFX |
| player.slide | 4 | SFX |
| player.land | 3 | SFX |
| pickup.xp | 5 | SFX |
| ui.hover | 3 | UI |
| ui.confirm | 3 | UI |
| ui.open | 3 | UI |
| ui.close | 3 | UI |
| ui.purchase | 3 | UI |
| reward.level_up | 3 | UI |
| reward.chest.tick | 3 | UI |
| reward.chest.reveal | 3 | UI |
| reward.chest.legendary | 3 | UI |
| boss.warning | 3 | SFX |
| enemy.death | 3 | SFX |
| ambient.forest | 3 | Ambience |
| reward.applause | 1 | UI |

All ten active weapons have separate identities: Sword swing; Firestaff flame cast; Lightning zap; Chunkers stone impact; Bone throw; Bow whoosh; Revolver shot; Bananarang wind throw; Aura pulse; Mines placement with shared explosion on detonation. Archived Aegis gets a heavy metal/crunch impact and remains excluded from new active pools. Chunkers/Aegis play on connection rather than duplicate activation. Impact events aggregate through short cooldowns and voice caps. Ordinary enemy damage never triggers generic enemy pain audio; deaths, explosions and boss warnings remain distinct.

## Mixer, controls and feedback

Native buses: Master, Music, SFX, UI, Ambience. Five0–100% sliders apply immediately, set true mute at zero, convert linear levels to decibels and persist every audio slider change without dropping other settings. A master hard limiter ceilings at−1dB. Music/event gains leave mix headroom; a limiter does not replace listening.

Ten reusable2D voices and fourteen positional3D voices support cooldowns, per-event concurrency and priority stealing. Two music players and one ambience player are separate: maximum27 playback nodes, with no per-hit player construction. Samples use small pitch/gain variation and avoid immediate repetition. Positional voices attenuate over distance. Voice-limit rejections also enter cooldown, avoiding repeated scans from an area hit. A sandbox-only Audio diagnostics action shows voice counts, recent events, suppression counters and bus levels.

Enemies flash white for0.10s through existing shared textured shaders and per-instance custom data, restore the original appearance, and refresh on repeated damage. Bounded existing flipbook particles add short outward hit feedback. No long hit-stun was added. Player damage keeps its red visual cue and uses the low-bit slash pool. Contact damage adds a3.2m/s horizontal shunt away from the attacker only when health was actually lost; immunity prevents stacking. Existing stronger explosion launch remains separate and unchanged.

Footsteps depend on actual grounded distance/speed and stop while still, airborne or sliding. Steep ground selects the rock pool; this is a slope proxy, not a new physical-surface taxonomy. Slides start a gritty scrape, refresh one voice during sustained motion and stop on exit/pause. Landing follows a real airborne-to-ground transition. XP pickup events aggregate; gem values/attraction stay unchanged.

Level-up celebration occurs when its screen opens. Chest ticks follow actual icon changes as cycling slows. Skipping cancels ticks, reveals the predetermined item once, and produces one final celebration. Existing continuous confetti remains. Rarity adjusts reveal gain and Legendary uses its own flourish; applause uses the existing original project clap bed. Menus, hover/confirmation, purchases, shrine selections and quest claims use small UI/reward events.

## Verification and limits

Focused retro-audio suite passed165 checks: registry dependencies, variation non-repetition/category safety, buses/mute, saved settings, voice caps/priority, thousand-gem aggregation,3D position, white feedback/restoration, no generic hit audio, contact immunity, stronger explosions, all four original tracks, same-track persistence/crossfade setup, movement events and exactly-once chest reveals.

Actual software-rendered images: [white hit](images/retro-audio/white_hit.png), [restored model](images/retro-audio/restored.png), [five sliders](images/retro-audio/audio_settings.png). These were viewed. They are graphical fixtures, not native Windows playtesting.

An ALSA-null mixer smoke decoded music and effects, exercised transitions and captured output:−15.84dBFS peak,−38.56dBFS RMS and zero full-scale clipped samples. **The null sink is unclocked and runs faster than real time**; this proves signal/decoder/mixer operation, not audible quality, live timing or physical output. No speaker audition is claimed. Details: [MIXER_CAPTURE.json](audio/MIXER_CAPTURE.json).

Dense-event CPU dispatch tests with50/100/250/500 live enemy records measured mean0.086/0.147/0.306/0.509ms and worst0.272/0.320/0.554/1.583ms per stressed frame, with at most15 active SFX/UI voices. Each enemy requests an impact every simulated frame plus pickup/weapon bursts: deliberately above normal traffic. Audio-device mixing is excluded under Dummy. Raw data: [VOICE_PROFILE.json](audio/VOICE_PROFILE.json). Existing dense-horde gameplay/GPU limits are not declared solved.

Final clean CI regression/export publication and downloaded-pack verification are recorded in releases/RETRO_AUDIO_VALIDATION.json when complete. Native Windows, speakers/headphones, spatial mix, subjective sample choice, loop joins, crossfade timing and dense live encounter listening remain local playtest requirements. Under Dummy, engine playback is skipped while dispatch, timing and voice accounting remain testable; this avoids headless MP3-loop shutdown leaks.
