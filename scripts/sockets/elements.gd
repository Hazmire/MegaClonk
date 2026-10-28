class_name Elements
extends RefCounted

# Data-driven definitions for the four socket-gem elements and the six dual-element
# combinations. Everything tunable lives here so balancing never touches combat code.
# Element ids are stable strings: they are what saves and weapon state store.
const CORROSIVE="corrosive"
const ICE="ice"
const FIRE="fire"
const ELECTRICITY="electricity"
const IDS=[CORROSIVE,ICE,FIRE,ELECTRICITY]

const DATA={
 "corrosive":{"name":"Corrosive","color":Color("5fd35a"),"summary":"Poison: 3% of current HP per second for 10s. Hits refresh it."},
 "ice":{"name":"Ice","color":Color("8fdcff"),"summary":"Chill: each hit slows 3% (max 10 stacks). Fully Chilled kills shatter."},
 "fire":{"name":"Fire","color":Color("ff5a24"),"summary":"5% chance to Ignite for 5s: critical hits deal 20% more."},
 "electricity":{"name":"Electricity","color":Color("b46bff"),"summary":"5% chance to Stun for up to 2s, with diminishing returns."}
}

# Keys are the two element ids sorted alphabetically and joined with "+", so installation
# order can never matter.
const COMBOS={
 "corrosive+electricity":{"id":"toxic_conduction","name":"Toxic Conduction"},
 "corrosive+fire":{"id":"caustic_combustion","name":"Caustic Combustion"},
 "corrosive+ice":{"id":"blightfrost","name":"Blightfrost"},
 "electricity+fire":{"id":"overcharge","name":"Overcharge"},
 "electricity+ice":{"id":"cryoshock","name":"Cryoshock"},
 "fire+ice":{"id":"thermal_shock","name":"Thermal Shock"}
}

# Enemy kinds treated as bosses/minibosses for the reduced-effect rules
# (8 boss, 9 champion, 10 hunter, 12 lesser golem, 13 statue elite; see Encounters.initialize).
const BOSS_KINDS=[8,9,10,12,13]

# Values marked SPEC come straight from the design document. Values marked GUESS were not
# specified and are initial placeholders to tune during playtesting.
const TUNING={
 "corrosive":{
  "percent_current_hp":0.03,"interval":1.0,"duration":10.0, # SPEC
  "boss_percent_current_hp":0.005,                          # SPEC
  "boss_tick_cap":60.0                                      # GUESS
 },
 "ice":{
  "slow_per_stack":0.03,"max_stacks":10,                    # SPEC
  "decay_delay":4.0,"decay_interval":1.0,                   # SPEC
  "boss_max_slow":0.15,                                     # SPEC
  "shatter_percent_max_hp":0.01,                            # SPEC
  "shatter_radius":3.5,"shatter_damage_cap":150.0,          # GUESS
  "shatter_max_depth":2                                     # GUESS
 },
 "fire":{
  "ignite_chance":0.05,"ignite_duration":5.0,               # SPEC
  "crit_damage_bonus":0.20                                  # SPEC
 },
 "electricity":{
  "stun_chance":0.05,                                       # SPEC
  "stun_durations":[2.0,1.2,0.7,0.4,0.3],                   # SPEC
  "diminish_reset":8.0,"proc_cooldown":1.5,                 # SPEC
  "boss_max_stun":0.5,"boss_immunity":5.0                   # SPEC
 },
 "combos":{
  # Every combo has a per-target cooldown and a damage cap. Global budget keeps crowds bounded.
  "budget_per_second":24,                                                                                                 # GUESS
  "thermal_shock":{"damage_percent_max_hp":0.02,"chill_stacks_consumed":3,"cooldown":3.0,"damage_cap":200.0},            # GUESS
  "toxic_conduction":{"damage_percent_max_hp":0.015,"targets":3,"radius":5.0,"cooldown":2.0,"damage_cap":100.0},         # GUESS
  "caustic_combustion":{"damage_percent_max_hp":0.03,"radius":3.5,"cooldown":3.0,"damage_cap":150.0},                    # GUESS
  "blightfrost":{"extra_chill_stacks":1},                                                                                 # SPEC
  "overcharge":{"damage_percent_max_hp":0.02,"cooldown":3.0,"damage_cap":200.0},                                          # GUESS
  "cryoshock":{"damage_percent_max_hp":0.015,"radius":4.0,"chill_stacks":2,"cooldown":3.0,"damage_cap":120.0}            # GUESS
 },
 "amulet":{"chest_chance":0.30,"max_per_run":1}                                                                           # GUESS
}

static func valid(element: String) -> bool:
 return element in IDS
static func display_name(element: String) -> String:
 return str(DATA[element].name) if valid(element) else ""
static func color(element: String) -> Color:
 return DATA[element].color if valid(element) else Color.GRAY
static func summary(element: String) -> String:
 return str(DATA[element].summary) if valid(element) else ""
static func combo_key(a: String, b: String) -> String:
 var pair=[a,b];pair.sort();return "%s+%s"%pair
# Returns {"id","name"} for two different valid elements, or an empty dictionary.
static func combo(a: String, b: String) -> Dictionary:
 if a==b or not valid(a) or not valid(b):return {}
 return COMBOS.get(combo_key(a,b),{})
static func is_boss_kind(kind: int) -> bool:
 return kind in BOSS_KINDS
