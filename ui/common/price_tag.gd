class_name PriceTag
extends Control
# Paper price tag (Fog-Kit): memo-coloured card with a punched hole, slightly rotated, price in Special Elite ink.
# `affordable` false shows the price in rust. The amount is always passed in (Economy owns prices).
var amount=0
var affordable=true
var font_size=26
func setup(price: int,can_pay: bool=true,px: int=26,angle: float=-2.0) -> PriceTag:
 amount=price;affordable=can_pay;font_size=px;rotation_degrees=angle;mouse_filter=Control.MOUSE_FILTER_IGNORE
 var w=MenuStyle.memo().get_string_size(str(price),HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
 custom_minimum_size=Vector2(w+px*1.9,px*1.5);size=custom_minimum_size;pivot_offset=size/2.0;queue_redraw();return self
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size);var cut=size.y*0.3
 var poly=PackedVector2Array([Vector2(cut,0),Vector2(size.x,0),Vector2(size.x,size.y),Vector2(cut,size.y),Vector2(0,size.y*0.5)])
 draw_colored_polygon(poly+Vector2(2,2),Color(0,0,0,0.45));draw_colored_polygon(poly,FogPalette.MEMO)
 draw_polyline(poly+PackedVector2Array([poly[0]]),MenuStyle.PAPER_LINE,1.0)
 draw_circle(Vector2(cut*0.55,size.y*0.5),size.y*0.09,FogPalette.NIGHT)
 var ink=FogPalette.MEMO_INK if affordable else MenuStyle.SILVER_RUST
 var font=MenuStyle.memo()
 draw_string(font,Vector2(cut+font_size*0.45,(size.y-font.get_height(font_size))*0.5+font.get_ascent(font_size)),str(amount),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
