class_name RunHud
extends Control
# The in-run HUD (RunHUD mockup), laid out in 1920x1080 design pixels inside RunStage. Everything it shows comes from
# RunData / game state. update() only compares cheap scalars with the last values it drew and touches a node when one
# changed; the build rows (weapons, tomes, items, socket gems) are rebuilt only when RunData.build_signature changes.
const TOP_LEFT=Vector2(40,32)
const ITEM_ROWS_MAX=3
const ITEMS_PER_ROW=12
var game: Node
var frontend: Node
var build_box: VBoxContainer
var build_signature_drawn=""
var timer_label: Label
var stage_label: Label
var banner: PanelContainer
var event_label: Label
var kills_value: Label
var chest_value: Label
var gold_value: Label
var gold_tick: Label
var gold_tick_left=0.0
var gold_tick_sum=0
var health_bar: HudBar
var health_text: Label
var xp_bar: HudBar
var level_label: Label
var xp_label: Label
var xp_tick: Label
var xp_tick_left=0.0
var xp_tick_sum=0
var ult_tile: UltimateTile
var trait_slot: Control
var trait_signature=""
var map_card: Control
var fps_label: Label
var fps_clock=0.0
var minimap: RunMinimap
var popups: PickupPopups
var drawn={} # last drawn scalar values
func setup(owner_game: Node,owner_frontend: Node) -> RunHud:
 game=owner_game;frontend=owner_frontend;name="RunHud";mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(MenuStyle.W,MenuStyle.H)
 _build_left();_build_top_centre();_build_top_right();_build_bottom_left();_build_map();_build_xp()
 fps_label=MenuStyle.label("",MenuStyle.sans(800,0.1,13),13,FogPalette.ASH,2,self);fps_label.position=Vector2(MenuStyle.W-44-120,124);fps_label.size=Vector2(120,18);fps_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;fps_label.name="FpsDebug";fps_label.visible=false
 popups=PickupPopups.new();popups.size=size;add_child(popups)
 return self
# ---- construction ---------------------------------------------------------------------------------------------------
func cap(text: String,size_px: int,tracking: float,color: Color,parent: Node=null,weight: int=800) -> Label:
 return MenuStyle.label(text,MenuStyle.sans(weight,tracking,size_px),size_px,color,2,parent)
func number(size_px: int,color: Color,parent: Node,shadow: int=3) -> Label:
 var base=FogTheme.sans(800);var l=MenuStyle.label("0",null,size_px,color,shadow,parent)
 if base!=null:
  var f=FontVariation.new();f.base_font=base;f.opentype_features={"tnum":1};l.add_theme_font_override("font",f)
 return l
func _build_left() -> void:
 build_box=VBoxContainer.new();build_box.name="Build";build_box.position=TOP_LEFT;build_box.add_theme_constant_override("separation",12);build_box.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(build_box)
func _build_top_centre() -> void:
 var column=VBoxContainer.new();column.position=Vector2(660,26);column.custom_minimum_size.x=600;column.size.x=600;column.add_theme_constant_override("separation",4);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
 timer_label=MenuStyle.label("00:00",MenuStyle.serif(),FogPalette.SIZE_HUD_TIMER,FogPalette.BONE_BRIGHT,3,column);timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",12);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(row)
 for i in 2:
  var rule=ColorRect.new();rule.color=FogPalette.RUST_BRIGHT;rule.custom_minimum_size=Vector2(28,3);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
  if i==0:row.add_child(rule)
  else:
   stage_label=cap("STAGE 1",13,0.32,Color("D9D4C4"),row);row.add_child(rule)
 banner=PanelContainer.new();banner.visible=false;banner.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var box=FogTheme.flat(Color(0.055,0.059,0.055,0.9),FogPalette.RUST_BRIGHT,1);box.content_margin_left=20;box.content_margin_right=20;box.content_margin_top=10;box.content_margin_bottom=8;banner.add_theme_stylebox_override("panel",box)
 var gap=Control.new();gap.custom_minimum_size=Vector2(0,10);gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(gap);column.add_child(banner)
 event_label=MenuStyle.label("",MenuStyle.memo(),18,FogPalette.BONE,0,banner);event_label.name="Announcement"
