class_name FrontEnd
extends CanvasLayer
var game: Node
var root: Control
var menu: Control
var hud_root: Control
var stopwatch_overlay: StopwatchOverlay
var run_stage: RunStage
var run_hud: RunHud
var run_overlay: RunOverlay
var tally=PickupTally.new()
var event_label: Label
var timer_label: Label
var minimap: RunMinimap
var menu_camera: Camera3D
var preview_mode="home"
var orbit=0.0
var menu_shop: Node3D
var menu_focus=Vector3.ZERO
var menu_player_position=Vector3.ZERO
var menu_world_instance=0
var map_tick=0.0
var settings_back: Callable
var in_run=false
const HEALTH_COLOR=FogPalette.RUST
var health_text: Label
var character_health: ProgressBar
var active_tab="weapons"
var shop_object: Dictionary={}
var shop_offers: Array=[]
var headline_font: Font
var card_gold=Color("d8b575")
var reward_generation=0
var reward_consumed=false
var reward_focus: Dictionary={}
var reward_tweens: Array=[]
var map_return_to_pause=false
var quest_tracker: Label # kept hidden and empty: quest tracking is not shown in gameplay (asserted by tests)
var stage_banner: Control
var quest_definitions: Array=[]
var chest_skip: Callable

func setup(owner_game: Node) -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 game=owner_game
 quest_definitions=LoadoutCatalog.quests()
 layer=2
 root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(root)
 root.theme=MenuStyle.theme() # the shared Fog theme; menus apply the same one to their own roots
 headline_font=load("res://assets/fonts/Kurland.ttf") if ResourceLoader.exists("res://assets/fonts/Kurland.ttf") else load("res://assets/fonts/PixelatedElegance.ttf")
 menu=Control.new();menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(menu)
 hud_root=Control.new();hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud_root)
 stopwatch_overlay=StopwatchOverlay.new();stopwatch_overlay.setup(hud_root);hud_root.add_child(stopwatch_overlay)
 game.ui=self
 game.hud=text("",hud_root,18);game.hud.hide()
 quest_tracker=text("",hud_root,13);quest_tracker.hide()
 run_stage=RunStage.new();hud_root.add_child(run_stage)
 run_hud=RunHud.new().setup(game,self);run_stage.stage.add_child(run_hud)
 game.health_bar=run_hud.health_bar;game.xp_bar=run_hud.xp_bar;health_text=run_hud.health_text;minimap=run_hud.minimap;event_label=run_hud.event_label;timer_label=run_hud.timer_label
 var hp_background=StyleBoxFlat.new();hp_background.bg_color=FogPalette.RUST_DEEP;hp_background.border_color=FogPalette.INK;hp_background.set_border_width_all(1)
 character_health=ProgressBar.new();character_health.name="CharacterHealth";character_health.size=Vector2(64,7);character_health.show_percentage=false;character_health.mouse_filter=Control.MOUSE_FILTER_IGNORE;character_health.add_theme_stylebox_override("background",hp_background.duplicate());var hp_fill=StyleBoxFlat.new();hp_fill.bg_color=HEALTH_COLOR;character_health.add_theme_stylebox_override("fill",hp_fill);character_health.add_theme_font_size_override("font_size",1);character_health.size=Vector2(64,7);hud_root.add_child(character_health)
 game.notice=NoticeLabel.new();root.add_child(game.notice);game.notice.position=Vector2(350,556);game.notice.custom_minimum_size=Vector2(590,34)
 run_overlay=RunOverlay.new();root.add_child(run_overlay);root.move_child(menu,root.get_child_count()-1) # order: HUD, run overlay, then pause/reward screens above
 hud_root.hide()
func text(value: String, parent: Node, size_value: int = 18) -> Label:
 var label=Label.new();label.text=value;label.add_theme_font_size_override("font_size",size_value);parent.add_child(label);return label
func heading(value: String, parent: Node, size_value: int = 28) -> Label:
 var label=text(value,parent,size_value);label.add_theme_font_override("font",headline_font);return label
func action(value: String, parent: Node, callback: Callable) -> Button:
 var button=Button.new();button.text=value;button.custom_minimum_size.y=42;parent.add_child(button)
 button.mouse_entered.connect(func():game.play_sound("ui.hover"))
 button.pressed.connect(func(): game.play_sound("ui.confirm");callback.call())
 return button
