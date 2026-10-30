class_name RunLevelUp
extends MenuScreen
# RunLevelUp: the Level-up screen. The frozen world behind, the Inventory and Stats panels either side and, between them, three
# rarity-framed paper cards with their real "current → new" numbers, then Take / Banish / Skip / Refresh. The entrance is the
# fanfare (any key skips it) and then the cards are dealt in. All choices run through the same game calls as before.
const CARD_X=572.0
const CARD_Y=330.0
const CARD_GAP=22.0
const CARD_START=[1.85,1.35,1.55]
const CARD_DUR=[0.55,0.5,0.5]
const REST_ROT=[-0.4,0.5,-0.3]
const HEADER_AT=1.15
const FOOTER_AT=2.1
const READY_AT=2.4
const SHAKE=[[0.0,0.0,0.0],[0.12,-12.0,7.0],[0.26,10.0,-8.0],[0.40,-7.0,5.0],[0.55,5.0,-4.0],[0.70,-3.0,2.0],[0.85,1.0,-1.0],[1.0,0.0,0.0]]
var choices: Array=[]
var cards_data: Array=[]
var cards: Array=[]
var inventory_panel: InventoryPanel
var stats_panel: StatsPanel
var fanfare: LevelFanfare
var header: Control
var footer: Control
var primary: MenuItem
var banish_button: LevelActionButton
var skip_button: LevelActionButton
var refresh_button: LevelActionButton
var bursts: Array=[]
var clock=0.0
var interactive=false
var plain=false # reduced motion or visual intensity ~0: no fanfare, no shake
var last_preview=-1
func _init() -> void:
 super._init();backdrop_kind="frozen";allow_back=false
func setup_choices(list: Array) -> RunLevelUp:
 choices=list;cards_data=RunData.level_cards(game,list) if game!=null else [];return self
func build() -> void:
 if choices.is_empty():choices=game.choices
 cards_data=RunData.level_cards(game,choices)
 plain=bool(game.settings.reduced) or float(game.settings.visual_intensity)<0.1
 inventory_panel=InventoryPanel.new().setup(game);inventory_panel.name="Inventory";inventory_panel.position=Vector2(72,150);content.add_child(inventory_panel)
 stats_panel=StatsPanel.new().setup(game);stats_panel.name="Stats";stats_panel.position=Vector2(1428,150);content.add_child(stats_panel)
 build_status()
 var section=Panel.new();section.name="Section";section.position=Vector2(532,150);section.size=Vector2(856,870);section.mouse_filter=Control.MOUSE_FILTER_IGNORE
 section.add_theme_stylebox_override("panel",FogTheme.flat(Color(0.055,0.059,0.055,0.94),FogPalette.BORDER,1));content.add_child(section)
 header=Control.new();header.name="Header";header.size=Vector2(776,110);header.position=Vector2(572,182);header.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(header)
 MenuStyle.label("LEVEL UP · LEVEL %d"%game.level,MenuStyle.sans(800,0.3,14),14,FogPalette.GOLD,0,header)
 var h1=MenuStyle.label("Choose an upgrade",MenuStyle.serif(),52,FogPalette.BONE,0,header);h1.position=Vector2(0,22)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(0,94);rule.size=Vector2(48,5);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;header.add_child(rule)
 for i in cards_data.size():
  var card=LevelCard.new().setup(cards_data[i],i,REST_ROT[i%3]);card.position=Vector2(CARD_X+i*(LevelCard.W+CARD_GAP),CARD_Y);content.add_child(card);cards.append(card)
  card.pressed.connect(func():take(i))
  card.focus_entered.connect(func():select(i))
 build_footer()
 wire_focus()
 set_hints_for_device()
 fanfare=LevelFanfare.new().setup(game.level);stage.add_child(fanfare);fanfare.finished.connect(func():pass)
 if plain:
  clock=READY_AT+1.0;fanfare.skip();apply_timeline()
 else:
  apply_timeline()
 set_process(true)
