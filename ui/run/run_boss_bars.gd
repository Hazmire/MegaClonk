class_name RunBossBars
extends Control
# Boss health bars (RunBossBars): at most 2 stage-boss bars and 2 miniboss bars, from a fixed pool of BossBar controls,
# plus "+n more" when there are more, and an edge tab pointing at any shown boss that is outside the camera view.
# Bosses are found by scanning game.enemies a few times a second; each bar then reads its own boss dictionary every frame.
# Stage bosses are kind 8; minibosses are kinds 9 (champion) and 10 (hunter), the same kinds the old bar used.
const MAX_STAGE=2
const MAX_MINI=2
const SCAN_EVERY=0.1
const STAGE_BOSS_KINDS=[8]
const MINI_BOSS_KINDS=[9,10]
const TOP=150.0
var game: Node
var hud: RunHud
var stage_bars: Array=[]
var mini_bars: Array=[]
var pointers: Array=[]
var more_label: Label
var scan_left=0.0
var extra_stage=0
var extra_mini=0
var clock=0.0
func setup(owner_game: Node,owner_hud: RunHud) -> RunBossBars:
 game=owner_game;hud=owner_hud;name="RunBossBars";mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(MenuStyle.W,MenuStyle.H)
 for i in MAX_STAGE:
  var b=BossBar.new().configure(true);add_child(b);stage_bars.append(b)
 for i in MAX_MINI:
  var b=BossBar.new().configure(false);add_child(b);mini_bars.append(b)
 more_label=MenuStyle.label("",MenuStyle.sans(800,0.2,12),12,FogPalette.ASH,2,self);more_label.visible=false;more_label.name="MoreBosses"
 for i in MAX_STAGE+MAX_MINI:
  var p=BossPointer.new();add_child(p);pointers.append(p)
 return self
static func is_stage_boss(e: Dictionary) -> bool:return int(e.get("kind",0)) in STAGE_BOSS_KINDS
static func is_mini_boss(e: Dictionary) -> bool:return int(e.get("kind",0)) in MINI_BOSS_KINDS
func shown_bars() -> Array:
 var out=[]
 for b in stage_bars+mini_bars:
  if b.lit:out.append(b)
 return out
func _assigned(e: Dictionary,bars: Array) -> bool:
 for b in bars:
  if b.lit and is_same(b.target,e):return true
 return false
func _scan() -> void:
 var live_stage=[];var live_mini=[]
 for e in game.enemies:
  if float(e.hp)<=0.0:continue
  if is_stage_boss(e):live_stage.append(e)
  elif is_mini_boss(e):live_mini.append(e)
 for b in stage_bars+mini_bars:
  if b.lit and b.slain_t<0.0 and not game.enemies.has(b.target):b.release() # despawned without dying
 var open_stage=0;var open_mini=0
 for e in live_stage:
  if _assigned(e,stage_bars):continue
  var slot=stage_bars.filter(func(b):return not b.lit)
  if slot.is_empty():open_stage+=1
  else:slot[0].assign(e)
 for e in live_mini:
  if _assigned(e,mini_bars):continue
  var slot=mini_bars.filter(func(b):return not b.lit)
  if slot.is_empty():open_mini+=1
  else:slot[0].assign(e)
 extra_stage=open_stage;extra_mini=open_mini
# Immediate rescan and redraw (tests and stage changes); normal play scans every SCAN_EVERY seconds.
func refresh_now() -> void:
 scan_left=0.0;update(0.0,TOP)
func occupied_height() -> float:
 var h=0.0
 for b in stage_bars:
  if b.lit:h+=b.size.y+8.0
 if mini_bars.any(func(b):return b.lit):h+=mini_bars[0].size.y+8.0
 if extra_stage+extra_mini>0:h+=20.0
 return h
func update(delta: float,top: float) -> void:
 clock+=delta;scan_left-=delta
 if scan_left<=0.0:scan_left=SCAN_EVERY;_scan()
 var y=top
 for b in stage_bars:
  if b.step(delta):b.visible=true;b.position=Vector2((MenuStyle.W-b.size.x)*0.5,y);y+=b.size.y+8.0
  elif b.lit:b.release()
 var lit_minis=[]
 for b in mini_bars:
  if b.step(delta):lit_minis.append(b)
  elif b.lit:b.release()
 var total=lit_minis.size()*440.0+maxf(0,lit_minis.size()-1)*16.0;var x=(MenuStyle.W-total)*0.5
 for b in lit_minis:b.position=Vector2(x,y);x+=456.0
 if not lit_minis.is_empty():y+=mini_bars[0].size.y+8.0
 var more=extra_stage+extra_mini
 more_label.visible=more>0
 if more>0:
  more_label.text="+%d MORE %s"%[more,"BOSS" if more==1 else "BOSSES"];more_label.position=Vector2((MenuStyle.W-more_label.size.x)*0.5,y)
 _pointers()
