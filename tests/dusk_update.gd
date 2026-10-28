extends SceneTree
var failures=[]
var checks=0
func verify(value: bool,message: String):
 checks+=1
 if not value:failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
 var profile=Progress.new()
 verify(LoadoutCatalog.entries("tomes").size()==10 and Catalog.ACTIVE_TOMES.size()==10,"Exactly ten active tome entries")
 verify(MetaProgress.unlocked(profile.data,"tomes","Might"),"Basic damage tome starts unlocked")
 verify(not MetaProgress.unlocked(profile.data,"tomes","Multishot"),"Projectile tome has a real unlock")
 profile.data.silver=1000
 verify(not MetaProgress.purchase(profile.data,"tomes","Multishot"),"Kill milestone cannot be bypassed with silver")
 profile.data.kills=100
 verify(MetaProgress.purchase(profile.data,"tomes","Multishot") and profile.data.silver==900,"Eligible tome purchase spends silver once")
 verify(not MetaProgress.purchase(profile.data,"tomes","Multishot") and profile.data.silver==900,"Tome unlock cannot be bought twice")
 verify(MetaProgress.toggle(profile.data,"tomes","Multishot") and not MetaProgress.enabled(profile.data,"tomes","Multishot"),"Unlocked tome can be disabled")
 profile.storage_path="user://dusk-tome-profile.json";verify(profile.save(),"Tome toggles save")
 var restored=Progress.new();verify(restored.load_save(profile.storage_path) and not MetaProgress.enabled(restored.data,"tomes","Multishot"),"Tome unlock and disabled flag survive loading")
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=profile;game.sandbox=false;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 verify(game.upgrade_pool().all(func(c):return c.type!="tome" or (c.id in Catalog.ACTIVE_TOMES and c.id!="Multishot" and MetaProgress.enabled(profile.data,"tomes",c.id))),"Normal pool excludes locked/disabled/archived tomes")
 var count_before=game.stats.count;game.apply_upgrade({"type":"tome","id":"Multishot"})
 verify(game.stats.count==count_before and not game.tomes.has("Multishot"),"Stale disabled acquisition cannot grant projectiles")
 game.sandbox=true
 var regions={}
 for id in Catalog.ACTIVE_TOMES:
  game.tomes.clear();var stat=Catalog.TOMES[id][0];var before=float(game.stats[stat]);game.apply_upgrade({"type":"tome","id":id})
  verify(is_equal_approx(game.stats[stat],before+float(Catalog.TOMES[id][1])),"Actual stat effect for "+Catalog.tome_name(id))
  var icon=UIAssets.icon("tomes",id)
  verify(icon is AtlasTexture and icon.atlas!=null and icon.region.size.x>0,"Generated tome icon loads: "+id)
  regions[str(icon.region)]=true
 verify(regions.size()==10,"All ten tomes use distinct generated regions")
 game.update_hud();verify(not game.frontend.quest_tracker.visible and game.frontend.quest_tracker.text.is_empty(),"Quest tracking is absent from the run HUD")
 var shrine={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object;break
 game.mode="run";ShrineCharging.tick(game,shrine,0,2);ShrineCharging.tick(game,shrine,8,.5)
 verify(shrine.charge>0 and shrine.node.get_node("ChargeProgress").visible,"Shrine text remains while residual charge decays outside")
 ShrineCharging.tick(game,shrine,8,3)
 verify(shrine.charge==0 and not shrine.node.get_node("ChargeProgress").visible,"Shrine text vanishes at zero percent")
 var audio=game.audio;verify(audio.tracks.size()==1 and not audio.menu_track.is_empty(),"One menu and one game music entry")
 audio.music_menu();verify(audio.current_track.ends_with("menu_dusk.mp3") and audio.streams[audio.current_track].loop,"Selected menu music loops")
 audio.music_stage(1);var slot=audio.music_slot
 audio.music_stage(3);verify(audio.current_track.ends_with("hollow_dusk.mp3") and audio.streams[audio.current_track].loop and audio.music_slot==slot,"Game music loops across stage changes without restart")
 game.frontend.home();await process_frame
 verify(game.frontend.menu_shop.get_meta("grimdark_kind","")=="Shop","Backdrop uses native shop model")
 verify(game.player.position.distance_to(game.frontend.menu_shop.position)<4,"Player stands in front of shop")
 var anchor=game.player.position;var camera_start=game.frontend.menu_camera.position
 var bounded=true
 for tick in 2400:
  game.frontend.update_menu_camera(.1)
  if game.frontend.menu_camera.position.distance_to(game.frontend.menu_focus)>8:bounded=false
 verify(bounded and game.player.position==anchor and camera_start!=game.frontend.menu_camera.position,"Bounded camera pans without moving the player or circling the map")
 verify(audio.current_track.ends_with("menu_dusk.mp3"),"Returning home restores menu music")
 game.queue_free();await process_frame;await process_frame
 print("DUSK UPDATE: ",checks," checks, ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
