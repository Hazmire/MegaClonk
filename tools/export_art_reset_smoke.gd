extends SceneTree
func _initialize():call_deferred("run")
func require(value: bool,message: String) -> bool:
 if not value:push_error(message);quit(1)
 return value
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 if not require(Catalog.ACTIVE_WEAPONS.size()==10 and LoadoutCatalog.entries("weapons").size()==10,"Compiled active roster is not ten"):return
 game.weapons.clear();game.tomes.clear()
 for choice in game.upgrade_pool():
  if choice.type in ["weapon","tome"] and not require(choice.metadata.rarity=="common","Compiled acquisition is not Common"):return
 game.apply_upgrade({"type":"weapon","id":2});game.apply_upgrade({"type":"tome","id":"Vampire"})
 if not require(game.equipment_meta("weapons",2).rarity=="common" and game.equipment_meta("tomes","Vampire").rarity=="common","Compiled equipment UI rarity mismatch"):return
 for stage_value in [1,2,3]:
  game.stage=stage_value;game.build_stage();game.portal_wind.set_process(false)
  if not require(is_instance_valid(game.portal.get_node("PortalAsset")) and game.world.get_child(0).environment.sky!=null,"Compiled portal or panorama missing"):return
  var wind=game.portal_wind;game.player.position=game.map_layout.spawn;wind.simulate(0.1)
  if not require(wind.guidance.valid and not wind.guidance.route(game.player.position).is_empty(),"Compiled terrain guidance has no route"):return
  game.portal_state="summoned";wind.simulate(0.1)
  if not require(wind.surge>0,"Compiled portal activation has no surge"):return
  game.portal_state="exit"
  for i in 20:wind.simulate(0.1)
  if not require(wind.factor==0 and wind.ambient.emitting,"Compiled guidance lifecycle or ambient independence broken"):return
 game.player.position=game.map_layout.spawn;game.invulnerability=0;game.health=100;game.loadout_runtime.reset("climber","nova");game.player.velocity=Vector3.ZERO
 var e=game.spawn_enemy(1,game.player.position+Vector3.RIGHT);e.variant=OrdinaryRoster.variant(1,0);e.detonated=false;e.damage=10
 EnemySimulation.detonate(game,e);var health=game.health;EnemySimulation.detonate(game,e)
 if not require(e.hp<=0 and game.health==health and game.player.velocity.y>=13 and game.player.velocity.x<0,"Compiled explosion lifecycle/launch broken"):return
 game.combat_fx.supplied_burst("shatter",game.player.position);game.combat_fx.supplied_burst("fire",game.player.position)
 game.queue_free();await process_frame;await process_frame
 print("EXPORTED ART RESET V10 SMOKE COMPLETE");quit()
