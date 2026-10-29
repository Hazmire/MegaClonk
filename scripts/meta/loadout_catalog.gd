class_name LoadoutCatalog
extends RefCounted
const TRAITS=[
 {"id":"climber","name":"Wall Climber","description":"Move forward against walls to climb.","goal":0,"cost":0},
 {"id":"momentum","name":"Momentum","description":"Movement builds damage, up to +40%. Stopping drains it.","goal":0,"cost":0},
 {"id":"sentry","name":"Unmoving Force","description":"Stand still to build up to +50% damage.","goal":0,"cost":0},
 {"id":"glider","name":"Glider","description":"Hold Jump while falling to glide and steer.","goal":0,"cost":0},
 {"id":"seer","name":"Cartographer","description":"Begin with the entire minimap revealed.","goal":0,"cost":0}
]
const ULTIMATES=[
 {"id":"nova","name":"Cataclysm","description":"A devastating 15m explosion. 90 second cooldown.","cooldown":90.0,"duration":0.0,"goal":0,"cost":0},
 {"id":"berserk","name":"Berserker","description":"12 seconds: +75% damage and 30% less incoming damage.","cooldown":90.0,"duration":12.0,"goal":0,"cost":0},
 {"id":"ghost","name":"Ghost Form","description":"8 seconds: invulnerable, +100% speed, +100% jump height.","cooldown":120.0,"duration":8.0,"goal":0,"cost":0}
]
const QUESTS=[
 {"id":"first_hunt","name":"First blood","category":"Hunting","metric":"kills","target":40,"credits":20,"gold":25},
 {"id":"hunter","name":"The hundred","category":"Hunting","metric":"kills","target":100,"credits":35,"gold":40},
 {"id":"horde","name":"Horde breaker","category":"Hunting","metric":"kills","target":500,"credits":75,"gold":100},
 {"id":"sword","name":"Steel resolve","category":"Arsenal","metric":"weapon:0","target":60,"credits":40,"gold":45},
 {"id":"fire","name":"Firestarter","category":"Arsenal","metric":"weapon:1","target":60,"credits":40,"gold":45},
 {"id":"bow","name":"True aim","category":"Arsenal","metric":"weapon:6","target":80,"credits":50,"gold":55},
 {"id":"survive","name":"Hold the line","category":"Survival","metric":"survival","target":180,"credits":30,"gold":35},
 {"id":"endure","name":"Beyond midnight","category":"Survival","metric":"survival","target":360,"credits":60,"gold":75},
 {"id":"speed","name":"Before the fifth bell","category":"Survival","metric":"fast_clear","target":1,"credits":90,"gold":100},
 {"id":"warden","name":"Warden breaker","category":"Exploration","metric":"bosses","target":1,"credits":50,"gold":60},
 {"id":"treasure","name":"Treasure trail","category":"Exploration","metric":"chests","target":6,"credits":40,"gold":50},
 {"id":"ultimate","name":"Unleashed","category":"Arsenal","metric":"ultimates","target":5,"credits":35,"gold":40}
]
const EXTRA_QUESTS=[
 {"id":"revolver","name":"Six shooter","category":"Arsenal","metric":"weapon:7","target":100,"credits":0,"gold":0,"silver":150},
 {"id":"champion","name":"Champion slayer","category":"Hunting","metric":"minibosses","target":1,"credits":0,"gold":0,"silver":150},
 {"id":"stage2","name":"Into the deep forest","category":"Exploration","metric":"stage","target":2,"credits":0,"gold":0,"silver":200},
 {"id":"endless_mode","name":"After the final bell","category":"Survival","metric":"endless","target":1,"credits":0,"gold":0,"silver":200},
 {"id":"early_exit","name":"Ahead of the darkness","category":"Survival","metric":"early_stage","target":1,"credits":0,"gold":0,"silver":200},
 {"id":"legendary_shop","name":"A fabled bargain","category":"Exploration","metric":"legendary_shop","target":1,"credits":0,"gold":0,"silver":250}
]
static func quests() -> Array:
 var result=QUESTS+EXTRA_QUESTS
 for id in Catalog.ACTIVE_WEAPONS:
  result.append({"id":"mastery_"+str(id),"name":Catalog.WEAPONS[id][0]+" mastery","category":"Arsenal","metric":"weapon:"+str(id),"target":100,"credits":0,"gold":0,"silver":150})
 return result
static func quest_reward(q: Dictionary) -> int:return int(q.get("silver",int(q.credits)+int(q.gold)))
static func entries(category: String) -> Array:
 var result: Array=[]
 match category:
  "weapons":
   for i in Catalog.ACTIVE_WEAPONS:
    var w=Catalog.WEAPONS[i]
    result.append({"id":str(i),"name":w[0],"description":"%s • %.0f damage • %.2fs cooldown"%[w[1],w[2],w[3]],"goal":0,"cost":0 if i in [0,1,6,7] else 15+i*3})
  "tomes":
   var requirements={"Multishot":[100,100],"Colossus":[150,100],"Vampire":[250,150],"Greed":[60,75]}
   for id in Catalog.ACTIVE_TOMES:
    var requirement=requirements.get(id,[0,0])
    result.append({"id":id,"name":Catalog.tome_name(id),"description":Catalog.tome_description(id),"goal":requirement[0],"cost":requirement[1]})
  "traits": result=TRAITS.duplicate(true)
  "ultimates": result=ULTIMATES.duplicate(true)
  "items":
   for id in Catalog.ITEM_IDS:
    var item=Catalog.ITEMS[id]
    result.append({"id":str(id),"name":str(item.name),"description":Catalog.item_description(id),"goal":0,"cost":0}) # every item starts unlocked; unlock conditions come later
 return result
static func entry(category: String, id: String) -> Dictionary:
 for definition in entries(category):
  if definition.id==id: return definition
 return {}
