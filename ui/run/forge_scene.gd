class_name ForgeScene
extends CanvasLayer
# ForgeScene: the Fusion forging moment (~3.4 s) at the Imbue Station. Own SubViewport/World3D over a darkened screen, the weapon's real
# model, two gems that orbit and collide, shards, a re-form in the Fusion's colours and the name card. Every visual is a pure function of
# the timeline t (seconds into the combo sound): t comes from the sound's playback position, falls back to a clock when the sound is
# muted/not playing, and is injectable (time_source) for tests. One-shot pieces fire on the frame t first crosses their mark.
signal finished
const LAYER_INDEX=4
const COLLIDE=0.85 # the FUSE marker in the combo sounds
const SHARDS_OUT=1.07
const SHARDS_BACK=1.43
const CARD=1.6
const END=3.4
const DARKEN=0.4
const SHARD_COUNT=16
const FusionLayerScript=preload("res://vfx/weapons/scripts/fusion_layer.gd")
const OverlayShader=preload("res://shaders/fusion_overlay.gdshader")
var fusion=""
var gems: Array=[]
var weapon_key=""
var weapon_name=""
var time_source: Callable=Callable()
var player: Node=null # the AudioStreamPlayer playing the combo sound (may be null)
var t=0.0
var clock=0.0
var floor_t=0.0
var paused=false
var skips=0
var done=false
var collided=false
var reformed=false
var carded=false
var collide_calls=0
var viewport: SubViewport
var holder: Node3D
var spin: Node3D
var model: Node3D
var cam: Camera3D
var dark: ColorRect
var flash: ColorRect
var card: PanelContainer
var layer3d: Node3D # the pack's FusionLayer
var motes: Node3D
var gem_nodes: Array=[]
var shard_nodes: Array=[]
var shard_home: Array=[]
var shard_out: Array=[]
var overlay_materials: Array=[]
var model_height=1.0
var time_since_audio=0.0
func setup(fusion_id: String,gem_ids: Array,key: String,w_name: String,audio_player: Node=null) -> ForgeScene:
 fusion=fusion_id;gems=gem_ids;weapon_key=key;weapon_name=w_name;player=audio_player
 layer=LAYER_INDEX;process_mode=Node.PROCESS_MODE_ALWAYS;name="Forge"
 _build();return self
func pack_gem(g: String) -> String:return "electric" if g=="electricity" else g
func _build() -> void:
 dark=ColorRect.new();dark.color=Color(0.03,0.03,0.035,0.0);dark.set_anchors_preset(Control.PRESET_FULL_RECT);dark.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(dark)
 var holder_c=SubViewportContainer.new();holder_c.set_anchors_preset(Control.PRESET_FULL_RECT);holder_c.stretch=true;holder_c.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(holder_c)
 viewport=SubViewport.new();viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.size=Vector2i(1920,1080);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;holder_c.add_child(viewport)
 holder=Node3D.new();viewport.add_child(holder)
 cam=Camera3D.new();cam.fov=38.0;holder.add_child(cam);cam.position=Vector3(0,0.15,4.6);cam.look_at_from_position(cam.position,Vector3(0,0,0))
 var sun=DirectionalLight3D.new();sun.light_energy=1.1;sun.rotation_degrees=Vector3(-35,30,0);holder.add_child(sun)
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_CLEAR_COLOR;e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color(0.35,0.35,0.4);e.ambient_light_energy=0.6;env.environment=e;holder.add_child(env)
 spin=Node3D.new();holder.add_child(spin);_load_model()
 layer3d=Node3D.new();layer3d.set_script(FusionLayerScript);holder.add_child(layer3d)
 layer3d.call("setup_fusion",pack_gem(str(gems[0])),pack_gem(str(gems[1])))
 for i in 2:
  var m=MeshInstance3D.new();var sm=SphereMesh.new();sm.radial_segments=4;sm.rings=2;sm.radius=0.5;sm.height=1.0;m.mesh=sm
  var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Elements.color(str(gems[i]));m.material_override=mat;m.scale=Vector3.ONE*0.2
  var l=OmniLight3D.new();l.light_color=mat.albedo_color;l.light_energy=2.0;l.omni_range=2.5;m.add_child(l)
  holder.add_child(m);gem_nodes.append(m)
 var r=RandomNumberGenerator.new();r.seed=3 # cosmetic only; never the game's rng
 var half=model_height*0.5
 for i in SHARD_COUNT:
  var s=MeshInstance3D.new();var bm=BoxMesh.new();bm.size=Vector3.ONE*r.randf_range(0.05,0.11)*model_height*0.8;s.mesh=bm
  var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.albedo_color=Fusions.color(fusion,"core") if i%3==0 else (Fusions.color(fusion,"mid") if i%2==1 else Fusions.color(fusion,"acc"));s.material_override=mat
  holder.add_child(s);s.visible=false;shard_nodes.append(s)
  var home=Vector3(r.randf_range(-0.06,0.06),r.randf_range(-half,half),0.0)
  shard_home.append(home);shard_out.append(home+Vector3(r.randf_range(-1.6,1.6),r.randf_range(-0.6,1.0),r.randf_range(-0.6,0.6)))
 flash=ColorRect.new();flash.color=Color(1,1,1,0);flash.set_anchors_preset(Control.PRESET_FULL_RECT);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(flash)
 _build_card()
 apply(0.0)
