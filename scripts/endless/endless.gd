class_name Endless
extends RefCounted
# Endless mode rules and curves. Every number lives in assets/config/endless_rules.json; this class only evaluates it.
# Times are endless minutes (0 = the moment the stage clock reached 0:00). Nothing has a ceiling except the live ghost cap, which only
# limits how many ghosts exist: when it is reached, damage and speed keep climbing instead.
const LOCK_PORTAL=true # once the ghosts come the portal seals and cannot open again; set false to allow escape
const GHOST_KIND=14
const PATH="res://assets/config/endless_rules.json"
static var cache: Dictionary={}
static func data() -> Dictionary:
 if cache.is_empty():cache=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return cache
static func tiers() -> Array:return data().tiers
static func tier(index: int) -> Dictionary:return data().tiers[clampi(index,0,data().tiers.size()-1)]
static func cap() -> int:return int(data().ghost_cap)
# Ghosts in one wave at endless minute m (before the Difficulty stat), and the average ghosts per second that works out to.
static func wave_count(minutes: float) -> float:
 var s=data().spawn;return float(s.wave_base)*pow(float(s.wave_growth_per_min),maxf(0.0,minutes))
static func wave_interval() -> float:return float(data().spawn.wave_interval_s)
static func spawn_rate(minutes: float) -> float:return wave_count(minutes)/wave_interval()
# Base flight speed (m/s) at endless minute m: slow and steady until the knee (it passes the player's run speed there), then much faster.
static func base_speed(minutes: float) -> float:
 var s=data().speed;var m=maxf(0.0,minutes);var knee=float(s.knee_min)
 return float(s.start)+float(s.slope_early)*minf(m,knee)+float(s.slope_late)*maxf(0.0,m-knee)
static func base_hp(minutes: float) -> float:
 var h=data().hp;return float(h.base)*pow(float(h.growth_per_min),maxf(0.0,minutes))
static func base_damage(minutes: float) -> float:
 var d=data().damage;return float(d.base)*pow(float(d.growth_per_min),maxf(0.0,minutes))
static func tier_speed(tier_index: int,minutes: float) -> float:return base_speed(minutes)*float(tier(tier_index).speed)
static func tier_hp(tier_index: int,minutes: float) -> float:return base_hp(minutes)*float(tier(tier_index).hp)
static func tier_damage(tier_index: int,minutes: float) -> float:return base_damage(minutes)*float(tier(tier_index).damage)
static func tier_joined(tier_index: int,minutes: float) -> bool:return minutes>=float(tier(tier_index).join_min)
# Picks the tier of the next ghost from the tiers that have joined, weighted. New tiers join the mix; earlier ones keep spawning.
static func choose_tier(minutes: float,rng: RandomNumberGenerator) -> int:
 var total=0.0
 for i in tiers().size():
  if tier_joined(i,minutes):total+=float(tier(i).weight)
 var roll=rng.randf()*total
 for i in tiers().size():
  if not tier_joined(i,minutes):continue
  roll-=float(tier(i).weight)
  if roll<=0.0:return i
 return 0
# "M:SS" or "H:MM:SS" for the endless timer; never rolls over.
static func clock(seconds: float) -> String:
 var s=maxi(0,int(seconds));var h=s/3600
 return "%d:%02d:%02d"%[h,(s/60)%60,s%60] if h>0 else "%02d:%02d"%[s/60,s%60]