func _build_top_right() -> void:
 var row=HBoxContainer.new();row.name="RunStatus";row.add_theme_constant_override("separation",34);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(row)
 var specs=[["KILLS",FogPalette.ASH,FogPalette.BONE_BRIGHT],["CHEST COST",FogPalette.ASH,FogPalette.BONE_BRIGHT],["GOLD",FogPalette.GOLD,FogPalette.GOLD_PALE]]
 for i in 3:
  var col=VBoxContainer.new();col.add_theme_constant_override("separation",2);col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col)
  var c=cap(specs[i][0],12,0.3,specs[i][1],col,600);c.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  var n=number(34,specs[i][2],col);n.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
  if i==0:kills_value=n
  elif i==1:chest_value=n
  else:
   gold_value=n;gold_tick=cap("",15,0.06,FogPalette.GOLD,col);gold_tick.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;gold_tick.modulate.a=0.0
 row.position=Vector2(MenuStyle.W-44-340,34);row.size=Vector2(340,0);row.alignment=BoxContainer.ALIGNMENT_END
func _build_bottom_left() -> void:
 var row=HBoxContainer.new();row.position=Vector2(40,MenuStyle.H-62-140);row.size=Vector2(900,140);row.alignment=BoxContainer.ALIGNMENT_BEGIN;row.add_theme_constant_override("separation",18);row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.size_flags_vertical=Control.SIZE_SHRINK_END;add_child(row)
 var hp=VBoxContainer.new();hp.custom_minimum_size.x=480;hp.add_theme_constant_override("separation",8);hp.size_flags_vertical=Control.SIZE_SHRINK_END;hp.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(hp)
 cap("HEALTH",13,0.26,Color("C9CEC8"),hp)
 health_bar=HudBar.new().setup(Vector2(480,30),FogPalette.RUST,FogPalette.RUST_DEEP,2);health_bar.outer_color=Color("5A1418");health_bar.name="HealthBar";hp.add_child(health_bar)
 health_text=MenuStyle.label("",MenuStyle.sans(800,0,16),16,FogPalette.BONE_BRIGHT,1,health_bar);health_text.name="HealthValue";health_text.position=Vector2(12,0);health_text.size=Vector2(456,30);health_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var hint=HBoxContainer.new();hint.add_theme_constant_override("separation",6);hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;hp.add_child(hint)
 var key=cap("TAB",12,0.2,FogPalette.BONE,hint,800);key.name="TabKey";cap("BUILD & STATS",12,0.2,Color("A9ADA4"),hint,600)
 ult_tile=UltimateTile.new();ult_tile.size_flags_vertical=Control.SIZE_SHRINK_END;row.add_child(ult_tile)
 trait_slot=VBoxContainer.new();trait_slot.size_flags_vertical=Control.SIZE_SHRINK_END;trait_slot.mouse_filter=Control.MOUSE_FILTER_IGNORE;trait_slot.add_theme_constant_override("separation",6);row.add_child(trait_slot)
func _build_map() -> void:
 map_card=Control.new();map_card.name="MapCard";map_card.size=Vector2(316,318);map_card.position=Vector2(MenuStyle.W-40-316,MenuStyle.H-58-318);map_card.pivot_offset=map_card.size/2.0;map_card.rotation_degrees=1.2;map_card.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(map_card)
 var paper=ColorRect.new();paper.color=FogPalette.MEMO;paper.size=map_card.size;paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var shadow=ColorRect.new();shadow.color=Color(0,0,0,0.5);shadow.size=map_card.size;shadow.position=Vector2(5,6);shadow.mouse_filter=Control.MOUSE_FILTER_IGNORE;map_card.add_child(shadow);map_card.add_child(paper)
 minimap=RunMinimap.new();minimap.game=game;minimap.position=Vector2(10,10);minimap.size=Vector2(296,260);minimap.paper_style=true;map_card.add_child(minimap)
 var tape=ColorRect.new();tape.color=Color(0.91,0.886,0.816,0.75);tape.size=Vector2(72,20);tape.position=Vector2(122,-10);tape.rotation_degrees=-4;tape.mouse_filter=Control.MOUSE_FILTER_IGNORE;map_card.add_child(tape)
 var legend=HBoxContainer.new();legend.position=Vector2(12,278);legend.size=Vector2(292,24);legend.add_theme_constant_override("separation",8);legend.mouse_filter=Control.MOUSE_FILTER_IGNORE;map_card.add_child(legend)
 for entry in [["YOU",Color("1C1A15")],["PORTAL",Color("8E1B22")],["CHEST",Color("C9861A")],["IMBUE",Color("7B3FB3")],["SHOP",Color("33772F")]]:
  var cell=HBoxContainer.new();cell.add_theme_constant_override("separation",4);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;legend.add_child(cell)
  var dot=ColorRect.new();dot.color=entry[1];dot.custom_minimum_size=Vector2(8,8);dot.size_flags_vertical=Control.SIZE_SHRINK_CENTER;dot.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(dot)
  MenuStyle.label(entry[0],MenuStyle.sans(800,0.14,10),10,Color("3A352A"),0,cell)
