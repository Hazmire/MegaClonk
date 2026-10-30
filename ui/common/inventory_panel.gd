class_name InventoryPanel
extends PanelContainer
# Shared Inventory panel (RunInventory, 420x870 at 1920x1080): weapons with LV and socket diamonds, tomes, socket gems
# plus the Imbued Amulet count, items as a grid with stack counts, trait and ultimate. All data comes from RunData.
# The items grid compresses to small tiles and scrolls when the build holds many different items.
const SIZE_PX=Vector2(420,870)
const ROOMY_ITEMS=8 # up to this many different items get the 88px tiles
var game: Node
var signature=""
var items_scroll: ScrollContainer
var column: VBoxContainer
func setup(game_node: Node) -> InventoryPanel:
 game=game_node;custom_minimum_size=SIZE_PX;size=SIZE_PX;clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
 var box=FogTheme.flat(FogPalette.NIGHT_PANEL,FogPalette.BORDER,1);box.content_margin_left=30;box.content_margin_right=30;box.content_margin_top=28;box.content_margin_bottom=28
 add_theme_stylebox_override("panel",box)
 refresh();return self
# Rebuilds only if the build changed since the last refresh.
func refresh(force: bool=false) -> void:
 var now=RunData.build_signature(game)+"|%s"%[RunData.loadout(game).ready]
 if not force and now==signature and column!=null:return
 signature=now
 for c in get_children():remove_child(c);c.queue_free()
 column=VBoxContainer.new();column.add_theme_constant_override("separation",22);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
 column.add_child(StatsPanel._heading("Inventory"))
 _weapons();_tomes();_gems();_items();_loadout()
func _caption(text: String) -> Label:
 return MenuStyle.label(text,MenuStyle.sans(800,0.28,13),13,FogPalette.ASH_DIM)
func _section(caption: String) -> VBoxContainer:
 var s=VBoxContainer.new();s.add_theme_constant_override("separation",10);s.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(s);s.add_child(_caption(caption));return s
func _grid(parent: Node,columns: int,gap: int=10) -> GridContainer:
 var g=GridContainer.new();g.columns=columns;g.add_theme_constant_override("h_separation",gap);g.add_theme_constant_override("v_separation",gap);g.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(g);return g
static func empty_cell(height: float,line: Color=FogPalette.BORDER,fill: Color=Color(0,0,0,0)) -> Control:
 var c=Control.new();c.custom_minimum_size=Vector2(78,height);c.mouse_filter=Control.MOUSE_FILTER_IGNORE
 c.draw.connect(func():
  var r=Rect2(Vector2.ZERO,c.size).grow(-0.5);var dash=6.0
  if fill.a>0.0:c.draw_rect(Rect2(Vector2.ZERO,c.size),fill)
  for x in range(0,int(r.size.x),int(dash*2)):
   c.draw_line(r.position+Vector2(x,0),r.position+Vector2(mini(x+dash,r.size.x),0),line);c.draw_line(r.position+Vector2(x,r.size.y),r.position+Vector2(mini(x+dash,r.size.x),r.size.y),line)
  for y in range(0,int(r.size.y),int(dash*2)):
   c.draw_line(r.position+Vector2(0,y),r.position+Vector2(0,mini(y+dash,r.size.y)),line);c.draw_line(r.position+Vector2(r.size.x,y),r.position+Vector2(r.size.x,mini(y+dash,r.size.y)),line))
 return c
# Icon tile: rarity frame, 32px art at a whole-number scale, small caption under it.
static func tile(category: String,id: String,tier: int,caption: String,box: Vector2,icon_px: int,tooltip: String="") -> Control:
 var wrap=Control.new();wrap.custom_minimum_size=box;wrap.tooltip_text=tooltip;wrap.mouse_filter=Control.MOUSE_FILTER_STOP if tooltip!="" else Control.MOUSE_FILTER_IGNORE
 var slot=MenuStyle.spawn("rarity_slot") as RaritySlot;wrap.add_child(slot);slot.setup(tier,UIAssets.icon(category,id),icon_px,box)
 slot.icon.position.y=maxf(2.0,(box.y-icon_px-(16 if caption!="" else 0))*0.5)
 if caption!="":
  var l=MenuStyle.label(caption,MenuStyle.sans(800,0.16,11),11,Color("D9D4C4"),0,wrap);l.position=Vector2(0,box.y-17);l.size=Vector2(box.x,14);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 return wrap
func _weapons() -> void:
 var s=_section("WEAPONS");var g=_grid(s,4)
 var limit=maxi(4,game.weapon_limit());var list=RunData.weapons(game)
 for w in list:
  var t=tile("weapons",str(w.id),w.tier,"LV %d"%w.level,Vector2(78,88),52,"%s · LV %d\n%s"%[w.name,w.level,SocketScreens.tooltip(game.weapons[w.id])])
  var pips=SocketPips.new().setup(game.weapons[w.id]);t.add_child(pips);pips.position=Vector2((78-pips.custom_minimum_size.x)*0.5,3)
  g.add_child(t)
 for i in range(list.size(),limit):g.add_child(empty_cell(88))
