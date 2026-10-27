extends SceneTree
var game: Node
var failures=[]
var checks=0
func verify(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=123;game.begin_run();game.mode="pause";game.player.active=false;game.settings.invincible=true
 await physics_frame;await physics_frame
 verify(game.world.get_node("TerraceTerrain").material_override.shader.resource_path.ends_with("forest_floor.gdshader"),"World-space floor shader replaces flat ground")
 var env=game.world.get_child(0).environment
 verify(env.background_mode==Environment.BG_SKY and env.sky!=null and env.fog_enabled and env.fog_density>=0.003 and env.fog_density<=0.008,"Layered blue sky and readable distance fog are configured")
 var min_crest=1000.0
 for i in range(-96,97,8):min_crest=minf(min_crest,ForestMap.wall_vertex(Vector3(i,0,96),9,1).y)
 verify(min_crest>60,"Irregular rocky perimeter rises above sixty metres")
 var grasses=0
 for key in game.prop_batches:
  if str(key).begins_with("wind_grass"):
   grasses+=game.prop_batches[key].multimesh.visible_instance_count
   verify(game.prop_batches[key].visibility_range_end<=60,"Grass chunk has a bounded draw distance")
 verify(grasses>0 and grasses<650,"Uploaded grass shader uses sparse batched non-colliding clumps")
 game.enemies.clear();game.pickups.clear();game.effects.clear();game.player.position=Vector3.ZERO;game.stats.crit=0;game.stats.gold_gain=1;game.gold=0;game.debug_combat=true
 var reward=0.0
 for i in 100:
  var e=game.spawn_enemy(0,Vector3(5+float(i%4)*0.2,0,0));reward+=e.variant.reward;e.hp=0
 while not game.enemies.is_empty():game.kill_enemy(game.enemies.size()-1)
 var granted=0.0
 for pickup in game.pickups:granted+=pickup.value
 verify(granted==reward and game.gold==100,"XP merging preserves every XP point and gold reward")
 verify(game.pickups.size()<10,"Nearby mass-death XP is aggregated")
 verify(game.effects.size()<=48,"Mass deaths have a bounded corpse budget")
 var created=game.pool.created
 game.update_effects(1)
 for i in 30:var e=game.spawn_enemy(0,Vector3(5,0,0));e.hp=0
 while not game.enemies.is_empty():game.kill_enemy(game.enemies.size()-1)
 verify(game.pool.created==created,"Second death batch reuses cached corpse nodes")
 game.numbers.show_damage(Vector3(1,1,1),3,false,Color.WHITE,1)
 game.numbers.show_damage(Vector3(1,1,1),4,true,Color.YELLOW,1.01)
 verify(game.numbers.active.size()==1 and game.numbers.active[0].amount==7,"Nearby rapid damage numbers aggregate without losing displayed damage")
 game.numbers.tick(1);verify(game.numbers.active.is_empty(),"Pooled number expires and releases its bucket")
 game.weapons.clear();game.equip(4);game.stats.count=3;game.stats.size=1;game.elapsed=2
 game.update_special_visuals(0.016)
 verify(game.weapons[4].visuals.size()==game.orbit_count(4),"Chunkers visual count matches damaging orbit count")
 for i in game.orbit_count(4):verify(game.weapons[4].visuals[i].position.is_equal_approx(game.orbit_position(4,i)),"Orbit rock shares exact damage position")
 verify(game.weapons[4].visuals[0].mesh==WeaponArt.mesh("stone") and game.weapons[4].debris.multimesh.instance_count==12,"Chunkers uses real stone geometry and instanced foot debris")
 game.stats.count=5;game.update_special_visuals(0.016);verify(game.weapons[4].visuals.size()==game.orbit_count(4),"Orbit visuals respond to projectile-count upgrades")
 var actor=game.player.avatar;var position=game.player.position
 verify(actor.playback.get_animation_library("").get_animation_list().size()==4,"Only four core animations control the Ranger")
 var lengths=[]
 for b in actor.rig.get_bone_count():lengths.append(actor.rig.get_bone_rest(b).origin.length())
 for state in ["idle","run","jump","fall","slide","crouch"]:
  for tick in 10:actor.animate(state,6,0.02)
  actor.rig.force_update_all_bone_transforms();var valid=true
  for b in actor.rig.get_bone_count():
   if actor.rig.get_bone_name(b)!="pelvis" and absf(actor.rig.get_bone_pose_position(b).length()-lengths[b])>0.005:valid=false
  verify(valid,"Generic %s preserves bone lengths and limb attachments"%state)
 actor.animate("hit",6,0.1);verify(actor.animation_state=="move","Taking damage does not interrupt moving locomotion")
 verify(game.player.position==position,"Animation never applies root motion to physics")
 # Find real downward edges for all orientations and both elevation differences.
 var passed=0;var attempted=0
 for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.BACK,Vector3.FORWARD]:
  for height in [12,24]:
   var found={}
   for index in game.map_layout.planes.size():
    var x=-95+(index%96)*2;var z=-95+int(index/96)*2
    if maxf(absf(x),absf(z))>84:continue
    var high=Vector3(x,game.terrain_height(x,z)+0.65,z);var low=high+direction*4;low.y=game.terrain_height(low.x,low.z)+0.65
    if absf(high.y-low.y-height)>0.1:continue
    var clear=true
    for point in [high,high-direction,low,low+direction*5]:
     if game.forest_navigation.blocked.has(ForestMap.index(point.x,point.z)) or ForestMap.normal(9,point.x,point.z).y<0.99:clear=false
    if clear:found={"high":high,"low":low+direction*5};break
   if found.is_empty():continue
   attempted+=1;game.enemies.clear();game.player.position=found.low-Vector3.UP*0.65;game.player.position.y=game.terrain_height(game.player.position.x,game.player.position.z);game.forest_navigation.refresh(game.player.position)
   var e=game.spawn_enemy(0,found.high);e.cooldown=999;var fell=false;var min_y=e.pos.y
   for tick in 700:
    EnemySimulation.step(game,e,1.0/60)
    if not e.get("drop",{}).is_empty() and e.drop.phase=="fall":fell=true
    min_y=minf(min_y,e.pos.y)
   if fell and e.get("drop",{}).is_empty() and e.pos.distance_to(game.player.position+Vector3.UP*0.65)<3:passed+=1
 verify(attempted>=4 and passed==attempted,"Real cliff drops work in multiple orientations and elevations (%d/%d)"%[passed,attempted])
 print("POLISH RESULT: %d checks, %d failures"%[checks,failures.size()])
 game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