func _build_xp() -> void:
 var row=HBoxContainer.new();row.position=Vector2(40,MenuStyle.H-18-26);row.size=Vector2(MenuStyle.W-80,26);row.add_theme_constant_override("separation",16);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(row)
 level_label=MenuStyle.label("Level 1",MenuStyle.serif(),26,FogPalette.BONE_BRIGHT,2,row)
 xp_bar=HudBar.new().setup(Vector2(100,16),FogPalette.XP,Color(0.055,0.059,0.055,0.85),1,10,0.0);xp_bar.name="XpBar";xp_bar.border_color=FogPalette.INK;xp_bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;xp_bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(xp_bar)
 xp_label=cap("0 / 18 XP",13,0.18,Color("DDF1FF"),row);xp_label.name="XpValue"
 xp_tick=cap("",15,0.06,FogPalette.XP_GLOW,self);xp_tick.modulate.a=0.0
# ---- update ---------------------------------------------------------------------------------------------------------
func set_text(l: Label,text: String) -> void:
 if l.text!=text:l.text=text
func update(delta: float) -> void:
 var signature=RunData.build_signature(game)
 if signature!=build_signature_drawn:build_signature_drawn=signature;_rebuild_build()
 var left=maxf(0,game.STAGE_SECONDS-game.stage_time)
 set_text(timer_label,"%02d:%02d"%[int(left)/60,int(left)%60] if left>0 else "00:00")
 timer_label.add_theme_color_override("font_color",FogPalette.RUST_TEXT if left<=0 else FogPalette.BONE_BRIGHT)
 set_text(stage_label,("STAGE %d · %s"%[game.stage,str(StageThemes.config(game.stage).title)]+(" · ENDLESS" if left<=0 else "")).to_upper())
 set_text(kills_value,str(game.kills));set_text(chest_value,str(game.chest_cost()));set_text(gold_value,str(game.gold))
 _tick(gold_tick,"gold",delta,"+")
 var hp_now=ceili(maxf(0,game.health));var hp_max=ceili(game.stats.max_health)
 if drawn.get("hp")!=hp_now or drawn.get("hpmax")!=hp_max:
  drawn["hp"]=hp_now;drawn["hpmax"]=hp_max;health_bar.max_value=game.stats.max_health;health_bar.value=game.health;health_text.text="%d / %d"%[hp_now,hp_max]
  health_bar.set_fill_color(FogPalette.RUST_BRIGHT if RunOverlay.wants_low_hp(game.health,game.stats.max_health) else FogPalette.RUST)
 else:health_bar.value=game.health
 var need=Catalog.threshold(game.level)
 if drawn.get("lv")!=game.level or absf(drawn.get("xp",-1.0)-game.xp)>0.01:
  drawn["lv"]=game.level;drawn["xp"]=game.xp;xp_bar.max_value=need;xp_bar.value=game.xp
  set_text(level_label,"Level %d"%game.level);set_text(xp_label,"%d / %d XP"%[int(game.xp),int(need)])
 _tick(xp_tick,"xp",delta," XP")
 xp_tick.position=xp_label.global_position-global_position+Vector2(xp_label.size.x-xp_tick.size.x,-24)
 ult_tile.sync(game)
 # Debug FPS counter (Settings > Graphics > Debug): refreshed twice a second, hidden when off.
 fps_label.visible=bool(game.settings.get("fps",false));fps_clock+=delta
 if fps_label.visible and fps_clock>=0.5:fps_clock=0.0;fps_label.text="%d FPS"%Engine.get_frames_per_second()
 banner.visible=event_label.text!=""
 minimap.paper_style=true
func gain(kind: String,amount: float,at: Vector2) -> void:
 popups.add(kind,amount,at)
 if kind=="gold":gold_tick_sum+=int(amount);gold_tick_left=1.6
 else:xp_tick_sum+=int(amount);xp_tick_left=1.6
func _tick(l: Label,kind: String,delta: float,suffix: String) -> void:
 var left=gold_tick_left if kind=="gold" else xp_tick_left;var sum=gold_tick_sum if kind=="gold" else xp_tick_sum
 if left<=0.0:
  if l.modulate.a>0.0:l.modulate.a=0.0
  return
 left-=delta
 if left<=0.0:sum=0
 if kind=="gold":gold_tick_left=left;gold_tick_sum=sum
 else:xp_tick_left=left;xp_tick_sum=sum
 var text=("+%d"%sum) if kind=="gold" else ("+%d XP"%sum)
 if l.text!=text:l.text=text
 l.modulate.a=clampf(left/0.5,0.0,1.0) if left>0.0 else 0.0
