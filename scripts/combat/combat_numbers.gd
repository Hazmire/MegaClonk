class_name CombatNumbers
extends Node3D
# One shared billboard batch, not one text scene/font atlas per hit.
const LIMIT=32
var active: Array=[]
var buckets: Dictionary={}
var view: MultiMeshInstance3D
var created=1
func _ready() -> void:
 view=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.use_custom_data=true
 var quad=QuadMesh.new();quad.size=Vector2.ONE;var material=ShaderMaterial.new();material.shader=preload("res://shaders/combat_numbers.gdshader");material.render_priority=100;material.set_shader_parameter("glyphs",preload("res://assets/config/combat_digits.png"));quad.material=material
 mm.mesh=quad;mm.instance_count=512;mm.visible_instance_count=0;view.multimesh=mm;view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(view)
func prewarm() -> void:pass
func show_damage(pos: Vector3,amount: float,critical: bool,color: Color,clock: float) -> void:
 var key=Vector3i(roundi(pos.x/3),roundi(pos.y/3),roundi(pos.z/3))
 if buckets.has(key) and clock-buckets[key].time<0.12:
  var item: Dictionary=buckets[key];item.amount+=amount;item.critical=item.critical or critical;item.time=clock
  if critical:item.color=color
  return
 if active.size()>=LIMIT:return
 var item={"pos":pos,"life":0.55,"amount":amount,"critical":critical,"time":clock,"key":key,"color":color};active.append(item);buckets[key]=item
func tick(delta: float) -> void:
 for i in range(active.size()-1,-1,-1):
  var item=active[i];item.life-=delta;item.pos.y+=delta*1.6
  if item.life<=0:
   if buckets.get(item.key)==item:buckets.erase(item.key)
   active.remove_at(i)
 var at=0;var camera=get_viewport().get_camera_3d();var right=camera.global_basis.x if camera!=null else Vector3.RIGHT
 for item in active:
  var text=str(int(item.amount))+("!" if item.critical else "");var width=0.27 if item.critical else 0.21;var size=Vector3(width,0.36 if item.critical else 0.28,1)
  for i in text.length():
   if at>=512:break
   var glyph=10 if text[i]=="!" else int(text[i])
   var pos: Vector3=item.pos+right*(float(i)-float(text.length()-1)/2)*width
   view.multimesh.set_instance_transform(at,Transform3D(Basis.IDENTITY.scaled(size),pos));view.multimesh.set_instance_color(at,item.color);view.multimesh.set_instance_custom_data(at,Color(glyph,0,0,0));at+=1
 view.multimesh.visible_instance_count=at
