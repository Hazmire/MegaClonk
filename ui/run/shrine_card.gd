class_name ShrineCard
extends Button
# One Shrine offer (RunShrine): a wide paper strip with the stat bonus in big type, the stat name and what it does, the rarity
# badge and the [n] key. Rare and above get a "FIND" tag and a glow; Legendary is gold with light stripes. The selected card
# shifts left, straightens and wears a rust outline.
const SIZE_PX=Vector2(776,150)
const PAPERS={0:Color("D3CBB2"),1:Color("D2D6C0"),2:Color("D5D6CB"),3:Color("DAD0DC"),4:Color("E6D6A8")}
const BONUS_INK={0:Color("1C1A15"),1:Color("245A22"),2:Color("1F5A9C"),3:Color("5E2C8F"),4:Color("8A4F00")}
const INK=Color("1C1A15")
var data: Dictionary={}
var number=1
var face: Control
var amount_selected=0.0
var rest_rot=0.0
func setup(card: Dictionary,index: int) -> ShrineCard:
 data=card;number=index+1;name="ShrineChoice%d"%index;rest_rot=deg_to_rad([-0.4,0.3,0.5][index%3])
 custom_minimum_size=SIZE_PX;size=SIZE_PX;focus_mode=Control.FOCUS_ALL;flat=true;text="";clip_contents=false
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 face=Control.new();face.name="Face";face.size=SIZE_PX;face.pivot_offset=SIZE_PX*0.5;face.rotation=rest_rot;face.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(face);face.draw.connect(_draw_face)
 mouse_entered.connect(func():if not has_focus():grab_focus())
 set_process(true);return self
func _process(delta: float) -> void:
 var target=1.0 if has_focus() else 0.0
 if amount_selected!=target:
  amount_selected=move_toward(amount_selected,target,delta*7.0)
  face.position.x=-6.0*amount_selected;face.rotation=lerpf(rest_rot,deg_to_rad(0.3),amount_selected);face.queue_redraw()
func _draw_face() -> void:
 var tier=int(data.tier);var info=FogPalette.RARITY[tier];var color: Color=info["color"];var r=Rect2(Vector2.ZERO,SIZE_PX);var sel=amount_selected
 if tier>=FogPalette.Rarity.UNCOMMON and RaritySlot.GLOW.has(tier):
  var g: Array=RaritySlot.GLOW[tier];var reach: float=g[1]*(1.7 if sel>0.0 or tier==FogPalette.Rarity.LEGENDARY else 0.8);var col: Color=g[0]
  for i in 8:
   var k=float(i+1)/8.0;face.draw_rect(r.grow(reach*k*0.5),Color(col.r,col.g,col.b,col.a*0.14*(1.0-k)),false,reach/8.0)
 face.draw_rect(Rect2(Vector2(5,7),r.size),Color(0,0,0,0.5))
 face.draw_rect(r,PAPERS[tier])
 if tier==FogPalette.Rarity.LEGENDARY:
  var x=-80.0
  while x<r.size.x:
   face.draw_colored_polygon(PackedVector2Array([Vector2(x,0),Vector2(x+12,0),Vector2(x-30,r.size.y),Vector2(x-42,r.size.y)]),Color(1.0,0.957,0.804,0.45));x+=80.0
 if tier>0:face.draw_rect(r.grow(-2.0),color,false,4.0)
 if tier==FogPalette.Rarity.LEGENDARY:face.draw_rect(r.grow(1.5),Color("3A2600"),false,3.0)
 if sel>0.01:face.draw_rect(r.grow(10.0),Color(FogPalette.RUST_BRIGHT.r,FogPalette.RUST_BRIGHT.g,FogPalette.RUST_BRIGHT.b,sel),false,4.0)
 var memo=MenuStyle.memo();var bonus=str(data.bonus);var bsize=62 if tier==FogPalette.Rarity.LEGENDARY else 58
 while bsize>30 and memo.get_string_size(bonus,HORIZONTAL_ALIGNMENT_LEFT,-1,bsize).x>168.0:bsize-=2
 face.draw_string(memo,Vector2(24,(r.size.y+bsize*0.62)*0.5),bonus,HORIZONTAL_ALIGNMENT_LEFT,170,bsize,BONUS_INK[tier])
 var rule_x=24.0+170.0+6.0;var y=26.0
 while y<r.size.y-24.0:face.draw_line(Vector2(rule_x,y),Vector2(rule_x,minf(y+5.0,r.size.y-24.0)),Color("8F876F"),1.0);y+=9.0
 face.draw_string(memo,Vector2(rule_x+24.0,68),str(data.stat_name),HORIZONTAL_ALIGNMENT_LEFT,360,28,INK)
 face.draw_multiline_string(memo,Vector2(rule_x+24.0,98),str(data.description),HORIZONTAL_ALIGNMENT_LEFT,360,16,2,Color("4A453A"))
 var cf=MenuStyle.sans(800,0.22,14);var label=str(data.tier_name).to_upper();var lw=cf.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
 if tier>0:
  face.draw_set_transform(Vector2(r.size.x-28.0-lw-26.0,44.0),deg_to_rad(-5.0),Vector2.ONE)
  face.draw_rect(Rect2(Vector2(-2,-17),Vector2(lw+34.0,28)),color)
  face.draw_string(cf,Vector2(24,3),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,info["on"])
  face.draw_colored_polygon(PackedVector2Array([Vector2(10,-11),Vector2(12,-6),Vector2(17,-4),Vector2(12,-2),Vector2(10,3),Vector2(8,-2),Vector2(3,-4),Vector2(8,-6)]),info["on"])
  face.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
 else:face.draw_string(cf,Vector2(r.size.x-28.0-lw,48),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("5A5446"))
 face.draw_string(MenuStyle.sans(800,0.2,13),Vector2(r.size.x-28.0-40.0,r.size.y-28.0),"[%d]"%number,HORIZONTAL_ALIGNMENT_RIGHT,40,13,Color("5A5446"))
 if tier>=FogPalette.Rarity.RARE:
  var tf=MenuStyle.sans(800,0.24,13);var tag="%s FIND"%str(data.tier_name).to_upper();var tw=tf.get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+48.0
  face.draw_rect(Rect2(Vector2(-4,-18),Vector2(tw,24)),color if tier!=FogPalette.Rarity.LEGENDARY else Color("C9861A"))
  face.draw_string(tf,Vector2(22,-1),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,13,info["on"])
