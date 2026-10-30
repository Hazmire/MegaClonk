extends SceneTree
var failures=[]
var checks=0
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func descendants(node: Node) -> Array:
 var result=[]
 for child in node.get_children():result.append(child);result.append_array(descendants(child))
 return result
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause"
 check(XPGems.eligible({"ordinary":true,"kind":0}) and not XPGems.eligible({"ordinary":true,"kind":0,"summon_owner":"boss"}) and not XPGems.eligible({"ordinary":false,"kind":8}),"Only non-summoned ordinary enemies roll red gems")
 var rng=RandomNumberGenerator.new();rng.seed=123;var red=0
 for i in 100000:
  if rng.randf()<XPGems.RED_CHANCE:red+=1
 check(absf(red/100000.0-0.0025)<0.0006,"Red gem probability is 0.25%% (%d/100000)"%red)
 game.level=5;game.xp=Catalog.threshold(5)*0.4;game.pending_upgrades=0;game.stats.xp=3
 game.grant_red_level()
 check(game.level==6 and is_equal_approx(game.xp/Catalog.threshold(6),0.4) and game.pending_upgrades==1,"Red gem grants exactly one level and preserves progress fraction, ignoring XP multipliers")
 game.add_xp_drop(game.player.position+Vector3(7,1,0),3);game.add_red_gem(game.player.position+Vector3(7,1,0));game.add_xp_drop(game.player.position+Vector3(7,1,0),4)
 check(game.pickups.size()==2 and game.pickups[0].value==7 and game.pickups[1].red,"Blue XP merges without absorbing red gems")
 check(game.pickups[0].node.mesh==XPGems.mesh() and XPGems.material(false)!=XPGems.material(true),"Gem geometry and distinct materials are shared")
 var position=game.pickups[0].node.position;game.update_pickups(0.1)
 check(game.pickups[0].node.rotation.y>0 and game.pickups[0].node.position.y!=position.y,"Gems rotate and bob")
 game.pending_upgrades=2;game.mode="pause"
 var state=str(game.gem_rng.state)
 check(game.save_run("user://reward-ui-run.json") and game.load_run("user://reward-ui-run.json"),"Queued rewards and gems save/load")
 check(game.mode=="upgrade" and game.pending_upgrades==1 and str(game.gem_rng.state)==state and game.pickups.any(func(p):return p.get("red",false)),"Load retains gem type/RNG and opens exactly one queued reward")
 await process_frame
 var queued_screen: RunLevelUp
 for node in game.frontend.menu.get_children():
  if node is RunLevelUp:queued_screen=node
 queued_screen.fanfare.skip();queued_screen.clock=RunLevelUp.READY_AT+1.0;queued_screen.apply_timeline()
 var buttons=queued_screen.cards
 check(buttons.size()==3 and buttons[0].global_position.x<buttons[1].global_position.x and buttons[1].global_position.x<buttons[2].global_position.x,"Three upgrade offers sit side by side")
 var first=buttons[0];var old_generation=game.frontend.reward_generation;first.pressed.emit();var after=[game.weapons.duplicate(true),game.tomes.duplicate(),game.stats.duplicate()];first.pressed.emit()
 check(game.frontend.reward_generation>old_generation and [game.weapons,game.tomes,game.stats]==after,"Stale modal controls cannot apply a reward twice")
 game.pending_upgrades=0;game.mode="pause";game.frontend.inventory();await process_frame
 var labels=[]
 for node in descendants(game.frontend.menu):
  if node is Label:labels.append(node.text)
 check("Inventory" in labels and "Stats" in labels and "Weapons" in labels and "Items" in labels,"Build screen uses inventory and real stats sidebars")
 var shop={"tier":"Common","offers":["whetstone"],"sold":[],"used":false};game.gold=0;game.frontend.shop(shop)
 var shop_screen: RunShop
 for node in game.frontend.menu.get_children():
  if node is RunShop:shop_screen=node
 var disabled=shop_screen!=null and shop_screen.rows.size()==1 and not shop_screen.rows[0].can_buy() and shop_screen.rows[0].button_text().begins_with("NEED")
 check(disabled,"Unaffordable shop card cannot be bought and says how much more is needed")
 game.gold=100;var count=game.item_total();game.grant_item("salted_pork");game.frontend.reward("salted_pork");game.frontend.reward("salted_pork")
 check(game.item_total()==count+1,"Showing or skipping a chest reveal never grants a duplicate")
 var initial_items=game.items.duplicate();var skip: Button
 for node in descendants(game.frontend.menu):
  if node is Button and node.text=="SKIP REVEAL":skip=node;break
 skip.pressed.emit();skip.pressed.emit()
 check(game.items==initial_items,"Skipping the preselected roulette twice cannot duplicate rewards")
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=size;game.frontend.upgrades();await process_frame
  var level_screen: RunLevelUp
  for node in game.frontend.menu.get_children():
   if node is RunLevelUp:level_screen=node
  check(level_screen!=null and level_screen.cards.size()==3 and level_screen.stage.scale.x>0.0 and level_screen.stage.position.x>=0.0 and level_screen.stage.size.x*level_screen.stage.scale.x<=float(size.x)+1.0,"Level-up stage and three cards fit the window at "+str(size))
 var level_screen: RunLevelUp
 for node in game.frontend.menu.get_children():
  if node is RunLevelUp:level_screen=node
 level_screen.fanfare.skip();level_screen.clock=RunLevelUp.READY_AT+1.0;level_screen.apply_timeline();await process_frame
 level_screen.cards[0].grab_focus();await process_frame
 var focus=root.gui_get_focus_owner();var event=InputEventAction.new();event.action="ui_right";event.pressed=true;root.push_input(event);await process_frame
 check(root.gui_get_focus_owner()!=focus,"Keyboard/controller UI-right moves between offers")
 event=InputEventAction.new();event.action="ui_accept";event.pressed=true;root.push_input(event)
 event=InputEventAction.new();event.action="ui_accept";event.pressed=false;root.push_input(event);await process_frame
 check(game.mode=="run","Keyboard/controller UI-accept applies the focused offer")
 game.pending_upgrades=0;game.pause_menu();await process_frame
 var pause_screen: RunPause
 for node in game.frontend.menu.get_children():
  if node is RunPause:pause_screen=node
 check(pause_screen!=null and pause_screen.inventory_panel!=null and pause_screen.stats_panel!=null,"Pause shows the Inventory and Stats panels")
 pause_screen.items["map"].chosen.emit();await process_frame
 var expanded: RunMinimap
 for node in descendants(game.frontend.menu):
  if node is RunMinimap:expanded=node
 check(game.mode=="map" and expanded!=null,"Pause map button opens the expanded world map")
 check(expanded.explored==game.frontend.minimap.explored and expanded.reveal_all==game.frontend.minimap.reveal_all,"Expanded map preserves current fog of war")
 check(is_equal_approx(expanded.extent().x,expanded.extent().y),"Expanded map keeps world aspect ratio")
 var elapsed=game.elapsed;game._physics_process(0.25)
 check(game.elapsed==elapsed and not game.player.active,"Expanded map pauses gameplay simulation")
 var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true;game._unhandled_input(cancel)
 check(game.mode=="pause","Escape from pause map returns to pause")
 game.resume();var map_event=InputEventAction.new();map_event.action="map";map_event.pressed=true;game._unhandled_input(map_event)
 check(game.mode=="map" and InputMap.has_action("map") and game.bindings.has("map"),"World-map action uses existing rebindable input system")
 game._unhandled_input(cancel)
 check(game.mode=="run" and game.player.active,"Escape from gameplay map resumes normally")
 game.queue_free();await process_frame;await process_frame
 print("REWARD UI: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