# ---- off-screen pointer ---------------------------------------------------------------------------------------------
# Where an off-view boss gets its tab. `point` is the boss's projected position in stage pixels, `behind` is true when it is
# behind the camera. Returns {} when the boss is on screen (no pointer). Clamped clear of the HUD corners and the minimap.
static func pointer_for(point: Vector2,behind: bool) -> Dictionary:
 var area=Rect2(Vector2.ZERO,Vector2(MenuStyle.W,MenuStyle.H))
 if not behind and area.grow(-24.0).has_point(point):return {}
 var centre=area.get_center();var dir=point-centre
 if behind:dir=-dir
 if dir.length_squared()<1.0:dir=Vector2.DOWN
 dir=dir.normalized()
 var margin=Vector2(110,40);var inner=Rect2(Vector2(margin.x,230.0),Vector2(MenuStyle.W-margin.x*2.0,MenuStyle.H-230.0-150.0))
 var tx=INF if absf(dir.x)<0.0001 else (inner.size.x*0.5)/absf(dir.x);var ty=INF if absf(dir.y)<0.0001 else (inner.size.y*0.5)/absf(dir.y)
 var p=inner.get_center()+dir*minf(tx,ty)
 # keep clear of the paper map (bottom right), the health / ultimate block (bottom left) and the build panel (top left)
 var map_rect=Rect2(1540,670,380,410);var hp_rect=Rect2(0,880,780,200);var build_rect=Rect2(0,0,700,540)
 if map_rect.has_point(p):p=Vector2(p.x,map_rect.position.y-8.0) if p.x>=inner.end.x-2.0 else Vector2(map_rect.position.x-8.0,p.y)
 if hp_rect.has_point(p):p=Vector2(hp_rect.end.x+8.0,p.y) if p.y>=inner.end.y-2.0 else Vector2(p.x,hp_rect.position.y-8.0)
 if build_rect.has_point(p):p=Vector2(p.x,build_rect.end.y+8.0) if p.x<=inner.position.x+2.0 else Vector2(build_rect.end.x+8.0,p.y)
 return {"pos":p,"dir":dir}
func _pointers() -> void:
 var cam=game.player.camera if is_instance_valid(game.player) else null
 var i=0
 if cam!=null and is_instance_valid(cam) and DisplayServer.get_name()!="headless":
  for b in stage_bars+mini_bars:
   if not b.lit or b.slain_t>=0.0 or i>=pointers.size():continue
   var world: Vector3=b.target.pos;var behind=cam.is_position_behind(world)
   var point=hud.frontend.run_stage.from_screen(cam.unproject_position(world))
   var result=pointer_for(point,behind)
   if result.is_empty():continue
   var p: BossPointer=pointers[i];i+=1
   p.show_at(result.pos,result.dir,b.boss_name,world.distance_to(game.player.position),clock,b.stage_boss)
 for j in range(i,pointers.size()):pointers[j].visible=false
class BossPointer extends Control:
 var label=""
 var metres=0
 var dir=Vector2.DOWN
 var stage_kind=true
 func _init() -> void:
  mouse_filter=Control.MOUSE_FILTER_IGNORE;visible=false;size=Vector2(190,34)
 func show_at(pos: Vector2,direction: Vector2,boss_name: String,distance: float,clock: float,is_stage: bool) -> void:
  var m=roundi(distance)
  if boss_name!=label or m!=metres or direction!=dir or is_stage!=stage_kind:label=boss_name;metres=m;dir=direction;stage_kind=is_stage;queue_redraw()
  position=pos-size*0.5+direction*3.0*sin(clock*3.0);visible=true
 func _draw() -> void:
  var c=FogPalette.RUST_BRIGHT if stage_kind else Color("D9963A")
  draw_rect(Rect2(Vector2.ZERO,size),Color(0.055,0.059,0.055,0.92));draw_rect(Rect2(Vector2(0.5,0.5),size-Vector2.ONE),c,false,1.0)
  var tip=size*0.5+dir*(size*0.5+Vector2(12,12));var base=size*0.5+dir*(size*0.5+Vector2(2,2));var side=Vector2(-dir.y,dir.x)*8.0
  draw_colored_polygon(PackedVector2Array([tip,base+side,base-side]),c)
  var f=MenuStyle.sans(800,0.1,12);var name_text=label.to_upper();var shown=name_text if f.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x<120.0 else name_text.substr(0,12)+"…"
  draw_string(f,Vector2(8,14),shown,HORIZONTAL_ALIGNMENT_LEFT,-1,12,FogPalette.BONE_BRIGHT)
  draw_string(MenuStyle.sans(600,0.1,12),Vector2(8,28),"%d m"%metres,HORIZONTAL_ALIGNMENT_LEFT,-1,12,FogPalette.ASH)