func _tomes() -> void:
 var list=RunData.tomes(game);var limit=game.tome_limit()
 var s=_section("TOMES · %d/%d"%[list.size(),limit]);var g=_grid(s,4)
 for t in list:g.add_child(tile("tomes",t.id,t.tier,"LV %d"%t.level,Vector2(78,72),32,"%s · LV %d"%[t.name,t.level]))
 for i in range(list.size(),maxi(4,limit)):g.add_child(empty_cell(72))
func _gems() -> void:
 var s=_section("SOCKET GEMS");var g=_grid(s,5,6)
 var counts=RunData.gem_counts(game)
 for element in Elements.IDS:
  var color=FogPalette.ELEMENT.get(element,Elements.color(element));var n=int(counts[element])
  g.add_child(_gem_cell(color,str(n),Elements.display_name(element).substr(0,4).to_upper(),n>0,"%s gem ×%d — %s"%[Elements.display_name(element),n,Elements.summary(element)]))
 g.add_child(_gem_cell(FogPalette.GOLD,str(game.amulets),"AMUL",game.amulets>0,"Imbued Amulet ×%d — unlocks a second socket on one weapon (a different element)."%game.amulets))
func _gem_cell(color: Color,count: String,short: String,lit: bool,tooltip: String) -> Control:
 var c=Control.new();c.custom_minimum_size=Vector2(60,70);c.tooltip_text=tooltip;c.mouse_filter=Control.MOUSE_FILTER_STOP;c.modulate=Color.WHITE if lit else Color(1,1,1,0.4)
 c.draw.connect(func():
  var r=Rect2(Vector2.ZERO,c.size);c.draw_rect(r,Color("1C1E1B"));c.draw_rect(r.grow(-0.5),color if lit else FogPalette.BORDER,false,1.0)
  var ctr=Vector2(18.0,26.0);var d=PackedVector2Array([ctr+Vector2(0,-8),ctr+Vector2(8,0),ctr+Vector2(0,8),ctr+Vector2(-8,0)])
  c.draw_colored_polygon(d,Color(color.r,color.g,color.b,0.35));c.draw_polyline(d+PackedVector2Array([d[0]]),color,2.0))
 var n=MenuStyle.label(count,MenuStyle.sans(800,0,20),20,FogPalette.BONE_BRIGHT if lit else FogPalette.ASH_FAINT,0,c);n.position=Vector2(32,13)
 var s=MenuStyle.label(short,MenuStyle.sans(800,0.2,10),10,color,0,c);s.position=Vector2(0,50);s.size=Vector2(c.size.x,14);s.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 return c
func _items() -> void:
 var list=RunData.items(game)
 var s=_section("ITEMS" if list.is_empty() else "ITEMS · %d"%list.size())
 if list.is_empty():
  MenuStyle.label("No items collected",MenuStyle.sans(400,0,15),15,FogPalette.ASH_FAINT,0,s);return
 var roomy=list.size()<=ROOMY_ITEMS
 items_scroll=ScrollContainer.new();items_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;items_scroll.focus_mode=Control.FOCUS_ALL
 items_scroll.custom_minimum_size=Vector2(0,186 if roomy else 120);items_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;s.add_child(items_scroll)
 var g=_grid(items_scroll,4 if roomy else 6,10 if roomy else 8)
 for it in list:
  var cell=tile("items",it.id,it.tier,"×%d"%it.stacks,Vector2(78,88),64,"-") if roomy else _compact_item(it,"-")
  RunData.lazy_tip(cell,func():return "%s ×%d\n%s"%[it.name,it.stacks,RunData.item_description(it.id)])
  g.add_child(cell)
func _compact_item(it: Dictionary,tip: String) -> Control:
 var box=Vector2(52,52);var wrap=Control.new();wrap.custom_minimum_size=box;wrap.tooltip_text=tip;wrap.mouse_filter=Control.MOUSE_FILTER_STOP
 var slot=MenuStyle.spawn("rarity_slot") as RaritySlot;wrap.add_child(slot);slot.setup(it.tier,UIAssets.icon("items",it.id),32,box,true)
 var badge=MenuStyle.label("×%d"%it.stacks,MenuStyle.sans(800,0,11),11,FogPalette.BONE_BRIGHT,1,wrap);badge.position=Vector2(2,0)
 return wrap
func _loadout() -> void:
 var s=_section("TRAIT & ULTIMATE");var g=_grid(s,4)
 var l=RunData.loadout(game)
 g.add_child(tile("traits",l.trait,FogPalette.Rarity.COMMON,"TRAIT",Vector2(78,88),52,"Trait: %s"%l.trait.capitalize()))
 var u=tile("ultimates",l.ultimate,FogPalette.Rarity.COMMON,"",Vector2(78,88),52,"Ultimate: %s"%l.ultimate.capitalize())
 var stamp=MenuStyle.label("Q READY" if l.ready else "%ds"%ceili(l.cooldown_left),MenuStyle.sans(800,0.16,11),11,FogPalette.BONE_BRIGHT,0,u)
 stamp.position=Vector2(0,70);stamp.size=Vector2(78,14);stamp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if l.ready:
  var bar=ColorRect.new();bar.color=FogPalette.RUST;bar.position=Vector2(8,69);bar.size=Vector2(62,15);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;u.add_child(bar);u.move_child(bar,u.get_child_count()-2)
 g.add_child(u)
