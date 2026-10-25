# Verified assets-v1 inventory

All four actual release ZIPs were downloaded, byte-counted, SHA256-checked and CRC-tested.
Source: https://github.com/Hazmire/MegaClonk/releases/tag/assets-v1
Only selected runtime files and complete applicable licences are committed under assets/quaternius.

| Archive | Bytes | Contents and licence |
|---|---:|---|
| Bestiary.-.Dungeon.Monsters.Kit.Standard.zip | 47,299,856 | Imp and Puglin; two GLB/two FBX, 16 PNG; 55 bones each, no animation clips. Quaternius Asset License v1.0 (2026-08-28), **not CC0**. |
| Modular.Character.Outfits.-.Fantasy.Standard.zip | 294,347,394 | 24 glTF+bin, 24 FBX, 46 PNG; four outfits and twenty parts; 65-bone rigs, no clips. CC0. |
| Stylized.Nature.MegaKit.Standard.zip | 104,088,529 | 68 glTF+bin, 136 FBX, 68 OBJ+MTL, 40 PNG, four JPG. CC0. |
| Universal.Animation.Library.2.Standard.zip | 18,735,003 | Three GLB/three FBX; 43 clips in standard non-root-motion library, 65-bone mannequin. CC0. |

SHA256, in table order:
```
94dbeed196b6ead9776c2ed0cfa02de818730886a25a507fb9d6c379bbbc4645
c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70
298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9
4008ea208a604773a2b2177d965f0f5d3195498b5bf838c3f5785d68e95f2a68
```

Integration: Male_Ranger with referenced textures (4K maps limited to 2K at import), UAL2 standard
library and mannequin head, both complete Bestiary GLBs, nine Nature models and dependencies.
UAL2 has Slide/Slide_Start/Slide_Exit, NinjaJump_Start/Idle/Land, Hit_Knockback, Walk_Carry,
Zombie_Idle/Walk_Fwd and other ability/interact clips; there is no dedicated ordinary run/crouch.
Supplied root-motion edition is not used: existing controller owns world motion.

Outfit README requires a separate Base Character head. The supplied animation mannequin head
provides a coherent fallback without acquiring another kit. Rig rest transforms differ, so raw
clip assignment is insufficient; runtime retargeting corrects rotations and pelvis offsets.
Bestiary walk/idle frames are reproducibly baked from that retargeting for efficient hordes.

Bestiary terms allow use/modification/distribution in games/products and prohibit standalone
asset resale/redistribution. The licence text accompanies the game. Other three pack licences
are CC0. No Unity package, external paid animation, or ripped asset is required.
