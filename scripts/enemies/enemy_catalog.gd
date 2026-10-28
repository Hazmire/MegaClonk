class_name EnemyCatalog
extends RefCounted
const ARCHETYPES=["melee","fast","heavy","ranged","charger","flying","explosive","shielded"]
# ID, model, HP, speed, damage, range, cooldown, modules, projectile speed,
# blast radius, knockback multiplier, windup, reward.
const VARIANTS=[
 [["Goblin Warrior","goblin",38,3.2,10,1.5,1.2,["melee"],0,0,1.0,0.3,2],
  ["Skeleton Duelist","skeleton",27,4.0,7,1.6,0.65,["melee"],0,0,1.1,0.18,2]],
 [["Feral Wolf","wolf",34,5.4,13,1.6,2.4,["charge","melee"],0,0,1.0,0.5,3],
  ["Ember Spider","spider",24,5.0,18,2.2,2.8,["proximity","death_blast"],0,3.8,1.2,0.85,3]],
 [["Armoured Ogre","ogre",140,1.9,24,2.4,2.6,["melee","knockback"],0,0,0.35,0.8,5],
  ["Stone Golem","golem",195,1.4,20,5.0,3.8,["slam"],0,5.0,0.15,1.1,6]],
 [["Goblin Archer","archer",34,2.7,11,19.0,2.0,["ranged","reposition"],15,0,1.0,0.55,3],
  ["Cactus Spitter","cactus",68,0.0,9,24.0,2.9,["ranged","stationary","fan"],11,0,0.5,0.8,4]],
 [["Dark Knight","knight",95,3.4,18,2.0,3.0,["charge","melee"],0,0,0.45,0.75,5],
  ["Demonic Brute","brute",135,2.1,25,4.2,3.7,["charge","slam"],0,4.2,0.3,1.0,6]],
 [["Dusk Bat","bat",29,4.7,9,1.8,1.4,["melee","flying"],0,0,1.2,0.35,3],
  ["Storm Wisp","wisp",42,2.7,12,20.0,2.5,["ranged","flying","reposition"],12,0,0.7,0.6,4]],
 [["Fuse Scarab","scarab",36,3.8,23,2.8,3.0,["proximity"],0,4.5,0.9,1.0,4],
  ["Sporecap","mushroom",56,1.8,17,3.1,3.2,["proximity","death_blast"],0,5.0,0.6,1.15,4]],
 [["Crystal Bulwark","bulwark",155,2.0,16,2.4,2.4,["melee","shield"],0,0,0.2,0.65,5],
  ["Horned Beetle","beetle",100,3.3,18,2.1,2.8,["charge","shield"],0,0,0.3,0.7,5]]
]
static func variant(kind: int, choice: int) -> Dictionary:
 var d=VARIANTS[kind][choice]
 var names=[["Blighted Wretch","Pale Wanderer"],["Longlimb Hunter","Volatile Husk"],["Rot Behemoth","The Wrapper"],["Ash Seer","Rooted Pale One"],["Masked Sentinel","Hooded Ravager"],["Drifting Revenant","Storm Wretch"],["Fuse Husk","Spore Brute"],["Armoured Mutant","Masked Bulwark"]]
 var model=[["Goblin","Skeleton"],["Hunter","BlightHusk"],["Behemoth","Golem"],["Ghost","Skeleton"],["Knight","Champion"],["Ghost","Imp"],["BlightHusk","Puglin"],["Behemoth","Knight"]][kind][choice]
 return {"id":d[1],"name":names[kind][choice],"archetype":kind,"model":BestiaryFrames.source_path(model),"visual_model":model,"visual_tint":[Color.WHITE,Color("ffbd9e"),Color("b9c6a5"),Color("b1dcbf"),Color("c6a9c9"),Color("9ce1ef"),Color("e2da8b"),Color("adc9f1")][kind],"visual_scale":1.25 if kind in [2,7] else (0.85 if kind in [1,6] else 1.0),"health":float(d[2]),"speed":float(d[3]),"damage":float(d[4]),"range":float(d[5]),"cooldown":float(d[6]),"modules":d[7],"projectile_speed":float(d[8]),"blast_radius":float(d[9]),"knockback":float(d[10]),"windup":float(d[11]),"reward":int(d[12])}
