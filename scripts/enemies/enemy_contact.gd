class_name EnemyContact
extends RefCounted
const EMPTY: Dictionary={}
const EMPTY_MODULES: Array=[]
const SETTINGS=preload("res://assets/config/stage_update.tres")
static func height(e: Dictionary) -> float:return maxf(1.2,1.4*e.get("scale",1.0)*float(e.get("variant",EMPTY).get("visual_scale",1.0)))
static func overlaps(game: Node,e: Dictionary) -> bool:
 var radius=float(e.get("radius",0.5))+game.player.collider.shape.radius+0.12
 var p: Vector3=game.player.position;var bottom=float(e.pos.y)-0.65
 return Vector2(p.x-e.pos.x,p.z-e.pos.z).length_squared()<=radius*radius and p.y<bottom+height(e)+0.1 and p.y+game.player.collider.shape.height>bottom
static func step(game: Node,e: Dictionary,delta: float) -> void:
 e.contact_clock=maxf(0,float(e.get("contact_clock",0))-delta)
 if e.hp<=0 or "proximity" in e.get("variant",EMPTY).get("modules",EMPTY_MODULES) or e.contact_clock>0:return
 if not overlaps(game,e):return
 e.contact_clock=SETTINGS.contact_interval
 var previous=float(game.health);game.hurt_contact(float(e.get("damage",8)),e.pos)
 if game.health<previous and game.stats.thorns>0:game.hit(e,game.stats.thorns,0)
