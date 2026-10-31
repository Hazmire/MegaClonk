class_name FilterChip
extends Button
# Rarity filter chip on Unlocks > Items: a colour dot, the tier name and its count ("COMMON 19"). Active chip is filled.
signal chosen_filter(id: String)
var filter_id="all"
var label_text=""
var count_text=""
var dot=FogPalette.BONE
var active=false
func setup(id: String,label: String,count: int,dot_color: Color) -> FilterChip:
 filter_id=id;label_text=label.to_upper();count_text=str(count);dot=dot_color;name="Chip_"+id;tooltip_text=label
 var f=MenuStyle.sans(800,0.16,13)
 var w=14.0+10.0+8.0+f.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+8.0+f.get_string_size(count_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+14.0
 custom_minimum_size=Vector2(ceilf(w),38);return self
func set_active(value: bool) -> void:active=value;queue_redraw()
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true
 for s in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(s,StyleBoxEmpty.new())
 pressed.connect(func():MenuScreen.sfx("confirm");chosen_filter.emit(filter_id))
 mouse_entered.connect(func():MenuScreen.sfx("hover"))
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size)
 draw_rect(r,Color("2A1416") if active else Color(0.055,0.059,0.055,0.85))
 draw_rect(r.grow(-0.5),FogPalette.RUST_BRIGHT if (active or has_focus()) else FogPalette.BORDER,false,2.0 if has_focus() else 1.0)
 var f=MenuStyle.sans(800,0.16,13)
 var y=(size.y-f.get_height(13))*0.5+f.get_ascent(13)
 draw_rect(Rect2(12,(size.y-10)*0.5,10,10),dot)
 var x=12.0+10.0+8.0
 var col=FogPalette.BONE_BRIGHT if active else FogPalette.ASH
 draw_string(f,Vector2(x,y),label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,col)
 x+=f.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+8.0
 draw_string(f,Vector2(x,y),count_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,FogPalette.BONE if active else FogPalette.ASH_DIM)
