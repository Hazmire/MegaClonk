class_name Ghosts
extends RefCounted
# Endless-mode ghosts. They are ordinary entries of Game.enemies (so weapons, Game.hit(), statuses, the grid, kills and saves all work), flagged
# "ghost". They do not use the ground-bound enemy simulation: they fly straight at the player's chest, bank into turns, ignore terrain and walls,
# and are drawn by GhostView. Contact damage goes through Game.hurt_contact; they obey hostile time (the Stopwatch and Hourglass freeze them).
# Every number comes from Endless (assets/config/endless_rules.json). Ghost spawns draw only from game.ghost_rng, so seeded runs reproduce them.
static func minutes(game: Node) -> float:return float(game.endless_time)/60.0
# Spawner: a credit budget on hostile time, capped, one ghost at a time. Hitting the live cap stops the count growing, not the escalation.
static func tick_spawner(game: Node,hostile_delta: float) -> void:
 var m=minutes(game)
 game.ghost_budget=minf(float(Endless.data().spawn.budget_cap),game.ghost_budget+hostile_delta*Endless.spawn_rate(m)*maxf(0.1,float(game.stats.difficulty)))
 while game.ghost_budget>=1.0:
  game.ghost_budget-=1.0
  if game.ghost_count<Endless.cap():spawn(game,Endless.choose_tier(m,game.ghost_rng),Vector3.INF)
static func spawn(game: Node,tier_index: int,at: Vector3) -> Dictionary:
 if game.ghost_count>=Endless.cap():return {}
 var ring: Dictionary=Endless.data().spawn_ring;var pos=at
 if at==Vector3.INF:
  # Just outside the camera view, at a spread of heights, never inside the player's immediate radius.
  var angle=game.ghost_rng.randf()*TAU;var distance=game.ghost_rng.randf_range(float(ring.min_m),float(ring.max_m));var height=game.ghost_rng.randf_range(float(ring.height_min),float(ring.height_max))
  pos=game.player.position+Vector3(cos(angle)*distance,height,sin(angle)*distance)
  var clamp_to=float(ring.arena_clamp);pos.x=clampf(pos.x,-clamp_to,clamp_to);pos.z=clampf(pos.z,-clamp_to,clamp_to)
  var flat=Vector2(pos.x-game.player.position.x,pos.z-game.player.position.z).length()
  if flat<float(ring.immediate_radius):pos+=Vector3(pos.x-game.player.position.x,0,pos.z-game.player.position.z).normalized()*(float(ring.immediate_radius)-flat+1.0)
 var e={"pos":pos,"kind":Endless.GHOST_KIND,"cooldown":0.0,"slow":0.0,"frozen":0.0,"spore":false,"burn":0.0,"burn_clock":0.0,"poison":0.0,"poison_clock":0.0,"knock":Vector3.ZERO,"age":0.0,"phase":0,"biome":game.biome,"target":Vector3.ZERO,"telegraph":0.0,"hit_time":0.0,"state":"move","ghost":true,"no_gold":true,"vel":Vector3.ZERO,"tier":tier_index,"enemy_id":0}
 refresh(game,e,true)
 e["crowd_id"]=game.crowd.next_id;game.crowd.next_id+=1
 game.enemies.append(e);game.ghost_count+=1
 return e
# (Re)derives the data-driven fields from the tier. Called on spawn and after a save is restored.
static func refresh(game: Node,e: Dictionary,fresh: bool=false) -> void:
 e.tier=clampi(int(e.tier),0,Endless.tiers().size()-1);var t: Dictionary=Endless.tier(e.tier)
 e.scale=float(t.scale);e.radius=float(Endless.data().flight.hit_radius)*e.scale
 e.variant={"id":"ghost_"+str(t.id),"reward":float(t.xp),"modules":[],"knockback":0.2,"visual_scale":1.0}
 if fresh:
  var hp=Endless.tier_hp(e.tier,minutes(game))*maxf(0.1,float(game.stats.difficulty));e.hp=hp;e.max_hp=hp
 e.speed=Endless.tier_speed(e.tier,minutes(game))
