class_name FusionForms
extends RefCounted

# The eight fused attack forms. Each weapon, when it is a Fusion, gains one extra behaviour on top of its normal attack:
#   Sword       every 3rd slash throws a crescent wave          Firestaff  the lead fireball is a comet that splits into a meteor shower
#   Lightning   a storm cloud strikes on its own and tethers    Bow        the arrow splits into three shards on its first pierce
#   Revolver    every 6th shot is a judgement round + a line    Aura       twin rings, every 3rd pulse erupts
#   Scythes     a vortex where each blade turns back            Shotgun    a bile wall across the cone
# Rules: every point of damage goes through Game.hit() (tagged with the Fusion, see strike_form); every number is in Fusions.FORMS;
# the forms use the weapon's own rng for gameplay picks and the cosmetic rng for looks, so VFX and audio never change a seeded run.
const MAX_CRESCENTS=12
const MAX_TETHERS=24
const MAX_LINES=10
const MAX_CLOUD_TARGETS=4
var rt: WeaponRuntime
var game: Node
var crescents: Array=[]
var tethers: Array=[]
var lines: Array=[]
var vortices: Array=[]
var walls: Array=[]
var clouds: Dictionary={} # weapon id -> {"clock","t"}
var counters: Dictionary={"slashes":0,"shots":0,"pulses":0}
var form_bucket=0.0
var stats={"hits":0,"dropped":0,"crescents":0,"meteors":0,"strikes":0,"splits":0,"judgements":0,"lines":0,"vortices":0,"walls":0,"eruptions":0}
static var enabled=true # tests and the DPS table switch the forms off to measure a Fusion without its attack form
func _init(runtime: WeaponRuntime) -> void:
 rt=runtime;game=runtime.game;form_bucket=float(Fusions.SAFETY.form_hits_per_second)
func clear() -> void:
 crescents.clear();tethers.clear();lines.clear();vortices.clear();walls.clear();clouds.clear()
 counters={"slashes":0,"shots":0,"pulses":0}
# ----------------------------------------------------------------------------------------------------------------------------
# Damage: the only way a form hurts an enemy. Tagged with the Fusion, through Game.hit (crit, items, status procs and the boss clamp all apply).
func strike_form(f: String,e: Dictionary,damage: float,id: int,source: String,dir: Vector3=Vector3.ZERO,pos: Vector3=Vector3.INF) -> bool:
 if e.is_empty() or e.hp<=0:return false
 if form_bucket<1.0:stats.dropped+=1;return false
 form_bucket-=1.0;stats.hits+=1
 game.hit(e,damage,id,{"source":source,"dir":dir,"pos":pos if pos.is_finite() else e.pos,"fusion":f,"form":true})
 return true
func refill(delta: float) -> void:
 form_bucket=minf(float(Fusions.SAFETY.form_hits_per_second),form_bucket+delta*float(Fusions.SAFETY.form_hits_per_second))
func fusion_of(id: int) -> String:return str(rt.fusion_of.get(id,""))
func base_damage(id: int) -> float:
 return float(WeaponStats.resolve(game,id,game.weapons[id]).damage) if game.weapons.has(id) else 0.0
# ----------------------------------------------------------------------------------------------------------------------------
# Per-frame step, after the weapons have fired.
func tick(delta: float) -> void:
 refill(delta)
 for id in game.weapons.keys():
  var f=fusion_of(id)
  if f=="":clouds.erase(id);continue
  FusionFx.begin(rt,f)
  if id==2:cloud_tick(id,f,delta)
  FusionFx.motes(rt,f,float(game.elapsed)+float(id))
 step_crescents(delta);step_tethers(delta);step_lines(delta);step_vortices(delta);step_walls(delta)
 rt.psx.tint_end()
# ---- Sword: every 3rd slash throws a crescent wave ----------------------------------------------------------------------------
func on_slash(id: int,f: String,dir: Vector3,r: Dictionary) -> void:
 if not enabled:return
 var form=Fusions.form(0)
 counters.slashes+=1
 if counters.slashes%int(form.every)!=0 or crescents.size()>=MAX_CRESCENTS:return
 stats.crescents+=1
 var from=rt.origin_pos()
 crescents.append({"id":id,"f":f,"pos":from,"dir":dir,"t":0.0,"time":float(form.crescent_time),"speed":float(form.crescent_dist)/float(form.crescent_time),"damage":float(r.damage)*float(form.damage_mult),"reach":float(form.crescent_width)*float(r.size_mult),"hits":{}})
 game.audio.emit("weapon.sword_swing_final",from,0.8,1.2)
