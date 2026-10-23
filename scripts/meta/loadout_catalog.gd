class_name LoadoutCatalog
extends RefCounted
const TRAITS=[
 {"id":"climber","name":"Cliffwalker","description":"Move forward against walls to climb.","goal":0,"cost":0},
 {"id":"momentum","name":"Endless Stride","description":"Movement builds damage, up to +50%. Stopping drains it.","goal":0,"cost":0},
 {"id":"sentry","name":"Rooted Fury","description":"Stand still to build up to +60% damage.","goal":100,"cost":30},
 {"id":"glider","name":"Skyweaver","description":"Hold Jump while falling to glide and steer.","goal":250,"cost":50},
 {"id":"seer","name":"Far Sight","description":"Begin with the entire minimap revealed.","goal":500,"cost":75}
]
const ULTIMATES=[
 {"id":"nova","name":"Cataclysm","description":"A devastating 28m explosion. 90 second cooldown.","cooldown":90.0,"duration":0.0,"goal":0,"cost":0},
 {"id":"berserk","name":"Berserker","description":"12 seconds: double damage and 50% less incoming damage.","cooldown":75.0,"duration":12.0,"goal":150,"cost":60},
 {"id":"ghost","name":"Ghost Form","description":"8 seconds: invulnerable, +100% speed, +125% jump height.","cooldown":90.0,"duration":8.0,"goal":400,"cost":100}
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
static func entries(category: String) -> Array:
 var result: Array=[]
 match category:
  "weapons":
   for i in Catalog.WEAPONS.size():
    var w=Catalog.WEAPONS[i]
    result.append({"id":str(i),"name":w[0],"description":"%s • %.0f damage • %.2fs cooldown"%[w[1],w[2],w[3]],"goal":0 if i in [0,1,6,7] else (i+1)*15,"cost":0 if i in [0,1,6,7] else 15+i*3})
  "traits": result=TRAITS.duplicate(true)
  "ultimates": result=ULTIMATES.duplicate(true)
  "items":
   for i in Catalog.ITEMS.size():
    var item=Catalog.ITEMS[i]
    result.append({"id":str(i),"name":item[0],"description":"%s • +%s %s"%[item[1],item[3],item[2]],"goal":0 if i<5 else i*50,"cost":0 if i<5 else i*10})
 return result
static func entry(category: String, id: String) -> Dictionary:
 for definition in entries(category):
  if definition.id==id: return definition
 return {}