# ---- build rows (weapons, tomes, items, socket gems, trait) ---------------------------------------------------------
# build_box holds fixed children in this order (tests and the layout rely on it): [0] weapons caption, [1] weapons row,
# [2] tomes caption, [3] tomes row, [4] items caption, [5] items flow, [6] gems caption, [7] gems row. Each section is
# refilled only when its own RunData signature changes; the item tiles come from a pool of ITEM_POOL nodes made once.
const ITEM_POOL=ITEM_ROWS_MAX*ITEMS_PER_ROW
var section_signature={}
var weapons_caption: Label
var tomes_caption: Label
var weapons_row: HBoxContainer
var tomes_row: HBoxContainer
var items_flow: HFlowContainer
var gems_row: HBoxContainer
var item_pool: Array=[] # {wrap, slot, badge, more_label, item_id}
func _caption(text: String) -> Label:
 return cap(text,12,0.28,Color("C9CEC8"),build_box)
func _row(separation: int=8) -> HBoxContainer:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",separation);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;build_box.add_child(row);return row
func _dashed(box: Vector2) -> Control:
 var c=InventoryPanel.empty_cell(box.y,Color(0.79,0.81,0.78,0.35),Color(0.055,0.059,0.055,0.35));c.custom_minimum_size=box;return c
func _badge(text: String,bg: Color,fg: Color,pos: Vector2,parent: Control) -> Label:
 var l=MenuStyle.label(text,MenuStyle.sans(800,0.1,11),11,fg,0,parent);l.position=pos
 var style=FogTheme.flat(bg);style.content_margin_left=5;style.content_margin_right=5;style.content_margin_top=2;style.content_margin_bottom=0;l.add_theme_stylebox_override("normal",style);return l
func _build_structure() -> void:
 weapons_caption=_caption("WEAPONS");weapons_row=_row();tomes_caption=_caption("TOMES");tomes_row=_row();_caption("ITEMS")
 items_flow=HFlowContainer.new();items_flow.add_theme_constant_override("h_separation",6);items_flow.add_theme_constant_override("v_separation",6)
 items_flow.custom_minimum_size.x=ITEMS_PER_ROW*50-6;items_flow.size.x=ITEMS_PER_ROW*50-6;items_flow.mouse_filter=Control.MOUSE_FILTER_IGNORE;build_box.add_child(items_flow)
 for i in ITEM_POOL:
  var box=Vector2(44,44);var wrap=Control.new();wrap.custom_minimum_size=box;wrap.mouse_filter=Control.MOUSE_FILTER_STOP;wrap.visible=false
  var slot=MenuStyle.spawn("rarity_slot") as RaritySlot;wrap.add_child(slot);slot.setup(0,null,32,box,true)
  var badge=_badge("",FogPalette.BONE,FogPalette.MEMO_INK,Vector2(box.x-24,-7),wrap);badge.visible=false
  var entry={"wrap":wrap,"slot":slot,"badge":badge,"item":{},"more":0};item_pool.append(entry);items_flow.add_child(wrap)
  wrap.mouse_entered.connect(func():wrap.tooltip_text=_item_tip(entry))
 _caption("SOCKET GEMS");gems_row=_row(6);gems_row.name="SocketGems"
func _item_tip(entry: Dictionary) -> String:
 if entry.more>0:return "%d more items — Tab shows the whole build"%entry.more
 var it: Dictionary=entry.item;return "%s ×%d\n%s"%[it.name,it.stacks,RunData.item_description(it.id)] if not it.is_empty() else ""
func _rebuild_build() -> void:
 if build_box.get_child_count()==0:_build_structure()
 var sigs={"w":RunData.weapons_signature(game),"t":RunData.tomes_signature(game),"i":RunData.items_signature(game),"g":RunData.gems_signature(game)}
 if section_signature.get("w")!=sigs.w:section_signature["w"]=sigs.w;_fill_weapons()
 if section_signature.get("t")!=sigs.t:section_signature["t"]=sigs.t;_fill_tomes()
 if section_signature.get("i")!=sigs.i:section_signature["i"]=sigs.i;_fill_items()
 if section_signature.get("g")!=sigs.g:section_signature["g"]=sigs.g;_fill_gems()
 if trait_signature=="":trait_signature="drawn";_rebuild_trait()
func _clear(parent: Node) -> void:
 for c in parent.get_children():parent.remove_child(c);c.queue_free()