# Per-frame step, called from Game.update_enemies with hostile-scaled dt.
static func step(game: Node,e: Dictionary,dt: float) -> void:
 e.age+=dt;e.hit_time=maxf(0.0,float(e.hit_time)-dt)
 if e.has("fx"):StatusManager.tick(game,e,dt)
 e.slow=maxf(0.0,e.slow-dt);e.frozen=maxf(0.0,e.frozen-dt);e.poison=maxf(0.0,e.poison-dt);e.burn=maxf(0.0,e.burn-dt)
 if e.burn>0:
  e.burn_clock-=dt
  if e.burn_clock<=0:game.hit(e,(3+game.level*0.5)*game.irt.status_harder(),int(e.get("burn_source",1)));e.burn_clock=0.5
 if e.poison>0:
  e.poison_clock-=dt
  if e.poison_clock<=0:game.hit(e,5+game.level,int(e.get("poison_source",23)));e.poison_clock=0.5
 if e.hp<=0:return
 var flight: Dictionary=Endless.data().flight
 var speed=Endless.tier_speed(e.tier,minutes(game))*game.difficulty_speed()*(0.2 if e.slow>0 else 1.0)
 e.speed=speed
 var chest: Vector3=game.player.position+Vector3(0,float(flight.chest_height),0)
 var want=(chest-e.pos).normalized()*(0.0 if e.frozen>0 else speed)
 e["bank_to"]=want.normalized() if want.length_squared()>0.0 else e.vel.normalized()
 e.vel=e.vel.lerp(want,clampf(float(flight.turn_rate)*dt,0.0,1.0))
 var previous: Vector3=e.pos
 e.pos+=(e.vel+e.knock)*dt;e.knock=e.knock.move_toward(Vector3.ZERO,dt*15.0)
 # Swept sphere test, so a ghost faster than the player cannot tunnel through them in one frame.
 if game.segment_distance(chest,previous,e.pos)<float(flight.player_radius)+e.radius and e.frozen<=0.0:
  game.hurt_contact(Endless.tier_damage(e.tier,minutes(game))*maxf(0.1,float(game.stats.difficulty)),e.pos)
  e["spent"]=true;e.hp=0.0 # a ghost that touches the player dissipates, whether or not the hit landed
 draw(game,e)
static func draw(game: Node,e: Dictionary) -> void:
 var view: GhostView=game.ghost_view
 view.put(int(e.tier),transform_of(e),clampf(float(e.age)/float(Endless.data().fade["in_s"]),0.0,1.0))
static func transform_of(e: Dictionary) -> Transform3D:
 var velocity: Vector3=e.vel;var forward=velocity.normalized() if velocity.length_squared()>0.01 else Vector3.FORWARD
 var basis=Basis.looking_at(forward,Vector3.UP if absf(forward.y)<0.98 else Vector3.RIGHT)
 var want: Vector3=e.get("bank_to",forward)
 var bank=clampf(-forward.cross(want).y*2.0,-float(Endless.data().flight.bank),float(Endless.data().flight.bank))
 basis=basis*Basis(Vector3(0,0,1),bank)*Basis.from_scale(Vector3.ONE*float(e.scale))
 return Transform3D(basis,e.pos)
# Death by a weapon, status or contact. Contact deaths give nothing; real kills give a little XP and no gold.
static func kill(game: Node,index: int,e: Dictionary) -> void:
 game.ghost_view.dissipate(int(e.tier),transform_of(e))
 StatusManager.on_death(game,e)
 if not e.get("spent",false):
  game.kills+=1
  var source=int(e.get("last_weapon",-1))
  if source>=0:game.run_metrics["weapon:"+str(source)]=int(game.run_metrics.get("weapon:"+str(source),0))+1
  game.add_xp_drop(e.pos+Vector3(game.rng.randf()-0.5,0,game.rng.randf()-0.5),float(e.variant.reward))
  if game.irt.kill_hooks:game.irt.on_kill(e)
 game.enemies.remove_at(index);game.ghost_count=maxi(0,game.ghost_count-1)
