# Core overhaul and combat feedback

## Implemented
- [x] Preserve the newest user upload branch, all original archives, existing combat and run variants.
- [x] Integrate Jacob, Kurland, ability icons, Undead skill/loot icons, supplied forest models,
  Ancient Reliques landmark, RPG audio, PSX flipbooks and Electric FX shaders.
- [x] Red damage flashes on all enemy types and the player, with material restoration and invulnerability checks.
- [x] Ten-minute stages; saved once-only events, 08:00/04:00 rushes, 07:00/03:00 minibosses, zero/endless.
- [x] Dormant/summoned/exit portal, main-boss choice, continued stages and retained build/gold/variants.
- [x] Forest Colossus: jump-dodgeable slam, telegraphed charge, thorn barrage.
- [x] Wraith Sovereign: swept single-hit dash, three-wave soul barrage, marked phantom explosion.
- [x] Brute Champion / Shadow Hunter, prioritized health bars, rewards, wind-up/recovery/cooldowns.
- [x] Fast glowing endless ghosts with bounded speed, increasing health/damage and spawn pressure.
- [x] Broad planar forest slopes, elevated terrain, cliffs, deterministic layouts and objective reachability.
- [x] Seed batch tests and F8 sandbox regeneration; instanced imported props with simple colliders.
- [x] Grounded movement, crouch/slide, wall jump/climbing, glide pose, stackable jump/speed/slide/glide/climb upgrades.
- [x] Five initially available traits and three ultimates with revised caps/timing and configurable Resources.
- [x] Eligible per-weapon attribute pools; physical Revolver bullets with velocity/count/ricochet/crit upgrades.
- [x] Exact upgrade proposals, persistent attributes, rolling measured DPS excluding overkill, labelled estimates.
- [x] Profile V3 silver migration; quest-only permanent rewards, silver weapon purchases, independent 250/750 slot upgrades.
- [x] Real-event quests and weapon mastery quests sufficient to progress through the collection.
- [x] Common/Rare/Legendary NPC shops, one successful purchase, consumed-shop saves, three distinctive legendary effects.
- [x] HUD empty slots, XP/level text, cooldown numbers, fog/facing/objectives minimap without ordinary mobs.
- [x] Paused Tab build screen, percentage/absolute stats and hover explanations/current weapon values.
- [x] Automated regressions and rendered 720p/1080p/1440p inspection; performance observations documented.

## Delivery checks
- [ ] Final clean-source Windows export and packed-resource validation.
- [ ] Successful GitHub Actions artifact and updated durable ZIP/download checksum.

## Exact-art substitutions / validation limits
- The Quaternius Bestiary is absent from the uploads. Its free Standard download was
  attempted, but the storage host is proxy-blocked. Original distinct low-poly enemies
  and new procedural encounter models remain in use, with shared procedural animation.
- The linked 48 Scroll pack is absent and currently paid; no purchase was made.
  Scroll artwork already present in the supplied free loot pack is used for tomes.
- Native Windows execution and 60 FPS on desktop GPU hardware cannot be verified here.
  These are disclosed testing limits, not claims of completed hardware certification.
