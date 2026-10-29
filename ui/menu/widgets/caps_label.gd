class_name SmallCapsLabel
extends Label
# Small-caps label: Overpass, upper case, wide tracking (the "SILVER", "WEAPON", "LEVEL-UP OPTIONS" lines).
func setup(value: String,size: int=13,color: Color=FogPalette.ASH_DIM,weight: int=800,tracking_em: float=0.28,shadow: int=0) -> SmallCapsLabel:
 text=value.to_upper();mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_theme_font_override("font",MenuStyle.sans(weight,tracking_em,size));add_theme_font_size_override("font_size",size)
 add_theme_color_override("font_color",color)
 add_theme_color_override("font_shadow_color",FogPalette.INK if shadow>0 else Color(0,0,0,0))
 add_theme_constant_override("shadow_offset_x",shadow);add_theme_constant_override("shadow_offset_y",shadow)
 return self
