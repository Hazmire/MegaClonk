class_name UnlocksScreen
extends MenuScreen
# Fog-Unlocks / Fog-Unlocks-Weapons / Fog-Unlocks-Items: one frame (title, silver, Home, tab bar) and one body per
# category. Everything shown comes from LoadoutCatalog / Catalog / MetaProgress / MenuData; nothing is typed twice.
const GRID_POS=Vector2(120,322)
const MEMO_INK_BORDER=Color("1C1A15")
var category="weapons"
var tab_bar: MenuTabBar
var body: Control
var memo: MemoCard
var silver_number: HudNumber
var home_button: MenuItem
var tiles: Dictionary={}
var entry_data: Dictionary={}
var selected_id=""
var toggle: OnOffToggle
var buy_button: Button
var slots_block: Control
func progress() -> Dictionary:return game.progress.data
func build() -> void:
 category=frontend.active_tab if frontend.active_tab in ['weapons','tomes','traits','items','ultimates'] else 'weapons'
 var header=VBoxContainer.new();header.name="Header";header.position=Vector2(120,72);header.add_theme_constant_override("separation",12);header.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(header)
 header.add_child(MenuStyle.label("Unlocks & collection",MenuStyle.serif(),FogPalette.SIZE_TITLE,FogPalette.BONE,3))
 var sub=HBoxContainer.new();sub.add_theme_constant_override("separation",16);sub.mouse_filter=Control.MOUSE_FILTER_IGNORE;header.add_child(sub)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.custom_minimum_size=Vector2(48,6);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;sub.add_child(rule)
 sub.add_child(SmallCapsLabel.new().setup("Enabled entries can appear in runs",17,Color("A9ADA4"),600,0.3))
 home_button=MenuStyle.spawn("menu_item") as MenuItem;home_button.setup("Home",30,30,false,Vector2(60,60));home_button.hint_text="ESC";home_button.indent=22.0;home_button.outlined=true
 home_button.position=Vector2(MenuStyle.W-110-190,121);home_button.custom_minimum_size=Vector2(190,60);home_button.size=Vector2(190,60);home_button.chosen.connect(go_back);content.add_child(home_button)
 var cap=SmallCapsLabel.new().setup("Silver",15,Color("8D9188"),600,0.3);cap.name="SilverCaption";cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;cap.position=Vector2(MenuStyle.W-110-190-40-240,122);cap.size=Vector2(240,22);content.add_child(cap)
 silver_number=HudNumber.new().setup(progress().silver,42,FogPalette.BONE_BRIGHT);silver_number.name="SilverAmount";silver_number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;silver_number.position=Vector2(MenuStyle.W-110-190-40-240,138);silver_number.size=Vector2(240,50);content.add_child(silver_number)
 tab_bar=MenuTabBar.new();tab_bar.name="Tabs";tab_bar.position=Vector2(120,232);content.add_child(tab_bar)
 tab_bar.set_tabs(MenuData.UNLOCK_TABS,category);tab_bar.tab_selected.connect(show_category)
 body=Control.new();body.name="Body";body.size=Vector2(MenuStyle.W,MenuStyle.H);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(body)
 build_body()
func step_tabs(direction: int) -> void:tab_bar.step(direction)
func show_category(id: String) -> void:
 category=id;frontend.active_tab=id;build_body()
func go_back() -> void:navigate(frontend.home)
func remember_focus() -> String:
 var owner=get_viewport().gui_get_focus_owner() if is_inside_tree() else null
 return owner.name if owner!=null else ""
func clear_body() -> void:
 for c in body.get_children():body.remove_child(c);c.queue_free()
 tiles.clear();entry_data.clear();toggle=null;buy_button=null;memo=null;slots_block=null;selected_id=""
func build_body() -> void:
 clear_body()
 tab_bar.set_note("")
 match category:
  "items":build_items()
  "weapons":build_weapons()
  _:build_cards(category)
 set_hints(hint_set())
 var first=first_tile()
 if first!=null:first.grab_focus.call_deferred()
func hint_set() -> Array:
 var hints_list=[["Q / E","Category"],["ENTER","Toggle" if category!="traits" and category!="ultimates" else "Inspect"],["ESC","Home"]]
 if category=="items":hints_list.insert(1,["TAB","Rarity"])
 return hints_list
func first_tile() -> CollectionTile:
 for id in tiles:return tiles[id]
 return null
