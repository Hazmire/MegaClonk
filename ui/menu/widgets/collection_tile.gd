class_name CollectionTile
extends Button
# One entry in the Unlocks grids. States: On / Off / Locked, plus Selected (focus or hover) and a NEW badge.
#  "card" style (Weapons, Tomes, Traits, Ultimates): art, serif name and an ON / OFF / LOCKED chip.
#  "mini" style (Items): 88px tile, 2x art, 4px rarity strip along the bottom, OFF chip, padlock when locked.
signal highlighted(tile: CollectionTile)
var entry_id=""
var entry_name=""
var category=""
var state="on" # on | off | locked
var is_new=false
var rarity=-1
var mini=false
var icon_px=96
var frame_style="plain" # plain | patch (sewn patch, Traits) | iron (iron frame, Ultimates)
var art: TextureRect
func setup(cat: String,id: String,display_name: String,tile_state: String,tile_size: Vector2,icon_pixels: int,rarity_tier: int=-1,new_badge: bool=false,mini_style: bool=false) -> CollectionTile:
 category=cat;entry_id=id;entry_name=display_name;state=tile_state;rarity=rarity_tier;is_new=new_badge;mini=mini_style;icon_px=icon_pixels
 custom_minimum_size=tile_size;size=tile_size;name="Tile_"+id.replace(" ","_");tooltip_text=display_name
 if art==null:
  art=MenuStyle.icon_rect(cat,id,icon_pixels);add_child(art)
 art.size=Vector2(icon_px,icon_px);_apply_state();_place();return self
func set_state(value: String) -> void:state=value;_apply_state();queue_redraw()
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true
 for s in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(s,StyleBoxEmpty.new())
 focus_entered.connect(_on_focus);focus_exited.connect(queue_redraw)
 mouse_entered.connect(func():if not has_focus():grab_focus())
func _on_focus() -> void:queue_redraw();highlighted.emit(self)
func _apply_state() -> void:
 if art==null:return
 if state=="locked":art.material=MenuStyle.shader_material("res://ui/shaders/grayscale.gdshader");art.modulate=Color.WHITE
 else:art.material=null;art.modulate=Color(1,1,1,0.4) if state=="off" else Color.WHITE
func _place() -> void:
 if art!=null:art.position=Vector2(floorf((size.x-icon_px)*0.5),8.0 if mini else 14.0)
func _notification(what: int) -> void:
 if what==NOTIFICATION_RESIZED:_place()
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size);var selected=has_focus()
 draw_rect(r,Color("221616") if selected else (Color(0.055,0.059,0.055,0.6) if state=="locked" else FogPalette.NIGHT_TILE))
 var border=FogPalette.RUST_BRIGHT if selected else FogPalette.BORDER
 if mini and rarity==FogPalette.Rarity.LEGENDARY and state!="locked" and not selected:border=Color("8A5A0E")
 if selected:
  draw_rect(r.grow(-1.0),border,false,2.0)
  if mini:draw_rect(r.grow(1.5),Color(0.702,0.212,0.247,0.35),false,3.0)
 elif state=="locked":_dashed(r,border)
 else:draw_rect(r.grow(-0.5),border,false,1.0)
 if frame_style=="patch":_draw_patch()
 elif frame_style=="iron":_draw_iron()
 if mini:_draw_mini()
 else:_draw_card()
func _draw_patch() -> void:
 # sewn patch: round cloth with a ring of stitches behind the icon
 var c=Vector2(size.x*0.5,14.0+icon_px*0.5);var radius=icon_px*0.5+10.0
 draw_circle(c,radius,Color("2B2A22") if state!="locked" else Color("1F201D"))
 var n=28
 for i in n:
  var a=TAU*float(i)/n
  draw_line(c+Vector2(cos(a),sin(a))*(radius-4.0),c+Vector2(cos(a+0.12),sin(a+0.12))*(radius-4.0),Color("A9ADA4") if state!="locked" else Color("5A5D56"),2.0)
func _draw_iron() -> void:
 var iron=Color("5A5D56") if state!="locked" else Color("34362F")
 draw_rect(Rect2(Vector2.ZERO,size).grow(-3.0),iron,false,4.0)
 draw_rect(Rect2(Vector2.ZERO,size).grow(-7.0),Color("141513"),false,2.0)
 for corner in [Vector2(9,9),Vector2(size.x-9,9),Vector2(9,size.y-9),Vector2(size.x-9,size.y-9)]:
  draw_rect(Rect2(corner-Vector2(3,3),Vector2(6,6)),Color("8D9188") if state!="locked" else Color("4A4D47"))
