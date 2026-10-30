class_name Economy
extends RefCounted
# Economy Rework: the one place for luck, tier odds, prices, shop types, chest cost and upgrade sizes.
# Numbers marked GUESS are tuning proposals, not measured against real play.

# ---- luck (diminishing returns: boost = MAX * luck / (luck + HALF); luck 1 -> +0.20, 2 -> +0.30, 8 -> +0.48, never above MAX)
const LUCK_MAX_BOOST=0.6 # GUESS
const LUCK_HALF=2.0 # GUESS
static func luck_boost(luck: float) -> float:
 var l=maxf(0.0,luck);return LUCK_MAX_BOOST*l/(l+LUCK_HALF)
# 0..1 share of the luck ceiling reached; used for shop-type odds.
static func luck_share(luck: float) -> float:return luck_boost(luck)/LUCK_MAX_BOOST
# Tier weights nudged by luck: Common shrinks, every higher tier grows, the best tiers most (tier index i multiplies the boost).
static func tier_weights(base: Dictionary,luck: float) -> Dictionary:
 var b=luck_boost(luck);var result={}
 for i in Rarity.IDS.size():
  var tier=Rarity.IDS[i];var w=float(base.get(tier,0.0))
  result[tier]=w*(1.0-b) if i==0 else w*(1.0+b*float(i))
 return result

# ---- level caps (number of upgrades a tome / weapon can receive)
const TOME_MAX_LEVEL=80
const WEAPON_MAX_LEVEL=40

# ---- upgrade sizes: every upgrade can roll any tier; the tier only scales how big it is (Common = 1.0).
# Legendary = 14% where Common = 6% for a damage tome, so the top multiplier is 14/6.
const TIER_SCALE={"common":1.0,"uncommon":1.35,"rare":1.7,"epic":2.0,"legendary":2.3333333}
static func tier_scale(tier: String) -> float:return float(TIER_SCALE.get(tier,1.0))
# Whole-number stats (projectile count, bounces) are never scaled.
static func scaled(base: float,tier: String,whole_number: bool=false) -> float:return base if whole_number else base*tier_scale(tier)
static func tier_from_scale(step: float,base: float) -> String:
 for tier in Rarity.IDS:
  if is_equal_approx(step,base*tier_scale(tier)):return tier
 return ""

# ---- prices: base per tier, grown per stage (GUESS)
const ITEM_PRICE={"common":15,"uncommon":25,"rare":40,"epic":65,"legendary":150}
const STAGE_PRICE_GROWTH=1.6
const GEM_PRICE_TIER="epic" # a socket gem is stocked like a Rare item but costs like an Epic one
static func stage_factor(stage: int) -> float:return pow(STAGE_PRICE_GROWTH,float(maxi(1,stage)-1))
static func item_price(tier: String,stage: int) -> int:return roundi(float(ITEM_PRICE[tier])*stage_factor(stage))
static func gem_price(stage: int) -> int:return item_price(GEM_PRICE_TIER,stage)

# ---- chests: exponential in chests opened this run (GUESS: 15 gold for the first, ~230 for the 15th, ~3,500 for the 30th)
const CHEST_BASE=15.0
const CHEST_GROWTH=1.2
static func chest_cost(opened: int) -> int:return roundi(CHEST_BASE*pow(CHEST_GROWTH,float(maxi(0,opened))))

# ---- shop types. Standard sells every tier (Legendary very rarely), Rare sells Rare and better, Legendary sells only Legendary.
const SHOP_BASE={"rare":0.20,"legendary":0.05} # per shop, at luck 0
const SHOP_LUCK_BONUS={"rare":0.15,"legendary":0.07} # added at the luck ceiling
const MAX_LEGENDARY_SHOPS_PER_STAGE=1 # never lets luck guarantee several
const MIN_STANDARD_SHOPS_PER_STAGE=1
const SHOP_ITEM_TIERS={"Common":["common","uncommon","rare","epic","legendary"],"Rare":["rare","epic","legendary"],"Legendary":["legendary"]}
static func shop_type_odds(luck: float) -> Dictionary:
 var share=luck_share(luck)
 var rare=float(SHOP_BASE.rare)+float(SHOP_LUCK_BONUS.rare)*share
 var legendary=float(SHOP_BASE.legendary)+float(SHOP_LUCK_BONUS.legendary)*share
 return {"Common":1.0-rare-legendary,"Rare":rare,"Legendary":legendary}
static func roll_shop_type(rng: RandomNumberGenerator,luck: float) -> String:
 var odds=shop_type_odds(luck);var roll=rng.randf()
 if roll<float(odds.Legendary):return "Legendary"
 if roll<float(odds.Legendary)+float(odds.Rare):return "Rare"
 return "Common"
# Types for all of a stage's shops, in order. Fairness rules are applied after the rolls.
static func roll_stage_shops(count: int,rng: RandomNumberGenerator,luck: float) -> Array:
 var types=[]
 for i in count:types.append(roll_shop_type(rng,luck))
 var legendary=0
 for i in types.size():
  if types[i]=="Legendary":
   legendary+=1
   if legendary>MAX_LEGENDARY_SHOPS_PER_STAGE:types[i]="Rare"
 if count>=2 and types.count("Common")<MIN_STANDARD_SHOPS_PER_STAGE:types[types.size()-1]="Common"
 return types
static func shop_display_name(tier_name: String) -> String:return "Standard" if tier_name=="Common" else tier_name