# ---- tiles -------------------------------------------------------------------------------------------------------
func make_tile(parent: Control,cat: String,e: Dictionary,tile_size: Vector2,icon_px: int,mini: bool=false) -> CollectionTile:
 var id=String(e.id)
 var tile=MenuStyle.spawn("collection_tile") as CollectionTile
 var rarity=MenuStyle.rarity_for_tier(Catalog.item_tier(id)) if cat=="items" else -1
 var shown_name=String(e.name)
 tile.setup(cat,id,shown_name,MenuData.tile_state(progress(),cat,id),tile_size,icon_px,rarity,MenuData.is_new(progress(),cat,id),mini)
 tile.tooltip_text=String(e.name)
 parent.add_child(tile);tiles[id]=tile;entry_data[id]=e
 tile.highlighted.connect(on_highlight)
 tile.pressed.connect(func():on_pressed(id))
 return tile
func on_highlight(tile: CollectionTile) -> void:
 if tile.entry_id!=selected_id:select(tile.entry_id)
func select(id: String) -> void:
 selected_id=id
 for key in tiles:tiles[key].queue_redraw()
 if MenuData.mark_seen(progress(),category,id):
  game.progress.save();tiles[id].is_new=false
 fill_memo(id)
func on_pressed(id: String) -> void:
 if MenuData.is_locked(progress(),category,id) or category in ["traits","ultimates"]:return
 flip(id)
func flip(id: String) -> void:
 if not MetaProgress.toggle(progress(),category,id):return
 game.progress.save();refresh_tile(id)
 if id==selected_id:fill_memo(id)
func refresh_tile(id: String) -> void:
 var tile: CollectionTile=tiles[id];tile.set_state(MenuData.tile_state(progress(),category,id));tile.is_new=MenuData.is_new(progress(),category,id);tile.queue_redraw()
func refresh_all_tiles() -> void:
 for id in tiles:refresh_tile(id)
func refresh_silver() -> void:silver_number.set_value(progress().silver)
# ---- shared memo pieces ------------------------------------------------------------------------------------------
func new_memo(at: Vector2,width: float,tilt: float,margins: Vector4) -> MemoCard:
 memo=MenuStyle.spawn("memo_card") as MemoCard;memo.name="DetailMemo";memo.position=at;memo.custom_minimum_size.x=width;memo.size.x=width
 memo.tape_angle=-3.0;memo.tape_size=Vector2(96,28);memo.set_look(tilt,margins);memo.body.add_theme_constant_override("separation",20)
 body.add_child(memo);return memo
func memo_rule(parent: Node=null) -> Control:
 var r=DashedLine.new();(parent if parent!=null else memo.body).add_child(r);return r
func caps_on_paper(text: String,size: int,parent: Node,tracking: float=0.3) -> SmallCapsLabel:
 var l=SmallCapsLabel.new().setup(text,size,FogPalette.MEMO_INK_SOFT,800,tracking);l.add_theme_color_override("font_shadow_color",Color(0,0,0,0));parent.add_child(l);return l
func icon_box(cat: String,id: String,px: int,border_color: Color,border_w: int,locked: bool,box: float) -> Control:
 var holder=PanelContainer.new();holder.custom_minimum_size=Vector2(box+2.0*border_w,box+2.0*border_w);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var st=FogTheme.flat(FogPalette.NIGHT,border_color,border_w);st.set_content_margin_all(border_w)
 holder.add_theme_stylebox_override("panel",st)
 var center=CenterContainer.new();center.mouse_filter=Control.MOUSE_FILTER_IGNORE;holder.add_child(center)
 center.add_child(MenuStyle.icon_rect(cat,id,px,locked));return holder
func locked_stamp(text: String,font_px: int,parent: Node) -> Stamp:
 var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Locked";stamp.setup(text,MenuStyle.SILVER_RUST,font_px,0.24,3,-4.0,Color(0,0,0,0),Vector2(14,5))
 var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(stamp);parent.add_child(row);return stamp
func toggle_row(label: String,font_px: int) -> void:
 var row=HBoxContainer.new();row.name="ToggleRow";row.mouse_filter=Control.MOUSE_FILTER_IGNORE;memo.body.add_child(row)
 var text=memo.memo_label(label,font_px,FogPalette.MEMO_INK_SOFT,row);text.name="ToggleLabel"
 toggle=MenuStyle.spawn("on_off_toggle") as OnOffToggle;toggle.name="Toggle";toggle.setup(MetaProgress.enabled(progress(),category,selected_id));toggle.changed.connect(func(_on):flip(selected_id));row.add_child(toggle)
