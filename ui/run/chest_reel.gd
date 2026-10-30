class_name ChestReel
extends Control
# The chest's reel: a row of item cards that slides under a gold marker and lands on the item the chest already holds. The motion
# is a pure function of `progress` (0..1), so the screen drives it and tests can set it. Drawing only; nothing is allocated per frame.
const STEP=192.0
const CARD=Vector2(180,224)
const CENTER=960.0
const BG=[Color("1A1C19"),Color("18201A"),Color("141E29"),Color("1E1528"),Color("2A2010")]
const NAME=[Color("D9D4C4"),Color("D9D4C4"),Color("E8E2D0"),Color("E8E2D0"),Color("FFF1C2")]
const GLOW_COL=[Color(0,0,0,0),Color(0,0,0,0),Color(0.27,0.55,0.86,0.35),Color(0.63,0.39,0.9,0.45),Color(0.95,0.76,0.3,0.55)]
var strip: Array=[]
var win_index=34
var land_offset=0.0
var progress=0.0
var landed=false
var blink=0.0
var last_tick=-1
func setup(cards: Array,win: int,offset: float) -> ChestReel:
 strip=cards;win_index=win;land_offset=offset;size=Vector2(1920,240);mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true;return self
# x of the strip's left edge for a progress value: starts two cards in, ends with the winner on the marker (a little off-centre).
func strip_x(p: float) -> float:
 var start=CENTER-90.0-2.0*STEP;var end=CENTER-90.0-win_index*STEP+land_offset
 return lerpf(start,end,1.0-pow(1.0-clampf(p,0.0,1.0),5.0))
# Index of the card under the marker (used for tick sounds).
func under_marker(p: float) -> int:return int(floorf((CENTER-strip_x(p))/STEP))
func set_progress(p: float,did_land: bool) -> void:
 progress=p;landed=did_land;queue_redraw()
func _process(delta: float) -> void:
 if landed:blink+=delta;queue_redraw()
func _draw() -> void:
 var x0=strip_x(progress);var blur=0.0 if landed else clampf((1.0-progress)*1.4,0.0,1.0)
 var first=maxi(0,int(floorf((-x0)/STEP))-1);var last=mini(strip.size()-1,int(ceilf((1920.0-x0)/STEP)))
 var name_font=MenuStyle.serif();var tag_font=MenuStyle.sans(800,0.22,11)
 for i in range(first,last+1):
  var c: Dictionary=strip[i];var t=int(c.tier);var info=FogPalette.RARITY[t];var col: Color=info["color"]
  var win=landed and i==win_index;var pulse=(sin(blink*7.0)*0.5+0.5) if win else 0.0
  var r=Rect2(Vector2(x0+i*STEP,8.0),CARD)
  if win:r=r.grow(8.0+pulse*5.0)
  if GLOW_COL[t].a>0.0 or win:
   var g: Color=Color(0.95,0.76,0.3,0.7) if win else GLOW_COL[t]
   for k in 5:draw_rect(r.grow(float(k+1)*3.0),Color(g.r,g.g,g.b,g.a*0.16*(1.0-float(k)/5.0)),false,3.0)
  draw_rect(r,BG[t]);draw_rect(r,col,false,3.0)
  var band=Rect2(r.position,Vector2(r.size.x,28.0));draw_rect(band,col)
  var label=str(info["name"]).to_upper()
  if t>=FogPalette.Rarity.RARE:label="★ %s%s"%[label," ★" if t==FogPalette.Rarity.LEGENDARY else ""]
  draw_string(tag_font,Vector2(r.position.x,r.position.y+19.0),label,HORIZONTAL_ALIGNMENT_CENTER,r.size.x,11,info["on"])
  var tex=UIAssets.icon("items",str(c.id))
  if tex!=null:
   var s=104.0*r.size.x/CARD.x;draw_texture_rect(tex,Rect2(r.position+Vector2((r.size.x-s)*0.5,28.0+(r.size.y-80.0-s)*0.5),Vector2(s,s)),false,Color(1,1,1,1.0-blur*0.35))
  draw_multiline_string(name_font,r.position+Vector2(8.0,r.size.y-38.0),str(c.name),HORIZONTAL_ALIGNMENT_CENTER,r.size.x-16.0,18,2,NAME[t])
 # marker
 var ma=1.0
 if landed:ma=1.0 if int(blink*8.0)%2==0 else 0.35
 draw_rect(Rect2(Vector2(CENTER-1.5,0),Vector2(3,size.y)),Color(0.95,0.76,0.3,ma))
 for k in 4:draw_rect(Rect2(Vector2(CENTER-1.5-float(k)*3.0,0),Vector2(3.0+float(k)*6.0,size.y)),Color(0.95,0.76,0.3,0.08*ma))
