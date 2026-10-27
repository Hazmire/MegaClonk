extends SceneTree
var failures=[]
var checks=0
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();await process_frame;game.set_physics_process(false);game.player.active=false;game.stats.armor=0;game.stats.evasion=0;game.stats.thorns=0
 var origin=game.player.position
 for kind in [0,3,8,9,13]:
  var e=game.spawn_enemy(kind,origin);e.pos=origin+Vector3(0.4,0.65,0);e.cooldown=999;game.health=1000;game.invulnerability=0
  EnemyContact.step(game,e,0.01)
  check(is_equal_approx(game.health,1000-e.damage),"Contact uses existing damage independently of attacks: "+str(kind))
  var after=game.health
  for i in 60:game.invulnerability=0;EnemyContact.step(game,e,0.01)
  check(game.health==after,"Contact cannot damage every frame: "+str(kind))
  game.invulnerability=0;EnemyContact.step(game,e,0.2)
  check(is_equal_approx(game.health,after-e.damage),"Per-enemy contact interval expires: "+str(kind))
 check(game.player.hurt_time>0,"Contact triggers the existing player flash/hit feedback")
 var bug=game.spawn_enemy(1,origin);bug.variant=OrdinaryRoster.variant(1,0);bug.pos=origin+Vector3.UP*0.65
 var before=game.health;game.invulnerability=0;EnemyContact.step(game,bug,1)
 check(game.health==before,"Exploding Bugs do not double up ordinary contact and explosion damage")
 var enemy=game.enemies[0];enemy.contact_clock=0;enemy.pos=origin+Vector3.UP*0.65;game.invulnerability=1;before=game.health;EnemyContact.step(game,enemy,0.1)
 check(game.health==before,"Contact respects ordinary invulnerability")
 game.invulnerability=0;enemy.contact_clock=0;game.loadout_runtime.ultimate_id="ghost";game.loadout_runtime.remaining=3;EnemyContact.step(game,enemy,0.1)
 check(game.health==before,"Ghost form still prevents contact damage")
 game.loadout_runtime.remaining=0;enemy.contact_clock=0;game.player.position.y+=10;EnemyContact.step(game,enemy,1)
 check(game.health==before,"Vertical separation prevents contact hits through floors/air")
 game.player.position=origin;enemy.hp=0;EnemyContact.step(game,enemy,1);check(game.health==before,"Dead enemies cannot deal contact damage")
 game.queue_free();await process_frame;await process_frame
 print("ENEMY CONTACT: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
