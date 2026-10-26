class_name RewardSelector
extends RefCounted
# Caller supplies context eligibility (unlocks, slots, banishes); selector also
# rejects malformed/maxed candidates. No save mutation or global random source.
static func eligible(candidate: Dictionary) -> bool:
 var meta=candidate.get("metadata",{})
 return not meta.is_empty() and Rarity.valid(str(meta.get("rarity",""))) and candidate.get("enabled",true) and (int(meta.get("max_level",0))==0 or int(meta.get("level",0))<int(meta.max_level))
static func choose(candidates: Array,rng: RandomNumberGenerator,weights: Dictionary={}) -> Dictionary:
 var buckets={};var total=0.0
 for candidate in candidates:
  if not eligible(candidate):continue
  var tier=str(candidate.metadata.rarity)
  if not buckets.has(tier):buckets[tier]=[]
  buckets[tier].append(candidate)
 for tier in Rarity.IDS:
  if buckets.has(tier):total+=maxf(0,float(weights.get(tier,Rarity.TIERS[tier].weight)))
 if total<=0:return {}
 var roll=rng.randf()*total;var last=""
 for tier in Rarity.IDS:
  if not buckets.has(tier):continue
  var weight=maxf(0,float(weights.get(tier,Rarity.TIERS[tier].weight)))
  if weight<=0:continue
  last=tier;roll-=weight
  if roll<0:return buckets[tier][rng.randi_range(0,buckets[tier].size()-1)].duplicate(true)
 return buckets[last][rng.randi_range(0,buckets[last].size()-1)].duplicate(true)
static func draw(candidates: Array,count: int,rng: RandomNumberGenerator,weights: Dictionary={}) -> Array:
 var remaining=candidates.duplicate();var result=[]
 for i in count:
  var selected=choose(remaining,rng,weights)
  if selected.is_empty():break
  result.append(selected)
  for j in range(remaining.size()-1,-1,-1):
   if remaining[j].metadata.uid==selected.metadata.uid:remaining.remove_at(j)
 return result
static func items(ids: Array) -> Array:
 var result=[]
 for id in ids:result.append({"id":int(id),"metadata":RewardCatalog.entry("items",id)})
 return result
