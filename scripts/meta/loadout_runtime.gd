class_name LoadoutRuntime
extends RefCounted
var trait_id="climber"
var ultimate_id="nova"
var cooldown=0.0
var remaining=0.0
var movement_charge=0.0
var still_charge=0.0
var uses=0
func reset(trait_value: String, ultimate_value: String) -> void:
 trait_id=trait_value; ultimate_id=ultimate_value; cooldown=0; remaining=0; movement_charge=0; still_charge=0; uses=0
func tick(game: Node, delta: float) -> void:
 cooldown=maxf(0,cooldown-delta)
 remaining=maxf(0,remaining-delta)
 var moving=Vector2(game.player.velocity.x,game.player.velocity.z).length()>1
 movement_charge=clampf(movement_charge+(delta if moving else -delta*2),0,20)
 still_charge=clampf(still_charge+(-delta*3 if moving else delta),0,6)
 game.player.can_climb=trait_id=="climber"
 game.player.can_glide=trait_id=="glider"
 game.player.movement_multiplier=2.0 if remaining>0 and ultimate_id=="ghost" else 1.0
 game.player.jump_multiplier=2.25 if remaining>0 and ultimate_id=="ghost" else 1.0
 game.ability_visual(ultimate_id if remaining>0 and ultimate_id in ["ghost","berserk"] else "base")
 if Input.is_action_just_pressed("ultimate"): activate(game)
func damage_multiplier() -> float:
 var value=1.0
 if trait_id=="momentum": value+=movement_charge/20*0.5
 if trait_id=="sentry": value+=still_charge/6*0.6
 if remaining>0 and ultimate_id=="berserk": value*=2
 return value
func immune() -> bool: return remaining>0 and ultimate_id=="ghost"
func incoming_multiplier() -> float: return 0.5 if remaining>0 and ultimate_id=="berserk" else 1.0
func activate(game: Node) -> bool:
 if cooldown>0 or game.mode!="run": return false
 var definition=LoadoutCatalog.entry("ultimates",ultimate_id)
 if definition.is_empty(): return false
 cooldown=float(definition.cooldown); remaining=float(definition.duration); uses+=1
 if ultimate_id=="nova":
  game.area(game.player.position,28,180+game.level*20,-2)
  game.flash(game.player.position,Color("ffc77a"),28)
  game.impact(game.player.position,Color("ffdc8b"),16)
 elif ultimate_id=="ghost": game.flash(game.player.position,Color("9bdeff"),4)
 else: game.flash(game.player.position,Color("ff8168"),4)
 game.tone(220,0.3)
 return true
func serialize() -> Dictionary:
 return {"trait":trait_id,"ultimate":ultimate_id,"cooldown":cooldown,"remaining":remaining,"movement_charge":movement_charge,"still_charge":still_charge,"uses":uses}
func restore(data: Dictionary) -> void:
 reset(str(data.get("trait","climber")),str(data.get("ultimate","nova")))
 cooldown=maxf(0,float(data.get("cooldown",0))); remaining=maxf(0,float(data.get("remaining",0)))
 movement_charge=clampf(float(data.get("movement_charge",0)),0,20); still_charge=clampf(float(data.get("still_charge",0)),0,6); uses=int(data.get("uses",0))