func build_status() -> void:
 var row=HBoxContainer.new();row.name="Status";row.position=Vector2(72,36);row.add_theme_constant_override("separation",48);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(row)
 var t=int(game.elapsed)
 for pair in [["LVL",str(game.level),FogPalette.GOLD],["STAGE",str(game.stage),FogPalette.BONE_BRIGHT]]:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(cell)
  MenuStyle.label(pair[0],MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);cell.add_child(HudNumber.new().setup(pair[1],32,pair[2],3))
 var hp=VBoxContainer.new();hp.add_theme_constant_override("separation",6);hp.custom_minimum_size=Vector2(240,0);hp.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(hp)
 MenuStyle.label("HP",MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,hp)
 var bar=Control.new();bar.name="Hp";bar.custom_minimum_size=Vector2(240,24);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;hp.add_child(bar)
 var frac=clampf(float(game.health)/maxf(1.0,float(game.stats.max_health)),0.0,1.0)
 bar.draw.connect(func():
  bar.draw_rect(Rect2(Vector2.ZERO,bar.size),Color("2A1416"));bar.draw_rect(Rect2(Vector2(2,2),Vector2((bar.size.x-4.0)*frac,bar.size.y-4.0)),FogPalette.RUST);bar.draw_rect(Rect2(Vector2.ZERO,bar.size).grow(-1.0),Color("050505"),false,2.0))
 var hpl=MenuStyle.label("%d / %d"%[roundi(game.health),roundi(game.stats.max_health)],MenuStyle.sans(800,0,14),14,FogPalette.BONE_BRIGHT,0,bar);hpl.position=Vector2(8,2)
 for pair in [["GOLD",str(game.gold)],["TIME","%02d:%02d"%[t/60,t%60]]]:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(cell)
  MenuStyle.label(pair[0],MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);cell.add_child(HudNumber.new().setup(pair[1],32,FogPalette.BONE_BRIGHT,3))
func build_footer() -> void:
 footer=Control.new();footer.name="Footer";footer.position=Vector2(572,850);footer.size=Vector2(776,138);footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(footer)
 primary=MenuStyle.spawn("menu_item") as MenuItem;primary.setup("Take",36,36).make_primary("ENTER",72,36);primary.size=Vector2(776,72);primary.position=Vector2.ZERO;primary.indent=60.0;footer.add_child(primary)
 primary.chosen.connect(func():take(selected_index()))
 var row=HBoxContainer.new();row.position=Vector2(0,84);row.size=Vector2(776,54);row.add_theme_constant_override("separation",12);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;footer.add_child(row)
 banish_button=LevelActionButton.new().setup("BANISH",FogPalette.RUST_BRIGHT,FogPalette.RUST_TEXT);skip_button=LevelActionButton.new().setup("SKIP · HEAL 10",FogPalette.BORDER,Color("D9D4C4"));refresh_button=LevelActionButton.new().setup("REFRESH",FogPalette.BORDER,Color("D9D4C4"))
 for b in [banish_button,skip_button,refresh_button]:b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(b)
 banish_button.pressed.connect(banish);skip_button.pressed.connect(skip);refresh_button.pressed.connect(refresh)
 refresh_button.set_caption("REFRESH · %d LEFT"%game.rerolls);refresh_button.disabled=game.rerolls<=0
 banish_button.disabled=cards.is_empty() or cards_data[0].type=="supply"
 select(0)
func wire_focus() -> void:
 for i in cards.size():
  var c: Control=cards[i]
  c.focus_neighbor_left=c.get_path_to(cards[maxi(0,i-1)]);c.focus_neighbor_right=c.get_path_to(cards[mini(cards.size()-1,i+1)]);c.focus_neighbor_top=c.get_path_to(c);c.focus_neighbor_bottom=c.get_path_to(primary)
 primary.focus_neighbor_top=primary.get_path_to(cards[0]);primary.focus_neighbor_bottom=primary.get_path_to(skip_button)
 var row=[banish_button,skip_button,refresh_button]
 for i in row.size():
  var b: Control=row[i];b.focus_neighbor_left=b.get_path_to(row[maxi(0,i-1)]);b.focus_neighbor_right=b.get_path_to(row[mini(row.size()-1,i+1)]);b.focus_neighbor_top=b.get_path_to(primary);b.focus_neighbor_bottom=b.get_path_to(b)
func selected_index() -> int:
 for i in cards.size():
  if cards[i].has_focus():return i
 return clampi(last_preview,0,maxi(0,cards.size()-1))