func _dashed(r: Rect2,color: Color) -> void:
 var dash=6.0
 var x=r.position.x
 while x<r.end.x:
  var w=minf(dash,r.end.x-x)
  draw_rect(Rect2(x,r.position.y,w,1),color);draw_rect(Rect2(x,r.end.y-1,w,1),color);x+=dash*2.0
 var y=r.position.y
 while y<r.end.y:
  var h=minf(dash,r.end.y-y)
  draw_rect(Rect2(r.position.x,y,1,h),color);draw_rect(Rect2(r.end.x-1,y,1,h),color);y+=dash*2.0
func _draw_card() -> void:
 var locked=state=="locked"
 var serif=MenuStyle.serif()
 var name_color=Color("7A7D76") if locked else FogPalette.BONE
 var name_y=14.0+icon_px+8.0
 draw_multiline_string(serif,Vector2(6,name_y+serif.get_ascent(22)),entry_name,HORIZONTAL_ALIGNMENT_CENTER,size.x-12,22,2,name_color)
 var chip_y=size.y-12.0-20.0
 match state:
  "on":_chip("ON",Rect2(0,chip_y,0,20),FogPalette.RUST,FogPalette.BONE_BRIGHT,false)
  "off":_chip("OFF",Rect2(0,chip_y,0,20),Color(0,0,0,0),FogPalette.ASH,true)
  "locked":_locked_chip(chip_y)
  "plain":pass
 if is_new:
  var f=MenuStyle.sans(800,0.18,11);var s=f.get_string_size("NEW",HORIZONTAL_ALIGNMENT_LEFT,-1,11)
  var box=Rect2(size.x-8-(s.x+12),8,s.x+12,s.y+4)
  draw_rect(box,FogPalette.GOLD);draw_string(f,box.position+Vector2(6,2+f.get_ascent(11)),"NEW",HORIZONTAL_ALIGNMENT_LEFT,-1,11,FogPalette.MEMO_INK)
func _chip(word: String,at: Rect2,bg: Color,fg: Color,outline: bool) -> void:
 var f=MenuStyle.sans(800,0.22,12);var s=f.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
 var box=Rect2((size.x-(s.x+18))*0.5,at.position.y,s.x+18,20)
 if bg.a>0.0:draw_rect(box,bg)
 if outline:draw_rect(box.grow(-0.5),Color("6A6D66"),false,1.0)
 draw_string(f,box.position+Vector2(9,(20-f.get_height(12))*0.5+f.get_ascent(12)),word,HORIZONTAL_ALIGNMENT_LEFT,-1,12,fg)
func _locked_chip(y: float) -> void:
 var f=MenuStyle.sans(800,0.22,12);var s=f.get_string_size("LOCKED",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
 var total=s.x+13+6;var x=(size.x-total)*0.5
 _padlock(Vector2(x,y+4),13,FogPalette.ASH_DIM)
 draw_string(f,Vector2(x+19,y+(20-f.get_height(12))*0.5+f.get_ascent(12)),"LOCKED",HORIZONTAL_ALIGNMENT_LEFT,-1,12,FogPalette.ASH_DIM)
func _padlock(at: Vector2,px: float,color: Color) -> void:
 var k=px/24.0
 draw_rect(Rect2(at+Vector2(5,11)*k,Vector2(14,10)*k),color,false,2.5*k)
 draw_polyline(PackedVector2Array([at+Vector2(8,11)*k,at+Vector2(8,7)*k,at+Vector2(10,4.5)*k,at+Vector2(14,4.5)*k,at+Vector2(16,7)*k,at+Vector2(16,11)*k]),color,2.5*k)
func _draw_mini() -> void:
 var locked=state=="locked"
 if rarity>=0:
  draw_rect(Rect2(0,size.y-4,size.x,4),Color(0.35,0.35,0.35) if locked else MenuStyle.rarity_color(rarity))
  if rarity==FogPalette.Rarity.LEGENDARY and state!="locked":
   var g=Color(0.941,0.667,0.235)
   for i in 4:draw_rect(Rect2(Vector2.ZERO,size).grow(float(i)*1.5),Color(g.r,g.g,g.b,0.10*(1.0-float(i)/4.0)),false,1.5)
 if state=="off":
  var f=MenuStyle.sans(800,0.18,10);var s=f.get_string_size("OFF",HORIZONTAL_ALIGNMENT_LEFT,-1,10)
  var box=Rect2(4,4,s.x+8,15);draw_rect(box,Color(0.055,0.059,0.055,0.9));draw_rect(box.grow(-0.5),Color("6A6D66"),false,1.0)
  draw_string(f,box.position+Vector2(4,(15-f.get_height(10))*0.5+f.get_ascent(10)),"OFF",HORIZONTAL_ALIGNMENT_LEFT,-1,10,FogPalette.ASH)
 if locked:_padlock(Vector2(size.x-19,size.y-23),15,FogPalette.ASH)
 if is_new:draw_rect(Rect2(size.x-10,4,6,6),FogPalette.GOLD)
