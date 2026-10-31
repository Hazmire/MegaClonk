class_name ElementAudio
extends RefCounted

# Element layers: a weapon that carries a gem also plays that element's attack / hit / loop sound on top of its own.
# Event ids and loop keys are built once here so nothing allocates per attack or per hit.
const EVENTS={
 "corrosive":["element.corrosive.attack","element.corrosive.hit","element.corrosive.loop"],
 "ice":["element.ice.attack","element.ice.hit","element.ice.loop"],
 "fire":["element.fire.attack","element.fire.hit","element.fire.loop"],
 "electricity":["element.electric.attack","element.electric.hit","element.electric.loop"]}
static var keys: Dictionary={}
static func gems(game: Node,id: int) -> Array:
 var state=game.weapons.get(id)
 if state==null or not state.get("sockets") is Dictionary:return []
 return state.sockets.gems
static func attack(game: Node,id: int,pos: Vector3) -> void:
 for element in gems(game,id):game.audio.emit(EVENTS[element][0],pos,1.0,1.0)
static func hit(game: Node,id: int,pos: Vector3) -> void:
 for element in gems(game,id):game.audio.emit(EVENTS[element][1],pos,1.0,1.0)
static func loop_key(id: int,element: String) -> String:
 var k=id*16+Elements.IDS.find(element)
 if not keys.has(k):keys[k]="element_loop:%d:%s"%[id,element]
 return keys[k]
# Called every frame by weapons that have a looping body (aura, scythes in flight, fireballs in flight).
static func loop_sync(game: Node,id: int,active: bool,pos: Vector3) -> void:
 for element in gems(game,id):
  var key=loop_key(id,element)
  if active:
   if not game.audio.loop_start(key,EVENTS[element][2],pos):continue
   game.audio.loop_update(key,1.0,pos)
  else:game.audio.loop_stop(key)
