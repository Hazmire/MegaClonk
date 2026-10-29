class_name HudNumber
extends Label
# HUD-style number: Overpass 800, tabular figures, hard ink shadow. Same look as the in-run counters.
func setup(value: Variant,size: int=44,color: Color=FogPalette.BONE_BRIGHT,shadow: int=0) -> HudNumber:
 text=str(value);mouse_filter=Control.MOUSE_FILTER_IGNORE
 var base=FogTheme.sans(800)
 if base!=null:
  var f=FontVariation.new();f.base_font=base;f.opentype_features={"tnum":1};f.variation_opentype={"wght":800};add_theme_font_override("font",f)
 add_theme_font_size_override("font_size",size);add_theme_color_override("font_color",color)
 add_theme_color_override("font_shadow_color",FogPalette.INK if shadow>0 else Color(0,0,0,0))
 add_theme_constant_override("shadow_offset_x",shadow);add_theme_constant_override("shadow_offset_y",shadow)
 return self
func set_value(value: Variant) -> void:text=str(value)
