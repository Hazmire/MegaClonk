class_name BossBar
extends Control
# One boss health bar, drawn entirely in _draw (no child nodes, no allocations per frame). Used for both kinds:
#   stage boss: 920px, skull + name (IM Fell English SC 34), optional italic epithet, rust STAGE BOSS tag, hp / max, a 24px
#               dithered rust bar split in 10 segments between iron end caps, status row underneath, "ENRAGED" at <=25%.
#   miniboss:   440px, amber diamond + name (IM Fell English 24), outlined MINIBOSS tag, hp / max, 12px amber bar, 5 segments.
# Damage trail: the fill drops at once, a bone strip drains after 0.45 s over 0.55 s. Hit flash: white for 0.14 s.
# Kill: the SLAIN stamp slams onto the bar and the bar leaves after ~1.5 s (RunBossBars frees the slot).
const TRAIL_DELAY=0.45
const TRAIL_DRAIN=0.55
const FLASH=0.14
const SLAIN_TIME=1.5
const LOW=0.25
var stage_boss=true
var target: Dictionary={}
var boss_name=""
var epithet=""
var hp=0.0
var max_hp=1.0
var fraction=1.0
var trail=1.0
var trail_hold=0.0
var flash_left=0.0
var slain_t=-1.0 # <0 alive; otherwise seconds since death
var clock=0.0
var statuses: Array=[] # element ids active on the boss
var lit=false # inside the pool (true while assigned)
func configure(is_stage: bool) -> BossBar:
 stage_boss=is_stage;custom_minimum_size=Vector2(920 if is_stage else 440,(100 if is_stage else 58));size=custom_minimum_size;mouse_filter=Control.MOUSE_FILTER_IGNORE;visible=false;return self
func assign(enemy: Dictionary) -> void:
 target=enemy;var v: Dictionary=enemy.get("variant",{});boss_name=str(v.get("name","Boss"));epithet=str(v.get("epithet",""))
 max_hp=maxf(1.0,float(enemy.max_hp));hp=maxf(0.0,float(enemy.hp));fraction=hp/max_hp;trail=fraction;trail_hold=0.0;flash_left=0.0;slain_t=-1.0;statuses=[];lit=true;visible=true;queue_redraw()
func release() -> void:
 target={};lit=false;visible=false;slain_t=-1.0
# Reads the boss and advances the animation. Returns true while the bar still needs drawing.
func step(delta: float) -> bool:
 if not lit:return false
 clock+=delta
 if slain_t>=0.0:
  slain_t+=delta;trail=maxf(0.0,trail-delta/TRAIL_DRAIN);queue_redraw();return slain_t<SLAIN_TIME
 var now=maxf(0.0,float(target.hp));max_hp=maxf(1.0,float(target.max_hp))
 if now<=0.0:
  hp=0.0;fraction=0.0;slain_t=0.0;flash_left=FLASH;queue_redraw();return true
 var f=now/max_hp
 if f<fraction-0.0001:flash_left=FLASH;trail_hold=TRAIL_DELAY
 hp=now;fraction=f
 if trail>fraction:
  if trail_hold>0.0:trail_hold-=delta
  else:trail=maxf(fraction,trail-delta/TRAIL_DRAIN*maxf(0.2,trail-fraction)*2.0)
 else:trail=fraction
 flash_left=maxf(0.0,flash_left-delta)
 statuses=[]
 var fx=target.get("fx")
 if fx is Dictionary:
  for element in Elements.IDS:
   if fx.has(element):statuses.append(element)
 queue_redraw();return true
func low() -> bool:return slain_t<0.0 and fraction<=LOW
func _draw() -> void:
 if not lit:return
 if stage_boss:_draw_stage()
 else:_draw_mini()
func _fill_color() -> Color:
 if stage_boss:return FogPalette.RUST_BRIGHT if low() else FogPalette.RUST
 return Color("D9963A")