func _load_model() -> void:
 var path="res://assets/models/weapons/%s.glb"%weapon_key
 if not ResourceLoader.exists(path):return
 var packed=load(path) as PackedScene
 if packed==null:return
 var node=packed.instantiate() as Node3D
 var box=AABB();var first=true
 for c in node.find_children("*","MeshInstance3D",true,false):
  var mi=c as MeshInstance3D;var bb=mi.transform*mi.get_aabb();box=bb if first else box.merge(bb);first=false
 var long_z=box.size.z>box.size.y and box.size.z>box.size.x
 model=Node3D.new();spin.add_child(model);model.add_child(node)
 var longest=maxf(box.size.x,maxf(box.size.y,box.size.z));var k=2.0/maxf(longest,0.001);model_height=2.0
 node.position=-(box.position+box.size*0.5)
 model.scale=Vector3.ONE*k
 if long_z:model.rotation.y=PI*0.5
 for c in node.find_children("*","MeshInstance3D",true,false):
  var sm=ShaderMaterial.new();sm.shader=OverlayShader;sm.set_shader_parameter("core",Fusions.color(fusion,"core"));sm.set_shader_parameter("mid",Fusions.color(fusion,"mid"));sm.set_shader_parameter("acc",Fusions.color(fusion,"acc"));sm.set_shader_parameter("strength",2.0)
  overlay_materials.append(sm)
func _build_card() -> void:
 card=PanelContainer.new();card.name="NameCard";card.modulate.a=0.0
 var sb=StyleBoxFlat.new();sb.bg_color=Color("E8E2D0");sb.border_color=Color("7E1820");sb.set_border_width_all(3);sb.border_width_top=6
 sb.content_margin_left=44;sb.content_margin_right=44;sb.content_margin_top=14;sb.content_margin_bottom=18;sb.shadow_color=Color(Fusions.color(fusion,"mid"),0.6);sb.shadow_size=18
 card.add_theme_stylebox_override("panel",sb)
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",0);card.add_child(v)
 var top=Label.new();top.name="Top";top.text="FUSION FORGED  ·  %s"%Fusions.combo_name(fusion).to_upper();top.add_theme_font_override("font",FogTheme.sans(800));top.add_theme_font_size_override("font_size",18);top.add_theme_color_override("font_color",Color("7E1820"));top.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(top)
 var nm=Label.new();nm.name="Name";nm.text=weapon_name;nm.add_theme_font_override("font",FogTheme.serif());nm.add_theme_font_size_override("font_size",58);nm.add_theme_color_override("font_color",Color("0E0F0E"));nm.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(nm)
 var sub=Label.new();sub.name="Gems";sub.text="%s  +  %s"%[Elements.display_name(str(gems[0])),Elements.display_name(str(gems[1]))];sub.add_theme_font_override("font",FogTheme.sans(800));sub.add_theme_font_size_override("font_size",20);sub.add_theme_color_override("font_color",Fusions.color(fusion,"deep").lerp(Color.BLACK,0.2));sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(sub)
 add_child(card)
# ---- timeline
func audio_live() -> bool:
 return is_instance_valid(player) and player is AudioStreamPlayer and (player as AudioStreamPlayer).playing and not paused
