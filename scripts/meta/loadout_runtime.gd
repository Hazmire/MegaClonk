class_name LoadoutRuntime
extends RefCounted
const RULES=preload("res://assets/config/abilities.tres")
var trait_id="climber"
var ultimate_id="nova"
var cooldown=0.0
var remaining=0.0
var movement_charge=0.0
var still_charge=0.0
var stationary_time=0.0
var still_time=0.0
var uses=0
func reset(trait_value: String, ultimate_value: String) -> void:
 trait_id=trait_value;ultimate_id=ultimate_value;cooldown=0;remaining=0;movement_charge=0;still_charge=0;uses=0;stationary_time=0;still_time=0
func tick(game: Node, delta: float) -> void:
 var was_cooling=cooldown>0
 cooldown=maxf(0,cooldown-delta);remaining=maxf(0,remaining-delta)
 if was_cooling and cooldown<=0:game.toast("ULTIMATE READY");game.play_sound("ready")
 var moving=Vector2(game.player.velocity.x,game.player.velocity.z).length()>1
 if moving:movement_charge=minf(RULES.movement_cap/RULES.movement_damage_per_second,movement_charge+delta);stationary_time=0
 else:
  var before=stationary_time;stationary_time+=delta
  movement_charge=maxf(0,movement_charge-(RULES.movement_cap/RULES.movement_damage_per_second)/RULES.movement_decay_seconds*maxf(0,stationary_time-maxf(RULES.movement_grace,before)))
 var intentional=Input.get_vector("left","right","forward","back").length()>0.1 or game.player.posture=="sliding"
 if moving and intentional:still_time=0;still_charge=0
 elif not moving or game.player.hurt_time>0:
  still_time+=delta;still_charge=clampf(still_time-RULES.standing_grace,0,RULES.standing_cap/RULES.standing_damage_per_second)
 game.player.can_climb=trait_id=="climber";game.player.can_glide=trait_id=="glider"
 game.player.movement_multiplier=RULES.ghost_speed_multiplier if remaining>0 and ultimate_id=="ghost" else 1.0
 game.player.jump_multiplier=RULES.ghost_jump_height_multiplier if remaining>0 and ultimate_id=="ghost" else 1.0
 game.ability_visual(ultimate_id if remaining>0 and ultimate_id in ["ghost","berserk"] else "base")
 if Input.is_action_just_pressed("ultimate"):activate(game)
func damage_multiplier() -> float:
 var value=1.0
 if trait_id=="momentum":value+=minf(RULES.movement_cap,movement_charge*RULES.movement_damage_per_second)
 if trait_id=="sentry":value+=minf(RULES.standing_cap,still_charge*RULES.standing_damage_per_second)
 if remaining>0 and ultimate_id=="berserk":value*=RULES.berserk_damage_multiplier
 return value
func immune() -> bool:return remaining>0 and ultimate_id=="ghost"
func incoming_multiplier() -> float:return RULES.berserk_incoming_multiplier if remaining>0 and ultimate_id=="berserk" else 1.0
func activate(game: Node) -> bool:
 if cooldown>0 or remaining>0 or game.mode!="run":return false
 var definition=LoadoutCatalog.entry("ultimates",ultimate_id)
 if definition.is_empty():return false
 cooldown=float(definition.cooldown);remaining=float(definition.duration);uses+=1
 if ultimate_id=="nova":
  var base=(float(Catalog.WEAPONS.get(game.selected_weapon,Catalog.WEAPONS[0])[2]))*RULES.nova_base_multiplier
  game.area(game.player.position,RULES.nova_radius,base,-2)
  for e in game.nearby(game.player.position,RULES.nova_radius):e.knock+=(e.pos-game.player.position).normalized()*8
  game.flash(game.player.position,Color("ffc77a"),15)
  game.combat_fx.burst("explosion_small",game.player.position,5)
  if game.settings.shake:game.player.camera.h_offset=0.3
 elif ultimate_id=="ghost":game.flash(game.player.position,Color("9bdeff"),4)
 else:game.flash(game.player.position,Color("ff8168"),4)
 game.play_sound("explosion");return true
func serialize() -> Dictionary:
 return {"trait":trait_id,"ultimate":ultimate_id,"cooldown":cooldown,"remaining":remaining,"movement_charge":movement_charge,"still_charge":still_charge,"stationary_time":stationary_time,"still_time":still_time,"uses":uses}
func restore(data: Dictionary) -> void:
 reset(str(data.get("trait","climber")),str(data.get("ultimate","nova")))
 cooldown=maxf(0,float(data.get("cooldown",0)));remaining=maxf(0,float(data.get("remaining",0)))
 movement_charge=clampf(float(data.get("movement_charge",0)),0,20);still_charge=clampf(float(data.get("still_charge",0)),0,10);uses=int(data.get("uses",0))
 stationary_time=float(data.get("stationary_time",0));still_time=float(data.get("still_time",still_charge+1))
