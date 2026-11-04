class_name WorldTime
extends RefCounted

# Centralised time-modifier for the Stopwatch power-up. It never touches Engine.time_scale:
# the player, weapons, camera, UI and music keep running on the real physics delta, and only
# hostile systems ask for hostile(delta). One instance lives on the game.
#
# Rules (initial balance, see TUNING):
#  - Collecting a Stopwatch sets the remaining time to the full duration. It never adds time
#    and never multiplies the slow, so repeated pickups refresh instead of stacking.
#  - The duration counts down in real time and only while the run is active, so menus,
#    level-up screens, pauses and stage transitions can never eat or corrupt the effect.
# HOSTILE_SCALE 0.0: the Stopwatch freezes hostile time completely (spec SPEC). Enemies, bosses, ghosts, hostile projectiles and spawners get delta*0.
const HOSTILE_SCALE=0.0
const TUNING={"duration":8.0,"world_speed":HOSTILE_SCALE}

var remaining=0.0
var scale=1.0
var bonus=0.0 # Cracked Hourglass: extra seconds on the current effect
var just_released=false # true for the one tick on which the effect expired (enemies jolt for a frame)
var hard_resets=0 # bumped by reset() (run/stage start/end), never by a normal expiry: the look snaps off on it

func active() -> bool:
 return remaining>0.0
# True while hostile time is stopped dead (the Stopwatch and the Hourglass of the Damned).
func frozen() -> bool:
 return remaining>0.0 and scale<=0.0
# Scales a delta for enemies, bosses, hostile projectiles, hostile timers and spawning.
func hostile(delta: float) -> float:
 return delta*scale
# Starts or refreshes the effect. Returns true when this started a new effect.
func activate(extra: float=0.0) -> bool:
 var started=not active()
 remaining=float(TUNING.duration)+maxf(0.0,extra);bonus=maxf(0.0,extra);scale=float(TUNING.world_speed)
 return started
# Hourglass of the Damned: hostile time stops completely (scale 0) for `seconds`. Same system as the Stopwatch.
func freeze(seconds: float) -> void:
 remaining=seconds;scale=0.0;bonus=0.0
# Real-time countdown. Called once per active physics tick.
func tick(delta: float) -> void:
 just_released=false
 if remaining<=0.0:
  scale=1.0;return
 remaining-=delta
 if remaining<=0.0:remaining=0.0;scale=1.0;bonus=0.0;just_released=true
# Restores normal speed cleanly; called on expiry, stage builds, run start and run end.
func reset() -> void:
 remaining=0.0;scale=1.0;bonus=0.0;just_released=false;hard_resets+=1
func fraction() -> float:
 return clampf(remaining/(float(TUNING.duration)+bonus),0.0,1.0)
func serialize() -> Dictionary:
 return {"remaining":remaining,"scale":scale}
func restore(data: Variant) -> void:
 reset()
 if not data is Dictionary:return
 var left=clampf(float(data.get("remaining",0.0)),0.0,float(TUNING.duration)+60.0)
 if left>0.0:remaining=left;scale=clampf(float(data.get("scale",TUNING.world_speed)),0.0,1.0)
