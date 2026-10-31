class_name HudBar
extends ProgressBar
# Dithered HUD bar (health, XP). A ProgressBar so value/max_value keep their meaning everywhere; the look is a track, an ink
# border, a fill that uses the shared dither_fill shader and optional segment gaps. Width of the fill is updated only when the
# value, range or size actually change (signals), never per frame.
var fill: ColorRect
var fill_material: ShaderMaterial
var segments=0
var border_color=FogPalette.INK
var outer_color=Color(0,0,0,0) # extra 1px ring outside the border (health bar: #5A1418)
var track_color=FogPalette.RUST_DEEP
var inset=2
func setup(size_px: Vector2,color: Color,track: Color,border_px: int=2,segment_count: int=0,glow: float=0.0) -> HudBar:
 custom_minimum_size=size_px;size=size_px;show_percentage=false;mouse_filter=Control.MOUSE_FILTER_IGNORE;track_color=track;inset=border_px;segments=segment_count
 for style in ["background","fill"]:add_theme_stylebox_override(style,StyleBoxEmpty.new())
 fill=ColorRect.new();fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;fill.color=Color.WHITE
 fill_material=MenuStyle.shader_material("res://ui/shaders/dither_fill.gdshader",{"fill_color":color,"glow":glow});fill.material=fill_material;add_child(fill)
 value_changed.connect(func(_v):_sync());changed.connect(_sync);resized.connect(_sync)
 _sync();return self
func set_fill_color(color: Color) -> void:
 if fill_material!=null:fill_material.set_shader_parameter("fill_color",color)
func _sync() -> void:
 if fill==null:return
 var span=Vector2(size.x-inset*2,size.y-inset*2);var fraction=clampf(value/maxf(0.001,max_value),0.0,1.0)
 fill.position=Vector2(inset,inset);fill.size=Vector2(span.x*fraction,span.y);fill.visible=fraction>0.0
 queue_redraw()
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size)
 if outer_color.a>0.0:draw_rect(r.grow(1.0),outer_color,false,1.0)
 draw_rect(r,track_color)
 draw_rect(r.grow(-inset*0.5),border_color,false,float(inset))
 if segments>1:
  var span=size.x-inset*2
  for i in range(1,segments):draw_rect(Rect2(inset+span*float(i)/segments-1.0,inset,2.0,size.y-inset*2),Color(0.02,0.02,0.02,0.85))
func _exit_tree() -> void:
 if fill!=null:fill.material=null
 fill_material=null
