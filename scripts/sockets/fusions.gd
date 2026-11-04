class_name Fusions
extends RefCounted

# The six Fusion weapons: two different gems that form a combo make the weapon a named Fusion ("Steamforged Bow").
# This is the ONLY place that decides whether a weapon is a Fusion (is_fusion / of_state / of_gems) and the only place its numbers live.
# The existing combo gameplay (Combos / StatusManager) is untouched; a Fusion adds a look, a sound set, a name and one fused attack form.
# Tags: SPEC = taken from the Fusion brief, GUESS = my tuning, easy to change here.
const IDS=["steamforged","plasma","aurora","livewire","pyrebile","rimerot"]
# gem pair (sorted, game ids) -> Fusion. The pack spells electricity "electric"; the game's gem id is "electricity".
const BY_GEMS={"fire+ice":"steamforged","electricity+fire":"plasma","electricity+ice":"aurora","corrosive+electricity":"livewire","corrosive+fire":"pyrebile","corrosive+ice":"rimerot"}
const TABLE={
 "steamforged":{"name":"Steamforged","epithet":"The ice shell snaps shut, then cracks into scalding steam","gems":["fire","ice"],"combo":"thermal_shock",
  "palette":{"core":Color("F4F1EA"),"mid":Color("FF8A3D"),"deep":Color("3D7FA6"),"acc":Color("A8E0F5"),"smoke":Color("E2DED6")}},
 "plasma":{"name":"Plasma","epithet":"A white-hot core in a violet corona; the crackle line detonates","gems":["electricity","fire"],"combo":"overcharge",
  "palette":{"core":Color("FFFFFF"),"mid":Color("C77DFF"),"deep":Color("4A1F7A"),"acc":Color("FF9A4A"),"smoke":Color("2A1438")}},
 "aurora":{"name":"Aurora","epithet":"Crystals hang in the air and zap each other into a net","gems":["electricity","ice"],"combo":"cryoshock",
  "palette":{"core":Color("F0FFFF"),"mid":Color("6FE3D6"),"deep":Color("3E2A86"),"acc":Color("B89BFF"),"smoke":Color("8FD0E0")}},
 "livewire":{"name":"Livewire","epithet":"Dripping green lightning, tethered from foe to foe","gems":["corrosive","electricity"],"combo":"toxic_conduction",
  "palette":{"core":Color("F0FFC8"),"mid":Color("9BE04A"),"deep":Color("1F4A1A"),"acc":Color("B08AF0"),"smoke":Color("2E4A22")}},
 "pyrebile":{"name":"Pyrebile","epithet":"Sticky burning glands under a black smoke column","gems":["corrosive","fire"],"combo":"caustic_combustion",
  "palette":{"core":Color("FFF2A0"),"mid":Color("C8D23A"),"deep":Color("3A2A10"),"acc":Color("FF7A2A"),"smoke":Color("121010")}},
 "rimerot":{"name":"Rimerot","epithet":"Black ice grows from the ground and the frost-rot spreads","gems":["corrosive","ice"],"combo":"blightfrost",
  "palette":{"core":Color("DDF5E4"),"mid":Color("4F8A6C"),"deep":Color("070C0A"),"acc":Color("A6E070"),"smoke":Color("18221C")}}
}
# Weapon id -> the 3D model the forge shows (see WeaponModels).
const WEAPON_KEYS={0:"sword",1:"firestaff",2:"lightning_staff",6:"bow",7:"revolver",9:"scythe",10:"aura",15:"shotgun"}
# Every Fusion number. A weapon that is a Fusion also does DAMAGE_MULT x its normal damage (Fusions are meant to be overpowered).
const DAMAGE_MULT=1.25 # GUESS
const SAFETY={
 "boss_hit_max_fraction":0.02, # GUESS: no single Fusion-form hit may take more than 2% of a boss's max HP, so a form can never instakill one
 "form_hits_per_second":160    # GUESS: hard cap on form hits (not the weapon's own) per second, on top of the 24/s combo budget for impacts
}
const FORMS={
 0:{"every":3,"crescent_dist":6.5,"crescent_time":0.5,"crescent_width":1.4,"damage_mult":1.6},                                                    # SPEC every 3rd slash; rest GUESS
 1:{"comet_scale":1.5,"comet_damage_mult":1.4,"meteors":4,"meteor_delay":0.18,"meteor_gap":0.12,"meteor_damage_mult":0.9,"meteor_radius":1.7,"meteor_range":9.0}, # GUESS
 2:{"cloud_interval":0.9,"cloud_strikes":2,"cloud_damage_mult":0.7,"cloud_height":4.2,"tether_time":1.0,"tether_tick":0.25,"tether_damage_mult":0.18,"cloud_range":22.0}, # GUESS
 6:{"shards":3,"shard_fan_deg":28.0,"shard_damage_mult":0.75,"shard_range":12.0,"shard_speed_mult":0.85},                                           # SPEC 3 shards on first pierce; rest GUESS
 7:{"every":6,"judge_damage_mult":3.5,"judge_speed_mult":0.55,"judge_scale":2.6,"line_delay":0.35,"line_spacing":0.7,"line_radius":1.3,"line_damage_mult":0.8,"line_max_pops":16}, # SPEC every 6th; rest GUESS
 9:{"vortex_time":1.6,"vortex_radius":2.4,"vortex_tick":0.4,"vortex_damage_mult":0.55,"vortex_pull":3.0,"max_vortices":8},                         # GUESS
 10:{"inner_radius_frac":0.7,"inner_damage_mult":0.6,"every":3,"erupt_damage_mult":2.5,"erupt_crystals":6},                                          # SPEC twin rings, every 3rd pulse erupts; rest GUESS
 15:{"wall_time":1.7,"wall_width":3.8,"wall_depth":0.9,"wall_dist_frac":0.55,"wall_tick":0.35,"wall_damage_mult":1.4,"max_walls":8}                 # GUESS
}
static func valid(id: String) -> bool:return TABLE.has(id)
static func key_of(a: String,b: String) -> String:
 var pair=[a,b];pair.sort();return "%s+%s"%pair
