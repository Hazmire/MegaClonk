class_name LevelCard
extends Button
# One Level-up offer (RunLevelUp): a paper card framed by its rarity. Rare and above get a coloured header band and a glow,
# the selected card lifts, straightens and wears a rust outline. Everything shown comes from RunData.level_card().
const W=244.0
const H=470.0
const PAPERS=[Color("CFC7AD"),Color("D3CBB2")]
const INK=Color("1C1A15")
const INK_SOFT=Color("3A352C")
const INK_DIM=Color("5A5446")
const RULE=Color("8F876F")
var index=0
var number=1
var data: Dictionary={}
var face: Control
var selected_amount=0.0
var rest_rot=0.0
var dealt=1.0 # 0..1 deal-in progress, driven by the screen
var new_stamp: Stamp
var burst=-1.0 # Rare and above: 0..1 while the extra burst plays (set by the screen), -1 otherwise
const SPARKS=[[Vector2(-120,-140),10.0,false],[Vector2(130,-120),8.0,true],[Vector2(20,-190),12.0,false],[Vector2(-150,40),8.0,false],[Vector2(150,60),10.0,true]]
func setup(card_data: Dictionary,card_index: int,rotation_deg: float) -> LevelCard:
 data=card_data;index=card_index;number=card_index+1;rest_rot=deg_to_rad(rotation_deg);name="Card%d"%number
 custom_minimum_size=Vector2(W,H);size=Vector2(W,H);focus_mode=Control.FOCUS_ALL;flat=true;text="";clip_contents=false
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 face=Control.new();face.name="Face";face.size=size;face.pivot_offset=size*0.5;face.mouse_filter=Control.MOUSE_FILTER_IGNORE;face.rotation=rest_rot;add_child(face);face.draw.connect(_draw_face)
 if bool(data.is_new) and int(data.tier)==0 and data.type!="supply":
  new_stamp=Stamp.new().setup("NEW",Color("8E1B22"),13,0.2,2,-4.0 if index%2==0 else 3.0,Color(0,0,0,0),Vector2(7,3));new_stamp.position=Vector2(W-20-70,14);face.add_child(new_stamp)
 mouse_entered.connect(func():if not has_focus() and not disabled:grab_focus())
 focus_entered.connect(queue_redraw)
 set_process(true);return self
func tier_color() -> Color:return FogPalette.RARITY[int(data.tier)]["color"]
func is_selected() -> bool:return has_focus()
func _process(delta: float) -> void:
 var target=1.0 if is_selected() else 0.0
 if selected_amount!=target:
  selected_amount=move_toward(selected_amount,target,delta*7.0)
  face.position.y=-10.0*selected_amount;face.rotation=lerpf(rest_rot,deg_to_rad(-0.6),selected_amount);face.queue_redraw()
