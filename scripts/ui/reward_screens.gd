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
static func pause(ui: FrontEnd) -> void:
 var game=ui.game;game.mode="pause";ui.clear()
 var shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(0.005,0.025,0.04,0.72);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.menu.add_child(shade)
 equipment(ui,frame(ui,Vector2(24,80),Vector2(300,600),"Inventory"))
 statistics(ui,frame(ui,Vector2(938,80),Vector2(318,600),"Stats"))
 var title=ui.heading("PAUSED",ui.menu,48);title.position=Vector2(340,28);title.custom_minimum_size.x=560;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var center=VBoxContainer.new();center.position=Vector2(490,110);center.custom_minimum_size.x=260;center.add_theme_constant_override("separation",12);ui.menu.add_child(center)
 var summary=ui.heading("FOREST · STAGE %d"%game.stage,center,26);summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var details=ui.text("Level %d · %d kills · %d gold"%[game.level,game.kills,game.gold],center,16);details.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 button(ui,center,"RESUME",game.resume).grab_focus()
 button(ui,center,"MAP",func():ui.world_map(true))
 button(ui,center,"INSPECT BUILD",game.show_build)
 button(ui,center,"SETTINGS",func():game.settings_menu(game.pause_menu))
 button(ui,center,"SAVE RUN",func():game.toast("Run saved" if game.save_run() else "Save failed"))
 if game.sandbox:button(ui,center,"SANDBOX TOOLS",game.sandbox_menu)
 button(ui,center,"RESTART RUN",game.begin_run)
 button(ui,center,"ABANDON RUN",func():game.finish_run(false),Color("783c38"))
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
 image.custom_minimum_size=Vector2(size-12,size-12);image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
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
   var meta=RewardCatalog.entry(category,id,rank)
   var tile=icon(ui,grid,category,str(id),"Lv %d"%rank,Rarity.definition(meta.rarity).color,46);tile.tooltip_text=game.weapon_tooltip(int(id)) if category=="weapons" else meta.description
  var limit=game.weapon_limit() if category=="weapons" else game.tome_limit()
  for index in range(owned.size(),maxi(4,limit)):
   var empty=PanelContainer.new();empty.custom_minimum_size=Vector2(46,62);empty.add_theme_stylebox_override("panel",style(Color("4e5553"),Color("171c1b")));empty.tooltip_text=("Empty " if index<limit else "Locked ")+category.trim_suffix("s")+" slot";grid.add_child(empty)
   var mark=ui.text("—" if index<limit else "LOCK",empty,12);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mark.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;mark.modulate=Color("6e7875")
 ui.heading("Items",parent,20)
 var items_grid=GridContainer.new();items_grid.columns=5;parent.add_child(items_grid)
 for id in Catalog.ITEMS.size():
  var count=game.items.count(Catalog.ITEMS[id][0])
  if count==0:continue
  var meta=RewardCatalog.entry("items",id,count);var tile=icon(ui,items_grid,"items",str(id),"×%d"%count,Rarity.definition(meta.rarity).color,46);tile.tooltip_text=meta.name+"\n"+meta.description
 if game.items.is_empty():ui.text("No items collected",parent,14)
 ui.heading("Trait & ultimate",parent,18)
 var abilities=HBoxContainer.new();abilities.add_theme_constant_override("separation",10);parent.add_child(abilities)
 for category in ["traits","ultimates"]:
  var id=game.loadout_runtime.trait_id if category=="traits" else game.loadout_runtime.ultimate_id
  var tile=icon(ui,abilities,category,id,"Trait" if category=="traits" else "Ready" if game.loadout_runtime.cooldown<=0 else "%.0fs"%game.loadout_runtime.cooldown,Color("ffbf45"),46)
  var entry=LoadoutCatalog.entry(category,id);tile.tooltip_text=entry.get("name",id)+"\n"+entry.get("description","")
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
static func offer(ui: FrontEnd,parent: Node,category: String,id: Variant,rank: int,description: String,callback: Callable,button_text: String="") -> Button:
 var meta=RewardCatalog.entry(category,id,rank);var tier=Rarity.definition(meta.rarity)
 var button=Button.new();button.custom_minimum_size=Vector2(552,122);button.add_theme_stylebox_override("normal",style(tier.color,tier.color.darkened(0.91)));button.add_theme_stylebox_override("hover",style(tier.color.lightened(0.3),tier.color.darkened(0.8)));button.add_theme_stylebox_override("focus",style(Color("fff0bf"),tier.color.darkened(0.82)));parent.add_child(button)
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",14);margin.add_theme_constant_override("margin_right",14);margin.add_theme_constant_override("margin_top",9);margin.add_theme_constant_override("margin_bottom",9);button.add_child(margin)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);margin.add_child(row)
 icon(ui,row,category,str(id),"",tier.color,66)
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
static func upgrades(ui: FrontEnd) -> void:
 var game=ui.game;game.mode="upgrade";var center=layout(ui,"LEVEL UP · Upgrade offers")
 var celebration=celebration(ui,Color("ffdf75"),0.6)
 if game.settings.reduced or game.settings.visual_intensity<0.1:celebration.hide();celebration.set_process(false)
 game.choices=game.upgrade_choices();ui.reward_focus={}
 var first: Button
 for choice in game.choices:
  if choice.type=="supply":
   var supplies=ui.action("Field supplies · restore 25 health",center,func():game.apply_upgrade(choice);game.resume())
   if first==null:first=supplies
   continue
  var category="weapons" if choice.type=="weapon" else "tomes"
  var rank=int(game.weapons[choice.id].level) if choice.type=="weapon" and game.weapons.has(choice.id) else int(game.tomes.get(choice.id,0)) if choice.type=="tome" else 0
  var description=choice.metadata.description
  if choice.type=="weapon" and rank>0:description=WeaponUpgrades.description(int(choice.id),game.weapons[choice.id],choice.attribute)
  elif choice.type=="tome":
   var stat=Catalog.TOMES[choice.id][0];description=stat.replace("_"," ").capitalize()+": "+BuildStats.value(stat,game.stats[stat])+" → "+BuildStats.value(stat,game.stats[stat]+Catalog.TOMES[choice.id][1])
  var button=offer(ui,center,category,choice.id,rank,description,func():game.apply_upgrade(choice);game.resume())
  button.focus_entered.connect(func():ui.reward_focus=choice)
  button.mouse_entered.connect(func():ui.reward_focus=choice)
  if first==null:first=button;ui.reward_focus=choice
 var controls=HBoxContainer.new();controls.add_theme_constant_override("separation",8);center.add_child(controls)
 button(ui,controls,"BANISH",func():
  if not ui.reward_focus.is_empty():game.banished.append(ui.reward_focus.key);game.resume(),Color("9d353a"))
 button(ui,controls,"SKIP · heal 10",func():game.health=minf(game.stats.max_health,game.health+10);game.resume(),Color("306942"))
 button(ui,controls,"REFRESH (%d)"%game.rerolls,func():
  if game.rerolls>0:game.rerolls-=1;upgrades(ui),Color("276292")).disabled=game.rerolls<=0
 if first!=null:first.grab_focus()
