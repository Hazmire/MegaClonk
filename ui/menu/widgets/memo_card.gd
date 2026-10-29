class_name MemoCard
extends Control
# Paper memo: Fog memo paper, tape strip on top, hard offset shadow, a slight rotation. Three quest variants:
#  counted  - title, description, ink progress bar and "n / target"
#  passfail - title, description and a NOT YET stamp
#  complete - struck-through title, DONE stamp and a CLAIM button
# "plain" leaves the body empty for screens that fill it themselves (detail memo, personal bests).
signal claim_pressed
var tilter: Control # everything visible hangs off this child, because containers reset the rotation of their direct children
var paper: PanelContainer
var body: VBoxContainer
var tape: ColorRect
var variant="plain"
var tilt=0.0
var tape_size=Vector2(90,28)
var tape_angle=-3.0
var claim_button: Button
func _init() -> void:
 mouse_filter=Control.MOUSE_FILTER_PASS
 tilter=Control.new();tilter.name="Tilt";tilter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tilter.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(tilter)
 paper=PanelContainer.new();paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style=FogTheme.memo_style();style.shadow_color=Color(0,0,0,0.45);style.shadow_offset=Vector2(4,6)
 style.content_margin_left=22;style.content_margin_right=22;style.content_margin_top=20;style.content_margin_bottom=22
 paper.add_theme_stylebox_override("panel",style);tilter.add_child(paper)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",8);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;paper.add_child(body)
 tape=ColorRect.new();tape.color=Color(0.91,0.886,0.816,0.7);tape.mouse_filter=Control.MOUSE_FILTER_IGNORE;tilter.add_child(tape)
 paper.minimum_size_changed.connect(_fit);resized.connect(_layout)
func _ready() -> void:_fit();_layout()
func _fit() -> void:custom_minimum_size.y=paper.get_combined_minimum_size().y
func _layout() -> void:
 tilter.pivot_offset=size*0.5;tilter.rotation_degrees=tilt
 tape.size=tape_size;tape.pivot_offset=tape_size*0.5;tape.rotation_degrees=tape_angle
 tape.position=Vector2((size.x-tape_size.x)*0.5,-tape_size.y*0.5)
func set_look(rotation_deg: float,margins: Vector4=Vector4(22,20,22,22)) -> MemoCard:
 tilt=rotation_deg;tilter.rotation_degrees=rotation_deg
 var s: StyleBoxFlat=paper.get_theme_stylebox("panel")
 s.content_margin_left=margins.x;s.content_margin_top=margins.y;s.content_margin_right=margins.z;s.content_margin_bottom=margins.w
 return self
func set_paper(color: Color) -> MemoCard:
 (paper.get_theme_stylebox("panel") as StyleBoxFlat).bg_color=color;return self
func memo_label(text: String,size: int,color: Color=FogPalette.MEMO_INK,parent: Node=null) -> Label:
 var l=Label.new();l.text=text;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_override("font",MenuStyle.memo());l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color)
 l.add_theme_color_override("font_shadow_color",Color(0,0,0,0));l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 (parent if parent!=null else body).add_child(l);return l
func fill_quest(title: String,description: String,state: String,value: float,target: float,pass_fail: bool,reward_text: String="") -> MemoCard:
 variant="complete" if state!="active" else ("passfail" if pass_fail else "counted")
 var head=memo_label(title,22)
 head.name="Title"
 if variant=="complete":
  # struck title: a red rule through the text (the label is wrapped so the rule matches the text width)
  var holder=Control.new();holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
  body.remove_child(head);holder.add_child(head);body.add_child(holder);body.move_child(holder,0)
  head.autowrap_mode=TextServer.AUTOWRAP_OFF
  var w=MenuStyle.memo().get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,22)
  holder.custom_minimum_size=Vector2(0,maxf(30.0,w.y))
  var rule=ColorRect.new();rule.name="Strike";rule.color=MenuStyle.SILVER_RUST;rule.position=Vector2(0,w.y*0.5);rule.size=Vector2(w.x,2);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;holder.add_child(rule)
 var desc=memo_label(description,17,Color("2E2A22"));desc.name="Description"
 match variant:
  "counted":
   var bar=ProgressTrack.new();bar.name="Progress";bar.ratio=clampf(value/maxf(1.0,target),0.0,1.0);bar.custom_minimum_size=Vector2(0,8);body.add_child(bar)
   var count=memo_label("%s / %s"%[_n(value),_n(target)],15,FogPalette.MEMO_INK_SOFT);count.name="Count"
  "passfail":
   var row=HBoxContainer.new();row.name="StampRow";row.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(row)
   var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="NotYet";stamp.setup("Not yet",MenuStyle.SILVER_RUST,15,0.22,2,-4.0);row.add_child(stamp)
  "complete":
   var row=HBoxContainer.new();row.name="DoneRow";row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",16);body.add_child(row)
   var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Done";stamp.setup("Done",MenuStyle.SILVER_RUST,15,0.22,2,-3.0,Color("F4EFE2"));row.add_child(stamp)
   if state=="completed":
    claim_button=Button.new();claim_button.name="Claim";claim_button.text="CLAIM  %s"%reward_text;claim_button.focus_mode=Control.FOCUS_ALL
    var f=MenuStyle.sans(800,0.14,15);claim_button.add_theme_font_override("font",f);claim_button.add_theme_font_size_override("font_size",15)
    for c in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:claim_button.add_theme_color_override(c,FogPalette.MEMO_INK if c!="font_pressed_color" else FogPalette.MEMO)
    claim_button.add_theme_stylebox_override("normal",FogTheme.flat(Color(0,0,0,0),FogPalette.MEMO_INK,2))
    claim_button.add_theme_stylebox_override("hover",FogTheme.flat(Color("E4DCC3"),FogPalette.MEMO_INK,2))
    claim_button.add_theme_stylebox_override("focus",FogTheme.flat(Color("E4DCC3"),FogPalette.RUST,3))
    claim_button.add_theme_stylebox_override("pressed",FogTheme.flat(FogPalette.MEMO_INK,FogPalette.MEMO_INK,2))
    row.add_child(claim_button);claim_button.pressed.connect(func():claim_pressed.emit())
   else:
    var note=memo_label("Reward claimed",15,FogPalette.MEMO_INK_SOFT,row);note.name="Claimed"
 return self
static func _n(v: float) -> String:return str(int(v)) if is_equal_approx(v,floorf(v)) else "%.1f"%v
class ProgressTrack extends Control:
 var ratio=0.0
 func _init() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO,size),MenuStyle.PAPER_TRACK)
  draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*ratio,size.y)),FogPalette.MEMO_INK)
