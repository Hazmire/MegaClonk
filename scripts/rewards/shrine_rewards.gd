class_name ShrineRewards
extends RefCounted
const TABLE=preload("res://assets/config/stat_rewards.tres")
const DESCRIPTIONS={"damage":"Increases damage dealt by all weapons.","speed":"Increases movement speed.","max_health":"Increases maximum health and heals the added amount.","crit":"Increases critical hit chance, capped at 100%.","haste":"Increases weapon attack speed.","pickup":"Increases the XP attraction radius.","xp":"Increases experience gained.","armor":"Reduces incoming damage through existing armour rules.","regen":"Restores additional health per second."}
static func roll_tier(rng: RandomNumberGenerator) -> String:
 var roll=rng.randf()*100
 for tier in Rarity.IDS:
  roll-=Rarity.TIERS[tier].weight
  if roll<0:return tier
 return "legendary"
static func generate(stats: Dictionary,rng: RandomNumberGenerator,golden: bool=false) -> Array:
 var available=[];var result=[]
 for stat in TABLE.bonuses:
  if stats.has(stat) and float(stats[stat])<float(TABLE.caps.get(stat,INF))-0.000001:available.append(stat)
 for i in mini(3,available.size()):
  var index=rng.randi_range(0,available.size()-1);var stat=available.pop_at(index);var tier="legendary" if golden else roll_tier(rng)
  var amount=minf(float(TABLE.bonuses[stat][Rarity.IDS.find(tier)]),float(TABLE.caps.get(stat,INF))-float(stats[stat]))
  result.append({"stat":stat,"amount":amount,"rarity":tier,"description":DESCRIPTIONS.get(stat,"Increases "+str(stat)),"before":float(stats[stat]),"after":float(stats[stat])+amount})
 return result
static func apply(game: Node,choice: Dictionary) -> void:
 var stat=str(choice.stat);var amount=minf(float(choice.amount),maxf(0,float(TABLE.caps.get(stat,INF))-float(game.stats[stat])))
 game.stats[stat]+=amount
 if stat=="max_health":game.health=minf(game.stats.max_health,game.health+amount)
static func present_next(game: Node) -> bool:
 if game.active_shrine_reward.is_empty():
  if game.shrine_reward_queue.is_empty():return false
  game.active_shrine_reward=game.shrine_reward_queue.pop_front()
  # A preceding queued choice may have consumed some of a shared stat cap.
  # Clamp before this menu opens; keep its stat and rarity, never reroll.
  var eligible=[]
  for choice in game.active_shrine_reward.choices:
   var amount=minf(float(choice.amount),maxf(0,float(TABLE.caps.get(choice.stat,INF))-float(game.stats[choice.stat])))
   if amount<=0:continue
   choice.amount=amount;choice.before=float(game.stats[choice.stat]);choice.after=choice.before+amount;eligible.append(choice)
  game.active_shrine_reward.choices=eligible
 RewardScreens.shrine(game.frontend,game.active_shrine_reward);return true
static func select(game: Node,index: int) -> bool:
 if game.mode!="shrine" or game.active_shrine_reward.is_empty():return false
 var choices=game.active_shrine_reward.choices
 if index<0 or index>=choices.size():return false
 apply(game,choices[index]);game.active_shrine_reward={};game.play_sound("level");game.resume();return true

static func bonus_text(choice: Dictionary) -> String:
 var amount=float(choice.amount)
 if choice.stat=="max_health":return "+%s HP"%number(amount)
 if choice.stat=="armor":return "+%s"%number(amount)
 if choice.stat=="regen":return "+%s HP/s"%number(amount)
 return "+%s%%"%number(amount*100)

static func number(value: float) -> String:
 var text=String.num(value,2)
 return text.rstrip("0").rstrip(".") if text.contains(".") else text

static func stat_name(stat: String) -> String:
 return {"damage":"Damage","speed":"Movement speed","crit":"Critical chance","haste":"Attack speed","xp":"XP gain","regen":"Regeneration","pickup":"Pickup radius","armor":"Armour","max_health":"Maximum health"}.get(stat,stat.replace("_"," ").capitalize())