func step_crescents(delta: float) -> void:
 var i=crescents.size()-1
 while i>=0:
  var c=crescents[i]
  c.t+=delta;var prev: Vector3=c.pos;c.pos=prev+c.dir*float(c.speed)*delta
  for e in game.nearby(c.pos,float(c.reach)+2.5):
   if c.hits.has(e.crowd_id):continue
   if game.segment_distance(e.pos,prev,c.pos)>float(c.reach)+rt.hit_reach(e):continue
   c.hits[e.crowd_id]=true;strike_form(c.f,e,float(c.damage),int(c.id),"crescent",c.dir,e.pos)
  if c.t>=float(c.time):crescents.remove_at(i);i-=1;continue
  # the wave: a thick arc facing the way it travels, two tones, with the Fusion's trail behind it
  var right=Vector3(-c.dir.z,0,c.dir.x)
  var span=float(c.reach)
  var p=Fusions.palette(c.f)
  var grow=1.0-0.35*float(c.t)/float(c.time)
  var prev_pt=Vector3.ZERO
  for k in 8:
   var a=lerpf(-1.1,1.1,float(k)/7.0)
   var pt=c.pos+(c.dir*cos(a)*0.5+right*sin(a))*span*grow
   if k>0:
    rt.psx.draw_segment(prev_pt,pt,0.34,p.mid);rt.psx.draw_segment(prev_pt+Vector3.UP*0.04,pt+Vector3.UP*0.04,0.12,p.core)
   prev_pt=pt
  FusionFx.trail(rt,c.f,c.pos+right*rt.psx.rng.randf_range(-span,span)*0.6,1.2)
  i-=1
# ---- Firestaff: comet into meteor shower ----------------------------------------------------------------------------------------
func comet_splits(b: Dictionary,at: Vector3) -> void:
 if not enabled:return
 var form=Fusions.form(1);var f=str(b.fusion)
 var pool=game.nearby(at,float(form.meteor_range))
 var n=int(form.meteors)
 FusionFx.impact(rt,f,at,Vector3.UP,1.5)
 for k in n:
  var target=rt.random_enemy(pool)
  var land: Vector3=target.pos if not target.is_empty() else at+Vector3(rt.rng.randf_range(-2.5,2.5),0,rt.rng.randf_range(-2.5,2.5))
  rt.later(float(form.meteor_delay)+float(k)*float(form.meteor_gap),meteor_land.bind(int(b.id),f,land,float(b.base_damage)*float(form.meteor_damage_mult),float(form.meteor_radius)))
func meteor_land(id: int,f: String,land: Vector3,damage: float,radius: float) -> void:
 if not game.weapons.has(id):return
 stats.meteors+=1
 FusionFx.begin(rt,f)
 var sky=land+Vector3(-1.0,6.0,0.4)
 rt.psx.segment(sky,land,0.3,Fusions.color(f,"core"),Fusions.color(f,"mid"),0.1,0.0,0.4)
 FusionFx.impact(rt,f,land,Vector3.UP,1.0)
 for e in game.nearby(land,radius+1.0):
  if e.pos.distance_to(land)>radius+rt.hit_reach(e):continue
  strike_form(f,e,damage,id,"meteor",Vector3.DOWN,e.pos)
 game.audio.emit("weapon.firestaff.impact",land,0.7,0.9)
