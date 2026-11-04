class_name EndlessTimerStyle
extends RefCounted
# The endless timer's look as data: glitch timing, line colours, and the four tiers (digits, edge, glow, pulse, smoulder, twitch, embers, smoke).
# Source: assets/config/endless_timer_style.json. Nothing about the tiers is decided in code branches.
const PATH="res://assets/config/endless_timer_style.json"
static var cache: Dictionary={}
static func data() -> Dictionary:
 if cache.is_empty():cache=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return cache
static func tiers() -> Array:return data().tiers
# Index of the tier in force at the given endless seconds.
static func tier_index(seconds: float) -> int:
 var index=0
 for i in tiers().size():
  if seconds>=float(tiers()[i].from_s):index=i
 return index