func buy_row(entry: Dictionary) -> void:
 buy_button=Button.new();buy_button.name="Buy";buy_button.text="UNLOCK  ·  %d SILVER"%int(entry.cost);buy_button.focus_mode=Control.FOCUS_ALL;buy_button.alignment=HORIZONTAL_ALIGNMENT_CENTER
 var f=MenuStyle.sans(800,0.14,16);buy_button.add_theme_font_override("font",f);buy_button.add_theme_font_size_override("font_size",16)
 for c in ["font_color","font_hover_color","font_focus_color"]:buy_button.add_theme_color_override(c,FogPalette.MEMO_INK)
 buy_button.add_theme_color_override("font_pressed_color",FogPalette.MEMO)
 buy_button.add_theme_stylebox_override("normal",FogTheme.flat(Color(0,0,0,0),FogPalette.MEMO_INK,2))
 buy_button.add_theme_stylebox_override("hover",FogTheme.flat(Color("E4DCC3"),FogPalette.MEMO_INK,2))
 buy_button.add_theme_stylebox_override("focus",FogTheme.flat(Color("E4DCC3"),FogPalette.RUST,3))
 buy_button.add_theme_stylebox_override("pressed",FogTheme.flat(FogPalette.MEMO_INK,FogPalette.MEMO_INK,2))
 for s in ["normal","hover","focus","pressed"]:(buy_button.get_theme_stylebox(s) as StyleBoxFlat).set_content_margin_all(10)
 buy_button.mouse_entered.connect(func():MenuScreen.sfx("hover"))
 var id=selected_id
 buy_button.pressed.connect(func():buy(id));memo.body.add_child(buy_button)
func buy(id: String) -> void:
 if MetaProgress.purchase(progress(),category,id):
  sfx("purchase");game.progress.save();refresh_silver();refresh_tile(id);refresh_slots();fill_memo(id)
  if tiles.has(id):tiles[id].grab_focus()
 else:game.toast("Meet the kill milestone and silver cost")
# ---- Weapons / Tomes / Traits / Ultimates cards ------------------------------------------------------------------
func build_cards(cat: String) -> void:
 var columns=5
 var grid=GridContainer.new();grid.name="Grid";grid.columns=columns;grid.position=GRID_POS;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
 body.add_child(grid)
 var tile_w=(980.0-16.0*(columns-1))/columns
 for e in LoadoutCatalog.entries(cat):make_tile(grid,cat,e,Vector2(floorf(tile_w),196),64)
 new_memo(Vector2(1160,330),640,0.8,Vector4(44,40,44,36))
 if cat=="tomes":build_slots("tome",Vector2(120,GRID_POS.y+196*2+16+44),980.0)
 select(String(LoadoutCatalog.entries(cat)[0].id))
func build_weapons() -> void:
 var columns=4
 var grid=GridContainer.new();grid.name="Grid";grid.columns=columns;grid.position=GRID_POS;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
 body.add_child(grid)
 for e in LoadoutCatalog.entries("weapons"):make_tile(grid,"weapons",e,Vector2(200,196),96)
 WeaponPreview.still=bool(game.settings.get("reduced",false))
 new_memo(Vector2(1000,318),820,0.5,Vector4(32,32,32,30))
 build_slots("weapon",Vector2(120,GRID_POS.y+196*2+16+40),848.0)
 select(String(LoadoutCatalog.entries("weapons")[0].id))
