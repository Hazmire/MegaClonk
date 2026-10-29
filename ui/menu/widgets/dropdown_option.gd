class_name DropdownOption
extends Button
# One row in a slot dropdown: 40px icon, serif name, short stats, a tick on the current pick. Locked rows are greyed.
var info: Dictionary={}
var current=false
func setup(option: Dictionary,is_current: bool) -> DropdownOption:
 info=option;current=is_current;name="Option_"+String(option.id);custom_minimum_size=Vector2(0,60)
 tooltip_text=String(option.name)
 return self
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true
 for s in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(s,StyleBoxEmpty.new())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
 mouse_entered.connect(func():if not has_focus():grab_focus())
func _draw() -> void:
 var locked=not bool(info.get("unlocked",true))
 var focused=has_focus()
 if current:draw_rect(Rect2(Vector2.ZERO,size),Color("2A1416"))
 if focused:draw_rect(Rect2(Vector2.ZERO,size),Color(0.494,0.094,0.125,0.45))
 draw_rect(Rect2(0,0,size.x,1),Color("222420"))
 var tex: Texture2D=UIAssets.icon(String(info.category),String(info.id))
 var box=Rect2(16,10,40,40)
 draw_texture_rect(tex,box,false,Color(0.35,0.35,0.35,0.8) if locked else Color.WHITE)
 var serif=MenuStyle.serif()
 var name_color=Color("7A7D76") if locked else (FogPalette.BONE if (current or focused) else Color("D9D4C4"))
 draw_string(serif,Vector2(70,(size.y-serif.get_height(26))*0.5+serif.get_ascent(26)),String(info.name),HORIZONTAL_ALIGNMENT_LEFT,-1,26,name_color)
 var right=size.x-16.0
 if current:
  draw_polyline(PackedVector2Array([Vector2(right-14,size.y*0.5),Vector2(right-9,size.y*0.5+5),Vector2(right,size.y*0.5-6)]),FogPalette.RUST_TEXT,3.0)
 right-=32.0
 var sans=MenuStyle.sans(600,0.0,15)
 var stats=String(info.get("stats",""))
 if locked:stats="LOCKED"
 if stats!="":
  var w=sans.get_string_size(stats,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
  draw_string(sans,Vector2(right-w,(size.y-sans.get_height(15))*0.5+sans.get_ascent(15)),stats,HORIZONTAL_ALIGNMENT_LEFT,-1,15,FogPalette.ASH if current else FogPalette.ASH_DIM)
