class_name EnemySimulation
extends RefCounted

static func begin_attack(game: Node, e: Dictionary, action: String) -> void:
 e.action=action
 e.windup=e.variant.windup
 e.target=game.player.position+Vector3.UP*0.7
 e.state="windup"
 e.cooldown=e.variant.cooldown
 if action in ["explode","slam","charge"]:
  game.telegraph(e.pos,e.variant.blast_radius if action!="charge" else 2.5,e.windup,Color("ff994f"))
static func detonate(game: Node, e: Dictionary) -> void:
 if e.detonated: return
 e.detonated=true
 game.flash(e.pos,Color("ffb05d"),e.variant.blast_radius)
 game.impact(e.pos,Color("ffab55"),10)
 game.play_sound("explosion")
 if (game.player.position+Vector3.UP*0.65).distance_to(e.pos)<e.variant.blast_radius: game.hurt(e.damage)
 # Nearby enemies are affected, but death processing is deferred to the usual loop.
 for other in game.nearby(e.pos,e.variant.blast_radius):
  if other!=e: game.hit(other,e.damage*0.6,-1)
 e.hp=0
static func step(game: Node, e: Dictionary, delta: float) -> void:
 if e.frozen>0 and e.get("drop",{}).is_empty():return
 if not e.get("climb",{}).is_empty() or not e.get("drop",{}).is_empty():
  e.pos=EnemyTraversal.move(game,e,e.speed,delta);return
 var config=e.variant
 var modules=config.modules
 var difference=game.player.position-e.pos
 difference.y=0
 var distance=difference.length()
 var direction=game.navigation_direction(e.pos,game.player.position)
 var speed=e.speed*(0.2 if e.slow>0 else 1)
 e.hit_time=maxf(0,e.hit_time-delta)
 if e.frozen>0:
  e.state="frozen"
  return
 if e.state=="frozen": e.state="move"
 if e.state=="windup":
  e.windup-=delta
  speed=0
  if e.windup<=0:
   e.state="recover"
   e.recovery=0.45
   match e.action:
    "explode": detonate(game,e)
    "shoot":
     var aim=(e.target-e.pos).normalized()
     for offset in ([-0.26,0.0,0.26] if "fan" in modules else [0.0]):
      game.hostile_bolt(e.pos+Vector3.UP*0.6,e.pos+Vector3.UP*0.6+aim.rotated(Vector3.UP,offset)*10,e.damage,config.projectile_speed,"thorn" if "stationary" in modules else "arrow")
    "slam":
     game.flash(e.pos,Color("e6a665"),config.blast_radius)
     game.impact(e.pos,Color("d6ad82"),8)
     if distance<config.blast_radius: game.hurt(e.damage); game.player.velocity+=direction*8+Vector3.UP*3
    "charge":
     e.state="charging"
     e.charge_time=0.5
     e.charge_direction=(e.target-e.pos).normalized()
     e.charge_direction.y=0
    "melee":
     if distance<config.range+0.6:
      game.hurt(e.damage)
      if "knockback" in modules: game.player.velocity+=direction*9+Vector3.UP*2
      if game.stats.thorns>0: game.hit(e,game.stats.thorns,0)
 elif e.state=="charging":
  e.charge_time-=delta
  direction=e.charge_direction
  speed=13 if "fast" not in modules else 16
  if distance<config.range and not e.charge_hit:
   game.hurt(e.damage)
   e.charge_hit=true
  if e.charge_time<=0: e.state="recover"; e.recovery=0.65; e.charge_hit=false
 elif e.state=="recover":
  speed=0
  e.recovery-=delta
  if e.recovery<=0: e.state="move"
 else:
  e.state="move"
  if "stationary" in modules: speed=0
  elif "reposition" in modules and distance<9: direction=-direction; speed=e.speed
  elif "ranged" in modules and distance<config.range*0.8: speed=0
  if e.cooldown<=0:
   if "proximity" in modules and e.pos.distance_to(game.player.position+Vector3.UP*0.65)<config.range: begin_attack(game,e,"explode")
   elif "ranged" in modules and distance<config.range: begin_attack(game,e,"shoot")
   elif "charge" in modules and distance<16 and game.enemy_line_clear(e.pos,game.player.position): begin_attack(game,e,"charge")
   elif "slam" in modules and distance<config.range and absf(e.pos.y-game.player.position.y)<2.5: begin_attack(game,e,"slam")
   elif "melee" in modules and distance<config.range and absf(game.player.position.y-e.pos.y)<2.5: begin_attack(game,e,"melee")
 e["move_direction"]=direction
 if e.get("ordinary",false):e.pos=EnemyTraversal.move(game,e,speed,delta)
 else:e.pos=game.constrain_enemy_motion(e.pos,e.pos+(direction*speed+e.knock)*delta)
 e.knock=e.knock.move_toward(Vector3.ZERO,delta*15)
 if e.get("climb",{}).is_empty() and e.get("drop",{}).is_empty():
  if not "flying" in modules and not e.get("ordinary",false):e.pos=game.avoid_props(e.pos)
  e.pos.x=clampf(e.pos.x,-95,95);e.pos.z=clampf(e.pos.z,-95,95)
  e.pos.y=game.terrain_height(e.pos.x,e.pos.z)+0.65+(1.3+sin(e.age*3)*0.25 if "flying" in modules else 0)
