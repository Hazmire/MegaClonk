class_name RewardScreens
extends RefCounted
# Original framed UI inspired by the supplied composition; all content is live.
static func style(color: Color=Color("b8b09a"),background: Color=Color("202626")) -> StyleBoxFlat:
 var box=StyleBoxFlat.new();box.bg_color=background;box.border_color=color;box.set_border_width_all(2)
 box.shadow_color=Color(0,0,0,0.7);box.shadow_size=5
 box.content_margin_left=12;box.content_margin_right=12;box.content_margin_top=10;box.content_margin_bottom=10
 return box
static func button(ui: FrontEnd,parent: Node,label: String,callback: Callable,tint: Color=Color("51585a")) -> Button:
 var generation=ui.reward_generation
 var control=ui.action(label,parent,func():
  if ui.reward_generation==generation:callback.call())
 control.custom_minimum_size=Vector2(120,44)
 for state in ["normal","hover","pressed","focus","disabled"]:
  var box=style(Color("a6a89f") if state=="normal" else Color("fff0bf"),tint.darkened(0.25) if state=="pressed" else tint.lightened(0.15) if state in ["hover","focus"] else tint.darkened(0.55) if state=="disabled" else tint)
  box.set_corner_radius_all(2);box.border_width_bottom=5;box.shadow_size=2
  control.add_theme_stylebox_override(state,box)
 return control
static func world_map(ui: FrontEnd,from_pause: bool) -> void:
 var game=ui.game;game.mode="map";ui.clear();ui.map_return_to_pause=from_pause;ui.minimap.reveal(game.player.position)
 var shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(0.005,0.025,0.04,0.45);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.menu.add_child(shade)
 var center=frame(ui,Vector2(24,28),Vector2(860,652),"FOREST · Stage %d · World map"%game.stage)
 var map=RunMinimap.new();map.game=game;map.reveal_all=ui.minimap.reveal_all;map.explored=ui.minimap.explored;map.terrain_colors=ui.minimap.terrain_colors;map.custom_minimum_size=Vector2(560,450);map.size_flags_horizontal=Control.SIZE_EXPAND_FILL;center.add_child(map)
 ui.text("N ↑    Gold: chest · Green: shop · Red: healing · Cyan: shrine\nOrange: elite · Purple: boss statue · Blue ring: portal\nWhite: you · Pink: enemies · Pale gold: free reward chests",center,14)
 button(ui,center,"BACK" if from_pause else "RESUME",game.pause_menu if from_pause else game.resume).grab_focus()
 statistics(ui,frame(ui,Vector2(938,28),Vector2(318,652),"Stats"))
static func frame(ui: FrontEnd,pos: Vector2,dimensions: Vector2,title: String) -> VBoxContainer:
 var panel=RewardFrame.new();panel.position=pos;panel.custom_minimum_size=dimensions;panel.size=dimensions;panel.add_theme_stylebox_override("panel",style());ui.menu.add_child(panel)
 var stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(stack)
 var header=PanelContainer.new();header.add_theme_stylebox_override("panel",style(Color("a89d85"),Color("29483b")));stack.add_child(header)
 ui.heading(title,header,20)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(scroll)
 var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
 if pos.x==24 or pos.x==322:ui.game.panel=panel
 return body
static func icon(ui: FrontEnd,parent: Node,category: String,id: String,rank: String="",edge: Color=Color("786f60"),size: int=48) -> Control:
 var slot=PanelContainer.new();slot.custom_minimum_size=Vector2(size,size+16);slot.add_theme_stylebox_override("panel",style(edge,Color("152321")));parent.add_child(slot)
 if size<=48:
  var padding=slot.get_theme_stylebox("panel").duplicate();padding.content_margin_left=4;padding.content_margin_right=4;padding.content_margin_top=4;padding.content_margin_bottom=4;slot.add_theme_stylebox_override("panel",padding)
 var body=VBoxContainer.new();body.add_theme_constant_override("separation",1);slot.add_child(body)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;body.add_child(image)
 var inner=size-12
 if category=="items":inner=32*maxi(1,int((size-12)/32)) # 32x32 pixel art is only ever shown at whole-number scales
 image.custom_minimum_size=Vector2(inner,inner);image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if rank!="":
  var label=ui.text(rank,body,12);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return slot
