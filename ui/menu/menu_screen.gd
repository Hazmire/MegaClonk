class_name MenuScreen
extends Control
# Root of every out-of-run menu screen. Owns the look that is shared: the Fog theme (applied here only, never
# project-wide, so in-run screens keep their own), a 1920x1080 design stage scaled to the window, the dithered fog
# background, the scanline/vignette overlay, the key-hint bar, the ~150 ms fade through #0E0F0E and Esc / Q / E handling.
signal back_requested
# State lives in Engine metadata, not script statics: static vars on this class left the engine with heap corruption at shutdown (Godot 4.7.2).
static func is_instant() -> bool:return bool(Engine.get_meta("menu_instant",false)) # tests switch fades off
static func set_instant(value: bool) -> void:Engine.set_meta("menu_instant",value)
static func pad_active() -> bool:return bool(Engine.get_meta("menu_using_pad",false))
static func set_pad_active(value: bool) -> void:Engine.set_meta("menu_using_pad",value)
const FADE=0.075
var right_dark=false # "world" backdrop only: also darken the right edge (the loadout memo sits there)
var left_stop=0.56
var backdrop_kind="fog" # "fog" = checker fog + 86% dim; "world" = live scene behind, darkened at the left and bottom
var hint_side="right"
var allow_back=true
var stage: Control
var backdrop: Control
var content: Control
var overlay: ColorRect
var fade: ColorRect
var hint_bar: KeyHintBar
var tween: Tween
var frontend: Node # FrontEnd that owns screen switching (set by FrontEnd before the screen enters the tree)
var game: Node
func bind(owner_frontend: Node) -> MenuScreen:
 frontend=owner_frontend;game=owner_frontend.game;return self
static func set_audio_owner(game_node: Node) -> void:
 if not game_node.is_in_group("menu_audio"):game_node.add_to_group("menu_audio")
# UI sound name -> event id (ids of moments the game already had are kept; the rest are the Fog pack ids).
const SFX={"hover":"ui.hover","confirm":"ui.confirm","purchase":"ui.purchase","open":"ui.open","close":"ui.close","deny":"ui.cant_afford","back":"ui.menu_back","locked":"ui.menu_locked","toggle_on":"ui.toggle_on","toggle_off":"ui.toggle_off","slider_tick":"ui.slider_tick","play":"ui.menu_play","run_start":"ui.run_start","weapon_select":"ui.weapon_select","quest_claim":"ui.quest_claim","socket_hover":"ui.socket_hover","socket_place":"ui.socket_place","gem_pickup":"gem.pickup","card_deal":"ui.card_deal","card_hover":"ui.card_hover","card_take":"ui.card_take","banish":"ui.banish","skip_heal":"ui.skip_heal","refresh":"ui.refresh_shuffle","item_take":"ui.item_take","stamp_done":"ui.stamp_done","stamp_not_yet":"ui.stamp_not_yet","memo_hover":"ui.memo_hover"}
# Held sounds (the socket-hover charge): on while the pointer is on the control, off when it leaves.
static func charge(on: bool) -> void:
 var tree=Engine.get_main_loop() as SceneTree
 var target=tree.get_first_node_in_group("menu_audio") if tree!=null else null
 if target!=null and is_instance_valid(target.get("audio")):target.audio.charge(on)
static func sfx(name: String) -> void:
 if name=="":return
 var tree=Engine.get_main_loop() as SceneTree
 var target=tree.get_first_node_in_group("menu_audio") if tree!=null else null
 if target!=null:target.play_sound(SFX.get(name,"ui.confirm"))
func _init() -> void:
 theme=MenuStyle.theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 stage=Control.new();stage.name="Stage";stage.size=Vector2(MenuStyle.W,MenuStyle.H);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
 content=Control.new();content.name="Content";content.size=stage.size;content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hint_bar=KeyHintBar.new()
# Nodes built in _init but never parented (a screen instantiated and freed without entering the tree) would leak.
func _notification(what: int) -> void:
 if what==NOTIFICATION_PREDELETE:
  for n in [hint_bar,content,stage]:
   if is_instance_valid(n) and n.get_parent()==null:n.free()
func _ready() -> void:
 backdrop=Control.new();backdrop.name="Backdrop";backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(backdrop);_build_backdrop()
 add_child(stage);stage.add_child(content);stage.add_child(hint_bar)
 overlay=ColorRect.new();overlay.name="FogOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.color=Color.WHITE
 overlay.material=MenuStyle.shader_material("res://ui/shaders/fog_overlay.gdshader",{"vignette_strength":0.42,"vignette_start":0.62}) # lighter than the token default: the overlay sits on top of text here, the mockup vignette sits under it
 add_child(overlay)
 fade=ColorRect.new();fade.name="Fade";fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;fade.color=FogPalette.NIGHT;add_child(fade)
 resized.connect(fit_stage);fit_stage();_place_hints()
 build()
 refresh_hints()
 if is_instant():fade.color.a=0.0
 else:
  tween=create_tween();tween.tween_property(fade,"color:a",0.0,FADE).from(1.0)
# Subclasses add their widgets to `content` here (design coordinates, 1920x1080).
func build() -> void:pass
func fit_stage() -> void:
 var s=minf(size.x/MenuStyle.W,size.y/MenuStyle.H)
 stage.scale=Vector2(s,s);stage.position=((size-stage.size*s)*0.5).floor()
