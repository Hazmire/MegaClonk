class_name Encounters
extends RefCounted
static var meshes: Dictionary={}
static func config(id: String) -> Dictionary:
 var table={
 "colossus":{"name":"The Forest Colossus","health":2400.0,"speed":2.4,"damage":28.0,"scale":2.4,"reward":80,"attacks":["slam","charge","thorns"]},
 "sovereign":{"name":"The Wraith Sovereign","health":1900.0,"speed":4.0,"damage":23.0,"scale":2.2,"reward":80,"attacks":["dash","souls","phantom"]},
 "champion":{"name":"Brute Champion","health":650.0,"speed":2.0,"damage":20.0,"scale":1.7,"reward":30,"attacks":["slam","charge"]},
 "hunter":{"name":"Shadow Hunter","health":480.0,"speed":4.8,"damage":17.0,"scale":1.4,"reward":30,"attacks":["leap","cleave"]},
 "ghost":{"name":"Endless Revenant","health":100.0,"speed":5.5,"damage":16.0,"scale":1.0,"reward":4,"attacks":["cleave"]}}
 var d=table[id].duplicate(true);d.id=id;d.model="";d.mesh=model(id);return d
static func model(id: String) -> Mesh:
 if meshes.has(id):return meshes[id]
 var parts=[]
 match id:
  "colossus":
   parts=ModelBuilder.enemy_parts("golem")
   for side in [-1,1]:
    parts.append(ModelBuilder.part(ModelBuilder.cone(0.35,1.1),Vector3(side*0.6,2,0),"517640",Vector3(0,0,side*0.4)))
    parts.append(ModelBuilder.part(ModelBuilder.cube(Vector3(0.4,0.9,0.7)),Vector3(side*0.7,1.1,0),"8d9064"))
  "champion":
   parts=ModelBuilder.enemy_parts("ogre")
   for side in [-1,1]:parts.append(ModelBuilder.part(ModelBuilder.cone(0.22,0.7),Vector3(side*0.35,2,0),"efbf58",Vector3(0,0,side*0.5)))
   parts.append(ModelBuilder.part(ModelBuilder.cube(Vector3(1.7,0.25,0.25)),Vector3(0,1.4,0.4),"b46048"))
  "hunter":
   parts=ModelBuilder.enemy_parts("knight")
   for side in [-1,1]:parts.append(ModelBuilder.part(ModelBuilder.cone(0.16,1.2),Vector3(side*0.8,1,0.3),"df80b4",Vector3(0,0,side*0.8)))
  _:
   parts=[ModelBuilder.part(ModelBuilder.cone(0.7,1.8,0.15),Vector3(0,0.9,0),"63769e" if id=="sovereign" else "8acbcf"),ModelBuilder.part(ModelBuilder.cone(0.4,0.7,0.15),Vector3(0,2,0),"b9d8dd")]
   for side in [-1,1]:
    parts.append(ModelBuilder.part(ModelBuilder.cone(0.2,1),Vector3(side*0.65,1.2,0),"859cc2",Vector3(0,0,side*-0.7)))
    parts.append(ModelBuilder.part(ModelBuilder.cube(Vector3(0.13,0.1,0.08)),Vector3(side*0.15,2,0.22),"ff638d"))
   if id=="sovereign":
    for side in [-1,1]:parts.append(ModelBuilder.part(ModelBuilder.cone(0.15,1),Vector3(side*0.3,2.7,0),"b192f3",Vector3(0,0,side*-0.3)))
 meshes[id]=ModelBuilder.bake(parts);return meshes[id]
static func initialize(game: Node, e: Dictionary, id: String) -> void:
 var d=config(id);var scaling=(1+(game.stage-1)*0.6)*(1+(game.tier-1)*0.3)*game.stats.difficulty
 if id=="ghost":scaling*=1+maxf(0,game.stage_time-game.STAGE_SECONDS)/120
 e.encounter=id;e.variant=d;e.hp=d.health*scaling;e.max_hp=e.hp;e.speed=d.speed;e.damage=d.damage*scaling;e.scale=d.scale
 e.state="move";e.action="";e.windup=0.0;e.recovery=0.0;e.charge_time=0.0;e.charge_direction=Vector3.ZERO;e.charge_hit=false;e.hit_time=0.0;e.special_cds={};e.wave_clock=0.0;e.waves=0