func _draw_face() -> void:
 var tier=int(data.tier);var info=FogPalette.RARITY[tier];var color: Color=info["color"];var r=Rect2(Vector2.ZERO,Vector2(W,H))
 var sel=selected_amount;var paper=PAPERS[index%2]
 if tier>0:paper=paper.lerp(color,0.06)
 if tier>0 and sel>0.0 and RaritySlot.GLOW.has(tier):
  var g: Array=RaritySlot.GLOW[tier];var reach: float=g[1]*1.6;var col: Color=g[0]
  for i in 8:
   var k=float(i+1)/8.0;face.draw_rect(r.grow(reach*k*0.5),Color(col.r,col.g,col.b,col.a*0.14*(1.0-k)*sel),false,reach/8.0)
 face.draw_rect(Rect2(Vector2(5,7),r.size),Color(0,0,0,0.5)) # hard paper shadow
 face.draw_rect(r,paper)
 if tier>0:face.draw_rect(r.grow(-2.0),color,false,4.0)
 if sel>0.01:face.draw_rect(r.grow(10.0),Color(FogPalette.RUST_BRIGHT.r,FogPalette.RUST_BRIGHT.g,FogPalette.RUST_BRIGHT.b,sel),false,4.0)
 var label_font=MenuStyle.sans(800,0.24,13);var body=MenuStyle.memo()
 var y=20.0
 if tier>0:
  face.draw_rect(Rect2(Vector2(2,2),Vector2(W-4,38)),color)
  var on: Color=info["on"];var d=Vector2(22,21)
  face.draw_colored_polygon(PackedVector2Array([d+Vector2(0,-7),d+Vector2(2,-2),d+Vector2(7,0),d+Vector2(2,2),d+Vector2(0,7),d+Vector2(-2,2),d+Vector2(-7,0),d+Vector2(-2,-2)]),on)
  face.draw_string(label_font,Vector2(36,26),str(data.tier_name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,on)
  var lv=level_text()
  if lv!="":
   var lf=MenuStyle.sans(800,0.14,13);var w=lf.get_string_size(lv,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
   face.draw_string(lf,Vector2(W-16-w,25),lv,HORIZONTAL_ALIGNMENT_LEFT,-1,13,on)
  y=62.0
 else:
  face.draw_string(label_font,Vector2(20,32),"COMMON",HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK_DIM)
  var lv=level_text()
  if lv!="" and not data.is_new:
   var lf=MenuStyle.sans(800,0.14,13);var w=lf.get_string_size(lv,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
   face.draw_string(lf,Vector2(W-20-w,32),lv,HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK_DIM)
  y=62.0
 # icon panel
 var panel=Rect2(Vector2(20,y),Vector2(W-40,150))
 face.draw_rect(panel,paper.darkened(0.1).lerp(color,0.12) if tier>0 else Color("C2B99D"));face.draw_rect(panel.grow(-1.0),color if tier>0 else RULE,false,2.0)
 var icon=_icon()
 if icon!=null:
  var w=icon.get_width();var px=float(w*maxi(1,floori(104.0/maxf(1.0,float(w))))) if w<104 else 104.0
  face.draw_texture_rect(icon,Rect2(panel.position+(panel.size-Vector2(px,px))*0.5,Vector2(px,px)),false)
 y=panel.end.y+36.0
 var name_text=str(data.name);var name_h=body.get_multiline_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,W-40,24,3).y
 face.draw_multiline_string(body,Vector2(20,y),name_text,HORIZONTAL_ALIGNMENT_LEFT,W-40,24,3,INK)
 y+=name_h+14.0
 for row in data.rows:
  if y>H-44.0:break
  if row.has("value"):
   face.draw_string(body,Vector2(20,y),str(row.label),HORIZONTAL_ALIGNMENT_LEFT,-1,16,INK_SOFT)
   var vw=body.get_string_size(str(row.value),HORIZONTAL_ALIGNMENT_LEFT,-1,16).x;face.draw_string(body,Vector2(W-20-vw,y),str(row.value),HORIZONTAL_ALIGNMENT_LEFT,-1,16,INK)
  else:
   face.draw_string(body,Vector2(20,y),str(row.label),HORIZONTAL_ALIGNMENT_LEFT,W-40,14,INK_SOFT);y+=22.0
   var inline="%s → %s"%[row.from,row.to]
   if body.get_string_size(inline,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x<=W-40:face.draw_string(body,Vector2(20,y),inline,HORIZONTAL_ALIGNMENT_LEFT,-1,16,INK)
   else:
    face.draw_multiline_string(body,Vector2(20,y),str(row.from),HORIZONTAL_ALIGNMENT_LEFT,W-40,16,2,INK_SOFT);y+=22.0
    face.draw_multiline_string(body,Vector2(20,y),"→ %s"%row.to,HORIZONTAL_ALIGNMENT_LEFT,W-40,16,2,INK)
  _dash(Vector2(20,y+10.0),W-40);y+=32.0
 if burst>=0.0 and burst<1.0 and tier>=FogPalette.Rarity.RARE:
  var k=burst;var c2=Color(color.r,color.g,color.b,0.95*(1.0-k));var sc=lerpf(0.85,1.6,k);var rr=Rect2(r.get_center()-r.size*sc*0.5,r.size*sc).grow(14.0*sc)
  face.draw_rect(rr,c2,false,6.0)
  for sp in SPARKS:
   var px=float(sp[1])*lerpf(1.0,0.2,k);var at=Vector2(W*0.5,H*0.4)+(sp[0] as Vector2)*k;face.draw_rect(Rect2(at-Vector2(px,px)*0.5,Vector2(px,px)),(color.lightened(0.7) if sp[2] else color.lightened(0.35)).lerp(Color(1,1,1,0),k))
 face.draw_string(MenuStyle.sans(800,0.2,13),Vector2(20,H-18),"[%d]"%number,HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK_DIM)
func _dash(at: Vector2,width: float) -> void:
 var x=0.0
 while x<width:face.draw_line(at+Vector2(x,0),at+Vector2(minf(x+4.0,width),0),RULE,1.0);x+=7.0
func level_text() -> String:
 if data.type=="supply" or int(data.level_to)==0:return ""
 if data.is_new:return "NEW"
 if int(data.level_from)>=int(data.level_to):return "LV %d MAX"%int(data.level_to)
 return "LV %d → %d"%[int(data.level_from),int(data.level_to)]
func _icon() -> Texture2D:
 if data.category=="":return null
 return UIAssets.icon(str(data.category),str(data.id))