func _fill_weapons() -> void:
 _clear(weapons_row);var weapons=RunData.weapons(game);var limit=maxi(4,game.weapon_limit())
 weapons_caption.text="WEAPONS · %d/%d"%[weapons.size(),game.weapon_limit()]
 for w in weapons:
  var t=InventoryPanel.tile("weapons",str(w.id),w.tier,"",Vector2(84,84),64,"%s · LV %d\n%s"%[w.name,w.level,SocketScreens.tooltip(game.weapons[w.id])])
  _badge("LV %d"%w.level,FogPalette.RUST,FogPalette.BONE_BRIGHT,Vector2(-2,64),t)
  var pips=SocketPips.new().setup(game.weapons[w.id]);pips.position=Vector2(84-pips.custom_minimum_size.x-4,4);t.add_child(pips)
  weapons_row.add_child(t)
 for i in range(weapons.size(),limit):weapons_row.add_child(_dashed(Vector2(84,84)))
func _fill_tomes() -> void:
 _clear(tomes_row);var tomes=RunData.tomes(game);var limit=maxi(4,game.tome_limit())
 tomes_caption.text="TOMES · %d/%d"%[tomes.size(),game.tome_limit()]
 for t in tomes:
  var tile=InventoryPanel.tile("tomes",t.id,t.tier,"",Vector2(56,56),32,"%s · LV %d"%[t.name,t.level]);_badge("LV %d"%t.level,FogPalette.RUST,FogPalette.BONE_BRIGHT,Vector2(-2,40),tile);tomes_row.add_child(tile)
 for i in range(tomes.size(),limit):tomes_row.add_child(_dashed(Vector2(56,56)))
func _fill_items() -> void:
 var items=RunData.items(game);var overflow=items.size()>ITEM_POOL
 var shown=ITEM_POOL-1 if overflow else items.size()
 for i in ITEM_POOL:
  var e: Dictionary=item_pool[i]
  if i<shown:
   var it: Dictionary=items[i];e.item=it;e.more=0;e.wrap.visible=true
   e.slot.setup(it.tier,UIAssets.icon("items",it.id),32,Vector2(44,44),true);e.slot.get_child(0).visible=true
   e.badge.visible=it.stacks>1;e.badge.text="%d"%it.stacks
   for c in e.wrap.get_children():
    if c is Label and c!=e.badge:c.queue_free()
  elif i==shown and overflow:
   e.item={};e.more=items.size()-shown;e.wrap.visible=true;e.slot.setup(0,null,32,Vector2(44,44),true);e.badge.visible=false
   var l=MenuStyle.label("+%d"%e.more,MenuStyle.sans(800,0,15),15,FogPalette.BONE,2,e.wrap);l.position=Vector2(4,12)
  else:
   e.item={};e.more=0;e.wrap.visible=false
func _fill_gems() -> void:
 _clear(gems_row);var counts=RunData.gem_counts(game)
 for element in Elements.IDS:gems_row.add_child(_gem_slot(FogPalette.ELEMENT.get(element,Elements.color(element)),int(counts[element]),"%s gem ×%d"%[Elements.display_name(element),counts[element]]))
 gems_row.add_child(_gem_slot(FogPalette.GOLD,game.amulets,"Imbued Amulet ×%d"%game.amulets))
func _gem_slot(color: Color,count: int,tip: String) -> Control:
 var c=Control.new();c.custom_minimum_size=Vector2(44,44);c.tooltip_text=tip;c.mouse_filter=Control.MOUSE_FILTER_STOP;c.modulate=Color.WHITE if count>0 else Color(1,1,1,0.28)
 c.draw.connect(func():
  c.draw_rect(Rect2(Vector2.ZERO,c.size),Color(0.055,0.059,0.055,0.85));c.draw_rect(Rect2(Vector2.ZERO,c.size).grow(-0.5),color,false,1.0)
  var m=Vector2(22,22);var d=PackedVector2Array([m+Vector2(0,-11),m+Vector2(11,0),m+Vector2(0,11),m+Vector2(-11,0)])
  c.draw_colored_polygon(d,Color(color.r,color.g,color.b,0.55));c.draw_polyline(d+PackedVector2Array([d[0]]),color,2.0))
 if count>0:_badge("%d"%count,FogPalette.BONE,FogPalette.MEMO_INK,Vector2(26,-7),c)
 return c
func _rebuild_trait() -> void:
 _clear(trait_slot)
 var l=RunData.loadout(game)
 var tile=InventoryPanel.tile("traits",l.trait,FogPalette.Rarity.COMMON,"",Vector2(72,72),64,"Trait: %s"%l.trait.capitalize());trait_slot.add_child(tile)
 var t=cap("TRAIT",11,0.22,Color("A9ADA4"),trait_slot);t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
