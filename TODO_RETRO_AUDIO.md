# Retro audio and visceral feedback

Baseline: art-reset v10 source e92d16c, merged Full-Release59a3135; Godot4.7.2 unchanged.

- [x] Audit release archive, licence, source inventory and original music.
- [x] Curate named variations outside project; record metadata and selection rationale.
- [x] Central event registry, Master/Music/SFX/UI/Ambience buses, pooled prioritized 2D/3D playback and persistent sliders.
- [x] Supplied music playlist with configurable crossfades; no replacement generated soundtrack.
- [x] Ten weapon identities, controlled impacts and no generic enemy hit audio.
- [x] White enemy flashes, bounded impact particles and contact-only player shunt.
- [x] Grounded footsteps, slide start/stop, landing and aggregated XP audio.
- [x] Exactly-once level/reveal celebrations, synchronized chest ticks and UI events.
- [x] Dense voice/CPU profiling and objective sample analysis; disclose listening limitations.
- [x] Regression, compiled-pack gates, committed source and verified Windows ZIP delivery.

Audit resolved: four original MP3 tracks were added to audio-assets-v1 and integrated. Project owner supplied Pixel Combat publisher URL and identified CC BY4.0; publisher access returns403, recorded transparently with attribution. 350 source WAVs extracted outside project;106 curated clips (3,190,904bytes), six active legacy ambience/death samples, and four original music tracks are used. Full source archive never enters res:// or Git.

Focused165-check audio suite passes. Actual white/restored/sliders renders were viewed. Dense dispatch benchmarks and ALSA-null signal capture are documented with headless/unclocked limitations. All26 local suites passed1,076 checks; clean CI passed the same26 suites. Clean source7ab7312 was published as retro-audio-v11, downloaded, checksum/CRC/source-verified and passed180 world frames plus five compiled smoke gates. Provenance: releases/RETRO_AUDIO_VALIDATION.json. Human listening, Windows/GPU/audio device testing and existing dense-horde performance remain local playtest gates.