func fill_weapon_memo(id: String) -> void:
 var e: Dictionary=entry_data[id]
 var locked=MenuData.is_locked(progress(),"weapons",id)
 var row=HBoxContainer.new();row.name="WeaponRow";row.add_theme_constant_override("separation",26);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;memo.body.add_child(row)
 # Polaroid: the clip, a caption strip and tape. The figure hangs off a holder because containers reset the rotation of their direct children.
 var holder=Control.new();holder.name="PolaroidHolder";holder.custom_minimum_size=Vector2(480,458);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(holder)
 var figure=Control.new();figure.name="Polaroid";figure.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);figure.mouse_filter=Control.MOUSE_FILTER_IGNORE;holder.add_child(figure)
 figure.resized.connect(func():figure.pivot_offset=figure.size*0.5)
 figure.pivot_offset=Vector2(240,229);figure.rotation_degrees=-1.4
 var card=ColorRect.new();card.color=Color("F1ECDD");card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);card.mouse_filter=Control.MOUSE_FILTER_IGNORE;figure.add_child(card)
 var shadow=ColorRect.new();shadow.color=Color(0,0,0,0.35);shadow.position=Vector2(3,4);shadow.size=Vector2(480,458);shadow.show_behind_parent=true;shadow.mouse_filter=Control.MOUSE_FILTER_IGNORE;figure.add_child(shadow)
 var preview=MenuStyle.spawn("weapon_preview") as WeaponPreview;preview.name="Preview";preview.position=Vector2(10,10);figure.add_child(preview);preview.setup(int(id),locked)
 var caption=MenuStyle.label("%s — in action"%String(e.name),MenuStyle.memo(),16,FogPalette.MEMO_INK_SOFT,0,figure);caption.name="Caption";caption.position=Vector2(10,418);caption.size=Vector2(460,40);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var tape=ColorRect.new();tape.color=Color(0.91,0.886,0.816,0.75);tape.position=Vector2(24,-10);tape.size=Vector2(70,22);tape.pivot_offset=Vector2(35,11);tape.rotation_degrees=-8.0;tape.mouse_filter=Control.MOUSE_FILTER_IGNORE;figure.add_child(tape)
 if locked:
  var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="PhotoLocked";stamp.setup("Locked",FogPalette.RUST_TEXT,22,0.26,4,-8.0,Color(0.055,0.059,0.055,0.55),Vector2(30,9));preview.add_child(stamp)
  stamp.position=(preview.size-stamp.size)*0.5
 var info=VBoxContainer.new();info.name="Info";info.add_theme_constant_override("separation",14);info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(info)
 caps_on_paper("Weapon",13,info).name="Kind"
 var title=memo.memo_label(String(e.name),34,FogPalette.MEMO_INK,info);title.name="Name"
 var desc=memo.memo_label(MenuData.weapon_sentence(int(id)),17,Color("2E2A22"),info);desc.name="Description"
 memo_rule(info)
 caps_on_paper("Level-up options",12,info,0.26).name="PoolCaption"
 var chips=HFlowContainer.new();chips.name="Pool";chips.add_theme_constant_override("h_separation",6);chips.add_theme_constant_override("v_separation",6);chips.mouse_filter=Control.MOUSE_FILTER_IGNORE;info.add_child(chips)
 for label in MenuData.weapon_pool_labels(int(id)):chips.add_child(pool_chip(label))
 var gap=Control.new();gap.size_flags_vertical=Control.SIZE_EXPAND_FILL;info.add_child(gap)
 if locked:
  var req=memo.memo_label(MenuData.unlock_text("weapons",e),16,FogPalette.MEMO_INK_SOFT,info);req.name="Requirement"
  buy_row(e);memo.body.remove_child(buy_button);info.add_child(buy_button)
 else:
  var toggle_holder=VBoxContainer.new();toggle_holder.add_theme_constant_override("separation",10);toggle_holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;info.add_child(toggle_holder)
  toggle_row("Appears in runs",16);var tr=memo.body.get_child(memo.body.get_child_count()-1);memo.body.remove_child(tr);toggle_holder.add_child(tr)
  var note=memo.memo_label("Starting weapons ignore this toggle.",13,FogPalette.MEMO_INK_SOFT,toggle_holder);note.name="StartingNote"
func pool_chip(label: String) -> Control:
 var panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var st=FogTheme.flat(Color(0,0,0,0),Color("5A5446"),1);st.content_margin_left=7;st.content_margin_right=7;st.content_margin_top=4;st.content_margin_bottom=2;panel.add_theme_stylebox_override("panel",st)
 var l=MenuStyle.label(label,MenuStyle.sans(800,0.12,11),11,Color("2E2A22"));panel.add_child(l);return panel
