class_name GemInventory
extends RefCounted

# Dedicated socket-gem inventory: stackable counts per element, separate from the weapon
# and tome slots. One instance lives on the game for the current run only.
var counts: Dictionary = {}

func _init() -> void:
 reset()
func reset() -> void:
 counts={}
 for id in Elements.IDS:counts[id]=0
func count(element: String) -> int:
 return int(counts.get(element,0))
func total() -> int:
 var sum=0
 for id in Elements.IDS:sum+=count(id)
 return sum
func add(element: String, amount: int = 1) -> bool:
 if not Elements.valid(element) or amount<=0:return false
 counts[element]=count(element)+amount
 return true
# All-or-nothing: never leaves a negative or partially removed stack.
func remove(element: String, amount: int = 1) -> bool:
 if not Elements.valid(element) or amount<=0 or count(element)<amount:return false
 counts[element]=count(element)-amount
 return true
func serialize() -> Dictionary:
 var data={}
 for id in Elements.IDS:data[id]=count(id)
 return data
# Tolerates missing, unknown or malformed entries so an old or edited save cannot break a run.
func restore(data: Variant) -> void:
 reset()
 if not data is Dictionary:return
 for id in Elements.IDS:
  counts[id]=maxi(0,int(data.get(id,0)))
