extends SceneTree
# Renders the shared menu widgets side by side (the "kit"): menu item states, memo variants, rarity frames, tiles,
# toggle, tab bar. usage: xvfb-run -a tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/menu_kit_capture.gd
func _initialize() -> void:call_deferred("run")
func run() -> void:
 MenuScreen.set_instant(true)
 var screen=MenuStyle.spawn("menu_screen") as MenuScreen
 root.add_child(screen);await process_frame
 var c=screen.content
 var items=VBoxContainer.new();items.position=Vector2(60,60);items.custom_minimum_size.x=480;c.add_child(items)
 for i in 4:
  var m=MenuStyle.spawn("menu_item") as MenuItem;m.setup(["Play","Unlocks","Quests","Settings"][i],38,48,i==3);items.add_child(m)
 await process_frame;items.get_child(0).grab_focus()
 var x=600
 var quests=[["First blood","Defeat 40 enemies across your runs.","active",27,40,false],["Before the fifth bell","Clear the stage before the fifth bell.","active",0,1,true],["The hundred","Defeat 100 enemies.","completed",100,100,false]]
 for q in quests:
  var card=MenuStyle.spawn("memo_card") as MemoCard;card.custom_minimum_size.x=380;card.position=Vector2(x,60);card.set_look(-1.0);card.fill_quest(q[0],q[1],q[2],q[3],q[4],q[5],"35 SILVER");c.add_child(card);x+=420
 var tx=60
 for r in 5:
  var s=MenuStyle.spawn("rarity_slot") as RaritySlot;s.position=Vector2(tx,420);s.setup(r,UIAssets.icon("items","whetstone"),64,Vector2(88,88),false);c.add_child(s)
  var m=MenuStyle.spawn("rarity_slot") as RaritySlot;m.position=Vector2(tx,540);m.setup(r,UIAssets.icon("items","whetstone"),64,Vector2(88,88),true);c.add_child(m);tx+=130
 var states=["on","off","locked"]
 for i in 3:
  var t=MenuStyle.spawn("collection_tile") as CollectionTile;t.position=Vector2(760+i*220,380);t.setup("weapons",["0","1","15"][i],["Sword","Firestaff","Shotgun"][i],states[i],Vector2(196,196),96,-1,i==2);c.add_child(t)
 var tog=MenuStyle.spawn("on_off_toggle") as OnOffToggle;tog.position=Vector2(60,700);tog.setup(true);c.add_child(tog)
 var tabs=MenuStyle.spawn("tab_bar") as MenuTabBar;tabs.position=Vector2(60,800);c.add_child(tabs);tabs.set_tabs([{"id":"weapons","label":"Weapons"},{"id":"tomes","label":"Tomes"},{"id":"items","label":"Items"}],"tomes");tabs.set_note("FOUND 60 / 60")
 var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.position=Vector2(400,700);stamp.setup("Locked",FogPalette.RUST_TEXT,22,0.26,4,-8.0,Color(0.055,0.059,0.055,0.55),Vector2(24,8));c.add_child(stamp)
 screen.set_hints([["Q / E","Category"],["ENTER","Toggle"],["ESC","Home"]])
 await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/images/menus/"))
 root.get_texture().get_image().save_png("res://docs/images/menus/kit.png");print("KIT_OK");quit()
