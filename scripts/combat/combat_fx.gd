class_name CombatFX
extends Node3D
# Shared flipbook frames and recycled billboards. No per-hit particle physics.
const LIMIT=24
static var frames: Dictionary={}
static var definitions: Dictionary={}
var active: Array[Dictionary]=[]
var idle: Array[AnimatedSprite3D]=[]
var electric: Array[Dictionary]=[]
var bursts_created=0
var intensity=0.7
var reduced=false
func _ready() -> void:
 for i in LIMIT:
  var sprite=AnimatedSprite3D.new();add_child(sprite);sprite.hide();idle.append(sprite)
static func definition(id: String) -> Dictionary:
 if definitions.is_empty():
  var data=load("res://assets/vendor/psx_fx/sheets/effects.json") as JSON
  for entry in data.data.effects:definitions[entry.name]=entry
 return definitions.get(id,{})
static func sprite_frames(id: String) -> SpriteFrames:
 if frames.has(id):return frames[id]
 var d=definition(id);var result=SpriteFrames.new()
 result.clear("default");result.set_animation_speed("default",d.fps);result.set_animation_loop("default",d.loop)
 var sheet=load("res://assets/vendor/psx_fx/sheets/64/"+d.file)
 var cell=Vector2(d.cell["64"][0],d.cell["64"][1])
 for i in int(d.frames):
  var atlas=AtlasTexture.new();atlas.atlas=sheet;atlas.region=Rect2(Vector2(i%int(d.columns),floorf(float(i)/d.columns))*cell,cell)
  result.add_frame("default",atlas)
 frames[id]=result;return result
func burst(id: String, pos: Vector3, size_multiplier: float=1, duration: float=-1) -> bool:
 if intensity<=0 or active.size()>=(6 if reduced else LIMIT):return false
 var d=definition(id)
 if d.is_empty():return false
 var sprite=idle.pop_back() if not idle.is_empty() else AnimatedSprite3D.new()
 if not sprite.get_parent():add_child(sprite)
 sprite.sprite_frames=sprite_frames(id);sprite.frame=0;sprite.stop()
 sprite.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y if d.facing=="upright" else BaseMaterial3D.BILLBOARD_ENABLED
 sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;sprite.shaded=false
 sprite.pixel_size=float(d.metres)/float(d.cell["64"][1])*size_multiplier
 sprite.position=pos;sprite.modulate=Color(1,1,1,clampf(intensity+0.3,0,1));sprite.show()
 bursts_created+=1
 active.append({"sprite":sprite,"age":0.0,"life":duration if duration>0 else float(d.frames)/d.fps,"data":d})
 return true
func lightning(pos: Vector3) -> bool:
 if intensity<=0 or reduced or electric.size()>=3:return false
 var emitter=GPUParticles3D.new();emitter.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;emitter.amount=12;emitter.lifetime=0.3;emitter.one_shot=true;emitter.explosiveness=1
 var process=ParticleProcessMaterial.new();process.direction=Vector3.UP;process.spread=150;process.initial_velocity_min=1;process.initial_velocity_max=5;process.gravity=Vector3.ZERO
 emitter.process_material=process
 var mesh=CylinderMesh.new();mesh.top_radius=0.025;mesh.bottom_radius=0.025;mesh.height=1.8;mesh.rings=8;mesh.radial_segments=6
 var material=ShaderMaterial.new();material.shader=preload("res://assets/vendor/electric/zap.gdshader")
 material.set_shader_parameter("primary_color",Vector3(0.7,0.95,1));material.set_shader_parameter("secondary_color",Vector3(0.15,0.45,1));material.set_shader_parameter("amplitude",0.15)
 var noise=NoiseTexture2D.new();noise.width=64;noise.height=64;noise.noise=FastNoiseLite.new();material.set_shader_parameter("noise_texture",noise)
 mesh.material=material;emitter.draw_pass_1=mesh;add_child(emitter);emitter.position=pos;emitter.emitting=true
 electric.append({"node":emitter,"age":0.0});return true
func tick(delta: float, running: bool=true) -> void:
 for e in electric:e.node.speed_scale=1 if running else 0
 if not running:return
 for i in range(active.size()-1,-1,-1):
  var e=active[i];e.age+=delta
  if e.age>=e.life:
   e.sprite.hide();idle.append(e.sprite);active.remove_at(i)
  else:e.sprite.frame=int(e.age*e.data.fps)%int(e.data.frames)
 for i in range(electric.size()-1,-1,-1):
  electric[i].age+=delta
  if electric[i].age>0.6:electric[i].node.queue_free();electric.remove_at(i)
func _exit_tree() -> void:
 for child in get_children():
  if child is AnimatedSprite3D:
   child.stop();child.sprite_frames=null
 active.clear();idle.clear();electric.clear()
