class_name WeaponVFX
extends RefCounted
static func attack(game: Node,id: int,pos: Vector3,target: Vector3) -> void:
 var type=Catalog.WEAPONS[id][1]
 if id==16:game.combat_fx.burst("smoke_puff",game.player.position+Vector3.UP*0.12,0.4,0.2);return
 if id in [1,2,10]:game.combat_fx.supplied_burst("fire" if id==1 else "arcane",pos,0.6)
 if type in ["bullet","scatter","beam"]:game.combat_fx.burst("muzzle_front",pos,0.45,0.1)
 elif type in ["fireball","cone"]:game.combat_fx.burst("fire_torch",pos,0.5,0.18)
 elif type in ["poison","spore"]:game.combat_fx.burst("smoke_puff",pos,0.35,0.16)
 elif type in ["mine","hammer","gravity","vortex"]:game.combat_fx.burst("smoke_puff",target,0.5,0.2)
static func contact(game: Node,id: int,pos: Vector3) -> void:
 if id==8:game.audio.emit("weapon.aegis.impact",pos)
 if id in [4,16]:game.combat_fx.supplied_burst("debris",pos,0.7)
 if id==4:
  game.combat_fx.burst("smoke_puff",pos,0.5,0.22);game.impact(pos,Color("9c927f"),3)
  game.audio.emit("weapon.chunkers.impact",pos)
 elif Catalog.WEAPONS[id][1] in ["fireball","cone","trail"]:game.combat_fx.burst("fire_torch",pos,0.5,0.2)
 elif Catalog.WEAPONS[id][1] in ["bullet","scatter","pierce","lob"]:game.combat_fx.burst("impact_concrete",pos,0.5,0.16)
 else:game.flash(pos,Color(Catalog.WEAPONS[id][5]),0.25)
static func trail(game: Node,p: Dictionary,previous: Vector3) -> void:
 if p.hostile:game.trail(p.node.position,Color("ff9b74"));return
 var kind=p.kind
 if kind in ["bullet","scatter"]:game.beam(previous,p.node.position,Color("ffe6a5"))
 elif kind=="pierce":return
 elif kind=="fireball":
  game.combat_fx.burst("fire_torch",p.node.position,0.25,0.18)
  if int(p.age*10)%3==0:game.combat_fx.burst("smoke_puff",previous,0.25,0.2)
 else:game.trail(p.node.position,Color(Catalog.WEAPONS[p.weapon][5]))

static func sound(id: int) -> String:
 var sounds={0:"weapon.sword.swing",1:"weapon.firestaff.cast",2:"weapon.lightning.zap",4:"",5:"weapon.bone.throw",6:"weapon.bow.fire",7:"weapon.revolver.fire",8:"",9:"weapon.bananarang.throw",10:"weapon.aura.pulse",16:"weapon.mines.place"}
 return sounds.get(id,"weapon.sword.swing")