static func equipment(ui: FrontEnd,parent: Node) -> void:
 var game=ui.game
 for category in ["weapons","tomes"]:
  ui.heading(category.capitalize(),parent,20)
  var grid=GridContainer.new();grid.columns=4;parent.add_child(grid)
  var owned=game.weapons if category=="weapons" else game.tomes
  for id in owned:
   var rank=int(owned[id].level) if category=="weapons" else int(owned[id])
   var meta=game.equipment_meta(category,id,rank)
   var tile=icon(ui,grid,category,str(id),"Lv %d"%rank,Rarity.definition(meta.rarity).color,46);tile.tooltip_text=game.weapon_tooltip(int(id)) if category=="weapons" else meta.description
   if category=="weapons":SocketScreens.add_pips(tile,game.weapons[id])
  var limit=game.weapon_limit() if category=="weapons" else game.tome_limit()
  for index in range(owned.size(),maxi(4,limit)):
   var empty=PanelContainer.new();empty.custom_minimum_size=Vector2(46,62);empty.add_theme_stylebox_override("panel",style(Color("4e5553"),Color("171c1b")));empty.tooltip_text=("Empty " if index<limit else "Locked ")+category.trim_suffix("s")+" slot";grid.add_child(empty)
   var mark=ui.text("—" if index<limit else "LOCK",empty,12);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mark.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;mark.modulate=Color("6e7875")
 SocketScreens.gem_inventory(ui,parent)
 ui.heading("Items",parent,20)
 var items_grid=GridContainer.new();items_grid.columns=5;parent.add_child(items_grid)
 for entry in game.items:
  var id=str(entry.id);var count=int(entry.stacks)
  var meta=RewardCatalog.entry("items",id,count);var tile=icon(ui,items_grid,"items",id,"×%d"%count,Rarity.definition(meta.rarity).color,46);tile.tooltip_text="%s · %s\n%s"%[meta.name,Rarity.definition(meta.rarity).name,meta.description]
 if game.items.is_empty():ui.text("No items collected",parent,14)
 ui.heading("Trait & ultimate",parent,18)
 var abilities=HBoxContainer.new();abilities.add_theme_constant_override("separation",10);parent.add_child(abilities)
 for category in ["traits","ultimates"]:
  var id=game.loadout_runtime.trait_id if category=="traits" else game.loadout_runtime.ultimate_id
  var tile=icon(ui,abilities,category,id,"Trait" if category=="traits" else "Ready" if game.loadout_runtime.cooldown<=0 else "%.0fs"%game.loadout_runtime.cooldown,Color("7d9ca0") if category=="traits" else Color("ffbf45"),46)
  var entry=LoadoutCatalog.entry(category,id);tile.tooltip_text=entry.get("name",id)+"\n"+entry.get("description","")
  if category=="ultimates":
   var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
   var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;tile.add_child(border)
static func statistics(ui: FrontEnd,parent: Node) -> void:
 var game=ui.game;parent.add_theme_constant_override("separation",3)
 for group in [["Survival",["max_health","regen","armor","evasion","lifesteal","thorns"]],["Combat",["damage","crit","crit_damage","haste","count","size","projectile_speed","duration","knockback"]],["Movement",["speed","air_jumps","jump","slide_speed","slide_friction"]],["Rewards",["pickup","xp","gold_gain","luck","difficulty"]]]:
  ui.heading(group[0],parent,16)
  var table=GridContainer.new();table.columns=2;table.add_theme_constant_override("h_separation",10);table.add_theme_constant_override("v_separation",0);parent.add_child(table)
  for key in group[1]:
   var label=ui.text(key.replace("_"," ").capitalize(),table,13);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.tooltip_text=BuildStats.help(key);label.mouse_filter=Control.MOUSE_FILTER_STOP
   var value=float(game.stats.get(key,0))
   if key=="crit":value=minf(1,value)
   if key=="evasion":value=minf(0.75,value)
   var number=ui.text(BuildStats.value(key,value),table,13);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var known=["max_health","regen","armor","evasion","lifesteal","thorns","damage","crit","crit_damage","haste","count","size","projectile_speed","duration","knockback","speed","air_jumps","jump","slide_speed","slide_friction","pickup","xp","gold_gain","luck","difficulty"]
 ui.heading("Other modifiers",parent,16)
 for key in game.stats:
  if key in known:continue
  var label=ui.text(key.replace("_"," ").capitalize()+": "+BuildStats.value(key,game.stats[key]),parent,13);label.tooltip_text=BuildStats.help(key);label.mouse_filter=Control.MOUSE_FILTER_STOP
 ui.text("Trait / ultimate damage ×%.2f"%game.loadout_runtime.damage_multiplier(),parent,13)
static func layout(ui: FrontEnd,title: String) -> VBoxContainer:
 ui.clear()
 var shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(0,0.025,0.035,0.35);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.menu.add_child(shade)
 var game=ui.game
 var header=ui.heading("LVL %d    STAGE %d    HP %.0f/%.0f    GOLD %d    TIME %02d:%02d"%[game.level,game.stage,game.health,game.stats.max_health,game.gold,int(game.elapsed)/60,int(game.elapsed)%60],ui.menu,20);header.position=Vector2(20,24)
 equipment(ui,frame(ui,Vector2(16,118),Vector2(290,562),"Inventory"))
 var middle=frame(ui,Vector2(322,78),Vector2(600,602),title)
 statistics(ui,frame(ui,Vector2(938,78),Vector2(326,602),"Stats"))
 return middle