# The frozen, blurred gameplay frame captured when the run was paused (RunPause, and Settings opened from it).
func frozen_backdrop(extra_dim: float=0.0) -> bool:
 var tex: Texture2D=frontend.pause_frame if frontend!=null else null
 if tex==null:return false
 var r=TextureRect.new();r.name="FrozenFrame";r.texture=tex;r.stretch_mode=TextureRect.STRETCH_SCALE;r.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);r.mouse_filter=Control.MOUSE_FILTER_IGNORE
 r.material=MenuStyle.shader_material("res://ui/shaders/pause_frame.gdshader",{"blur_px":6.0*float(tex.get_width())/MenuStyle.W});backdrop.add_child(r)
 if extra_dim>0.0:
  var dim=ColorRect.new();dim.color=Color(0.039,0.043,0.039,extra_dim);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(dim)
 return true
func _build_backdrop() -> void:
 if backdrop_kind=="frozen":
  if frozen_backdrop():return
  backdrop_kind="fog" # no captured frame (headless, or the run was loaded straight into pause): the fog backdrop stands in
 if backdrop_kind=="fog":
  var fog=TextureRect.new();fog.texture=MenuStyle.checker(Color("8F9A92"),Color("87928A"),8);fog.stretch_mode=TextureRect.STRETCH_TILE;fog.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fog.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(fog)
  var ground=TextureRect.new();ground.texture=MenuStyle.checker(Color("212821"),Color("1C221D"),8);ground.stretch_mode=TextureRect.STRETCH_TILE;ground.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  ground.anchor_top=0.52;ground.anchor_right=1.0;ground.anchor_bottom=1.0;ground.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(ground)
  var dim=ColorRect.new();dim.color=Color(0.039,0.043,0.039,0.86);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(dim)
 else:
  var left=TextureRect.new();left.texture=MenuStyle.gradient(Color(0.039,0.043,0.039,0.94),Color(0.039,0.043,0.039,0.0),false,0.0,1.0)
  left.stretch_mode=TextureRect.STRETCH_SCALE;left.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;left.anchor_right=left_stop;left.anchor_bottom=1.0;left.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(left)
  if right_dark:
   var right=TextureRect.new();right.texture=MenuStyle.gradient(Color(0.039,0.043,0.039,0.0),Color(0.039,0.043,0.039,0.7),false)
   right.stretch_mode=TextureRect.STRETCH_SCALE;right.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;right.anchor_left=0.64;right.anchor_right=1.0;right.anchor_bottom=1.0;right.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(right)
  var top=TextureRect.new();top.texture=MenuStyle.gradient(Color(0.039,0.043,0.039,0.6),Color(0.039,0.043,0.039,0.0),true) # keeps the silver readable over a bright scene
  top.stretch_mode=TextureRect.STRETCH_SCALE;top.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;top.anchor_right=1.0;top.anchor_bottom=0.24;top.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(top)
  var bottom=TextureRect.new();bottom.texture=MenuStyle.gradient(Color(0.039,0.043,0.039,0.0),Color(0.039,0.043,0.039,0.85),true)
  bottom.stretch_mode=TextureRect.STRETCH_SCALE;bottom.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bottom.anchor_top=0.63;bottom.anchor_right=1.0;bottom.anchor_bottom=1.0;bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_child(bottom)
func _place_hints() -> void:
 if hint_side=="right":
  hint_bar.position=Vector2(0,MenuStyle.H-32-24);hint_bar.size=Vector2(MenuStyle.W-110,24);hint_bar.alignment=BoxContainer.ALIGNMENT_END
 else:
  hint_bar.position=Vector2(120,MenuStyle.H-32-24);hint_bar.size=Vector2(900,24);hint_bar.alignment=BoxContainer.ALIGNMENT_BEGIN
# entries: [keyboard key, action]. On a controller the key word is swapped for the button name.
func set_hints(entries: Array) -> void:hint_bar.set_entries(entries)
func refresh_hints() -> void:
 if hint_bar!=null:hint_bar.refresh()
func _input(event: InputEvent) -> void:
 var pad=event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value)>0.5)
 var kb=event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length()>2.0)
 if (pad and not pad_active()) or (kb and pad_active()):
  set_pad_active(pad);refresh_hints()
func _unhandled_input(event: InputEvent) -> void:
 if not is_visible_in_tree():return
 if event.is_action_pressed("ui_cancel") and allow_back:
  get_viewport().set_input_as_handled();MenuScreen.sfx("back");go_back();return
 var step=0
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_Q:step=-1
  elif event.keycode==KEY_E:step=1
 elif event is InputEventJoypadButton and event.pressed:
  if event.button_index==JOY_BUTTON_LEFT_SHOULDER:step=-1
  elif event.button_index==JOY_BUTTON_RIGHT_SHOULDER:step=1
 if step!=0:
  get_viewport().set_input_as_handled();step_tabs(step)
func step_tabs(_direction: int) -> void:pass
func go_back() -> void:back_requested.emit()
# Leaves the screen through #0E0F0E, then runs `next` (which builds the following screen).
func navigate(next: Callable) -> void:
 if is_instant() or not is_inside_tree():next.call();return
 if tween!=null and tween.is_valid():tween.kill()
 fade.color.a=0.0;tween=create_tween();tween.tween_property(fade,"color:a",1.0,FADE)
 tween.tween_callback(next)
# Focus a control on the next idle frame, only if it is still on screen (screens can be replaced before the call runs).
func focus_later(control: Control) -> void:
 _focus_now.call_deferred(control)
func _focus_now(control: Variant) -> void:
 if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():control.grab_focus()
