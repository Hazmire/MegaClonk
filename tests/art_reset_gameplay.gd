extends SceneTree
var failures=[]
var checks=0
func check(value: bool,message: String):
 checks+=1
 if value:print("PASS: "+message)
 else:failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.invincible=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.enemies.clear()
 check(Catalog.ACTIVE_WEAPONS.size()==8,"Exactly eight stable active weapon IDs")
 var entries=LoadoutCatalog.entries("weapons")
 check(entries.size()==8 and entries.all(func(e):return int(e.id) in Catalog.ACTIVE_WEAPONS),"Loadouts and unlocks expose only eight active weapons")
 var regions=[]
 for id in Catalog.ACTIVE_WEAPONS:
  var texture=UIAssets.icon("weapons",str(id));var identity=str(texture.region) if texture is AtlasTexture else texture.resource_path
  check(texture!=null and not identity in regions,"Unique recognisable weapon icon: "+Catalog.WEAPONS[id][0]);regions.append(identity)
 game.weapons.clear();game.tomes.clear();game.tome_rarities.clear()
 var acquisition=true;var excluded=false
 for i in 1000:
  for choice in game.upgrade_choices():
   if choice.type=="supply":continue
   if choice.type=="weapon" and choice.get("acquisition",false) and choice.metadata.rarity!="common":acquisition=false
   if choice.type=="weapon" and not int(choice.id) in Catalog.ACTIVE_WEAPONS:excluded=true
 check(acquisition and not excluded,"One thousand reward rolls: new weapons are always Common and no excluded weapon appears")
 var lightning=game.upgrade_pool().filter(func(c):return c.type=="weapon" and c.id==2)[0]
 game.apply_upgrade(lightning);game.apply_upgrade({"type":"tome","id":"Vampire"})
 check(game.weapons[2].rarity=="common" and game.tome_rarities.Vampire=="common","Newly acquired weapon and Legendary-base tome store Common tier")
 var owned=game.upgrade_pool().filter(func(c):return c.type=="weapon" and c.id==2)[0]
 check(owned.metadata.rarity=="rare","Existing weapon upgrades retain supported base rarity")
 owned["tier"]="rare";game.apply_upgrade(owned)
 var tome=game.upgrade_pool().filter(func(c):return c.type=="tome" and c.id=="Vampire")[0]
 check(tome.metadata.rarity=="legendary","Existing tome upgrades retain Legendary support")
 tome["tier"]="legendary";game.apply_upgrade(tome)
 check(game.equipment_meta("weapons",2).rarity=="common" and game.equipment_meta("tomes","Vampire").rarity=="common","Displayed equipment tiers keep the rarity from first pick (upgrades do not recolour them)")
 game.equip(15)
 check(game.save_run("user://art-reset-legacy.json") and game.load_run("user://art-reset-legacy.json") and game.weapons.has(15) and game.weapons[2].rarity=="common" and game.tome_rarities.Vampire=="common","Owned weapon rarity and tome state survive an old-style loadout checkpoint")
 check(not game.upgrade_pool().any(func(c):return c.type=="weapon" and not int(c.id) in Catalog.ACTIVE_WEAPONS),"Removed weapons never appear in the reward pool")
 game.mode="pause";game.frontend.inventory();await process_frame
 var trait_icon: Control
 for node in RewardScreens.descendants(game.frontend.menu):
  if node is Control and node.tooltip_text.begins_with("Trait:"):trait_icon=node;break
 check(trait_icon!=null and not RewardScreens.descendants(trait_icon).any(func(n):return n is ColorRect and n.material is ShaderMaterial),"Build trait icon has no animated gold shader frame")
 game.frontend.enter_run();game.update_hud();await process_frame
 var trait_tile=game.frontend.run_hud.trait_slot
 check(not RewardScreens.descendants(trait_tile).any(func(n):return n is ColorRect and n.material is ShaderMaterial),"HUD trait icon has no gold glow")
 game.player.active=false;game.player.position=game.map_layout.spawn;game.health=100;game.invulnerability=0;game.stats=Catalog.base_stats();game.enemies.clear();game.loadout_runtime.reset("climber","nova")
 var e=game.spawn_enemy(1,game.player.position+Vector3(1,0,0));e.variant=OrdinaryRoster.variant(1,0);e.detonated=false;e.damage=20;game.player.velocity=Vector3.ZERO
 var kills=game.kills;EnemySimulation.detonate(game,e);var health=game.health;var velocity=game.player.velocity;game.invulnerability=0;EnemySimulation.detonate(game,e)
 check(e.hp<=0 and e.state=="dead" and game.health==health and game.player.velocity==velocity,"Proximity explosion self-destructs, damages and launches exactly once")
 check(velocity.x<0 and velocity.y>=13,"Explosion launches away from its centre and upward")
 game.kill_enemy(game.enemies.find(e));game.kill_enemy(game.enemies.find(e))
 check(game.kills==kills+1,"Exploding enemy death and rewards clean up once")
 for i in 30:game.player.launch(Vector3.RIGHT,18,13,24,18)
 check(Vector2(game.player.velocity.x,game.player.velocity.z).length()<=24.001 and game.player.velocity.y<=18,"Repeated explosion impulses cannot stack unlimited speed")
 var ground=StaticBody3D.new();root.add_child(ground);ground.position=Vector3(400,999.9,400);var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(80,0.2,80);collision.shape=box;ground.add_child(collision)
 game.player.crowd_world=null;game.player.position=Vector3(400,1000.05,400);game.player.velocity=Vector3.ZERO;game.player.active=true
 await physics_frame;await physics_frame
 game.player.launch(Vector3.RIGHT,18,13);var start=game.player.position.y
 for i in 12:await physics_frame
 check(game.player.position.y>start+1 and game.player.position.x>400,"Actual CharacterBody physics shows a visible airborne launch")
 for i in 100:await physics_frame
 check(game.player.is_on_floor() and game.player.active and game.player.velocity.is_finite(),"Player lands safely and retains normal controls after launch")
 game.player.active=false;ground.queue_free();game.queue_free();await process_frame;await process_frame
 print("ART RESET GAMEPLAY: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
