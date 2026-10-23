class_name StageClock
extends RefCounted
const RULES=preload("res://assets/config/run_rules.tres")
# Remaining-time thresholds; crossing several in one tick never loses an event.
const DURATION=600.0
const EVENTS=[{"id":"rush_1","remaining":480.0},{"id":"miniboss_1","remaining":420.0},{"id":"rush_2","remaining":240.0},{"id":"miniboss_2","remaining":180.0},{"id":"endless","remaining":0.0}]
var fired: Dictionary={}
var elapsed=0.0
var rush_until=0.0
func reset() -> void:
 fired.clear();elapsed=0; rush_until=0
func advance(seconds: float) -> Array[String]:
 elapsed+=maxf(0,seconds)
 var result: Array[String]=[]
 for event in EVENTS:
  if remaining()<=event.remaining and not fired.has(event.id):
   fired[event.id]=true;result.append(event.id)
   if event.id.begins_with("rush"):rush_until=maxf(rush_until,DURATION-event.remaining+RULES.rush_seconds)
 return result
func remaining() -> float:return maxf(0,DURATION-elapsed)
func endless() -> bool:return fired.has("endless")
func pressure() -> float:
 var base=lerpf(1,RULES.late_stage_pressure,clampf(elapsed/DURATION,0,1))
 if elapsed<rush_until:base=maxf(base,RULES.first_rush_pressure if elapsed<300 else RULES.second_rush_pressure)
 if endless():base+=minf(6,(elapsed-DURATION)/RULES.endless_pressure_seconds)
 return base
func serialize() -> Dictionary:return {"elapsed":elapsed,"fired":fired.duplicate(),"rush_until":rush_until}
func restore(data: Dictionary, fallback_elapsed: float=0) -> void:
 reset();elapsed=maxf(0,float(data.get("elapsed",fallback_elapsed)))
 fired=data.get("fired",{}).duplicate();rush_until=float(data.get("rush_until",0))
 # Old checkpoints must not replay events that happened before this scheduler existed.
 if not data.has("fired"):
  for event in EVENTS:
   if remaining()<=event.remaining:fired[event.id]=true