# Remembers the highlighted card, names it on the Take button and previews its stat change on the Stats panel.
func select(i: int) -> void:
 if cards.is_empty():return
 last_preview=i;var data: Dictionary=cards_data[i]
 if primary!=null:primary.label_text="Take "+str(data.short_name);primary.queue_redraw()
 stats_panel.clear_preview()
 if not data.preview.is_empty():stats_panel.preview(str(data.preview.stat),float(data.preview.from),float(data.preview.to))
func take(i: int) -> void:
 if not interactive or i<0 or i>=choices.size():return
 interactive=false;game.apply_upgrade(choices[i]);game.resume()
func banish() -> void:
 if not interactive or cards.is_empty():return
 var choice: Dictionary=choices[selected_index()]
 if choice.type=="supply":return
 interactive=false;game.banished.append(choice.key);game.resume()
func skip() -> void:
 if not interactive:return
 interactive=false;game.health=minf(game.stats.max_health,game.health+10);game.resume()
func refresh() -> void:
 if not interactive or game.rerolls<=0:return
 interactive=false;game.rerolls-=1;frontend.upgrades()
func set_hints_for_device() -> void:
 if pad_active():set_hints([["← →","Choose","D-PAD"],["ENTER","Take","A"]])
 else:set_hints([["← →","Choose"],["1–3","Select"],["ENTER","Take"]])
func refresh_hints() -> void:
 if hint_bar!=null:set_hints_for_device()
func _input(event: InputEvent) -> void:
 super._input(event)
 if not is_visible_in_tree():return
 var pressed_key=(event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed)
 if pressed_key and fanfare!=null and not fanfare.done:
  fanfare.skip();clock=maxf(clock,FANFARE_SKIP_TO);get_viewport().set_input_as_handled();return
 if interactive and event is InputEventKey and event.pressed and not event.echo:
  var n=event.keycode-KEY_1
  if n>=0 and n<cards.size():cards[n].grab_focus();get_viewport().set_input_as_handled()
const FANFARE_SKIP_TO=2.6
func _process(delta: float) -> void:
 clock+=delta
 apply_timeline()
# Positions everything for the current clock: the header, the dealt cards, the footer, the screen shake and the Rare bursts.
func apply_timeline() -> void:
 header.modulate.a=clampf((clock-HEADER_AT)/0.4,0.0,1.0);footer.modulate.a=clampf((clock-FOOTER_AT)/0.4,0.0,1.0)
 for i in cards.size():
  var card: LevelCard=cards[i];var s=float(CARD_START[i%3]);var d=float(CARD_DUR[i%3]);var p=clampf((clock-s)/d,0.0,1.0)
  var f=LevelFanfare._ease_out_back(p) if p<1.0 else 1.0
  card.modulate.a=clampf(p*1.6,0.0,1.0);card.pivot_offset=card.size*0.5
  card.scale=Vector2.ONE*lerpf(0.7,1.0,f);card.position.y=CARD_Y+(1.0-f)*180.0;card.rotation=(1.0-f)*deg_to_rad(12.0)
  card.mouse_filter=Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
  var was=card.burst;var raw=(clock-(s+0.35))/0.7;card.burst=raw if (not plain and int(card.data.tier)>=FogPalette.Rarity.RARE and raw>0.0 and raw<1.0) else -1.0
  if card.burst>=0.0 or was>=0.0:card.face.queue_redraw()
 if not interactive and clock>=READY_AT:
  interactive=true;primary.mouse_filter=Control.MOUSE_FILTER_STOP;_focus_first()
 content.position=Vector2.ZERO if plain else shake_offset()
func shake_offset() -> Vector2:
 var k=(clock-0.08)/0.5
 if k<=0.0 or k>=1.0 or not bool(game.settings.get("shake",true)):return Vector2.ZERO
 for j in range(1,SHAKE.size()):
  if k<=SHAKE[j][0]:
   var a=SHAKE[j-1];var b=SHAKE[j];var u=(k-a[0])/(b[0]-a[0]);return Vector2(lerpf(a[1],b[1],u),lerpf(a[2],b[2],u))*(0.5+0.5*float(game.settings.visual_intensity))
 return Vector2.ZERO
func _focus_first() -> void:
 if cards.is_empty():primary.grab_focus();return
 cards[clampi(last_preview,0,cards.size()-1)].grab_focus()
