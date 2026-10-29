class_name Stamp
extends Control
# Rubber-stamp tag: bordered upper-case Overpass text, slightly rotated (LOCKED, NOT YET, DONE, MAXIMUM, UNIQUE).
var text=""
var ink=FogPalette.RUST_TEXT
var fill=Color(0,0,0,0)
var border=2
var font_size=15
var tracking=0.22
var pad=Vector2(10,5)
func setup(value: String,color: Color,size: int=15,track: float=0.22,border_px: int=2,angle: float=-3.0,bg: Color=Color(0,0,0,0),padding: Vector2=Vector2(10,5)) -> Stamp:
 text=value.to_upper();ink=color;font_size=size;tracking=track;border=border_px;fill=bg;pad=padding;rotation_degrees=angle
 mouse_filter=Control.MOUSE_FILTER_IGNORE;_fit();return self
func text_size() -> Vector2:return MenuStyle.sans(800,tracking,font_size).get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
func _fit() -> void:
 var s=text_size()
 custom_minimum_size=s+pad*2;size=custom_minimum_size;pivot_offset=size/2.0;queue_redraw()
func _draw() -> void:
 var font=MenuStyle.sans(800,tracking,font_size)
 if fill.a>0.0:draw_rect(Rect2(Vector2.ZERO,size),fill)
 if border>0:draw_rect(Rect2(Vector2.ONE*border*0.5,size-Vector2.ONE*border),ink,false,border)
 var s=text_size()
 draw_string(font,Vector2((size.x-s.x)*0.5,(size.y-font.get_height(font_size))*0.5+font.get_ascent(font_size)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
