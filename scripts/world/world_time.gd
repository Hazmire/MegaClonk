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
const TUNING={"duration":8.0,"world_speed":0.20}

var remaining=0.0
var scale=1.0
var bonus=0.0 # Cracked Hourglass: extra seconds on the current effect

func active() -> bool:
 return remaining>0.0
# Scales a delta for enemies, bosses, hostile projectiles, hostile timers and spawning.
func hostile(delta: float) -> float:
 return delta*scale
# Starts or refreshes the effect. Returns true when this started a new effect.
func activate(extra: float=0.0) -> bool:
 var started=not active()
 remaining=float(TUNING.duration)+maxf(0.0,extra);bonus=maxf(0.0,extra);scale=float(TUNING.world_speed)
 return started
# Real-time countdown. Called once per active physics tick.
func tick(delta: float) -> void:
 if remaining<=0.0:
  scale=1.0;return
 remaining-=delta
 if remaining<=0.0:reset()
# Restores normal speed cleanly; called on expiry, stage builds, run start and run end.
func reset() -> void:
 remaining=0.0;scale=1.0;bonus=0.0
func fraction() -> float:
 return clampf(remaining/(float(TUNING.duration)+bonus),0.0,1.0)
func serialize() -> Dictionary:
 return {"remaining":remaining}
func restore(data: Variant) -> void:
 reset()
 if not data is Dictionary:return
 var left=clampf(float(data.get("remaining",0.0)),0.0,float(TUNING.duration)+60.0)
 if left>0.0:remaining=left;scale=float(TUNING.world_speed)