# ---- Lightning staff: a storm cloud strikes on its own and tethers the pack ---------------------------------------------------
func cloud_tick(id: int,f: String,delta: float) -> void:
 if not enabled:return
 var form=Fusions.form(2)
 var c=clouds.get(id)
 if c==null:c={"clock":float(form.cloud_interval)*0.5,"t":0.0};clouds[id]=c
 c.t+=delta;c.clock-=delta
 var p=Fusions.palette(f)
 var home: Vector3=game.player.position+Vector3(1.4,float(form.cloud_height)+sin(c.t*1.3)*0.2,0.0)
 # the cloud: dark puffs with the Fusion's underlight
 for k in 7:
  var off=Vector3(sin(float(k)*2.1)*1.2,sin(float(k)*1.3+c.t*0.5)*0.15,cos(float(k)*1.7)*0.7)
  rt.psx.draw_square(home+off,0.95-0.06*float(k%3),p.smoke.darkened(0.2))
 rt.psx.draw_square(home+Vector3(0,-0.5,0),0.5,p.mid)
 if rt.psx.rng.randf()<delta*10.0:rt.psx.spark(home+Vector3(rt.psx.rng.randf_range(-1,1),-0.5,rt.psx.rng.randf_range(-0.5,0.5)),Vector3(0,-9,0),p.core,p.mid,0.1,0.04,0.3)
 if c.clock>0.0:return
 c.clock=float(form.cloud_interval)
 var pool=game.nearby(game.player.position,float(form.cloud_range))
 if pool.is_empty():return
 var damage=base_damage(id)*float(form.cloud_damage_mult)
 var struck=[]
 var radius=float(WeaponStats.LIGHTNING.strike_radius)
 for k in mini(int(form.cloud_strikes),MAX_CLOUD_TARGETS):
  var t=rt.random_enemy(pool)
  if t.is_empty() or t in struck:continue
  struck.append(t);stats.strikes+=1
  rt.psx.bolt(home+Vector3(0,-0.5,0),t.pos,p.mid,p.core,0.14,0.4,6,3,0.05)
  FusionFx.impact(rt,f,t.pos,Vector3.UP,1.0)
  game.audio.emit("weapon.lightning.strike",t.pos,0.9,1.0)
  for e in game.nearby(t.pos,radius+1.0):
   if e.pos.distance_to(t.pos)>radius+rt.hit_reach(e):continue
   strike_form(f,e,damage,id,"cloud_strike",Vector3.DOWN,e.pos)
 for k in range(1,struck.size()):
  if tethers.size()<MAX_TETHERS:tethers.append({"a":struck[k-1],"b":struck[k],"f":f,"id":id,"left":float(form.tether_time),"tick":0.0,"damage":base_damage(id)*float(form.tether_damage_mult)})
func step_tethers(delta: float) -> void:
 var form=Fusions.form(2)
 var i=tethers.size()-1
 while i>=0:
  var t=tethers[i]
  t.left-=delta;t.tick-=delta
  if t.left<=0.0 or t.a.hp<=0 or t.b.hp<=0:tethers.remove_at(i);i-=1;continue
  FusionFx.tether(rt,t.f,t.a.pos+Vector3.UP*0.7,t.b.pos+Vector3.UP*0.7)
  if t.tick<=0.0:
   t.tick=float(form.tether_tick)
   strike_form(t.f,t.a,float(t.damage),int(t.id),"tether",Vector3.ZERO,t.a.pos);strike_form(t.f,t.b,float(t.damage),int(t.id),"tether",Vector3.ZERO,t.b.pos)
  i-=1
# ---- Bow: three shards on the first pierce -----------------------------------------------------------------------------------------
func arrow_split(a: Dictionary,at: Vector3,victim: Dictionary) -> void:
 if not enabled:return
 var form=Fusions.form(6);var f=str(a.fusion)
 stats.splits+=1
 FusionFx.impact(rt,f,at,Vector3.UP,0.8)
 var n=int(form.shards);var fan=deg_to_rad(float(form.shard_fan_deg))
 for k in n:
  if rt.arrows.size()>=WeaponRuntime.MAX_ARROWS:break
  var d=rt.yaw_dir(a.dir,(float(k)-float(n-1)*0.5)*fan)
  var hits={};hits[victim.crowd_id]=true
  rt.arrows.append({"pos":at+d*0.5,"dir":d,"speed":float(a.speed)*float(form.shard_speed_mult),"left":float(form.shard_range),"damage":float(a.damage)*float(form.shard_damage_mult),"id":a.id,"scale":float(a.scale)*0.75,"hit_r":a.hit_r,"hits":hits,"trail":0.0,"fusion":f,"shard":true})
