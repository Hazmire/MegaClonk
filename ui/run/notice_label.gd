class_name NoticeLabel
extends Label
# Game.notice: the one-line prompt near the bottom of the run ("E / Chest · 15 gold"). Same Label API as before (callers just set
# .text, .hide() and .show()), drawn as a small Fog plate (dark panel, bone text, rust underline) that appears only while there is text.
var plate: Panel
func _init() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 add_theme_font_override("font",MenuStyle.sans(800,0.12,16));add_theme_font_size_override("font_size",16);add_theme_color_override("font_color",FogPalette.BONE_BRIGHT)
 add_theme_color_override("font_shadow_color",Color("050505"));add_theme_constant_override("shadow_offset_x",2);add_theme_constant_override("shadow_offset_y",2)
 plate=Panel.new();plate.show_behind_parent=true;plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var sb=FogTheme.flat(Color(0.055,0.059,0.055,0.88),FogPalette.BORDER,1);sb.border_width_bottom=3;sb.border_color=FogPalette.RUST;plate.add_theme_stylebox_override("panel",sb)
 add_child(plate);plate.hide()
func _process(_d: float) -> void:
 var has=text!=""
 if plate.visible!=has:plate.visible=has
 if has:
  var need=get_minimum_size();plate.position=Vector2((size.x-need.x)*0.5-18.0,(size.y-need.y)*0.5-8.0);plate.size=need+Vector2(36,16)