var filter="all"
var chips: Dictionary={}
var item_grid: GridContainer
func build_items() -> void:
 chips.clear()
 var counts=MenuData.tier_counts()
 var row=HBoxContainer.new();row.name="Filters";row.position=Vector2(120,312);row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(row)
 var defs=[["all","All",FogPalette.BONE]]
 for tier in Catalog.ITEM_TIERS:defs.append([tier,MenuData.TIER_LABELS[tier],MenuStyle.rarity_color(MenuStyle.rarity_for_tier(tier))])
 for d in defs:
  var chip=MenuStyle.spawn("filter_chip") as FilterChip;chip.setup(String(d[0]),String(d[1]),int(counts[d[0]]),d[2]);chip.chosen_filter.connect(set_filter);row.add_child(chip);chips[d[0]]=chip
 item_grid=GridContainer.new();item_grid.name="Grid";item_grid.columns=10;item_grid.position=Vector2(120,368);item_grid.add_theme_constant_override("h_separation",12);item_grid.add_theme_constant_override("v_separation",12);item_grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(item_grid)
 var legend=HBoxContainer.new();legend.name="Legend";legend.position=Vector2(120,368+6*88+5*12+18);legend.add_theme_constant_override("separation",24);legend.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(legend)
 legend.add_child(SmallCapsLabel.new().setup("Locked",13,FogPalette.ASH_FAINT,600,0.16))
 legend.add_child(SmallCapsLabel.new().setup("Bar colour = rarity",13,FogPalette.ASH_FAINT,600,0.16))
 new_memo(Vector2(1180,320),630,0.7,Vector4(40,36,40,32))
 memo.min_height=560.0;memo._fit()
 for id in Catalog.ITEM_IDS:entry_data[String(id)]=LoadoutCatalog.entry("items",String(id))
 fill_items()
 select(String(Catalog.ITEM_IDS[0]))
func visible_item_ids() -> Array:
 var ids=[]
 for id in Catalog.ITEM_IDS:
  if filter=="all" or Catalog.item_tier(id)==filter:ids.append(String(id))
 return ids
func fill_items() -> void:
 for c in item_grid.get_children():item_grid.remove_child(c);c.queue_free()
 tiles.clear()
 for id in visible_item_ids():make_tile(item_grid,"items",entry_data[id],Vector2(88,88),64,true)
 for key in chips:chips[key].set_active(key==filter)
 tab_bar.set_note("FOUND %d / %d"%[MenuData.items_found(progress()),Catalog.ITEM_IDS.size()])
func set_filter(id: String) -> void:
 filter=id;fill_items()
 if not tiles.has(selected_id) and not tiles.is_empty():select(String(tiles.keys()[0]))
func cycle_filter(direction: int=1) -> void:
 var order=["all"]+Catalog.ITEM_TIERS
 sfx("hover");set_filter(order[posmod(order.find(filter)+direction,order.size())])
func _input(event: InputEvent) -> void:
 super._input(event)
 if category=="items" and is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_TAB:
  get_viewport().set_input_as_handled();cycle_filter(-1 if event.shift_pressed else 1)
 elif category=="items" and is_visible_in_tree() and event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_Y:
  get_viewport().set_input_as_handled();cycle_filter()
