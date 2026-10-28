class_name ShrineCharging
extends RefCounted
const SETTINGS=preload("res://assets/config/stage_update.tres")
const UPGRADES=["Vitality","Wind","Might","Haste","Precision","Magnet"]
static var sphere: SphereMesh
static var orb_material: ShaderMaterial
static func is_shrine(object: Dictionary) -> bool:return str(object.kind).ends_with("Shrine")
static func golden_for(seed_value: int,stage: int,index: int) -> bool:
 var rng=RandomNumberGenerator.new();rng.seed=seed_value+stage*32452843+index*49999+7621
 return rng.randf()<SETTINGS.golden_shrine_chance
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
  var object=shrines[i];object["shrine_index"]=i;object["golden"]=golden_for(game.run_seed,game.stage,i)
  var label=Label3D.new();label.name="ChargeProgress";label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=32;label.pixel_size=0.012;label.position=Vector3.UP*2.8;label.modulate=Color("a6f5ff");label.visibility_range_end=30;object.node.add_child(label)
  visual(game,object,false)
static func golden_visual(object: Dictionary) -> void:
 if not object.get("golden",false) or object.node.has_node("GoldenGlow"):return
 var gold=StandardMaterial3D.new();gold.albedo_color=Color("ffce55");gold.emission_enabled=true;gold.emission=Color("d49120");gold.emission_energy_multiplier=0.5
 # Gold lights and particles preserve the supplied stone textures.
 var light=OmniLight3D.new();light.name="GoldenGlow";light.light_color=Color("ffcd55");light.light_energy=0.6;light.omni_range=6;light.distance_fade_enabled=true;light.distance_fade_begin=25;object.node.add_child(light)
 var sparks=GPUParticles3D.new();sparks.name="GoldenParticles";sparks.amount=24;sparks.lifetime=2;var material=ParticleProcessMaterial.new();material.direction=Vector3.UP;material.spread=70;material.initial_velocity_min=0.3;material.initial_velocity_max=1.5;material.gravity=Vector3.ZERO;material.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE;material.emission_sphere_radius=1;material.color=Color("ffe897");material.scale_min=0.03;material.scale_max=0.08;sparks.process_material=material;var mesh=SphereMesh.new();mesh.radius=0.08;mesh.height=0.16;mesh.material=gold;sparks.draw_pass_1=mesh;sparks.position.y=1;object.node.add_child(sparks)
static func visual(game: Node,object: Dictionary,inside: bool) -> void:
 golden_visual(object)
 var fraction=clampf(float(object.charge)/SETTINGS.shrine_seconds,0,1)
 var transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*SETTINGS.shrine_radius),object.node.position+Vector3.UP*0.1)
 game.shrine_orbs.multimesh.set_instance_transform(int(object.shrine_index),transform)
 game.shrine_orbs.multimesh.set_instance_custom_data(int(object.shrine_index),Color(fraction,1 if inside else 0,1 if object.used else 0,1 if object.get("golden",false) else 0))
 var label=object.node.get_node("ChargeProgress") as Label3D
 var text="COMPLETE" if object.used else ("CHARGING %d%%"%int(fraction*100) if inside else "SHRINE · %d%%"%int(fraction*100))
 if object.get("golden",false):text="GOLDEN · "+text;label.modulate=Color("ffe08a")
 if object.used and object.node.has_node("GoldenParticles"):object.node.get_node("GoldenParticles").emitting=false
 if label.text!=text:label.text=text
static func tick(game: Node,object: Dictionary,distance: float,delta: float) -> void:
 if object.used or game.health<=0:return
 var inside=distance<=SETTINGS.shrine_radius
 if inside:object.charge=minf(SETTINGS.shrine_seconds,float(object.charge)+delta)
 elif SETTINGS.shrine_decay>0:object.charge=maxf(0,float(object.charge)-SETTINGS.shrine_decay*SETTINGS.shrine_seconds*delta)
 if object.charge>=SETTINGS.shrine_seconds:
  object.used=true
  var choices=ShrineRewards.generate(game.stats,game.rng,object.get("golden",false))
  object["shrine_choices"]=choices.duplicate(true)
  game.shrine_reward_queue.append({"choices":choices,"golden":object.get("golden",false)})
  game.run_metrics["shrines"]=int(game.run_metrics.get("shrines",0))+1
  game.combat_fx.burst("sparks_shower",object.node.position,2 if object.get("golden",false) else 1)
  game.flash(object.node.position,Color("ffd04d") if object.get("golden",false) else Color("8affcc"),SETTINGS.shrine_radius);game.play_sound("level")
  if game.mode=="run":ShrineRewards.present_next(game)
 elif inside:game.notice.text="Shrine · %d%% · stay inside the orb"%int(float(object.charge)/SETTINGS.shrine_seconds*100)
 visual(game,object,inside)