static func step(game: Node, e: Dictionary, delta: float) -> void:
 var d=e.variant
 for key in e.special_cds:e.special_cds[key]=maxf(0,e.special_cds[key]-delta)
 if e.encounter=="ghost":e.speed=minf(game.RUN_RULES.ghost_speed_cap,5.5+maxf(0,game.stage_time-game.STAGE_SECONDS)/game.RUN_RULES.ghost_growth_seconds)
 if e.frozen>0:return
 e.pos+=e.knock*delta
 var direction=game.player.position-e.pos;direction.y=0
 var distance=direction.length();direction=direction.normalized()
 if e.encounter=="ghost":
  e.pos+=direction*e.speed*delta;e.pos.x=clampf(e.pos.x,-70,70);e.pos.z=clampf(e.pos.z,-70,70);e.pos.y=game.terrain_height(e.pos.x,e.pos.z)+0.9+sin(e.age*3)*0.2
  if distance<1.8 and e.cooldown<=0:game.hurt(e.damage);e.cooldown=1.2
  return
 e.windup=maxf(0,e.windup-delta);e.recovery=maxf(0,e.recovery-delta)
 if e.state=="windup":
  if e.windup<=0:execute(game,e)
 elif e.state=="charging":
  var previous: Vector3=e.pos
  e.charge_time-=delta;e.pos+=e.charge_direction*(24 if e.action=="dash" else 18)*delta
  e.pos.x=clampf(e.pos.x,-68,68);e.pos.z=clampf(e.pos.z,-68,68)
  if not e.charge_hit and game.segment_distance(game.player.position,previous,e.pos)<2.0:
   game.hurt(e.damage*1.4);e.charge_hit=true
  if e.action=="leap":e.pos.y=game.terrain_height(e.pos.x,e.pos.z)+sin(clampf(1-e.charge_time/0.65,0,1)*PI)*3
  if e.charge_time<=0:e.state="recover";e.recovery=0.8
 elif e.state=="waves":
  e.wave_clock-=delta
  if e.wave_clock<=0:
   fire_wave(game,e,8,e.waves*0.2);e.waves-=1;e.wave_clock=0.55
   if e.waves<=0:e.state="recover";e.recovery=0.8
 else:
  if e.recovery>0:e.state="recover"
  else:
   e.state="move"
   e.pos+=direction*e.speed*delta*(0.3 if e.slow>0 else 1.0)
   if e.cooldown<=0:
    var candidates=[]
    for action in d.attacks:
     if e.special_cds.get(action,0)<=0:candidates.append(action)
    if not candidates.is_empty():
     # Weighted random, distance-aware choice; independent attack cooldowns.
     if distance<7 and "slam" in candidates:candidates.append("slam")
     if distance>12 and "charge" in candidates:candidates.append("charge")
     e.action=candidates[game.rng.randi_range(0,candidates.size()-1)]
     e.target=game.player.position;e.charge_hit=false;e.state="windup";e.windup=1.1 if e.action!="dash" else 0.8
     e.special_cds[e.action]=game.rng.randf_range(6,10);e.cooldown=3.3
     var target=e.target if e.action=="phantom" else e.pos
     game.telegraph(target,5 if e.action in ["slam","phantom","cleave"] else 2,e.windup,Color("ff8267"))
     if e.action in ["charge","dash","leap"]:
      var before=game.effects.size();game.beam(e.pos,e.target,Color("ff8a93"))
      if game.effects.size()>before:game.effects.back().life=e.windup
    elif distance<2 and e.cooldown<=0:game.hurt(e.damage);e.cooldown=1.3
 if e.state!="charging" or e.action!="leap":e.pos.y=game.terrain_height(e.pos.x,e.pos.z)+0.65
 e.pos.x=clampf(e.pos.x,-70,70);e.pos.z=clampf(e.pos.z,-70,70)
 e.knock=e.knock.move_toward(Vector3.ZERO,delta*15)
static func fire_wave(game: Node,e: Dictionary,count: int,offset: float=0) -> void:
 game.combat_fx.burst("sparks_shower",e.pos,1,0.4)
 for i in count:
  var angle=i*TAU/count+offset
  game.hostile_bolt(e.pos+Vector3.UP,e.pos+Vector3(cos(angle)*10,1,sin(angle)*10),e.damage*0.65,11,"soul" if e.encounter=="sovereign" else "thorn")
static func execute(game: Node,e: Dictionary) -> void:
 match e.action:
  "charge","dash","leap":
   e.state="charging";e.charge_time=0.65 if e.action=="leap" else 0.9
   e.charge_direction=(e.target-e.pos).normalized();e.charge_direction.y=0
   return
  "souls":e.state="waves";e.waves=3;e.wave_clock=0;return
  "thorns":fire_wave(game,e,12)
  "slam","cleave":
   game.flash(e.pos,Color("ffb575"),5)
   if Vector2(game.player.position.x-e.pos.x,game.player.position.z-e.pos.z).length()<5 and game.player.position.y<game.terrain_height(game.player.position.x,game.player.position.z)+1.4:game.hurt(e.damage)
  "phantom":
   game.combat_fx.burst("explosion_small",e.target,2.5)
   if game.player.position.distance_to(e.target)<5:game.hurt(e.damage*1.5)
 game.play_sound("explosion");e.state="recover";e.recovery=0.8
