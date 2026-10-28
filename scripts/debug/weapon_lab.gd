class_name WeaponLab
extends RefCounted

# Weapon test lab (debug / sandbox only). Drives the real Game in a controlled arena: choose a weapon,
# level, upgrade stats, sockets and global stats; place stationary or moving dummies in rings, arcs,
# lines, clusters or swarms; step the simulation deterministically; place a camera at any distance.
# Used by tests/weapons_*.gd (headless) and tools/weapon_lab_capture.gd (real rendered screenshots).
var game: Node
func _init(owner: Node) -> void:game=owner
func prepare(weapon_id: int,upgrades: Dictionary={},level: int=1,elements: Array=[],stat_overrides: Dictionary={}) -> Dictionary:
 game.weapons.clear();game.enemies.clear();game.wrt.clear();game.projectiles.clear()
 game.wrt.counters={"strike":{},"casts":{},"dropped_timers":0}
 game.equip(weapon_id)
 var state=game.weapons[weapon_id]
 state.upgrades=upgrades.duplicate();state.level=level;state.clock=9999.0 # held until fire() so set-up never casts
 for element in elements:WeaponSockets.install(state,str(element))
 game.stats=Catalog.base_stats();game.stats.merge(stat_overrides,true)
 game.player.position=game.map_layout.spawn+Vector3.UP;game.player.velocity=Vector3.ZERO;game.player.yaw=0.0
 game.mode="run";game.health=1000000.0;game.stats.max_health=1000000.0
 return state
# Spawns `count` dummies. Layouts: ring, arc (front), line (forward), cluster (front), swarm (wide, random).
func dummies(layout: String,count: int,distance: float,moving: bool=false,hp: float=100000.0,kind: int=0) -> Array:
 var made=[];var origin=game.player.position
 var rng=RandomNumberGenerator.new();rng.seed=77
 for i in count:
  var offset=Vector3.ZERO
  match layout:
   "ring":var a=TAU*float(i)/count;offset=Vector3(cos(a),0,sin(a))*distance
   "arc":var a=-1.0+2.0*float(i)/maxf(1.0,count-1.0);offset=Vector3(sin(a),0,-cos(a))*distance
   "line":offset=Vector3(0,0,-distance-float(i)*1.4)
   "cluster":offset=Vector3(rng.randf_range(-1.8,1.8),0,-distance-rng.randf_range(-1.5,1.5))
   "swarm":offset=Vector3(rng.randf_range(-distance,distance),0,-rng.randf_range(2.0,distance))
  var e=game.spawn_enemy(kind,origin+offset)
  if e.is_empty():continue
  e.hp=hp;e.max_hp=hp;e["age"]=2.0
  if not moving:e.speed=0.0
  made.append(e)
 return made
func step(frames: int,dt: float=1.0/60.0,player_velocity: Vector3=Vector3.ZERO) -> void:
 for f in frames:
  game.player.position+=player_velocity*dt
  game.update_enemies(dt);game.rebuild_grid();game.update_weapons(dt);game.update_projectiles(dt);game.update_effects(dt)
  game.elapsed+=dt
# Steps until the weapon has cast `n` times (or `limit` frames pass). Returns the frames used.
func fire(id: int) -> void:
 game.weapons[id].clock=0.0
func until_cast(id: int,n: int=1,limit: int=600,dt: float=1.0/60.0) -> int:
 var used=0
 if game.weapons[id].clock>100.0:fire(id)
 while int(game.wrt.counters.casts.get(id,0))<n and used<limit:step(1,dt);used+=1
 return used
func hide_hud() -> void:
 game.frontend.hud_root.hide();game.notice.hide()
func camera(position: Vector3,target: Vector3,fov: float=60.0) -> Camera3D:
 var view=Camera3D.new();game.world.add_child(view);view.position=position;view.fov=fov;view.look_at(target);view.current=true;return view
# Standard gameplay-ish views relative to the player, looking along -Z. `distance` scales the pull-back.
func view(kind: String) -> Vector3:
 var p=game.player.position
 match kind:
  "gameplay":return p+Vector3(0,7.5,10.5)
  "close":return p+Vector3(0,3.6,6.0)
  "mid":return p+Vector3(0,5.2,7.5)
  "side":return p+Vector3(8.0,4.5,-1.0)
  "top":return p+Vector3(0,11.0,2.5)
  "far":return p+Vector3(0,13.0,18.0)
 return p+Vector3(0,7.5,10.5)