# ---- Revolver: every 6th shot is a judgement round, and it leaves a detonating line ------------------------------------------
func on_revolver_shot(id: int,f: String,bullet: Dictionary) -> void:
 if not enabled:return
 var form=Fusions.form(7)
 counters.shots+=1
 if counters.shots%int(form.every)!=0:return
 stats.judgements+=1
 bullet["judge"]=true;bullet["fusion"]=f;bullet["damage"]=float(bullet.damage)*float(form.judge_damage_mult);bullet["speed"]=float(bullet.speed)*float(form.judge_speed_mult)
 bullet["bounces"]=0;bullet["origin"]=bullet.pos
 FusionFx.impact(rt,f,bullet.pos,bullet.dir,0.8)
func judgement_ends(b: Dictionary,at: Vector3) -> void:
 if lines.size()>=MAX_LINES:return
 var form=Fusions.form(7)
 stats.lines+=1
 lines.append({"a":b.origin,"b":at,"f":str(b.fusion),"id":int(b.id),"t":float(form.line_delay),"damage":float(b.damage)/float(form.judge_damage_mult)*float(form.line_damage_mult),"hits":{},"blink":0.0})
 FusionFx.impact(rt,str(b.fusion),at,Vector3.UP,1.4)
func step_lines(delta: float) -> void:
 var form=Fusions.form(7)
 var i=lines.size()-1
 while i>=0:
  var l=lines[i]
  l.t-=delta;l.blink-=delta
  if l.blink<=0.0:l.blink=0.07;FusionFx.tether(rt,l.f,l.a,l.b)
  if l.t<=0.0:
   var length=l.a.distance_to(l.b);var pops=clampi(int(length/float(form.line_spacing)),2,int(form.line_max_pops))
   for k in pops+1:
    var at=l.a.lerp(l.b,float(k)/float(pops))
    if k%2==0:FusionFx.impact(rt,l.f,at,Vector3.UP,0.7)
    for e in game.nearby(at,float(form.line_radius)+1.0):
     if l.hits.has(e.crowd_id) or e.pos.distance_to(at)>float(form.line_radius)+rt.hit_reach(e):continue
     l.hits[e.crowd_id]=true;strike_form(l.f,e,float(l.damage),int(l.id),"line",Vector3.ZERO,e.pos)
   game.audio.emit("weapon.revolver.hit",l.b,0.9,0.8)
   lines.remove_at(i)
  i-=1
# ---- Aura: twin rings, every 3rd pulse erupts ------------------------------------------------------------------------------------
func aura_draw(id: int,center: Vector3,radius: float,spin: float,flash: bool) -> void:
 var form=Fusions.form(10)
 rt.draw_aura_circle(center+Vector3.UP*0.03,radius*float(form.inner_radius_frac),-spin*2.2,flash)
func aura_pulse(id: int,f: String,center: Vector3,radius: float,r: Dictionary) -> void:
 if not enabled:return
 var form=Fusions.form(10)
 counters.pulses+=1
 var inner=radius*float(form.inner_radius_frac)
 var erupt=counters.pulses%int(form.every)==0
 if erupt:
  stats.eruptions+=1
  for k in int(form.erupt_crystals):
   var a=TAU*float(k)/float(form.erupt_crystals)
   FusionFx.impact(rt,f,center+Vector3(cos(a),0,sin(a))*radius*0.5,Vector3.UP,0.8)
  rt.psx.ring(center,radius*0.9,int(radius*8.0),Fusions.color(f,"core"),0.24,0.45,4.0)
  game.audio.emit("weapon.aura.pulse",center,1.0,0.7)
 for e in game.nearby(center,radius+1.5):
  var d=Vector2(e.pos.x-center.x,e.pos.z-center.z).length()
  if d>radius+rt.hit_reach(e):continue
  if erupt:strike_form(f,e,float(r.damage)*float(form.erupt_damage_mult),id,"erupt",Vector3.ZERO,e.pos)
  elif d<=inner+rt.hit_reach(e):strike_form(f,e,float(r.damage)*float(form.inner_damage_mult),id,"pulse_inner",Vector3.ZERO,e.pos)