static func inventory(ui: FrontEnd) -> void:
 var game=ui.game;game.mode="build";var center=layout(ui,"Your build & character stats")
 ui.heading("Current run",center,26)
 ui.text("Additional Bosses: +%d · %d per future encounter"%[game.additional_boss_count,1+game.additional_boss_count],center,18)
 ui.paragraph("Level %d · Stage %d\n%d kills · %.0f total damage\n%d gold · %d paid chests · %d free chests"%[game.level,game.stage,game.kills,game.damage_total,game.gold,game.chests_opened,int(game.run_metrics.get("free_chests",0))],center,520)
 for id in game.weapons:
  ui.heading(Catalog.WEAPONS[id][0]+" · Lv "+str(game.weapons[id].level),center,20)
  ui.paragraph(game.weapon_tooltip(id),center,520)
 ui.action("RESUME",center,game.resume).grab_focus()
static func shop(ui: FrontEnd,object: Dictionary) -> void:
 var game=ui.game;game.mode="shop";ui.shop_object=object
 if not object.has("offers"):object.offers=ShopSystem.offers(object.get("tier","Common"),game.available_items(),game.rng)
 ui.shop_offers=object.offers
 var center=layout(ui,object.get("tier","Common")+" shop · Gold %d"%game.gold)
 ui.text("One purchase per seller",center,15)
 for id_value in object.offers:
  var id=int(id_value);var price=ShopSystem.price(id);var sold=id in object.get("sold",[])
  var button=offer(ui,center,"items",id,game.items.count(Catalog.ITEMS[id][0]),Catalog.item_description(id),func():
   if not game.buy_shop(object,id,price):ui.reward_consumed=false;game.toast("Purchase unavailable"),"SOLD" if sold or object.get("used",false) else "NEED %d gold"%price if game.gold<price else "BUY · %d gold"%price)
  button.disabled=sold or game.gold<price or object.get("used",false) or not id in game.available_items()
 if object.offers.is_empty():ui.paragraph("No enabled items available",center,520)
 button(ui,center,"LEAVE SHOP",game.resume).grab_focus()
