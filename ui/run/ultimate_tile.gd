class_name UltimateTile
extends Control
# HUD ultimate tile (96px): Q key badge, ready pulse, cooldown sweep with seconds, READY / ACTIVE pill underneath.
# Redraws only when what it shows changes (state, whole seconds, key), plus a light pulse timer while READY.
const BOX=96.0
var texture: Texture2D
var key_text="Q"
var state="ready" # ready | cooling | active
var seconds=0
var fraction=0.0 # share of the cooldown still to go (0..1)
var ultimate_id=""
var pulse=0.0
var last_key=""
func _init() -> void:
 custom_minimum_size=Vector2(BOX,BOX+30);size=custom_minimum_size;mouse_filter=Control.MOUSE_FILTER_STOP;set_process(false)
func sync(game: Node) -> void:
 var l=RunData.loadout(game)
 var new_state="active" if l.active else ("ready" if l.ready else "cooling")
 var new_seconds=ceili(l.cooldown_left);var new_fraction=snappedf(l.cooldown_left/l.total,0.01)
 var new_key=OS.get_keycode_string(game.bindings.ultimate) if game.bindings.has("ultimate") else "Q"
 if l.ultimate!=ultimate_id:
  ultimate_id=l.ultimate;texture=UIAssets.icon("ultimates",ultimate_id);tooltip_text="Ultimate: %s"%ultimate_id.capitalize()
 if new_state!=state or new_seconds!=seconds or new_fraction!=fraction or new_key!=key_text:
  state=new_state;seconds=new_seconds;fraction=new_fraction;key_text=new_key;queue_redraw()
 set_process(state=="ready")
func _process(delta: float) -> void:
 pulse=fmod(pulse+delta/1.6,1.0);queue_redraw()
func _draw() -> void:
 var r=Rect2(0,0,BOX,BOX)
 var glow=0.5-0.5*cos(pulse*TAU) if state=="ready" else 0.0
 if state=="ready":
  for i in 5:draw_rect(r.grow(2+i*(2+glow*2)),Color(0.88,0.48,0.51,(0.22+0.2*glow)*(1.0-i/5.0)),false,2.0)
 draw_rect(r,Color("1C1E1B"))
 var border=FogPalette.RUST_BRIGHT if state!="active" else FogPalette.GOLD
 if state=="ready" and glow>0.5:border=FogPalette.RUST_TEXT
 if texture!=null:draw_texture_rect(texture,Rect2((BOX-64)*0.5,(BOX-64)*0.5,64,64),false,Color.WHITE if state!="cooling" else Color(1,1,1,0.45))
 if state=="cooling":
  # Dark sweep covers the part of the cooldown still to go, clockwise from the top.
  var centre=r.get_center();var pts=PackedVector2Array([centre]);var steps=24;var end=-PI/2.0+TAU*fraction
  for i in steps+1:
   var a=-PI/2.0+(end-(-PI/2.0))*float(i)/steps;pts.append(centre+Vector2(cos(a),sin(a))*BOX)
  var clip=PackedVector2Array()
  for p in pts:clip.append(Vector2(clampf(p.x,0,BOX),clampf(p.y,0,BOX)))
  if clip.size()>2 and fraction>0.0:draw_colored_polygon(clip,Color(0.02,0.02,0.02,0.55))
  var f=MenuStyle.sans(800,0,30);var text="%d"%seconds;var w=f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,30).x
  draw_string(f,Vector2((BOX-w)*0.5+2,BOX*0.5+11+2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,30,FogPalette.INK);draw_string(f,Vector2((BOX-w)*0.5,BOX*0.5+11),text,HORIZONTAL_ALIGNMENT_LEFT,-1,30,FogPalette.BONE_BRIGHT)
 draw_rect(r.grow(-1),border,false,2.0)
 draw_rect(Rect2(-8,-8,30,30),FogPalette.INK);draw_rect(Rect2(-10,-10,30,30),FogPalette.BONE)
 var kf=MenuStyle.sans(800,0,16);var kw=kf.get_string_size(key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
 draw_string(kf,Vector2(5-kw*0.5,16),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,FogPalette.MEMO_INK)
 var pill="READY" if state=="ready" else ("ACTIVE" if state=="active" else "")
 if pill!="":
  var pf=MenuStyle.sans(800,0.22,12);var pw=pf.get_string_size(pill,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+16
  var pr=Rect2((BOX-pw)*0.5,BOX+8,pw,19);draw_rect(pr,FogPalette.RUST if state=="ready" else Color("5A4310"))
  draw_string(pf,Vector2(pr.position.x+8,pr.position.y+14),pill,HORIZONTAL_ALIGNMENT_LEFT,-1,12,FogPalette.BONE_BRIGHT)
