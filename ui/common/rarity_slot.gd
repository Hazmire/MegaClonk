class_name RaritySlot
extends Control
# Icon in a rarity frame (Fog-Rarity): Common 1px, Uncommon 2px + faint glow, Rare 4px + glow, Epic 4px double + stronger
# glow, Legendary 4px gold + biggest glow and the gold shimmer. `strip` mode is the compact item tile: 1px frame and a
# 4px rarity strip along the bottom.
var rarity=FogPalette.Rarity.COMMON
var icon: TextureRect
var icon_px=64
var strip=false
var selected=false
var dim=false
const GLOW={
 FogPalette.Rarity.UNCOMMON:[Color(0.353,0.706,0.314,0.35),16.0],
 FogPalette.Rarity.RARE:[Color(0.275,0.549,0.863,0.5),28.0],
 FogPalette.Rarity.EPIC:[Color(0.627,0.392,0.902,0.55),34.0],
 FogPalette.Rarity.LEGENDARY:[Color(0.941,0.667,0.235,0.65),44.0],
}
func setup(r: int,texture: Texture2D,icon_pixels: int,box: Vector2,strip_mode: bool=false) -> RaritySlot:
 rarity=r;icon_px=icon_pixels;strip=strip_mode;custom_minimum_size=box;size=box;mouse_filter=Control.MOUSE_FILTER_IGNORE
 if icon==null:
  icon=TextureRect.new();icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_SCALE;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(icon)
 icon.texture=texture;icon.size=Vector2(icon_px,icon_px)
 icon.material=MenuStyle.shader_material("res://ui/shaders/legendary_shimmer.gdshader") if r==FogPalette.Rarity.LEGENDARY else null
 _place();queue_redraw();return self
func _place() -> void:
 if icon!=null:icon.position=((size-Vector2(icon_px,icon_px))*0.5).floor()-(Vector2(0,2) if strip else Vector2.ZERO)
func _notification(what: int) -> void:
 if what==NOTIFICATION_RESIZED:_place()
func set_dim(value: bool) -> void:
 dim=value;modulate=Color(1,1,1,0.45) if value else Color.WHITE
func _draw() -> void:
 var info=FogPalette.RARITY[rarity];var c: Color=info["color"]
 var r=Rect2(Vector2.ZERO,size)
 if GLOW.has(rarity) and not dim:
  var g: Array=GLOW[rarity];var reach: float=g[1]*(0.3 if strip else 1.0);var col: Color=g[0]
  for i in 6:
   var k=float(i+1)/6.0
   draw_rect(r.grow(reach*k*0.5),Color(col.r,col.g,col.b,col.a*0.12*(1.0-k)),false,reach/6.0)
 draw_rect(r,info["bg"] if not strip else FogPalette.NIGHT_TILE)
 if strip:
  draw_rect(r.grow(-0.5),FogPalette.RUST_BRIGHT if selected else FogPalette.BORDER,false,2.0 if selected else 1.0)
  draw_rect(Rect2(0,size.y-4,size.x,4),c)
  return
 var frame=FogPalette.RUST_BRIGHT if selected else c
 match rarity:
  FogPalette.Rarity.COMMON:draw_rect(r.grow(-0.5),frame,false,1.0)
  FogPalette.Rarity.UNCOMMON:draw_rect(r.grow(-1.0),frame,false,2.0)
  FogPalette.Rarity.RARE:draw_rect(r.grow(-2.0),frame,false,4.0)
  FogPalette.Rarity.EPIC:
   draw_rect(r.grow(-0.5),Color("A26DD8"),false,1.0);draw_rect(r.grow(-3.5),Color("A26DD8"),false,1.0)
  FogPalette.Rarity.LEGENDARY:
   draw_rect(r.grow(-2.0),Color("E0A33A"),false,4.0);draw_rect(r.grow(1.5),Color("3A2600"),false,3.0)