static func reward(ui: FrontEnd,item: Array) -> void:
 var game=ui.game;game.mode="reward";var center=layout(ui,"Treasure discovered")
 var id=Catalog.ITEMS.find(item);var tier=Rarity.definition(item[1])
 var effect=celebration(ui,tier.color,float(tier.celebration))
 var rarity=ui.heading("OPENING…",center,25);rarity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rarity.add_theme_color_override("font_color",tier.color)
 var name=ui.heading("Unsealing treasure",center,28);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var slot=CenterContainer.new();slot.custom_minimum_size.y=235;center.add_child(slot)
 var tile=icon(ui,slot,"items",str(id),"",tier.color,160);tile.name="ChestReveal";tile.set_meta("final_id",id)
 var image: TextureRect
 for child in descendants(tile):
  if child is TextureRect:image=child;break
 image.name="CyclingIcon"
 var description=ui.paragraph(Catalog.item_description(id),center,520);description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;description.hide()
 ui.text("Reward added to your build",center,14)
 var controls=HBoxContainer.new();center.add_child(controls)
 var proceed=button(ui,controls,"CONTINUE",game.resume,Color("276292"));proceed.disabled=true
 var generation=ui.reward_generation
 var reveal=func():
  if ui.reward_generation!=generation or not is_instance_valid(tile) or tile.get_meta("revealed",false):return
  tile.set_meta("revealed",true);image.texture=UIAssets.icon("items",str(id));rarity.text=tier.name.to_upper();name.text=item[0];description.show();proceed.disabled=false;proceed.grab_focus();ui.chest_skip=Callable()
  if tier.id=="legendary" and effect.has_meta("global_celebration"):effect.get_meta("global_celebration").burst(tier.color,2.0*game.settings.visual_intensity)
  effect.burst(tier.color,float(tier.celebration)*game.settings.visual_intensity);game.play_sound("applause",0.25+0.75*float(tier.celebration));game.play_sound("purchase",0.4+0.6*float(tier.celebration));game.play_sound("legendary" if tier.id=="legendary" else "level",0.4+0.6*float(tier.celebration))
 var eligible=game.available_items()
 if eligible.is_empty():eligible=[id]
 var tween=tile.create_tween();ui.reward_tweens.append(tween);tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 tween.tween_method(func(progress):
  if ui.reward_generation!=generation or not is_instance_valid(image):return
  var tick=int(70*(1-pow(1-progress,2.6)))
  if tile.get_meta("tick",-1)!=tick:
   tile.set_meta("tick",tick);image.texture=UIAssets.icon("items",str(eligible[posmod(tick+3,eligible.size())]));game.play_sound("menu",0.3)
  ,0.0,1.0,3.5)
 tween.tween_callback(reveal)
 ui.chest_skip=func():
  if tween.is_valid():tween.kill()
  reveal.call()
 var skip=button(ui,controls,"SKIP REVEAL",ui.chest_skip);skip.grab_focus()
 if game.settings.reduced:ui.chest_skip.call()

static func shrine(ui: FrontEnd,reward: Dictionary) -> void:
 var game=ui.game;game.mode="shrine";var center=layout(ui,"GOLDEN SHRINE · Choose one" if reward.golden else "SHRINE · Choose one stat")
 ui.text("Choose exactly one permanent upgrade for this run.",center,15)
 celebration(ui,Color("ffbf45") if reward.golden else Color("70dcd7"),1.0 if reward.golden else 0.4)
 for i in reward.choices.size():
  var choice=reward.choices[i];var tier=Rarity.definition(choice.rarity)
  var card=button(ui,center,"%s   ·   %s\n%s  %s\n%s"%[tier.name.to_upper(),"STAT UPGRADE",ShrineRewards.stat_name(str(choice.stat)),ShrineRewards.bonus_text(choice),choice.description],func():ShrineRewards.select(game,i),tier.color.darkened(0.85))
  card.name="ShrineChoice%d"%i;card.custom_minimum_size=Vector2(552,125);card.add_theme_stylebox_override("normal",style(tier.color,tier.color.darkened(0.90)));card.add_theme_stylebox_override("focus",style(tier.color.lightened(0.2),tier.color.darkened(0.82)));card.add_theme_font_size_override("font_size",19)
  if i==0:card.grab_focus()
 if reward.choices.is_empty():
  ui.paragraph("All eligible stats are capped. No invalid upgrade has been generated.",center,520)
  button(ui,center,"CONTINUE",func():game.active_shrine_reward={};game.resume())
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
