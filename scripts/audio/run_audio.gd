class_name RunAudio
extends RefCounted

# Sound hooks for run-time moments that have no screen of their own: player hurt / low HP / death, boss enrage and stage-boss
# death, gold streaks. Everything here only READS game state; it never touches game.rng or any gameplay value.
const HEAVY_HIT_FRACTION=0.18 # a single hit that takes >= 18 % of max HP plays player_hurt_heavy
const LOW_HP=0.30             # same threshold the HUD overlay uses (RunOverlay.LOW_HP_FRACTION)
const HEARTBEAT_KEY="low_hp_heartbeat"
const VICTORY_DELAY=2.0
# Enrage roar per boss: stage 1 splits by boss (the larger Big Chunkus bellows), then one roar per stage, repeating every 3 stages.
const STAGE_ENRAGE=["world.boss_enrage_beast","world.boss_enrage_shriek","world.boss_enrage_abyssal"]
static var gold_last=-100.0
static var gold_streak=0
static func hurt(game: Node,damage: float) -> void:
 if not is_instance_valid(game.audio):return
 game.audio.emit("player.player_hurt_heavy" if damage>=HEAVY_HIT_FRACTION*float(game.stats.max_health) else "player.damage")
static func low_hp(game: Node) -> void:
 var audio=game.audio
 if not is_instance_valid(audio):return
 var fraction=game.health/maxf(1.0,float(game.stats.max_health))
 if game.health>0.0 and fraction<=LOW_HP:
  if audio.loop_start(HEARTBEAT_KEY,"player.low_hp_heartbeat_loop"):audio.loop_update(HEARTBEAT_KEY,1.0+0.5*clampf(1.0-fraction/LOW_HP,0.0,1.0))
 else:audio.loop_stop(HEARTBEAT_KEY)
static func death(game: Node) -> void:
 if is_instance_valid(game.audio):game.audio.loop_stop(HEARTBEAT_KEY);game.audio.emit("player.player_death")
static func enrage_event(stage: int,encounter: String) -> String:
 if stage==1 and encounter=="chunkus":return "world.boss_enrage_bellow"
 return STAGE_ENRAGE[posmod(stage-1,STAGE_ENRAGE.size())]
# Called from Game.hit after damage: stage bosses (kind 8) roar once when they first fall to the boss bar's ENRAGED line.
static func check_enrage(game: Node,e: Dictionary) -> void:
 if e.hp<=0.0 or e.get("enraged",false) or e.hp>e.max_hp*BossBar.LOW:return
 e["enraged"]=true
 if is_instance_valid(game.audio):game.audio.emit(enrage_event(game.stage,str(e.get("variant",{}).get("id",""))),e.pos)
# Called when the LAST living stage boss dies (never for earlier bosses of a multi-boss stage or for minibosses).
static func stage_boss_cleared(game: Node,e: Dictionary) -> void:
 if not is_instance_valid(game.audio):return
 game.audio.emit("world.stage_boss_death",e.pos)
 var audio=game.audio
 game.get_tree().create_timer(VICTORY_DELAY).timeout.connect(func():if is_instance_valid(audio):audio.emit("world.stage_boss_victory"))
# Gold: three rising pitches by streak; the streak resets after 1.2 s without a pickup.
static func gold(game: Node) -> void:
 if not is_instance_valid(game.audio):return
 var now=float(game.audio.clock);var gap=now-gold_last
 gold_streak=gold_streak+1 if (gap>=0.0 and gap<=1.2) else 0
 gold_last=now
 game.audio.emit("pickup.gold",Vector3.INF,1.0,1.0,mini(gold_streak,2))
