extends SceneTree
var failures=[]
var checks=0
var game: Node
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func nodes(node: Node) -> Array:return RewardScreens.descendants(node)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=false;game.settings.focus_pause=false;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.set_physics_process(false);game.player.active=false;game.weapons.clear()
 var center=game.map_layout.spawn;game.player.position=center
 game.add_xp_drop(center+Vector3(20,1,0),1);game.pickups[0].age=40;var x=game.pickups[0].node.position.x;game.update_pickups(0.1)
 check(not game.pickups[0].get("attracted",false) and is_equal_approx(game.pickups[0].node.position.x,x),"Old XP gems remain idle outside real range")
 game.stats.pickup=5;game.update_pickups(0.1)
 check(game.pickups[0].attracted and game.pickups[0].attraction_reason=="pickup_range" and game.pickups[0].attraction_radius==25,"Legitimate pickup upgrade activates attraction with a recorded reason")
 game.stats.pickup=1;game.player.position=center+Vector3(-20,0,0);x=game.pickups[0].node.position.x;game.update_pickups(0.1)
 check(game.pickups[0].node.position.x<x,"Once legitimately attracted a gem consistently follows")
 game.pool.release(game.pickups[0].node);game.pickups.clear();game.add_xp_drop(center+Vector3(20,1,0),1);game.update_pickups(0.1)
 check(not game.pickups[0].get("attracted",false),"Recycled pooled XP mesh does not retain attraction state")
 game.pickups[0]["attracted"]=true;game.pickups[0]["attraction_reason"]="pickup_range"
 check(game.save_run("user://v9-xp.json") and game.load_run("user://v9-xp.json") and game.pickups[0].attracted,"Valid attraction state survives a checkpoint")
 game.player.position=center;game.mode="run";game.pending_upgrades=0
 var rng=RandomNumberGenerator.new();rng.seed=981
 var gold_count=0;var tiers={}
 for i in 100000:
  if ShrineCharging.golden_for(i,1,i%6):gold_count+=1
  var tier=ShrineRewards.roll_tier(rng);tiers[tier]=int(tiers.get(tier,0))+1
 check(gold_count>1800 and gold_count<2200,"Seeded Golden Shrine rate is approximately 2%% across 100000 placements: %d"%gold_count)
 check(ShrineCharging.golden_for(123,2,4)==ShrineCharging.golden_for(123,2,4),"Golden placement is deterministic")
 for tier in Rarity.IDS:check(absf(float(tiers[tier])/1000-Rarity.TIERS[tier].weight)<0.7,"Normal shrine rarity matches central weight: "+tier)
 for stat in ShrineRewards.TABLE.bonuses:
  for tier_index in 5:
   game.stats=Catalog.base_stats();game.health=100;var before=game.stats[stat];var amount=ShrineRewards.TABLE.bonuses[stat][tier_index]
   ShrineRewards.apply(game,{"stat":stat,"amount":amount})
   check(is_equal_approx(game.stats[stat]-before,amount),"Stat table applies exact displayed bonus: %s/%s"%[stat,Rarity.IDS[tier_index]])
 check(ShrineRewards.bonus_text({"stat":"damage","amount":0.25})=="+25%" and ShrineRewards.bonus_text({"stat":"regen","amount":0.16})=="+0.16 HP/s","Stat cards format additive bonuses rather than subtracting one from them")
 game.stats=Catalog.base_stats();game.stats.crit=0.99
 var capped=ShrineRewards.generate({"crit":0.99},rng,true)
 check(capped.size()==1 and is_equal_approx(capped[0].amount,0.01),"Insufficient eligible stats return valid capped choices without invented upgrades")
 check(ShrineRewards.generate({"crit":1.0},rng,true).is_empty(),"Fully capped stats produce a safe empty result")
 game.stats=Catalog.base_stats();game.shrine_reward_queue.clear();game.active_shrine_reward={};game.mode="run"
 var shrine={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object;break
 shrine.golden=true;var original=game.stats.duplicate()
 ShrineCharging.tick(game,shrine,0,4);ShrineCharging.tick(game,shrine,8,1)
 check(is_equal_approx(shrine.charge,2.8),"Leaving shrine decays by fifteen percentage points per second")
 ShrineCharging.tick(game,shrine,0,5.2)
 check(shrine.used and game.mode=="shrine" and game.active_shrine_reward.choices.size()==3 and game.stats==original,"Completion pauses for three choices without granting a stat")
 var fixed=game.active_shrine_reward.duplicate(true)
 check(fixed.choices.all(func(c):return c.rarity=="legendary"),"All three Golden Shrine cards are Legendary before selection")
 var saved=game.save_run("user://v9-shrine.json");var loaded=game.load_run("user://v9-shrine.json")
 check(saved and loaded and JSON.stringify(game.active_shrine_reward)==JSON.stringify(fixed),"Pending shrine cards survive save/load without reroll")
 var elapsed=game.elapsed;game._physics_process(1)
 check(game.elapsed==elapsed and not game.player.active,"Shrine choices pause gameplay")
 var choice=game.active_shrine_reward.choices[0];var before=game.stats.duplicate();ShrineRewards.select(game,0);var earned=game.stats.duplicate();ShrineRewards.select(game,0)
 check(is_equal_approx(earned[choice.stat]-before[choice.stat],choice.amount) and game.stats==earned,"Selecting once applies exactly its displayed amount and rejects repeated input")
 ShrineCharging.tick(game,shrine,0,20)
 check(game.stats==earned and game.active_shrine_reward.is_empty(),"Completed shrine cannot reopen or grant again")
 game.stats.crit=0.85;game.mode="loading"
 game.shrine_reward_queue=[{"choices":[{"stat":"crit","amount":0.1,"rarity":"legendary","description":"Critical chance"}],"golden":true},{"choices":[{"stat":"crit","amount":0.1,"rarity":"legendary","description":"Critical chance"}],"golden":true}]
 ShrineRewards.present_next(game);var old_card: Button
 for n in nodes(game.frontend.menu):
  if n.name=="ShrineChoice0":old_card=n
 old_card.pressed.emit()
 check(is_equal_approx(game.active_shrine_reward.choices[0].amount,0.05),"Queued shrine recalculates remaining cap before its menu opens without rerolling stat or rarity")
 old_card.pressed.emit()
 check(is_equal_approx(game.stats.crit,0.95),"A stale first shrine button cannot select the next shrine reward")
 ShrineRewards.select(game,0);check(is_equal_approx(game.stats.crit,1.0),"Second capped shrine grants exactly its displayed remaining bonus")
 game.mode="run";game.enemies.clear();game.player.position=center;game.health=100;game.invulnerability=0;game.stats=Catalog.base_stats();game.player.velocity=Vector3.ZERO
 var e=game.spawn_enemy(0,center+Vector3(3,0,0));e.cooldown=0;e.state="move";e.variant=OrdinaryRoster.variant(0,0)
 var stopped=false
 for i in 100:
  game.update_enemies(1.0/60)
  if e.state in ["windup","recover"]:stopped=true
 check(not stopped and game.health<100,"Standard enemy pursues continuously and deals contact damage without melee poses")
 e.state="windup";e.action="melee";EnemySimulation.step(game,e,0.01)
 check(e.state=="move","Legacy saved ordinary melee windup is repaired on first tick")
 e.pos=center+Vector3(4,0.65,0);game.health=100;game.invulnerability=0;e.contact_clock=0;game.update_enemies(0.01)
 check(game.health==100,"Ordinary melee cannot damage from outside contact overlap")
 game.frontend.enter_run();game.player.camera.current=true
 for yaw in [0.0,PI/2,PI,-PI/2]:
  game.player.camera.global_rotation=Vector3(-0.7,yaw,0);game.player.avatar.rotation.y=yaw+1.5
  var forward=-game.player.camera.global_basis.z;var expected=Vector2(forward.x,forward.z).normalized()
  check(game.frontend.minimap.camera_facing().distance_to(expected)<0.001,"Map arrow reads world camera forward at yaw %.2f"%yaw)
 game.player.camera.global_rotation=Vector3(-0.2,0.8,0);var pitched=game.frontend.minimap.camera_facing();game.player.camera.global_rotation=Vector3(-1.2,0.8,0)
 check(pitched.distance_to(game.frontend.minimap.camera_facing())<0.001,"Camera pitch changes preserve horizontal minimap facing")
 game.frontend.minimap.reveal_all=true;game.player.avatar.rotation.y+=1;game.player.velocity=Vector3(8,0,-8)
 var facing=game.frontend.minimap.camera_facing();game.player.avatar.rotation.y+=2
 check(facing==game.frontend.minimap.camera_facing(),"Strafing/backwards avatar rotation does not change map facing")
 game.weapons.clear();game.equip(0);game.tomes={"Wind":3};game.update_hud();await process_frame
 var hud_rows=game.frontend.run_hud.build_box;var filled=func(row):return row.get_children().filter(func(n):return n.tooltip_text!="")
 check(filled.call(hud_rows.get_child(1)).size()==1 and filled.call(hud_rows.get_child(3)).size()==1 and filled.call(hud_rows.get_child(1))[0].tooltip_text.begins_with(Catalog.weapon_name(0)) and filled.call(hud_rows.get_child(3))[0].tooltip_text.begins_with(Catalog.tome_name("Wind")),"Horizontal HUD shows only owned weapons/tomes")
 game.weapons[0].level=4;game.update_hud();await process_frame
 check(nodes(game.frontend.run_hud.build_box).any(func(n):return n is Label and n.text=="LV 4"),"Horizontal equipment levels update immediately")
 var profile=game.progress.data.duplicate(true);game.progress.data.claimed=[];game.progress.data.kills=0;game.kills=0;game.frontend.in_run=true
 var q=LoadoutCatalog.quests()[0];game.update_hud()
 check(MetaProgress.quest_state(game.progress.data,q)=="active","Quest state distinguishes active")
 game.kills=q.target;game.run_metrics[q.metric]=q.target
 if q.metric=="kills":game.progress.data.kills=0
 else:game.progress.data.quest_metrics[q.metric]=q.target
 game.update_hud()
 check(not q.name in game.frontend.quest_tracker.text,"Completed unclaimed quest immediately leaves gameplay tracker")
 game.progress.data.kills=100000;game.progress.data.best=100000
 for quest in LoadoutCatalog.quests():game.progress.data.quest_metrics[quest.metric]=100000
 game.frontend.quests();await process_frame
 var quest_screen=game.frontend.menu.get_child(game.frontend.menu.get_child_count()-1)
 quest_screen.tab_bar.select("Exploration");await process_frame
 var claim: Button
 for n in nodes(quest_screen.grid):
  if n is Button and n.name=="Claim":claim=n;break
 check(claim!=null,"Quest menu retains a claimable completed quest")
 if claim:
  var card=claim.get_parent()
  while not card is MemoCard:card=card.get_parent()
  var id=String(card.name).trim_prefix("Quest_");claim.pressed.emit();await process_frame
  check(quest_screen.category=="Exploration" and id in game.progress.data.claimed,"Claim keeps the selected category and records the claim")
  var again=quest_screen.grid.get_node("Quest_"+id)
  check(nodes(again).any(func(n):return n is Label and n.text=="Reward claimed") and again.claim_button==null,"Claimed quest stays visible as a DONE memo without a claim button")
 game.progress.data=profile;game.progress.save();game.shrine_reward_queue.clear();game.active_shrine_reward={};game.frontend.in_run=true
 game.active_reward="";game.reward_queue.clear();game.mode="run";var items=game.items.duplicate();var reward_rng=str(game.rng.state);game.frontend.reward("salted_pork");await process_frame
 var screen: RunChest
 for n in game.frontend.menu.get_children():
  if n is RunChest:screen=n
 check(screen!=null and screen.phase=="closed" and screen.reel.strip.size()==RunData.STRIP_LENGTH and screen.reel.strip[screen.reel.win_index].id=="salted_pork","Chest opens closed with a reel whose winning card is the item already decided")
 screen.open_chest();await create_timer(1.2).timeout
 check(screen.phase=="spinning" and screen.reel.progress>0.0,"The reel turns after the chest opens")
 game.frontend.chest_skip.call();await process_frame
 var reveal=screen.card
 check(screen.is_revealed() and reveal!=null and reveal.data.id=="salted_pork" and game.items==items,"Fast-forward reveals the predetermined item without awarding again")
 check(str(game.rng.state)==reward_rng,"Reel animation and skipping leave the gameplay reward RNG unchanged")
 check(game.sound_bank.has("applause") and game.sound_bank.has("legendary"),"Original applause and distinctive Legendary audio are loaded")
 game.resume();await create_timer(0.5).timeout
 game.frontend.reward("salted_pork");await process_frame
 for n in game.frontend.menu.get_children():
  if n is RunChest:screen=n
 screen.open_chest();screen.phase_time=0.0;await create_timer(RunChest.OPEN_TIME+RunChest.SPIN_TIME+RunChest.LAND_TIME+0.5).timeout
 check(screen.is_revealed() and game.items==items,"Natural reveal lands after the full reel without another grant")
 game.resume();await create_timer(0.5).timeout
 check(not is_instance_valid(screen) or not screen.is_visible_in_tree(),"Closing the chest frees its screen")
 game.queue_free();await process_frame;await process_frame
 print("REWARDS AI V9: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