# ---- Scythes: a vortex where the blade turns back ----------------------------------------------------------------------------------
func scythe_turns(s: Dictionary,at: Vector3) -> void:
 if not enabled:return
 var form=Fusions.form(9);var f=fusion_of(int(s.id))
 if f=="":return
 stats.vortices+=1
 if vortices.size()>=int(form.max_vortices):vortices.pop_front()
 var g=Vector3(at.x,game.terrain_height(at.x,at.z)+0.1,at.z)
 vortices.append({"pos":g,"f":f,"id":int(s.id),"t":float(form.vortex_time),"tick":0.0,"damage":float(s.damage)*float(form.vortex_damage_mult),"radius":float(form.vortex_radius)*float(s.scale),"spin":0.0})
 FusionFx.impact(rt,f,g,Vector3.UP,1.4)
func step_vortices(delta: float) -> void:
 var form=Fusions.form(9)
 var i=vortices.size()-1
 while i>=0:
  var v=vortices[i]
  v.t-=delta;v.tick-=delta;v.spin+=delta*10.0
  if v.t<=0.0:vortices.remove_at(i);i-=1;continue
  var p=Fusions.palette(v.f)
  var shrink=minf(1.0,float(v.t)/0.4)
  for k in 6:
   var a=float(v.spin)+TAU*float(k)/6.0;var rr=float(v.radius)*(0.35+0.65*float(k%3)/2.0)*shrink
   rt.psx.draw_square(v.pos+Vector3(cos(a)*rr,0.3+0.12*float(k%3),sin(a)*rr),0.42,p.mid if k%2==0 else p.deep)
  if v.tick<=0.0:
   v.tick=float(form.vortex_tick)
   for e in game.nearby(v.pos,float(v.radius)+1.0):
    var to=v.pos-e.pos;to.y=0.0
    if to.length()>float(v.radius)+rt.hit_reach(e):continue
    e.knock+=to.normalized()*float(form.vortex_pull)*float(form.vortex_tick)
    strike_form(v.f,e,float(v.damage),int(v.id),"vortex",Vector3.ZERO,e.pos)
  i-=1
# ---- Shotgun: a bile wall across the cone -----------------------------------------------------------------------------------------
func shotgun_blast(id: int,f: String,origin: Vector3,dir: Vector3,r: Dictionary) -> void:
 if not enabled:return
 var form=Fusions.form(15)
 stats.walls+=1
 if walls.size()>=int(form.max_walls):walls.pop_front()
 var flat_dir=rt.flat(dir)
 var center=Vector3(origin.x,0.0,origin.z)+flat_dir*float(r.range)*float(form.wall_dist_frac)
 center.y=game.terrain_height(center.x,center.z)+0.1
 walls.append({"c":center,"dir":flat_dir,"f":f,"id":id,"t":float(form.wall_time),"life":float(form.wall_time),"tick":0.05,"damage":float(r.damage)*float(form.wall_damage_mult)})
 FusionFx.impact(rt,f,center,Vector3.UP,1.2)
func step_walls(delta: float) -> void:
 var form=Fusions.form(15)
 var half_w=float(form.wall_width)*0.5;var half_d=float(form.wall_depth)*0.5
 var i=walls.size()-1
 while i>=0:
  var w=walls[i]
  w.t-=delta;w.tick-=delta
  if w.t<=0.0:walls.remove_at(i);i-=1;continue
  var side=Vector3(-w.dir.z,0,w.dir.x);var p=Fusions.palette(w.f)
  var grow=minf(1.0,(float(w.life)-float(w.t))/0.15);var fade=minf(1.0,float(w.t)/0.4)
  for k in 3:
   var off=float(k-1)*half_d*0.8
   rt.psx.draw_segment(w.c+w.dir*off-side*half_w*grow,w.c+w.dir*off+side*half_w*grow,0.18,p.mid if k!=1 else p.core)
  if rt.psx.rng.randf()<delta*18.0*fade:
   var at=w.c+side*rt.psx.rng.randf_range(-half_w,half_w)
   rt.psx.spark(at,Vector3(0,rt.psx.rng.randf_range(2.0,3.4),0),p.acc,p.mid,0.26,0.1,0.55,-1.0,0.8)
  if w.tick<=0.0:
   w.tick=float(form.wall_tick)
   for e in game.nearby(w.c,half_w+1.5):
    var to=e.pos-w.c;var along=to.dot(w.dir);var across=to.dot(side)
    if absf(along)>half_d+rt.hit_reach(e) or absf(across)>half_w+rt.hit_reach(e):continue
    strike_form(w.f,e,float(w.damage),int(w.id),"wall",Vector3.ZERO,e.pos)
  i-=1
