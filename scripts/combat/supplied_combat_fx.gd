class_name SuppliedCombatFX
extends Node3D
const SHATTER=preload("res://assets/art_reset/status/StatusFX/effects/status/vfx_status_shatter.tscn")
const LIMIT=8
var idle: Dictionary={}
var active=[]
var requests=0
func _ready():
 for kind in ["shatter","fire","arcane","debris"]:
  idle[kind]=[]
  for i in 2:
   var effect=create(kind);add_child(effect);effect.hide()
   if kind=="shatter":
    effect.anim.stop()
    for particle in effect.particles:particle.emitting=false;particle.amount=16;particle.fixed_fps=30
   idle[kind].append(effect)
func create(kind: String) -> Node3D:
 if kind=="shatter":
  var effect=SHATTER.instantiate();effect.set_meta("kind",kind);return effect
 var emitter=GPUParticles3D.new();emitter.emitting=false;emitter.one_shot=true;emitter.explosiveness=0.85;emitter.amount=16;emitter.lifetime=0.65;emitter.fixed_fps=30;emitter.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var process=ParticleProcessMaterial.new();process.direction=Vector3.UP;process.spread=120;process.initial_velocity_min=1;process.initial_velocity_max=3;process.gravity=Vector3(0,-2,0);process.scale_min=0.12;process.scale_max=0.45;process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE;process.emission_sphere_radius=0.3;emitter.process_material=process
 var material=ShaderMaterial.new();material.shader=preload("res://assets/art_reset/status/StatusFX/shader/aura_particle.gdshader")
 material.set_shader_parameter("noise_texture",ForestAtmosphere.noise_texture());material.set_shader_parameter("primary_color",Color("ffad46") if kind=="fire" else Color("8dceff") if kind=="arcane" else Color("a79683"));material.set_shader_parameter("secondary_color",Color("e24e29") if kind=="fire" else Color("545f9d") if kind=="arcane" else Color("4e4942"));material.set_shader_parameter("emission",1.5);material.set_shader_parameter("edge_position",0.05)
 if kind=="debris":emitter.draw_pass_1=ArtResetWorld.ROCK;process.scale_min=0.08;process.scale_max=0.2;process.gravity=Vector3(0,-10,0)
 else:
  var mesh=QuadMesh.new();mesh.size=Vector2(0.4,0.8);mesh.material=material;emitter.draw_pass_1=mesh;emitter.transform_align=GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD
 emitter.set_meta("kind",kind);return emitter
func burst(kind: String,position_value: Vector3,size_value: float=1) -> bool:
 if active.size()>=LIMIT or not idle.has(kind) or idle[kind].is_empty():return false
 requests+=1;var effect=idle[kind].pop_back();effect.position=position_value;effect.scale=Vector3.ONE*clampf(size_value,0.3,5);effect.show()
 if kind=="shatter":
  effect.emission=1.8;effect.primary_color=Color("ffbb7b");effect.secondary_color=Color("936b98");effect.emitting=true;effect.anim.stop()
  for p in effect.particles:p.amount=16;p.fixed_fps=30;p.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;p.restart();p.emitting=true
 else:effect.restart();effect.emitting=true
 active.append({"node":effect,"kind":kind,"age":0.0,"life":2.5 if kind=="shatter" else 0.8});return true
func tick(delta: float,running: bool):
 for i in range(active.size()-1,-1,-1):
  var effect=active[i];var node=effect.node
  if node is GPUParticles3D:node.speed_scale=1 if running else 0
  elif node.has_node("AnimationPlayer"):
   node.get_node("AnimationPlayer").speed_scale=1 if running else 0
   for p in node.particles:p.speed_scale=1 if running else 0
  if not running:continue
  effect.age+=delta
  if effect.kind=="shatter" and effect.age>0.5 and not effect.get("stopped",false):
   effect["stopped"]=true
   for p in node.particles:p.emitting=false
  if effect.age>=effect.life:
   node.hide();idle[effect.kind].append(node);active.remove_at(i)