func _draw_bar(rect: Rect2,segments: int,color: Color,cap_px: int) -> void:
 var pulse=0.5+0.5*sin(clock*TAU*1.6) if low() else 0.0
 draw_rect(rect.grow(2),FogPalette.INK);draw_rect(rect,Color(0.1,0.04,0.045,0.95) if stage_boss else Color(0.07,0.055,0.04,0.95))
 var fill=Rect2(rect.position,Vector2(rect.size.x*fraction,rect.size.y))
 var tr=Rect2(rect.position+Vector2(fill.size.x,0),Vector2(rect.size.x*maxf(0.0,trail-fraction),rect.size.y))
 if tr.size.x>0.0:draw_rect(tr,Color(FogPalette.BONE.r,FogPalette.BONE.g,FogPalette.BONE.b,0.85))
 if fill.size.x>0.0:
  var c=color.lerp(Color.WHITE,pulse*0.25)
  draw_rect(fill,c)
  # 4px checker dither, like the dither_fill shader used by the HUD bars
  var step=4.0
  for gx in range(0,int(fill.size.x/step)+1):
   for gy in range(0,int(rect.size.y/step)+1):
    if (gx+gy)%2==0:draw_rect(Rect2(fill.position+Vector2(gx*step,gy*step),Vector2(minf(step,fill.size.x-gx*step),minf(step,rect.size.y-gy*step))).intersection(fill),Color(1,1,1,0.06))
 if flash_left>0.0:draw_rect(rect,Color(1,1,1,0.75*flash_left/FLASH))
 for i in range(1,segments):draw_rect(Rect2(rect.position.x+rect.size.x*float(i)/segments-1.0,rect.position.y,2.0,rect.size.y),Color(0.02,0.02,0.02,0.85))
 if cap_px>0:
  for x in [rect.position.x-cap_px-2.0,rect.end.x+2.0]:
   draw_rect(Rect2(x,rect.position.y-3.0,cap_px,rect.size.y+6.0),Color("3A3D38"));draw_rect(Rect2(x+2.0,rect.position.y+rect.size.y*0.5-2.0,4.0,4.0),Color("8D9188"))