func current_time() -> float:
 if time_source.is_valid():return float(time_source.call())
 if audio_live():
  var p=player as AudioStreamPlayer
  return maxf(0.0,p.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
 return clock
func _process(delta: float) -> void:
 if done:return
 if not paused:clock+=delta
 t=maxf(floor_t,current_time()) # monotonic: a stopped or stalled sound cannot rewind the picture
 floor_t=t
 apply(t)
 if t>=END:end()
func apply(time: float) -> void:
 time=maxf(time,0.0)
 # darken the world, then hold
 dark.color.a=clampf(time/DARKEN,0.0,1.0)*0.55
 # weapon spin
 spin.rotation.y=time*TAU/3.0
 var colliding=time<COLLIDE
 # gems
 for i in gem_nodes.size():
  var g=gem_nodes[i] as Node3D;g.visible=colliding
  if colliding:
   var u=time/COLLIDE;var rad=lerpf(1.3,0.0,pow(u,1.6))*model_height*0.5+0.0;var a=u*TAU*2.6+PI*i
   g.position=Vector3(cos(a)*rad,sin(u*9.0+i)*0.1*(1.0-u),sin(a)*rad*0.6);g.rotation.y=u*20.0
 # weapon visible except between collision and re-form
 var weapon_vis=colliding or time>=SHARDS_BACK
 if model!=null:model.visible=weapon_vis
 var strength=2.0
 if time>=SHARDS_BACK:strength=lerpf(2.0,0.65,clampf((time-SHARDS_BACK)/0.6,0.0,1.0))
 var show_overlay=time>=SHARDS_BACK
 if model!=null:
  var idx=0
  for c in model.find_children("*","MeshInstance3D",true,false):
   var mi=c as MeshInstance3D
   if show_overlay and idx<overlay_materials.size():(overlay_materials[idx] as ShaderMaterial).set_shader_parameter("strength",strength);mi.material_overlay=overlay_materials[idx]
   else:mi.material_overlay=null
   idx+=1
 # shards
 var shards_on=time>=COLLIDE and time<SHARDS_BACK
 for i in shard_nodes.size():
  var s=shard_nodes[i] as Node3D;s.visible=shards_on
  if shards_on:
   var home=shard_home[i] as Vector3;var out=shard_out[i] as Vector3;var p=home
   if time<SHARDS_OUT:
    var u=(time-COLLIDE)/(SHARDS_OUT-COLLIDE);p=home.lerp(out,1.0-pow(1.0-u,3.0))
   elif time<SHARDS_OUT+0.12:p=out
   else:
    var u=clampf((time-SHARDS_OUT-0.12)/(SHARDS_BACK-SHARDS_OUT-0.12),0.0,1.0);var ease_in=u*u*(2.70158*u-1.70158) # back-in
    p=out.lerp(home,clampf(ease_in,0.0,1.2))
   s.position=p;s.rotation=Vector3(float(i)*0.9+time*6.0,float(i)*1.3+time*5.0,0.0)
 # flashes
 var f=0.0
 if time>=COLLIDE:f=maxf(f,0.9*clampf(1.0-(time-COLLIDE)/0.35,0.0,1.0))
 if time>=SHARDS_BACK:f=maxf(f,0.6*clampf(1.0-(time-SHARDS_BACK)/0.3,0.0,1.0))
 flash.color.a=f
 # name card: slams from 1.8x
 var cu=clampf((time-CARD)/0.16,0.0,1.0)
 card.modulate.a=clampf((time-CARD)/0.1,0.0,1.0)
 card.pivot_offset=card.size*0.5;card.scale=Vector2.ONE*lerpf(1.8,1.0,cu*cu);card.rotation=deg_to_rad(-1.5)
 var vs=get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920,1080)
 card.position=Vector2((vs.x-card.size.x)*0.5,vs.y*0.76)
 # one-shot effects on the first frame their mark is crossed
 if time>=COLLIDE and not collided:collide(true)
 if time>=SHARDS_BACK and not reformed:reform()
 if time>=CARD and not carded:carded=true
func collide(with_effects: bool) -> void:
 if collided:return
 collided=true;collide_calls+=1
 if with_effects and is_inside_tree():
  layer3d.call("_plasma_pop",Vector3(0,0,0),1.6);layer3d.call("impact",Vector3(0,0.0,0))
func reform() -> void:
 if reformed:return
 reformed=true
 if is_inside_tree() and spin!=null:
  layer3d.call("trail",spin,1.0);motes=layer3d.call("motes",spin)
# ---- control
func set_paused(on: bool) -> void:
 if paused==on:return
 paused=on
 if player is AudioStreamPlayer:(player as AudioStreamPlayer).stream_paused=on
# First skip jumps both the picture and the sound to the name card; the second closes the forge.
func skip() -> void:
 if done:return
 skips+=1
 if t<CARD:
  if not collided:collide(false)
  if not reformed:reform()
  clock=CARD;floor_t=CARD;t=CARD
  if is_instance_valid(player) and player is AudioStreamPlayer and (player as AudioStreamPlayer).playing:(player as AudioStreamPlayer).seek(CARD)
  apply(t)
 else:end(true)
func end(stop_sound=false) -> void:
 if done:return
 done=true
 if stop_sound and is_instance_valid(player) and player is AudioStreamPlayer:(player as AudioStreamPlayer).stop()
 visible=false;set_process(false);set_process_input(false);finished.emit()
 # the pack's one-shot effects own timers that fire after the picture is gone; keep the nodes alive until they have all expired
 if is_inside_tree():get_tree().create_timer(3.5).timeout.connect(queue_free)
 else:queue_free()
func _input(event: InputEvent) -> void:
 if done:return
 var hit=false
 if event is InputEventKey and event.pressed and not event.echo and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.keycode in [KEY_E,KEY_SPACE,KEY_ENTER]):hit=true
 elif event is InputEventMouseButton and event.pressed:hit=true
 elif event is InputEventJoypadButton and event.pressed:hit=true
 if hit:get_viewport().set_input_as_handled();skip()
