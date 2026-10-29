class_name MenuScreen
extends Control
# Root of every out-of-run menu screen. Owns the look that is shared: the Fog theme (applied here only, never
# project-wide, so in-run screens keep their own), a 1920x1080 design stage scaled to the window, the dithered fog
# background, the scanline/vignette overlay, the key-hint bar, the ~150 ms fade through #0E0F0E and Esc / Q / E handling.
signal back_requested
static var using_pad=false
static var instant=false # tests switch fades off
static var play_sound: Callable
const FADE=0.075
const PAD_WORDS={"ENTER":"A","ESC":"B","Q / E":"LB / RB","TAB":"Y","↑↓":"D-PAD","↑ ↓":"D-PAD"}
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
var hint_bar: HBoxContainer
var hints: Array=[]
var tween: Tween
var frontend: Node # FrontEnd that owns screen switching (set by FrontEnd before the screen enters the tree)
var game: Node
func bind(owner_frontend: Node) -> MenuScreen:
 frontend=owner_frontend;game=owner_frontend.game;return self
static func sfx(name: String) -> void:
 if play_sound.is_valid():play_sound.call(name)
func _init() -> void:
 theme=MenuStyle.theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 stage=Control.new();stage.name="Stage";stage.size=Vector2(MenuStyle.W,MenuStyle.H);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
 content=Control.new();content.name="Content";content.size=stage.size;content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hint_bar=HBoxContainer.new();hint_bar.name="KeyHints";hint_bar.add_theme_constant_override("separation",32);hint_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
func _ready() -> void:
 backdrop=Control.new();backdrop.name="Backdrop";backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(backdrop);_build_backdrop()
 add_child(stage);stage.add_child(content);stage.add_child(hint_bar)
 overlay=ColorRect.new();overlay.name="FogOverlay";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.color=Color.WHITE
 overlay.material=MenuStyle.shader_material("res://ui/shaders/fog_overlay.gdshader",{"vignette_strength":0.42,"vignette_start":0.62}) # lighter than the token default: the overlay sits on top of text here, the mockup vignette sits under it;add_child(overlay)
 fade=ColorRect.new();fade.name="Fade";fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;fade.color=FogPalette.NIGHT;add_child(fade)
 resized.connect(fit_stage);fit_stage();_place_hints()
 build()
 refresh_hints()
 if instant:fade.color.a=0.0
 else:
  tween=create_tween();tween.tween_property(fade,"color:a",0.0,FADE).from(1.0)
# Subclasses add their widgets to `content` here (design coordinates, 1920x1080).
func build() -> void:pass
func fit_stage() -> void:
 var s=minf(size.x/MenuStyle.W,size.y/MenuStyle.H)
 stage.scale=Vector2(s,s);stage.position=((size-stage.size*s)*0.5).floor()
func _build_backdrop() -> void:
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
func set_hints(entries: Array) -> void:hints=entries;refresh_hints()
func refresh_hints() -> void:
 if hint_bar==null:return
 for c in hint_bar.get_children():hint_bar.remove_child(c);c.queue_free()
 for e in hints:
  var pair=HBoxContainer.new();pair.add_theme_constant_override("separation",10);pair.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var key=String(e[0])
  if using_pad:key=String(e[2]) if e.size()>2 else PAD_WORDS.get(key,key)
  var font_key=MenuStyle.sans(800,0.18,15);var font_act=MenuStyle.sans(600,0.18,15)
  MenuStyle.label(key,font_key,15,FogPalette.BONE,0,pair);MenuStyle.label(String(e[1]).to_upper(),font_act,15,FogPalette.ASH_DIM,0,pair)
  hint_bar.add_child(pair)
func _input(event: InputEvent) -> void:
 var pad=event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value)>0.5)
 var kb=event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length()>2.0)
 if (pad and not using_pad) or (kb and using_pad):
  using_pad=pad;refresh_hints()
func _unhandled_input(event: InputEvent) -> void:
 if not is_visible_in_tree():return
 if event.is_action_pressed("ui_cancel") and allow_back:
  get_viewport().set_input_as_handled();go_back();return
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
 if instant or not is_inside_tree():next.call();return
 if tween!=null and tween.is_valid():tween.kill()
 fade.color.a=0.0;tween=create_tween();tween.tween_property(fade,"color:a",1.0,FADE)
 tween.tween_callback(next)
func focus_first(control: Control) -> void:
 if control!=null and control.is_inside_tree():control.grab_focus()