func card(parent: Node, pos: Vector2, dimensions: Vector2) -> VBoxContainer:
 var panel=PanelContainer.new();panel.position=pos;panel.size=dimensions;panel.custom_minimum_size=dimensions
 var style=StyleBoxFlat.new();style.bg_color=Color(0.045,0.085,0.10,0.95);style.border_color=Color("49645f");style.set_border_width_all(1);style.set_corner_radius_all(8)
 style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=18;style.content_margin_bottom=18
 panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10);scroll.add_child(column)
 game.panel=panel
 return column
func stop_reward_animations() -> void:
 if is_instance_valid(game.audio):game.audio.stop_event("reward.chest.tick")
 for tween in reward_tweens:
  if tween!=null and tween.is_valid():tween.kill()
 reward_tweens.clear()
func _exit_tree() -> void:
 stop_reward_animations()
func clear() -> void:
 if is_instance_valid(game.audio):game.audio.emit("ui.open")
 if is_instance_valid(stage_banner):stage_banner.hide()
 chest_skip=Callable()
 stop_reward_animations()
 reward_generation+=1;reward_consumed=false
 if is_instance_valid(game.notice):game.notice.text=""
 for child in menu.get_children():menu.remove_child(child);child.queue_free()
 menu.show();hud_root.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if is_instance_valid(game.player):game.player.active=false
func page(label: String) -> VBoxContainer:
 clear()
 var column=card(menu,Vector2(32,26),Vector2(1216,640))
 var row=HBoxContainer.new();column.add_child(row)
 heading(label,row)
 var spacer=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(spacer)
 if game.mode!="upgrade":action("Resume" if in_run and game.mode!="results" else "Home",row,game.resume if in_run and game.mode!="results" else home)
 return column
func paragraph(value: String, parent: Node, width: float = 500) -> Label:
 var label=text(value,parent,16);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=width;return label
func icon_row(parent: Node, category: String, id: String, label: String, golden: bool = false, grey: bool = false) -> HBoxContainer:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);parent.add_child(row)
 var slot=Control.new();slot.custom_minimum_size=Vector2(48,48);row.add_child(slot)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);slot.add_child(image)
 if grey:image.modulate=Color(0.3,0.3,0.3,0.8)
 if golden and category!="traits":
  var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;slot.add_child(border)
 paragraph(label,row,260)
 return row
func prepare_backdrop() -> void:
 game.mode="menu"
 if not is_instance_valid(game.player) or not is_instance_valid(game.enemy_view):
  game.variants.initialize(0);game.biome=0;game.run_seed=12;game.build_stage()
 if not is_instance_valid(menu_camera) or menu_camera.get_parent()!=game.world:
  menu_camera=Camera3D.new();game.world.add_child(menu_camera)
 if menu_world_instance!=game.world.get_instance_id() or not is_instance_valid(menu_shop) or not menu_shop.is_inside_tree():
  # The protected spawn clearing keeps the close camera away from cliffs/trees.
  # This is the native shop visual, not an interactive merchant added to the run.
  menu_shop=Node3D.new();menu_shop.name="MenuShopBackdrop";game.world.add_child(menu_shop)
  menu_shop.position=game.map_layout.spawn
  GrimdarkObjects.populate(menu_shop,"Shop",game.stage)
  menu_world_instance=game.world.get_instance_id();orbit=0.0
  var forward=menu_shop.basis.z.normalized()
  menu_player_position=menu_shop.position+forward*3.2
  menu_player_position.y=game.terrain_height(menu_player_position.x,menu_player_position.z)+.1
  menu_focus=menu_player_position+Vector3.UP*1.1
 menu_camera.current=true
 game.player.active=false;game.player.position=menu_player_position
 game.player.avatar.rotation.y=atan2(menu_shop.basis.z.x,menu_shop.basis.z.z)
 game.player.avatar.set_damage_flash(false);game.player.avatar.animate("idle",0,.1)
 game.enemy_view.hide();game.player.avatar.show()
 game.notice.text="";game.message_time=0
 if is_instance_valid(game.audio):game.audio.music_menu()
 update_menu_camera(0)
func update_menu_camera(delta: float) -> void:
 if not is_instance_valid(menu_camera) or not is_instance_valid(menu_shop):return
 orbit+=delta*.12
 # A bounded arc keeps the shop behind the adventurer and avoids terrain clipping.
 var yaw=atan2(menu_shop.basis.z.x,menu_shop.basis.z.z)+sin(orbit)*.22
 var radius=7.0 if preview_mode=="home" else 5.7
 menu_camera.position=menu_focus+Vector3(sin(yaw)*radius,1.65,cos(yaw)*radius)
 menu_camera.h_offset=-3.1 if preview_mode=="home" else -1.3
 menu_camera.fov=55;menu_camera.look_at(menu_focus)
