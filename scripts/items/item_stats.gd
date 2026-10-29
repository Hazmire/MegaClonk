class_name ItemStats
extends RefCounted

# Every number that drives an item effect lives here and nowhere else. Names, tiers and effect text come from
# res://data/items.json (Catalog.ITEMS). Same convention as Elements.TUNING:
#   SPEC  = the number comes straight from the item's effect text (or the drop-rate brief)
#   GUESS = the text did not give a number, or the reading is an interpretation: initial value to tune in playtests
const TIER_WEIGHTS={"common":0.50,"uncommon":0.28,"rare":0.15,"epic":0.05,"legendary":0.02} # SPEC (tokens.json dropWeight)

const DROPS={
 "vase_item_chance":0.04,           # GUESS: chance a smashed vase also yields a Common/Uncommon item
 "vase_tiers":["common","uncommon"], # SPEC
 "shop_tiers":["common","uncommon","rare","epic"], # SPEC: every tier except Legendary
 "shop_price":{"common":15,"uncommon":25,"rare":40,"epic":65,"legendary":150}, # GUESS: carried over from the old shop prices
 "rng_seed_offset":6100417          # item RNG stream, separate from game.rng so gem/weapon rolls are untouched
}

const T={
 # ---- batch 1: stat items
 "whetstone":{"damage":0.10},                                    # SPEC
 "pilgrims_sandals":{"speed":0.08},                              # SPEC
 "knucklebone":{"crit":0.05},                                    # SPEC
 "salted_pork":{"max_health":20.0},                              # SPEC
 "tallow_candle":{"regen":2.0},                                  # SPEC
 "flagellants_cord":{"haste":0.10},                              # SPEC
 "tithe_purse":{"gold_gain":0.15},                               # SPEC
 "bone_reliquary":{"xp":0.08},                                   # SPEC
 "crowsfoot_charm":{"evasion":0.12},                             # SPEC base; stacking 1-(1-x)^n is a GUESS ("diminishing returns")
 "rosary_teeth":{"crit":0.05,"crit_damage":0.10},                # SPEC
 "grave_salt":{"max_health":15.0,"armor":1.0},                   # SPEC hp; GUESS: 1 armour = 4.8% reduction under 100/(100+5a), the nearest to "+5% armour"
 "hex_penny":{"vase_gold":0.20},                                 # SPEC
 "bitter_wine":{"damage":0.20,"max_health_pct":-0.10},           # SPEC
 "bloodletting_knife":{"damage":0.25,"max_health":-15.0},        # SPEC
 "executioners_hood":{"bonus":0.20,"above":0.90},                # SPEC
 "bounty_writ":{"bonus":0.15},                                   # SPEC (elites and bosses)
 "brutes_gauntlet":{"bonus":0.20,"radius":4.0},                  # SPEC bonus; GUESS radius 4 m ("close range")
 "plague_mask":{"bonus":0.20},                                   # SPEC
 "pilgrims_pack":{"count":1.0},                                  # SPEC
 "max_health_floor":10.0,                                        # GUESS: max HP can never drop below this (Bitter Wine, Bloodletting Knife, Devil's Bargain)
 "evasion_cap":0.75,                                             # existing hurt() cap
 # ---- batch 2: event procs
 "rusted_key":{"chance":0.10,"cap":0.75},                        # SPEC; GUESS cap on stacked chance
 "hermits_ember":{"still_time":1.0,"heal_pct":0.03},             # SPEC (per second after 1 s of standing still)
 "mourners_veil":{"speed":0.05,"hurt_speed":0.25,"hurt_time":2.0}, # SPEC; GUESS: "+25% more" read as +0.25 speed
 "gravediggers_spade":{"chance":0.15,"cap":0.75},                # SPEC; GUESS cap
 "cracked_hourglass":{"seconds":2.0},                            # SPEC
 "tax_ledger":{"per_chest":0.025},                               # SPEC
 "pyre_ashes":{"chance":0.03,"heal_pct":0.15,"pickup_cap":10,"pickup_life":30.0,"pickup_radius":1.4}, # SPEC chance/heal; GUESS pool cap, life, radius
 "thunderstruck_nail":{"radius":6.0,"stun":1.5,"cooldown":3.0,"boss_stun":0.5}, # GUESS all (text only says "stuns nearby enemies")
 "restless_bones":{"wraiths":2,"life":8.0,"speed":9.0,"damage":12.0,"damage_per_level":0.5,"hit_radius":1.3,"hit_cooldown":0.5,"cap":12,"search":16.0}, # SPEC count/life; GUESS the rest
 "forgemasters_tongs":{"discount":0.20,"cap":0.8},               # SPEC; GUESS cap on stacks
 "leaden_heart":{"damage":0.10,"time":15.0},                     # SPEC
 "soul_lantern":{"chance":0.12,"cap":0.75},                      # SPEC; GUESS cap
 "cartographers_candle":{"reveal":true},                         # SPEC
 "black_candle":{"radius":3.0,"dps":5.0,"level_scale":0.04,"interval":0.5}, # SPEC radius/dps; GUESS +4% per player level, 0.5 s tick
 "witch_bottle":{"chance":0.20,"cap":0.60},                      # SPEC chance; GUESS cap so the player is never fully immune
 # ---- batch 3: gem and status items
 "tinder_pouch":{"bonus":0.15},                                  # SPEC
 "rime_shard":{"chill_longer":0.50,"shatter_radius":1.0},        # SPEC
 "lepers_bell":{"bonus":0.20},                                   # SPEC
 "lodestone":{"bonus":0.25},                                     # SPEC
 "mire_flask":{"chance":0.15,"radius":2.2,"life":4.0,"dps":8.0,"interval":0.5,"cap":24,"cooldown":0.25}, # SPEC chance; GUESS puddle numbers
 "gem_loupe":{"longer":0.30,"harder":0.30},                      # SPEC
 "alchemist_retort":{"radius":0.30,"cooldown":0.25},             # SPEC
 "heretics_prism":{"bonus":0.50,"heal":1.0},                     # SPEC
 "goat_skull":{"chance":0.10,"radius":3.0},                      # SPEC
 "coven_sigil":{"per_status":0.15,"cap":0.60},                   # SPEC
 "witch_hunters_brand":{"armor_each":0.4,"armor_cap":8.0,"lifesteal_each":0.002,"lifesteal_cap":0.04,"interval":0.5}, # GUESS all ("armour and lifesteal for every burning enemy")
 # ---- batch 4: build-defining
 "saints_finger":{"extra_rolls":1},                              # SPEC
 "butchers_hook":{"chance":0.15,"mult":2.0},                     # SPEC
 "blood_chalice":{"chance":0.20,"heal_pct":0.02},                # SPEC
 "shade_cloak":{"mult":2.0,"time":3.0,"haste":0.25,"speed":0.25}, # SPEC mult/time; GUESS haste/speed
 "hound_whistle":{"distance":15.0,"speed":22.0,"length":14.0,"damage":20.0,"damage_per_level":1.0,"hit_radius":1.3,"cap":8}, # SPEC distance; GUESS rest
 "hangmans_noose":{"percent":0.25,"interval":0.5,"search":14.0,"elite_percent":0.06}, # SPEC 25%/s of max HP; GUESS elite cap 6%/s
 "martyrs_shroud":{"max_bonus":0.60},                            # SPEC
 "shattered_codex":{"damage":8.0,"damage_per_level":0.4,"radius":1.1,"hit_cooldown":0.4,"checks_per_frame":16}, # GUESS all
 "reapers_sickle":{"souls":2,"damage":15.0,"damage_per_level":0.6,"speed":14.0,"life":3.0,"hit_radius":1.1,"cap":48}, # SPEC count; GUESS rest
 "powder_keg_heart":{"chance":0.25,"fraction":0.65,"radius":3.0,"per_second":20}, # SPEC chance/fraction; GUESS radius and per-second cap
 "headsmans_oath":{"chance":0.01,"per_execution":0.01,"elite_percent":0.25}, # SPEC; GUESS: elites lose 25% max HP instead of dying outright
 "hourglass_damned":{"freeze":5.0,"heal_to":0.50},               # SPEC
 "anvil_first_forge":{"extra":1},                                # SPEC; GUESS reading: a free extra random upgrade stat from the weapon's own pool
 "devils_bargain":{"hp":5.0,"damage":0.04},                      # SPEC
 "ouija_planchette":{"chance":0.03,"mult":10.0,"boss_cap":0.03,"elite_cap":0.10}, # SPEC; GUESS caps (fraction of max HP) for bosses/elites
 "bounds":{"max_stacks":99}                                      # GUESS: sanity clamp for debug-granted stacks
}

static func t(id: String) -> Dictionary:return T.get(id,{})
static func v(id: String,key: String,fallback: float=0.0) -> float:return float(T.get(id,{}).get(key,fallback))