func fill_item_memo(id: String) -> void:
 var e: Dictionary=entry_data[id]
 var item: Dictionary=Catalog.ITEMS[id]
 var tier=Catalog.item_tier(id);var rarity=MenuStyle.rarity_for_tier(tier);var info=FogPalette.RARITY[rarity]
 var locked=MenuData.is_locked(progress(),"items",id)
 var head=HBoxContainer.new();head.add_theme_constant_override("separation",24);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;memo.body.add_child(head)
 var box=PanelContainer.new();box.name="IconBox";box.custom_minimum_size=Vector2(152,152);box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var st=FogTheme.flat(FogPalette.NIGHT,info["color"],4);st.set_content_margin_all(4)
 if rarity==FogPalette.Rarity.LEGENDARY:st.shadow_color=Color(0.949,0.757,0.306,0.55);st.shadow_size=22
 box.add_theme_stylebox_override("panel",st);head.add_child(box)
 var center=CenterContainer.new();center.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(center);center.add_child(MenuStyle.icon_rect("items",id,128,locked))
 var titles=VBoxContainer.new();titles.add_theme_constant_override("separation",10);titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;titles.size_flags_vertical=Control.SIZE_SHRINK_CENTER;titles.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(titles)
 var chip_row=HBoxContainer.new();chip_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;titles.add_child(chip_row)
 var tier_stamp=MenuStyle.spawn("stamp") as Stamp;tier_stamp.name="TierChip";tier_stamp.setup(MenuData.TIER_LABELS[tier],info["on"],12,0.24,0,0.0,info["color"],Vector2(8,4));chip_row.add_child(tier_stamp)
 var title=memo.memo_label(String(item.name),36,FogPalette.MEMO_INK,titles);title.name="Name"
 var weight=caps_on_paper("%s drop weight"%MenuData.drop_weight_text(tier),13,titles,0.18);weight.name="DropWeight"
 var effect=memo.memo_label(String(item.full),20,Color("2E2A22"));effect.name="Effect"
 var element=MenuData.needs_element(id)
 if element!="":
  var need=PanelContainer.new();need.name="NeedsBox";need.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var ns=FogTheme.flat(Color(0,0,0,0));ns.content_margin_left=12;ns.content_margin_right=12;ns.content_margin_top=10;ns.content_margin_bottom=10;need.add_theme_stylebox_override("panel",ns)
  var dashed=DashedFrame.new();dashed.color=Elements.color(element);dashed.show_behind_parent=true;dashed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);need.add_child(dashed)
  var nrow=HBoxContainer.new();nrow.add_theme_constant_override("separation",10);nrow.mouse_filter=Control.MOUSE_FILTER_IGNORE;need.add_child(nrow)
  var diamond=Diamond.new();diamond.color=Elements.color(element);diamond.custom_minimum_size=Vector2(18,18);diamond.size_flags_vertical=Control.SIZE_SHRINK_CENTER;nrow.add_child(diamond)
  memo.memo_label("Does nothing until you own the %s socket gem."%Elements.display_name(element),16,Color("2E2A22"),nrow).name="NeedsText"
  memo.body.add_child(need)
 if bool(item.unique):
  var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;memo.body.add_child(row)
  var u=MenuStyle.spawn("stamp") as Stamp;u.name="UniqueStamp";u.setup("Unique · once per run",Color("8A5A0E"),16,0.24,3,-3.0,Color(0,0,0,0),Vector2(12,5));row.add_child(u)
 memo_rule()
 var spacer=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;memo.body.add_child(spacer)
 if locked:
  locked_stamp("Locked",18,memo.body)
  var req=memo.memo_label(MenuData.unlock_text("items",e),17,FogPalette.MEMO_INK_SOFT);req.name="Requirement"
 else:toggle_row(MenuData.sources_text(id),18)
class DashedFrame extends Control:
 var color=Color.BLACK
 func _init() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var r=Rect2(Vector2.ZERO,size);var dash=6.0
  var x=0.0
  while x<r.size.x:
   var w=minf(dash,r.size.x-x);draw_rect(Rect2(x,0,w,2),color);draw_rect(Rect2(x,r.size.y-2,w,2),color);x+=dash*2.0
  var y=0.0
  while y<r.size.y:
   var h=minf(dash,r.size.y-y);draw_rect(Rect2(0,y,2,h),color);draw_rect(Rect2(r.size.x-2,y,2,h),color);y+=dash*2.0
class Diamond extends Control:
 var color=Color.BLACK
 func _init() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var c=size*0.5;draw_colored_polygon(PackedVector2Array([Vector2(c.x,0),Vector2(size.x,c.y),Vector2(c.x,size.y),Vector2(0,c.y)]),color)
func build_slots(kind: String,at: Vector2,width: float) -> void:
 slots_block=VBoxContainer.new();slots_block.name="AccountUpgrades";slots_block.position=at;slots_block.custom_minimum_size.x=width;slots_block.size.x=width;(slots_block as VBoxContainer).add_theme_constant_override("separation",14);slots_block.mouse_filter=Control.MOUSE_FILTER_IGNORE
 body.add_child(slots_block);slots_block.set_meta("kind",kind)
 refresh_slots()