func home() -> void:
 in_run=false;game.mode="menu";preview_mode="home";prepare_backdrop();clear()
 if is_instance_valid(game.audio):game.audio.music_menu()
 show_screen("main_menu")
# Out-of-run menus are Fog County MenuScreen scenes (res://ui/menu). They own their theme; in-run screens keep theirs.
const SCREENS={"main_menu":"res://ui/menu/screens/main_menu.tscn","loadout":"res://ui/menu/screens/loadout_screen.tscn","unlocks":"res://ui/menu/screens/unlocks_screen.tscn","quests":"res://ui/menu/screens/quests_screen.tscn","settings":"res://ui/menu/screens/settings_screen.tscn"}
func show_screen(kind: String) -> MenuScreen:
 MenuScreen.set_audio_owner(game)
 var screen=load(SCREENS[kind]).instantiate() as MenuScreen
 screen.bind(self);menu.add_child(screen);return screen
func wallet() -> String:
 return "SILVER %d"%game.progress.data.silver
func play_screen() -> void:
 game.mode="play";preview_mode="play";prepare_backdrop();game.mode="play";clear()
 show_screen("loadout")
func unlocks() -> void:
 game.mode="unlocks";preview_mode="home";clear()
 show_screen("unlocks")
func quest_description(q: Dictionary) -> String:return MenuData.quest_description(q)
func quests() -> void:
 game.mode="quests";preview_mode="home";clear()
 show_screen("quests")
func enter_run() -> void:
 chest_skip=Callable()
 stop_reward_animations()
 in_run=true;pause_frame=null
 menu.hide();hud_root.show();game.player.camera.current=true
# Pickup notifications (RunToasts): where the item/gem was picked up is where the player stands, so the burst starts at the head.
func player_head_stage() -> Vector2:
 var origin=Vector2(640,380)
 if is_instance_valid(game.player) and is_instance_valid(game.player.camera) and DisplayServer.get_name()!="headless" and not game.player.camera.is_position_behind(game.player.position):
  origin=game.player.camera.unproject_position(game.player.position+Vector3.UP*1.5)
 return run_stage.from_screen(origin)
func gem_notice(element: String) -> void:
 run_hud.toasts.push_gem(element,game.gems.count(element),player_head_stage())
func item_notice(id: String,owned: int) -> void:
 run_hud.toasts.push_item(id,owned,player_head_stage())
# Running +gold / +XP totals beside the player's head, and the fading gem banner.
# Wall-clock seconds since the previous HUD update. update_hud can run several times per
# rendered frame (physics ticks), so counting get_process_delta_time() each call would make
# timers run several times too fast.
var last_hud_msec=-1
func real_delta() -> float:
 var now=Time.get_ticks_msec()
 var delta=0.0 if last_hud_msec<0 else clampf((now-last_hud_msec)/1000.0,0.0,0.25)
 last_hud_msec=now
 return delta
func update_tally(delta: float) -> void:
 tally.update(game,delta)
 var origin=Vector2(640,380)
 if is_instance_valid(game.player) and is_instance_valid(game.player.camera) and DisplayServer.get_name()!="headless" and not game.player.camera.is_position_behind(game.player.position):
  origin=game.player.camera.unproject_position(game.player.position+Vector3.UP*1.5)
 if tally.gold_gain_now>0:run_hud.gain("gold",tally.gold_gain_now,run_stage.from_screen(origin+Vector2(44,-16)))
 if tally.xp_gain_now>0.0:run_hud.gain("xp",tally.xp_gain_now,run_stage.from_screen(origin+Vector2(44,10)))
func update_hud() -> void:
 var frame_delta=real_delta()
 if stopwatch_overlay:stopwatch_overlay.update_state(game.world_time,frame_delta)
 if run_overlay:run_overlay.sync(game,frame_delta)
 update_tally(frame_delta)
 run_hud.update(frame_delta)
 character_health.max_value=game.stats.max_health;character_health.value=game.health
 update_character_health()
# Frozen gameplay frame behind RunPause (and Settings opened from it); null when nothing could be captured (headless).
var pause_frame: Texture2D
func capture_pause_frame() -> void:
 pause_frame=null
 if DisplayServer.get_name()=="headless" or not is_instance_valid(hud_root):return
 var was_visible=hud_root.visible;hud_root.hide() # the clean world, as in the mockup, not the HUD
 var banner_was=is_instance_valid(stage_banner) and stage_banner.visible;if banner_was:stage_banner.hide()
 var notice_was=game.notice.visible;game.notice.hide()
 RenderingServer.force_draw(false,0.0)
 var image=get_viewport().get_texture().get_image()
 if was_visible:hud_root.show()
 if banner_was:stage_banner.show()
 if notice_was:game.notice.show()
 if image!=null and not image.is_empty():pause_frame=ImageTexture.create_from_image(image)
