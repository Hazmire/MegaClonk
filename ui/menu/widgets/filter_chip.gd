class_name FilterChip
extends Button
# Rarity filter chip on Unlocks > Items: coloured square, label and count ("COMMON 19").
var chip_id=""
var label_text=""
var count_text=""
var dot=Color.WHITE
var active=false
func setup(id: String,label: String,count: int,dot_color: Color) -> FilterChip:
 chip_id=id;label_text=label.to_upper();count_text=str(count);dot=dot_color;name="Chip_"+id
 var f=MenuStyle.sans(800,0.16,13)
 custom_minimum_size=Vector2(12+10+8+f.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+8+f.get_string_size(count_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+12,38)
 return self
func set_active(value: bool) -> void:active=value;queue_redraw()
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true;toggle_mode=false
 for s in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(s,StyleBoxEmpty.new())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("221616") if active else FogPalette.NIGHT_TILE)
 draw_rect(Rect2(Vector2.ONE*0.5,size-Vector2.ONE),FogPalette.RUST_BRIGHT if (active or has_focus()) else FogPalette.BORDER,false,1.0 if not has_focus() else 2.0)
 draw_rect(Rect2(12,14,10,10),dot)
 var f=MenuStyle.sans(800,0.16,13);var y=(size.y-f.get_height(13))*0.5+f.get_ascent(13)
 draw_string(f,Vector2(30,y),label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,FogPalette.BONE_BRIGHT if active else Color("A9ADA4"))
 var w=f.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
 draw_string(f,Vector2(30+w+8,y),count_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,FogPalette.RUST_TEXT if active else FogPalette.ASH_FAINT)
