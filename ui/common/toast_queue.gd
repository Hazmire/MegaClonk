class_name ToastQueue
extends RefCounted
# Logic of the in-run notification queue (gem and item pickups). No visuals: a view reads `current` and asks for the next
# toast when `tick()` reports it finished. Rules from the design: a toast shows for at least MIN_SHOW seconds, pickups of
# the same key merge into one toast ("×2"), merging also applies to the toast being shown, and the waiting line is capped.
const MIN_SHOW=1.2
const DURATION=2.6
const CAP=6
var waiting: Array=[] # {key, count, data}
var current: Dictionary={}
var age=0.0
var merged_into_current=false
func push(key: String,data: Dictionary={}) -> void:
 if not current.is_empty() and current.key==key:
  current.count+=1;merged_into_current=true;return
 for w in waiting:
  if w.key==key:w.count+=1;return
 if waiting.size()>=CAP:waiting[waiting.size()-1].count+=1;return # full: fold into the last waiting toast, never grow
 waiting.append({"key":key,"count":1,"data":data})
# Pops the next waiting toast into `current` (the view calls this when it is idle). Returns false when nothing waits.
func start_next() -> bool:
 if not current.is_empty() or waiting.is_empty():return false
 current=waiting.pop_front();age=0.0;merged_into_current=false;return true
# Advances the shown toast. Returns the finished toast (a non-empty Dictionary) on the frame it ends, otherwise {}.
# With pickups waiting a toast leaves after MIN_SHOW; otherwise it shows its full DURATION.
func tick(delta: float) -> Dictionary:
 if current.is_empty():return {}
 age+=delta
 if age>=(MIN_SHOW if not waiting.is_empty() else DURATION):
  var done=current;current={};age=0.0;return done
 return {}
func busy() -> bool:return not current.is_empty() or not waiting.is_empty()
func clear() -> void:waiting.clear();current={};age=0.0