func refresh_slots() -> void:
 if slots_block==null:return
 for c in slots_block.get_children():slots_block.remove_child(c);c.queue_free()
 var kind: String=slots_block.get_meta("kind")
 var count=int(progress()[kind+"_slots"])
 slots_block.add_child(SmallCapsLabel.new().setup("Account upgrades",16,Color("8D9188"),800,0.3))
 var panel=PanelContainer.new();panel.custom_minimum_size.y=76;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var st=FogTheme.flat(Color(0.055,0.059,0.055,0.85),FogPalette.BORDER,1);st.content_margin_left=24;st.content_margin_right=24;panel.add_theme_stylebox_override("panel",st);slots_block.add_child(panel)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",28);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
 var title=MenuStyle.label("%s slots"%kind.capitalize(),MenuStyle.serif(),30,FogPalette.BONE,0,row);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 var pips=HBoxContainer.new();pips.name="Pips";pips.add_theme_constant_override("separation",6);pips.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pips.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(pips)
 for i in 4:
  var pip=ColorRect.new();pip.custom_minimum_size=Vector2(22,22);pip.color=FogPalette.RUST if i<count else Color(0,0,0,0);pip.mouse_filter=Control.MOUSE_FILTER_IGNORE;pips.add_child(pip)
  if i>=count:
   var frame=Panel.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.add_theme_stylebox_override("panel",FogTheme.flat(Color(0,0,0,0),FogPalette.BORDER_LIGHT,1));frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;pip.add_child(frame)
 var number=HudNumber.new().setup("%d/4"%count,22,FogPalette.BONE);number.custom_minimum_size.x=64;number.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(number)
 if count>=4:
  var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Maximum";stamp.setup("Maximum",FogPalette.BONE,14,0.24,2,2.0,Color(0,0,0,0),Vector2(10,5));stamp.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(stamp)
 else:
  var button=Button.new();button.name="BuySlot";button.text="BUY SLOT  ·  %d SILVER"%MetaProgress.slot_cost(progress(),kind);button.focus_mode=Control.FOCUS_ALL;button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  var f=MenuStyle.sans(800,0.14,15);button.add_theme_font_override("font",f);button.add_theme_font_size_override("font_size",15)
  for c in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:button.add_theme_color_override(c,FogPalette.BONE)
  button.add_theme_stylebox_override("normal",FogTheme.flat(Color(0,0,0,0),FogPalette.BONE,2));button.add_theme_stylebox_override("hover",FogTheme.flat(FogPalette.RUST,FogPalette.BONE,2))
  button.add_theme_stylebox_override("focus",FogTheme.flat(FogPalette.RUST,FogPalette.RUST_BRIGHT,3));button.add_theme_stylebox_override("pressed",FogTheme.flat(FogPalette.BONE,FogPalette.BONE,2))
  for s in ["normal","hover","focus","pressed"]:(button.get_theme_stylebox(s) as StyleBoxFlat).set_content_margin_all(9)
  button.mouse_entered.connect(func():MenuScreen.sfx("hover"))
  button.pressed.connect(func():buy_slot(kind));row.add_child(button)
func buy_slot(kind: String) -> void:
 if MetaProgress.buy_slot(progress(),kind):
  sfx("purchase");game.progress.save();refresh_silver();refresh_slots()
 else:game.toast("Not enough silver for the next slot")
# ---- detail memo ------------------------------------------------------------------------------------------------
func fill_memo(id: String) -> void:
 for c in memo.body.get_children():memo.body.remove_child(c);c.queue_free()
 toggle=null;buy_button=null
 if category=="weapons":fill_weapon_memo(id);return
 if category=="items":fill_item_memo(id);return
 var e: Dictionary=entry_data[id]
 var locked=MenuData.is_locked(progress(),category,id)
 var head=HBoxContainer.new();head.add_theme_constant_override("separation",24);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;memo.body.add_child(head)
 head.add_child(icon_box(category,id,128,MEMO_INK_BORDER,3,locked,128))
 var titles=VBoxContainer.new();titles.add_theme_constant_override("separation",8);titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;titles.size_flags_vertical=Control.SIZE_SHRINK_CENTER;titles.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(titles)
 caps_on_paper(category.trim_suffix("s").to_upper(),14,titles).name="Kind"
 var title=memo.memo_label(String(e.name),38,FogPalette.MEMO_INK,titles);title.name="Name"
 if locked:
  var desc=memo.memo_label("Details are revealed when this is unlocked.",20,Color("2E2A22"));desc.name="Description"
 else:
  var desc=memo.memo_label(String(e.description),20,Color("2E2A22"));desc.name="Description"
 memo_rule()
 if locked:
  locked_stamp("Locked",18,memo.body)
  var req=memo.memo_label(MenuData.unlock_text(category,e),18,FogPalette.MEMO_INK_SOFT);req.name="Requirement"
  if MenuData.can_buy(category):buy_row(e)
 elif category in ["traits","ultimates"]:
  var note=memo.memo_label("Always available for loadout selection.",18,FogPalette.MEMO_INK_SOFT);note.name="AlwaysAvailable"
 else:toggle_row("Appears in runs",18)
class DashedLine extends Control:
 func _init() -> void:custom_minimum_size.y=1;mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var x=0.0
  while x<size.x:draw_rect(Rect2(x,0,5,1),Color("8F876F"));x+=9.0
