class_name ChestCard
extends Control
# The reveal card: a 400x520 paper-dark card for the item the chest gave, framed and lit by its real tier (Legendary is gold with light
# stripes and a heavy glow). Pure drawing from RunData.chest_data(); no "Unique" label (every item stacks).
const SIZE_PX=Vector2(400,520)
const FILL=[Color("1F211E"),Color("1A241B"),Color("172331"),Color("22182E"),Color("2A2010")]
var data: Dictionary={}
var gem_line=""
var gem_color=Color.WHITE
func setup(d: Dictionary) -> ChestCard:
 data=d;size=SIZE_PX;custom_minimum_size=SIZE_PX;pivot_offset=SIZE_PX*0.5;mouse_filter=Control.MOUSE_FILTER_IGNORE;return self
func _draw() -> void:
 var t=int(data.tier);var info=FogPalette.RARITY[t];var col: Color=info["color"];var r=Rect2(Vector2.ZERO,SIZE_PX)
 if RaritySlot.GLOW.has(t):
  var g: Array=RaritySlot.GLOW[t];var gc: Color=g[0];var reach: float=g[1]*(2.4 if t==FogPalette.Rarity.LEGENDARY else 1.4)
  for i in 10:
   var k=float(i+1)/10.0;draw_rect(r.grow(reach*k*0.5),Color(gc.r,gc.g,gc.b,gc.a*0.12*(1.0-k)),false,reach/10.0)
 draw_rect(r,FILL[t])
 if t==FogPalette.Rarity.LEGENDARY:
  var x=-460.0
  while x<SIZE_PX.x:
   draw_colored_polygon(PackedVector2Array([Vector2(x+60,SIZE_PX.y),Vector2(x+76,SIZE_PX.y),Vector2(x+76+SIZE_PX.y*0.466,0),Vector2(x+60+SIZE_PX.y*0.466,0)]),Color(1.0,0.945,0.76,0.08));x+=150.0
 draw_rect(r.grow(-2.5),col,false,5.0)
 if t==FogPalette.Rarity.LEGENDARY:draw_rect(r.grow(4.0),Color("3A2600"),false,4.0)
 var band=Rect2(Vector2(5,5),Vector2(SIZE_PX.x-10.0,46));draw_rect(band,col)
 var cf=MenuStyle.sans(800,0.3,16);var label=str(data.tier_name).to_upper()
 if t>=FogPalette.Rarity.RARE:label="◆ %s ◆"%label
 draw_string(cf,Vector2(band.position.x,band.position.y+29.0),label,HORIZONTAL_ALIGNMENT_CENTER,band.size.x,16,info["on"])
 var tex=UIAssets.icon("items",str(data.id));var s=210.0
 if tex!=null:
  if t>=FogPalette.Rarity.RARE:
   for k in 4:draw_circle(Vector2(SIZE_PX.x*0.5,170.0),s*0.5+float(k)*16.0,Color(col.r,col.g,col.b,0.05))
  draw_texture_rect(tex,Rect2(Vector2((SIZE_PX.x-s)*0.5,65.0),Vector2(s,s)),false)
 var nf=MenuStyle.serif_sc();var name_col=Color("FFF1C2") if t==FogPalette.Rarity.LEGENDARY else Color("F2EDDC")
 draw_multiline_string(nf,Vector2(24,318),str(data.name),HORIZONTAL_ALIGNMENT_CENTER,SIZE_PX.x-48.0,36,2,name_col)
 var kind="Item · kept in your bag" if bool(data.consumable) else "Item"
 var stack=int(data.get("stack",1))
 if stack>1 and not bool(data.consumable):kind="Item · you now hold %s"%("×%d"%stack)
 draw_string(MenuStyle.sans(800,0.28,13),Vector2(24,386),kind.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,SIZE_PX.x-48.0,13,col.lightened(0.15))
 draw_multiline_string(MenuStyle.memo(),Vector2(26,420),str(data.description),HORIZONTAL_ALIGNMENT_CENTER,SIZE_PX.x-52.0,17,4,Color("E8DFC8"))
 if gem_line!="":draw_string(MenuStyle.sans(800,0.1,16),Vector2(20,SIZE_PX.y-18.0),gem_line,HORIZONTAL_ALIGNMENT_CENTER,SIZE_PX.x-40.0,16,gem_color)