# The Fusion for two gems in either order, or "" (same gem twice, an unknown gem or fewer than two gems).
static func of_gems(a: String,b: String) -> String:
 if a==b:return ""
 return str(BY_GEMS.get(key_of(a,b),""))
static func of_state(state: Dictionary) -> String:
 var installed=WeaponSockets.gems(state)
 if installed.size()<2:return ""
 return of_gems(str(installed[0]),str(installed[1]))
static func of_weapon(game: Object,id: int) -> String:
 var state=game.weapons.get(id) if "weapons" in game else null
 return of_state(state) if state is Dictionary else ""
static func is_fusion(state: Dictionary) -> bool:return of_state(state)!=""
static func display_name(id: String) -> String:return str(TABLE[id].name) if valid(id) else ""
static func epithet(id: String) -> String:return str(TABLE[id].epithet) if valid(id) else ""
static func combo_name(id: String) -> String:return combo_id(id).replace("_"," ").capitalize()
static func combo_id(id: String) -> String:return str(TABLE[id].combo) if valid(id) else ""
static func palette(id: String) -> Dictionary:return TABLE[id].palette if valid(id) else {}
static func color(id: String,key: String="mid") -> Color:return TABLE[id].palette.get(key,Color.WHITE) if valid(id) else Color.WHITE
# "Steamforged Bow": the name a weapon shows everywhere its name shows (HUD tooltip, inventory, Inspect build, level-up cards, Results).
static func weapon_name(state: Variant,id: int) -> String:
 var base=Catalog.weapon_name(id)
 var f=of_state(state) if state is Dictionary else ""
 return "%s %s"%[display_name(f),base] if f!="" else base
static func weapon_name_of(game: Object,id: int) -> String:
 var state=game.weapons.get(id) if "weapons" in game else null
 return weapon_name(state,id)
# Audio ids, built once. Index 0 attack, 1 hit, 2 loop.
static func events(id: String) -> Array:return ["fusion.%s.attack"%id,"fusion.%s.hit"%id,"fusion.%s.loop"%id]
static func form(weapon_id: int) -> Dictionary:return FORMS.get(weapon_id,{})