static func offer(ui: FrontEnd,parent: Node,category: String,id: Variant,rank: int,description: String,callback: Callable,button_text: String="",metadata: Dictionary={}) -> Button:
 var meta=RewardCatalog.entry(category,id,rank) if metadata.is_empty() else metadata;var tier=Rarity.definition(meta.rarity)
 var button=Button.new();button.custom_minimum_size=Vector2(552,122);button.add_theme_stylebox_override("normal",style(tier.color,tier.color.darkened(0.91)));button.add_theme_stylebox_override("hover",style(tier.color.lightened(0.3),tier.color.darkened(0.8)));button.add_theme_stylebox_override("focus",style(Color("fff0bf"),tier.color.darkened(0.82)));parent.add_child(button)
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",14);margin.add_theme_constant_override("margin_right",14);margin.add_theme_constant_override("margin_top",9);margin.add_theme_constant_override("margin_bottom",9);button.add_child(margin)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);margin.add_child(row)
 if category=="gems":GemIcon.add(row,str(id),tier.color,66)
 else:icon(ui,row,category,str(id),"",tier.color,66)
 var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(body)
 var headline=HBoxContainer.new();body.add_child(headline)
 var rarity=ui.text(tier.name,headline,14);rarity.add_theme_color_override("font_color",tier.color);rarity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var progression=ui.text(button_text if button_text!="" else "NEW" if rank==0 else ("Owned ×%d → ×%d" if category=="items" else "Lv %d → %d")%[rank,rank+1],headline,14);progression.add_theme_color_override("font_color",Color("ffcf65"))
 ui.heading(meta.name,body,22)
 var effects=ui.text(description+("\nOwned ×%d → ×%d"%[rank,rank+1] if category=="items" else ""),body,15);effects.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 for node in descendants(button):
  if node is Control:node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 button.mouse_filter=Control.MOUSE_FILTER_STOP
 button.mouse_entered.connect(func():button.create_tween().tween_property(button,"self_modulate",Color(1.12,1.12,1.12),0.1))
 button.mouse_exited.connect(func():button.create_tween().tween_property(button,"self_modulate",Color.WHITE,0.1))
 var generation=ui.reward_generation
 button.pressed.connect(func():
  if ui.reward_generation!=generation or ui.reward_consumed:return
  ui.reward_consumed=true;ui.game.play_sound("menu");callback.call())
 return button
static func descendants(node: Node) -> Array:
 var result=[]
 for child in node.get_children():result.append(child);result.append_array(descendants(child))
 return result
static func upgrades(ui: FrontEnd,fixed_choices: Array=[]) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="upgrade";ui.clear();ui.reward_focus={}
 game.choices=fixed_choices if not fixed_choices.is_empty() else game.upgrade_choices()
 var screen=RunLevelUp.new();MenuScreen.set_audio_owner(game);screen.bind(ui);screen.choices=game.choices;ui.menu.add_child(screen)
static func inventory(ui: FrontEnd) -> void:
 var game=ui.game;game.mode="build";var center=layout(ui,"Your build & character stats")
 ui.heading("Current run",center,26)
 ui.text("Additional Bosses: +%d · %d per future encounter"%[game.additional_boss_count,1+game.additional_boss_count],center,18)
 ui.paragraph("Level %d · Stage %d\n%d kills · %.0f total damage\n%d gold · %d paid chests · %d free chests"%[game.level,game.stage,game.kills,game.damage_total,game.gold,game.chests_opened,int(game.run_metrics.get("free_chests",0))],center,520)
 for id in game.weapons:
  ui.heading(Catalog.WEAPONS[id][0]+" · Lv "+str(game.weapons[id].level),center,20)
  ui.paragraph(game.weapon_tooltip(id),center,520)
  ui.paragraph(SocketScreens.tooltip(game.weapons[id]),center,520)
 ui.action("RESUME",center,game.resume).grab_focus()
static func imbue_station(ui: FrontEnd,object: Dictionary) -> void:
 SocketScreens.imbue_station(ui,object)
static func shop(ui: FrontEnd,object: Dictionary) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="shop";ui.shop_object=object
 if not object.has("offers"):
  object.offers=ShopSystem.offers(object.get("tier","Common"),game.available_items(),game.rng,float(game.stats.luck),game.world_content_version>=2)
 ui.shop_offers=object.offers
 ui.clear()
 var screen=RunShop.new();screen.object=object;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)
static func reward(ui: FrontEnd,id: String) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="reward";ui.clear()
 var screen=RunChest.new();screen.item_id=id;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)

static func shrine(ui: FrontEnd,reward: Dictionary) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="shrine";ui.clear()
 var screen=RunShrine.new();screen.reward=reward;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)
static func celebration(ui: FrontEnd,color: Color,strength: float) -> RewardCelebration:
 var effect=RewardCelebration.new();effect.rainbow=true;effect.tint=color;effect.strength=strength*ui.game.settings.visual_intensity;ui.menu.add_child(effect);ui.menu.move_child(effect,1)
 var local=RewardCelebration.new();local.set_meta("global_celebration",effect);local.confetti=false;local.rays=true;local.tint=color;local.strength=effect.strength;local.center=Vector2(288,262)
 for frame in ui.menu.get_children():
  if frame is RewardFrame and frame.position.x==322:
   frame.clip_contents=true;frame.add_child(local);frame.move_child(local,0);break
 if local.get_parent()==null:effect.add_child(local)
 if ui.game.settings.reduced or ui.game.settings.visual_intensity<0.1:
  effect.hide();effect.set_process(false);local.hide();local.set_process(false)
 return local