func _text_right(font: Font,text: String,px: int,right: float,baseline: float,color: Color) -> void:
 var w=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x;draw_string(font,Vector2(right-w,baseline),text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func _shadowed(font: Font,text: String,px: int,pos: Vector2,color: Color,shadow: float=2.0) -> void:
 draw_string(font,pos+Vector2(shadow,shadow),text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,FogPalette.INK);draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func _tag(text: String,x: float,y: float,color: Color,filled: bool) -> float:
 var f=MenuStyle.sans(800,0.2,11);var w=f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+14.0;var r=Rect2(x,y,w,18)
 if filled:draw_rect(r,color)
 else:draw_rect(r.grow(-0.5),color,false,1.0)
 draw_string(f,Vector2(x+7,y+13),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,FogPalette.BONE_BRIGHT if filled else color);return w
func _skull(at: Vector2,px: float) -> void:
 var rows=["..XXXXX..",".XXXXXXX.","XXXXXXXXX","XX..X..XX","XX..X..XX","XXXXXXXXX",".XXX.XXX.","..X.X.X..","..XXXXX.."]
 for y in rows.size():
  for x in rows[y].length():
   if rows[y][x]=="X":draw_rect(Rect2(at+Vector2(x,y)*px,Vector2(px,px)),FogPalette.BONE if not (y in [3,4] and x in [2,3,5,6]) else FogPalette.INK)
func _status_row(y: float,x0: float) -> void:
 var x=x0
 for element in statuses:
  var c: Color=FogPalette.ELEMENT.get(element,Elements.color(element));var f=MenuStyle.sans(800,0.14,11);var label=Elements.display_name(element).to_upper()
  var w=f.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+24.0
  draw_rect(Rect2(x,y,w,16),Color(c.r,c.g,c.b,0.18));draw_rect(Rect2(x+0.5,y+0.5,w-1,15),c,false,1.0);draw_colored_polygon(PackedVector2Array([Vector2(x+9,y+3),Vector2(x+15,y+8),Vector2(x+9,y+13),Vector2(x+3,y+8)]),c)
  draw_string(f,Vector2(x+19,y+12),label,HORIZONTAL_ALIGNMENT_LEFT,-1,11,c);x+=w+6.0
func _draw_stage() -> void:
 var w=size.x;var serif=MenuStyle.serif_sc();var num=MenuStyle.sans(800,0.04,18)
 _skull(Vector2(26,4),2.6)
 var name_x=62.0;_shadowed(serif,boss_name,34,Vector2(name_x,30),FogPalette.BONE_BRIGHT,3.0)
 var name_w=serif.get_string_size(boss_name,HORIZONTAL_ALIGNMENT_LEFT,-1,34).x
 var x=name_x+name_w+16.0
 if epithet!="":
  var ef=MenuStyle.serif();draw_string(ef,Vector2(x,28),epithet,HORIZONTAL_ALIGNMENT_LEFT,-1,20,FogPalette.ASH);x+=ef.get_string_size(epithet,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x+16.0
 x+=_tag("STAGE BOSS",x,12,FogPalette.RUST,true)+8.0
 if low() and fmod(clock,0.5)<0.3:_tag("ENRAGED",x,12,FogPalette.RUST_BRIGHT,false)
 _text_right(num,"%d / %d"%[ceili(hp),ceili(max_hp)],18,w-26.0,28,FogPalette.BONE)
 _draw_bar(Rect2(26,44,w-52,24),10,_fill_color(),12 if false else 0)
 # iron end caps sit just outside the bar
 for cap_x in [8.0,w-20.0]:
  draw_rect(Rect2(cap_x,41,12,30),Color("3A3D38"));draw_rect(Rect2(cap_x+4,52,4,8),Color("8D9188"))
 _status_row(76,26)
 if slain_t>=0.0:_stamp("SLAIN",FogPalette.RUST_BRIGHT,Vector2(w*0.5,56),38)
func _draw_mini() -> void:
 var w=size.x;var serif=MenuStyle.serif();var num=MenuStyle.sans(800,0.04,13)
 var d=PackedVector2Array([Vector2(8,15),Vector2(16,23),Vector2(8,31),Vector2(0,23)]);draw_colored_polygon(d,Color("D9963A"));draw_polyline(d+PackedVector2Array([d[0]]),FogPalette.INK,1.5)
 _shadowed(serif,boss_name,24,Vector2(26,28),FogPalette.BONE_BRIGHT,2.0)
 var x=26.0+serif.get_string_size(boss_name,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x+12.0
 _tag("MINIBOSS",x,12,Color("D9963A"),false)
 _text_right(num,"%d / %d"%[ceili(hp),ceili(max_hp)],13,w-4.0,26,FogPalette.BONE)
 _draw_bar(Rect2(2,38,w-4,12),5,_fill_color(),0)
 if slain_t>=0.0:_stamp("SLAIN",FogPalette.GOLD,Vector2(w*0.5,44),24)
func _stamp(text: String,color: Color,centre: Vector2,px: int) -> void:
 var k=clampf(slain_t/0.18,0.0,1.0);var scale=lerpf(2.2,1.0,k*k)
 var f=MenuStyle.sans(800,0.3,px);var tw=f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
 draw_set_transform(centre,-0.05,Vector2(scale,scale))
 var r=Rect2(Vector2(-tw*0.5-14,-px*0.5-8),Vector2(tw+28,px+16));draw_rect(r,Color(0.03,0.03,0.03,0.82));draw_rect(r.grow(-1.5),color,false,3.0)
 draw_string(f,Vector2(-tw*0.5,px*0.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
 draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
