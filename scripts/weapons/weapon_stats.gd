class_name WeaponStats
extends RefCounted

# Single source of truth for every resolved weapon number. Upgrade cards, tooltips and the combat
# code all read it, so the "current -> new" values a card shows are the values the weapon then uses.
# Tags: SPEC = taken from the Weapon Overhaul 2.0 brief, GUESS = my tuning, easy to change here.
const SWORD={"reach":4.6,"arc_deg":150.0,"burst_gap":0.12,"base_count":1,"max_count":8} # reach/arc GUESS, gap SPEC (0.10-0.15)
const FIRESTAFF={"speed":17.0,"radius":0.55,"fan_deg":11.0,"base_count":1,"max_count":9,"hit_radius":0.7,"shunt":5.0,"range_cap":26.0}
const LIGHTNING={"strike_radius":1.7,"chain_range":7.5,"chain_delay":0.09,"falloff":0.85,"base_count":1,"max_count":8,"max_bounces":6,"search_radius":22.0,"strike_delay":0.06}
const BOW={"speed":38.0,"range":36.0,"fan_deg":7.0,"base_count":1,"max_count":9,"hit_radius":0.65}
const REVOLVER={"speed":54.0,"range":30.0,"ricochet_range":13.0,"base_count":1,"max_count":8,"max_bounces":6,"hit_radius":0.5,"spacing":0.32}
const AURA={"radius":5.0,"pulse_gap":0.9}
const SCYTHES={"out_range":11.0,"speed":17.0,"return_speed":22.0,"hit_radius":1.15,"base_count":1,"max_count":10,"max_life":6.0,"catch":0.9}
const SHOTGUN={"base_pellets":6,"max_pellets":24,"cone_deg":19.0,"cone_max_deg":38.0,"range":11.0,"range_max":13.5,"hit_radius":0.7}
const CAPS={"ricochet":6}
static func base_stats(game: Object) -> Dictionary:
 return game.stats if game!=null and "stats" in game else Catalog.base_stats()
static func upg(state: Dictionary,key: String) -> float:return WeaponUpgrades.value(state,key)
static func resolve(game: Object,id: int,state: Dictionary) -> Dictionary:
 var s=base_stats(game);var def=Catalog.WEAPONS[id]
 var pool=WeaponUpgrades.POOLS[id]
 var haste=float(s.haste)+(minf(float(game.moving_time),20.0)*0.02 if game!=null and "character" in game and int(game.character)==2 else 0.0)
 haste*=1.0+upg(state,"haste")
 var r={"id":id,"kind":def[1],"damage":WeaponUpgrades.damage(id,state),"haste":haste,"interval":float(def[3])/maxf(0.1,haste)}
 r["size_mult"]=float(s.size)*(1.0+upg(state,"radius"))
 r["speed_mult"]=float(s.projectile_speed)*(1.0+upg(state,"velocity")) if "velocity" in pool else 1.0
 r["crit_chance"]=float(s.crit)+upg(state,"crit")
 r["crit_damage"]=float(s.crit_damage)+upg(state,"crit_damage")
 var extra=int(upg(state,"count"))+maxi(0,int(round(float(s.count)))-1)
 r["bounces"]=mini(int(CAPS.ricochet),int(upg(state,"ricochet")))
 match id:
  0:
   r["count"]=clampi(SWORD.base_count+extra,1,SWORD.max_count);r["reach"]=SWORD.reach*r.size_mult;r["arc_deg"]=SWORD.arc_deg;r["gap"]=SWORD.burst_gap
  1:
   r["count"]=clampi(FIRESTAFF.base_count+extra,1,FIRESTAFF.max_count);r["speed"]=FIRESTAFF.speed*r.speed_mult;r["scale"]=r.size_mult;r["hit_radius"]=FIRESTAFF.hit_radius*r.size_mult;r["range"]=minf(FIRESTAFF.range_cap,float(def[4]))
  2:
   r["count"]=clampi(LIGHTNING.base_count+extra,1,LIGHTNING.max_count);r["strike_radius"]=LIGHTNING.strike_radius*r.size_mult;r["bounces"]=mini(LIGHTNING.max_bounces,r.bounces)
  6:
   r["count"]=clampi(BOW.base_count+extra,1,BOW.max_count);r["speed"]=BOW.speed*r.speed_mult;r["scale"]=r.size_mult;r["hit_radius"]=BOW.hit_radius*r.size_mult;r["range"]=BOW.range
  7:
   r["count"]=clampi(REVOLVER.base_count+extra,1,REVOLVER.max_count);r["speed"]=REVOLVER.speed*r.speed_mult;r["bounces"]=mini(REVOLVER.max_bounces,r.bounces);r["range"]=REVOLVER.range
  9:
   r["count"]=clampi(SCYTHES.base_count+extra,1,SCYTHES.max_count);r["speed"]=SCYTHES.speed*r.speed_mult;r["return_speed"]=SCYTHES.return_speed*r.speed_mult;r["scale"]=r.size_mult;r["hit_radius"]=SCYTHES.hit_radius*r.size_mult;r["out_range"]=SCYTHES.out_range
  10:
   r["count"]=1;r["radius"]=AURA.radius*r.size_mult;r["interval"]=float(def[3])/maxf(0.1,haste)
  15:
   r["count"]=clampi(SHOTGUN.base_pellets+extra,1,SHOTGUN.max_pellets);r["cone_deg"]=minf(SHOTGUN.cone_max_deg,SHOTGUN.cone_deg*(1.0+0.55*(r.size_mult-1.0)));r["range"]=minf(SHOTGUN.range_max,SHOTGUN.range*(1.0+0.12*(r.size_mult-1.0)))
 return r
