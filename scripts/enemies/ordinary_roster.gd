class_name OrdinaryRoster
extends RefCounted
const SETTINGS=preload("res://assets/config/ordinary.tres")
static func choose(rng: RandomNumberGenerator) -> int:
 var roll=rng.randf()*(SETTINGS.basic_weight+SETTINGS.special_weight+SETTINGS.large_weight)
 return 0 if roll<SETTINGS.basic_weight else (1 if roll<SETTINGS.basic_weight+SETTINGS.special_weight else 2)
static func variant(kind: int,choice: int) -> Dictionary:
 var name="Goblin" if choice==0 else "Skeleton"
 var model="Goblin" if choice==0 else "Skeleton"
 var hp=SETTINGS.basic_health;var speed=SETTINGS.basic_speed;var damage=SETTINGS.basic_damage;var radius=0.5;var scale_value=1.0;var modules=["melee"]
 if kind==1:
  name="Exploding Bug" if choice==0 else "Speedy Monster";model="Puglin" if choice==0 else "Imp"
  hp=20 if choice==0 else 25;speed=3.2 if choice==0 else 4.5;damage=20 if choice==0 else 10
  modules=["proximity"] if choice==0 else ["melee"]
 elif kind==2:
  name="Forest Behemoth";model="Puglin";hp=250;speed=1.8;damage=20;scale_value=2.0;radius=1.15
 return {"id":name.to_snake_case(),"name":name,"archetype":kind,"model":"res://assets/quaternius/baked/"+model+"_enemy_idle_0.res","visual_model":model,"visual_tint":Color.WHITE,"visual_scale":scale_value,"radius":radius,"health":hp,"speed":speed,"damage":damage,"range":1.8 if kind!=1 or choice!=0 else 2.6,"cooldown":1.1,"modules":modules,"projectile_speed":0.0,"blast_radius":3.0,"knockback":0.3 if kind==2 else 1.0,"windup":0.6 if kind==1 and choice==0 else 0.2,"reward":6 if kind==2 else 2}
