class_name ShrineCharging
extends RefCounted
const SETTINGS=preload("res://assets/config/stage_update.tres")
const UPGRADES=["Vitality","Wind","Might","Haste","Precision","Magnet"]
static var sphere: SphereMesh
static var orb_material: ShaderMaterial
static func is_shrine(object: Dictionary) -> bool:return str(object.kind).ends_with("Shrine")
static func setup(game: Node) -> void:
 if sphere==null:
  sphere=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=24;sphere.rings=12
  orb_material=ShaderMaterial.new();orb_material.shader=preload("res://shaders/shrine_orb.gdshader")
 var shrines=[]
 for object in game.interactables:
  if is_shrine(object):shrines.append(object)
 var batch=MultiMeshInstance3D.new();batch.name="ShrineChargingOrbs";game.world.add_child(batch);batch.material_override=orb_material;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 batch.multimesh=MultiMesh.new();batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D;batch.multimesh.use_custom_data=true;batch.multimesh.mesh=sphere;batch.multimesh.instance_count=shrines.size();game.shrine_orbs=batch
 for i in shrines.size():
  var object=shrines[i];object["shrine_index"]=i
  var label=Label3D.new();label.name="ChargeProgress";label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=32;label.pixel_size=0.012;label.position=Vector3.UP*2.8;label.modulate=Color("a6f5ff");label.visibility_range_end=30;object.node.add_child(label)
  visual(game,object,false)
static func visual(game: Node,object: Dictionary,inside: bool) -> void:
 var fraction=clampf(float(object.charge)/SETTINGS.shrine_seconds,0,1)
 var transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*SETTINGS.shrine_radius),object.node.position+Vector3.UP*0.1)
 game.shrine_orbs.multimesh.set_instance_transform(int(object.shrine_index),transform)
 game.shrine_orbs.multimesh.set_instance_custom_data(int(object.shrine_index),Color(fraction,1 if inside else 0,1 if object.used else 0,1))
 var label=object.node.get_node("ChargeProgress") as Label3D
 var text="COMPLETE" if object.used else ("CHARGING %d%%"%int(fraction*100) if inside else "SHRINE · %d%%"%int(fraction*100))
 if label.text!=text:label.text=text
static func tick(game: Node,object: Dictionary,distance: float,delta: float) -> void:
 if object.used or game.health<=0:return
 var inside=distance<=SETTINGS.shrine_radius
 if inside:object.charge=minf(SETTINGS.shrine_seconds,float(object.charge)+delta)
 elif SETTINGS.shrine_decay>0:object.charge=maxf(0,float(object.charge)-SETTINGS.shrine_decay*delta)
 if object.charge>=SETTINGS.shrine_seconds:
  object.used=true
  var candidates=[]
  for id in UPGRADES:
   var stat=Catalog.TOMES[id][0]
   if game.stats.has(stat) and not (stat=="crit" and game.stats.crit>=1):candidates.append(id)
  var id=candidates[game.rng.randi_range(0,candidates.size()-1)];var upgrade=Catalog.TOMES[id];var stat=str(upgrade[0]);var amount=float(upgrade[1])
  game.stats[stat]+=amount
  if stat=="max_health":game.health=minf(game.stats.max_health,game.health+amount)
  object["shrine_reward"]={"stat":stat,"amount":amount};game.run_metrics["shrines"]=int(game.run_metrics.get("shrines",0))+1
  game.combat_fx.burst("sparks_shower",object.node.position,1.5);game.flash(object.node.position,Color("8affcc"),SETTINGS.shrine_radius);game.play_sound("level");game.toast("SHRINE COMPLETE · "+stat.replace("_"," ").capitalize()+" "+BuildStats.value(stat,amount))
 elif inside:game.notice.text="Shrine · %d%% · stay inside the orb"%int(float(object.charge)/SETTINGS.shrine_seconds*100)
 visual(game,object,inside)