func settings_from_pause() -> bool:return pause_frame!=null and settings_back.is_valid() and settings_back==Callable(game,"pause_menu")
func pause() -> void:
 if game.mode=="run":capture_pause_frame()
 game.mode="pause";clear()
 if is_instance_valid(game.audio):game.audio.music_duck(true)
 var screen=RunPause.new();MenuScreen.set_audio_owner(game);screen.bind(self);menu.add_child(screen)
func results(victory: bool,unlocked: Array) -> void:
 clear();var screen=RunResults.new();screen.info=RunData.results(game,victory,unlocked);MenuScreen.set_audio_owner(game);screen.bind(self);menu.add_child(screen)
func sandbox(entries: Array,seed_line: String) -> RunSandbox:
 if game.mode=="run":capture_pause_frame()
 clear();var screen=RunSandbox.new();screen.entries=entries;screen.seed_line=seed_line;MenuScreen.set_audio_owner(game);screen.bind(self);menu.add_child(screen);return screen
func world_map(from_pause: bool=false) -> void:
 RewardScreens.world_map(self,from_pause)
func inventory() -> void:
 RewardScreens.inventory(self)
func upgrades(fixed_choices: Array=[],quick: bool=false) -> void:
 RewardScreens.upgrades(self,fixed_choices,quick)
func shop(object: Dictionary) -> void:
 RewardScreens.shop(self,object)
func imbue_station(object: Dictionary) -> void:
 RewardScreens.imbue_station(self,object)
func reward(id: String) -> void:
 RewardScreens.reward(self,id)
func settings(back: Callable) -> void:
 settings_back=back
 game.mode="settings";clear()
 show_screen("settings")
func update_character_health() -> void:
 if not is_instance_valid(game) or game.mode!="run" or not is_instance_valid(game.player) or not is_instance_valid(game.player.camera):character_health.hide();return
 character_health.size=Vector2(64,7) # Apply after inherited theme minimum-size recalculation.
 var point=game.player.global_position+Vector3.UP*0.05;var camera=game.player.camera
 if (point-camera.global_position).dot(-camera.global_basis.z)<=0.05:character_health.hide();return
 var screen=camera.unproject_position(point);character_health.position=screen+Vector2(-32,12)
 character_health.visible=game.mode=="run" and not camera.is_position_behind(point) and Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).has_point(screen)
func _process(delta: float) -> void:
 update_character_health()
 if not is_instance_valid(game):return
 if game.mode!="run":
  for object in game.interactables:
   if ShrineCharging.is_shrine(object) and is_instance_valid(object.node):
    var label=object.node.get_node_or_null("ChargeProgress")
    if label:label.hide()
  game.message_time-=delta
  if game.message_time<=0:game.notice.text=""
 if menu.visible and is_instance_valid(menu_camera) and menu_camera.is_inside_tree() and game.mode in ["menu","play","unlocks","quests","settings"]:
  update_menu_camera(delta)
  if is_instance_valid(game.player):game.player.avatar.animate("idle",0,delta)
 if game.mode=="run":
  map_tick+=delta
  if map_tick>=0.12:map_tick=0;minimap.reveal(game.player.position);minimap.queue_redraw()

func icon_tile(parent: Node, category: String, id: String, hint: String, golden: bool, rank: int = 0) -> void:
 var slot=Control.new();slot.custom_minimum_size=Vector2(34,34);slot.tooltip_text=hint;parent.add_child(slot)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);slot.add_child(image)
 if rank>0:
  var number=text(str(rank),slot,12);number.position=Vector2(24,20)
 if golden and category!="traits":
  var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;slot.add_child(border)
func leave_settings() -> void:
 game.progress.data.settings=game.settings;game.progress.data.settings.bindings=game.bindings;game.progress.save()
 if settings_back.is_valid():settings_back.call()
 else:home()

func empty_slot(parent: Node, label: String) -> void:
 var slot=PanelContainer.new();slot.custom_minimum_size=Vector2(34,34);slot.tooltip_text=label;parent.add_child(slot)
 var mark=text("—",slot,18);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func stage_intro(number: int) -> void:
 if is_instance_valid(stage_banner):stage_banner.queue_free()
 stage_banner=StageBanner.new().setup(number,game.settings.reduced);root.add_child(stage_banner)
