class_name UnlocksScreen
extends MenuScreen
# Fog-Unlocks: "Unlocks & collection" with five tabs (Weapons, Tomes, Traits, Items, Ultimates), a tile grid on the left
# and a paper memo on the right. Every number and sentence comes from the catalogues / the profile.
const GRIDS={ # per tab: columns, tile size, icon pixels (always a whole multiple of the 32px art), frame, memo geometry
 "weapons":{"cols":4,"tile":Vector2(200,196),"icon":96,"frame":"plain","origin":Vector2(120,322),"memo":Vector2(1000,318),"memo_w":820.0,"tilt":0.5,"pad":Vector4(32,32,32,30)},
 "tomes":{"cols":5,"tile":Vector2(183,196),"icon":64,"frame":"plain","origin":Vector2(120,322),"memo":Vector2(1160,330),"memo_w":640.0,"tilt":0.8,"pad":Vector4(44,40,44,36)},
 "traits":{"cols":5,"tile":Vector2(183,196),"icon":64,"frame":"patch","origin":Vector2(120,322),"memo":Vector2(1160,330),"memo_w":640.0,"tilt":0.8,"pad":Vector4(44,40,44,36)},
 "ultimates":{"cols":3,"tile":Vector2(300,230),"icon":96,"frame":"iron","origin":Vector2(120,322),"memo":Vector2(1160,330),"memo_w":640.0,"tilt":0.8,"pad":Vector4(44,40,44,36)},
 "items":{"cols":10,"tile":Vector2(88,88),"icon":64,"frame":"plain","origin":Vector2(120,368),"memo":Vector2(1180,320),"memo_w":630.0,"tilt":0.7,"pad":Vector4(40,36,40,32)},
}
const SINGULAR={"weapons":"WEAPON","tomes":"TOME","traits":"TRAIT","items":"ITEM","ultimates":"ULTIMATE"}
var tab="weapons"
var tabs: MenuTabBar
var body: Control
var memo: MemoCard
var tiles: Array=[]
var tile_by_id: Dictionary={}
var selected_id=""
var tier_filter="all"
var chips: Dictionary={}
var silver_number: HudNumber
var home_button: Button
var preview: WeaponPreview
func _init() -> void:
 super._init();backdrop_kind="fog"
func build() -> void:
 var title=MenuStyle.label("Unlocks & collection",MenuStyle.serif(),72,FogPalette.BONE,3,content);title.name="Title";title.position=Vector2(120,72-(MenuStyle.serif().get_height(72)-72.0)*0.5)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(120,170);rule.size=Vector2(48,6);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(rule)
 var sub=SmallCapsLabel.new().setup("Enabled entries can appear in runs",17,Color("A9ADA4"),600,0.3);sub.position=Vector2(184,160);content.add_child(sub)
 var cap=SmallCapsLabel.new().setup("Silver",15,FogPalette.ASH_DIM,600,0.3);cap.name="SilverLabel";cap.position=Vector2(1500,90);cap.size=Vector2(150,20);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;content.add_child(cap)
 silver_number=HudNumber.new().setup(game.progress.data.silver,42,FogPalette.BONE_BRIGHT);silver_number.name="SilverAmount";silver_number.position=Vector2(1450,108);silver_number.size=Vector2(200,52);silver_number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;content.add_child(silver_number)
 home_button=ghost_button("Home","ESC");home_button.name="Home";home_button.position=Vector2(MenuStyle.W-110-148,96);home_button.size=Vector2(148,60);content.add_child(home_button)
 home_button.pressed.connect(func():sfx("confirm");go_back())
 tab=String(frontend.active_tab) if String(frontend.active_tab) in ["weapons","tomes","traits","items","ultimates"] else "weapons"
 tabs=MenuStyle.spawn("tab_bar") as MenuTabBar;tabs.position=Vector2(120,232);tabs.size=Vector2(1690,53);content.add_child(tabs)
 var entries=[]
 for t in MenuData.TABS:entries.append({"id":t[0],"label":t[1]})
 tabs.set_tabs(entries,tab);tabs.tab_selected.connect(set_tab)
 body=Control.new();body.name="Body";body.size=content.size;body.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(body)
 memo=MenuStyle.spawn("memo_card") as MemoCard;memo.name="Detail";content.add_child(memo)
 set_hints([["Q / E","Category"],["ENTER","Toggle"],["ESC","Home"]])
 set_tab(tab,false)
func ghost_button(label: String,hint: String) -> Button:
 var b=Button.new();b.flat=false;b.focus_mode=Control.FOCUS_ALL;b.text=""
 b.add_theme_stylebox_override("normal",FogTheme.flat(Color(0,0,0,0),MenuStyle.OUTLINE,1));b.add_theme_stylebox_override("hover",FogTheme.flat(Color(0.494,0.094,0.125,0.5),FogPalette.RUST_BRIGHT,1))
 b.add_theme_stylebox_override("focus",FogTheme.flat(FogPalette.RUST,FogPalette.RUST_BRIGHT,1));b.add_theme_stylebox_override("pressed",FogTheme.flat(FogPalette.BONE,FogPalette.BONE,1))
 var row=HBoxContainer.new();row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",16);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(row)
 MenuStyle.label(label,MenuStyle.serif(),30,Color("D9D4C4"),0,row)
 MenuStyle.label(hint,MenuStyle.sans(800,0.2,14),14,FogPalette.ASH_DIM,0,row)
 b.mouse_entered.connect(func():if not b.has_focus():b.grab_focus())
 return b
func go_back() -> void:navigate(frontend.home)
func step_tabs(direction: int) -> void:tabs.step(direction)
func _input(event: InputEvent) -> void:
 super._input(event)
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_TAB and tab=="items" and is_visible_in_tree():
   get_viewport().set_input_as_handled();cycle_filter(-1 if event.shift_pressed else 1)
  elif event.keycode==KEY_F9 and OS.is_debug_build() and selected_id!="":
   var key=tab+":"+selected_id
   if key in MenuData.debug_locked:MenuData.debug_locked.erase(key)
   else:MenuData.debug_locked.append(key)
   refresh_all();get_viewport().set_input_as_handled()
func cycle_filter(direction: int) -> void:
 var order=["all"]+Catalog.ITEM_TIERS
 set_filter(order[posmod(order.find(tier_filter)+direction,order.size())])
# ---------------------------------------------------------------------------------------------------------------
func set_tab(id: String,keep_focus: bool=true) -> void:
 tab=id;frontend.active_tab=id;tabs.select(id,false)
 tiles.clear();tile_by_id.clear();chips.clear();preview=null
 for c in body.get_children():body.remove_child(c);c.queue_free()
 var spec: Dictionary=GRIDS[id]
 memo.position=spec.memo;memo.size=Vector2(spec.memo_w,0);memo.custom_minimum_size=Vector2(spec.memo_w,560 if id=="items" else 0)
 memo.set_look(spec.tilt,spec.pad)
 tabs.set_note("")
 match id:
  "items":build_items()
  _:build_grid_tab(id)
  
 if id=="weapons" or id=="tomes":build_account(id)
 var first=null
 if tiles.size()>0:first=tiles[0]
 var focus_in_tabs=get_viewport().gui_get_focus_owner()!=null and tabs.is_ancestor_of(get_viewport().gui_get_focus_owner())
 if first!=null:
  var want=tile_by_id.get(selected_id,first) if selected_id in tile_by_id else first
  if not (focus_in_tabs and keep_focus):want.grab_focus.call_deferred()
  show_entry.call_deferred(want.entry_id)
func entries_for(category: String) -> Array:return LoadoutCatalog.entries(category)
func make_tile(category: String,e: Dictionary,spec: Dictionary,mini: bool) -> CollectionTile:
 var data=game.progress.data
 var rarity=MenuStyle.rarity_for_tier(Catalog.item_tier(e.id)) if category=="items" else -1
 var tile=MenuStyle.spawn("collection_tile") as CollectionTile
 tile.frame_style=spec.frame
 tile.setup(category,String(e.id),String(e.name),MenuData.entry_state(data,category,String(e.id)),spec.tile,spec.icon,rarity,MenuData.is_new(data,category,String(e.id)),mini)
 tile.highlighted.connect(func(t):show_entry(t.entry_id))
 tile.pressed.connect(func():toggle_entry(category,String(e.id)))
 tiles.append(tile);tile_by_id[String(e.id)]=tile
 return tile
func build_grid_tab(category: String) -> void:
 var spec: Dictionary=GRIDS[category]
 var grid=GridContainer.new();grid.name="Grid";grid.columns=spec.cols;grid.position=spec.origin;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(grid)
 for e in entries_for(category):grid.add_child(make_tile(category,e,spec,false))
func build_items() -> void:
 var spec: Dictionary=GRIDS["items"]
 tabs.set_note("FOUND %d / %d"%[MenuData.found_items(game.progress.data),Catalog.ITEM_IDS.size()])
 var row=HBoxContainer.new();row.name="Filters";row.position=Vector2(120,312);row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(row)
 var counts=MenuData.tier_counts()
 var defs=[["all","All",FogPalette.BONE]]
 for t in Catalog.ITEM_TIERS:defs.append([t,t.capitalize(),MenuStyle.rarity_color(MenuStyle.rarity_for_tier(t))])
 for d in defs:
  var chip=MenuStyle.spawn("filter_chip") as FilterChip;chip.setup(d[0],d[1],counts[d[0]],d[2]);chip.set_active(d[0]==tier_filter);row.add_child(chip);chips[d[0]]=chip
  var id: String=d[0];chip.pressed.connect(func():sfx("confirm");set_filter(id))
 var grid=GridContainer.new();grid.name="Grid";grid.columns=10;grid.position=spec.origin;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(grid)
 for e in entries_for("items"):
  if tier_filter!="all" and Catalog.item_tier(e.id)!=tier_filter:continue
  grid.add_child(make_tile("items",e,spec,true))
 var legend=HBoxContainer.new();legend.name="Legend";legend.position=Vector2(120,368+6*88+5*12+18);legend.add_theme_constant_override("separation",24);legend.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(legend)
 for t in ["LOCKED","BAR COLOUR = RARITY"]:legend.add_child(SmallCapsLabel.new().setup(t,13,FogPalette.ASH_FAINT,600,0.16))
func set_filter(id: String) -> void:
 if id==tier_filter or not (id=="all" or id in Catalog.ITEM_TIERS):return
 tier_filter=id
 for k in chips:chips[k].set_active(k==id)
 var keep=selected_id
 # rebuild the grid only (chips stay put so focus on them is not lost)
 var grid=body.get_node("Grid");for c in grid.get_children():grid.remove_child(c);c.queue_free()
 tiles.clear();tile_by_id.clear()
 for e in entries_for("items"):
  if tier_filter!="all" and Catalog.item_tier(e.id)!=tier_filter:continue
  grid.add_child(make_tile("items",e,GRIDS["items"],true))
 if tiles.size()>0:show_entry(keep if keep in tile_by_id else tiles[0].entry_id)
func build_account(category: String) -> void:
 var kind="weapon" if category=="weapons" else "tome"
 var spec: Dictionary=GRIDS[category]
 var width=848.0 if category=="weapons" else 980.0
 var y=322.0+2*196.0+16.0+(40.0 if category=="weapons" else 44.0)
 var block=VBoxContainer.new();block.name="AccountUpgrades";block.position=Vector2(120,y);block.size=Vector2(width,120);block.add_theme_constant_override("separation",14);block.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(block)
 block.add_child(SmallCapsLabel.new().setup("Account upgrades",16,FogPalette.ASH_DIM,800,0.3))
 var panel=PanelContainer.new();panel.custom_minimum_size.y=76;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style=FogTheme.flat(FogPalette.NIGHT_TILE,FogPalette.BORDER,1);style.content_margin_left=24;style.content_margin_right=24;panel.add_theme_stylebox_override("panel",style);block.add_child(panel)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",28);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
 var label=MenuStyle.label("%s slots"%kind.capitalize(),MenuStyle.serif(),30,FogPalette.BONE);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(label)
 var count=int(game.progress.data[kind+"_slots"])
 var squares=HBoxContainer.new();squares.add_theme_constant_override("separation",6);squares.size_flags_vertical=Control.SIZE_SHRINK_CENTER;squares.mouse_filter=Control.MOUSE_FILTER_IGNORE;squares.name="SlotSquares";row.add_child(squares)
 for i in 4:
  var sq=ColorRect.new();sq.custom_minimum_size=Vector2(22,22);sq.color=FogPalette.RUST if i<count else Color(0,0,0,0);sq.mouse_filter=Control.MOUSE_FILTER_IGNORE
  if i>=count:
   var outline=ReferenceRect.new();outline.border_color=MenuStyle.OUTLINE;outline.editor_only=false;outline.border_width=2.0;outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);sq.add_child(outline)
  squares.add_child(sq)
 var number=HudNumber.new().setup("%d/4"%count,22,FogPalette.BONE);number.custom_minimum_size.x=56;number.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(number)
 if count>=4:
  var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Maximum";stamp.setup("Maximum",FogPalette.BONE,14,0.24,2,-3.0 if category=="weapons" else 2.0,Color(0,0,0,0),Vector2(10,4));stamp.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(stamp)
 else:
  var buy=outlined_button("BUY · %d SILVER"%MetaProgress.slot_cost(game.progress.data,kind));buy.name="BuySlot";buy.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  buy.pressed.connect(func():
   if MetaProgress.buy_slot(game.progress.data,kind):
    sfx("confirm");game.progress.save();refresh_all()
   else:game.toast("Not enough silver for another %s slot"%kind))
  row.add_child(buy)
func outlined_button(text: String,on_paper: bool=false) -> Button:
 var b=Button.new();b.text=text;b.focus_mode=Control.FOCUS_ALL
 var ink=FogPalette.MEMO_INK if on_paper else FogPalette.BONE
 b.add_theme_font_override("font",MenuStyle.sans(800,0.14,15));b.add_theme_font_size_override("font_size",15)
 for k in ["font_color","font_hover_color","font_focus_color"]:b.add_theme_color_override(k,ink)
 b.add_theme_color_override("font_pressed_color",FogPalette.MEMO if on_paper else FogPalette.NIGHT)
 b.add_theme_stylebox_override("normal",FogTheme.flat(Color(0,0,0,0),ink,2))
 b.add_theme_stylebox_override("hover",FogTheme.flat(Color("E4DCC3") if on_paper else Color(0.494,0.094,0.125,0.5),ink,2))
 b.add_theme_stylebox_override("focus",FogTheme.flat(Color("E4DCC3") if on_paper else FogPalette.RUST,FogPalette.RUST_BRIGHT,3))
 b.add_theme_stylebox_override("pressed",FogTheme.flat(ink,ink,2))
 for k in ["normal","hover","focus","pressed"]:
  var sb: StyleBoxFlat=b.get_theme_stylebox(k);sb.content_margin_left=14;sb.content_margin_right=14;sb.content_margin_top=8;sb.content_margin_bottom=6
 return b
# ---------------------------------------------------------------------------------------------------------------
func refresh_all() -> void:
 var keep=selected_id
 set_tab(tab)
 silver_number.set_value(game.progress.data.silver)
 if keep in tile_by_id:show_entry(keep)
func toggle_entry(category: String,id: String) -> void:
 if category not in MenuData.TOGGLE_CATEGORIES or not MenuData.entry_unlocked(game.progress.data,category,id):return
 if MetaProgress.toggle(game.progress.data,category,id):
  game.progress.save();sfx("confirm")
  if tile_by_id.has(id):tile_by_id[id].set_state(MenuData.entry_state(game.progress.data,category,id))
  show_entry(id)
func show_entry(id: String) -> void:
 if not tile_by_id.has(id):return
 selected_id=id
 var data=game.progress.data
 if MenuData.mark_seen(data,tab,id):game.progress.save()
 var e=LoadoutCatalog.entry(tab,id)
 var b=memo.body
 for c in b.get_children():b.remove_child(c);c.queue_free()
 preview=null
 match tab:
  "weapons":fill_weapon(e)
  "items":fill_item(e)
  _:fill_generic(e)
 memo.size=Vector2(memo.custom_minimum_size.x,0)
func state_of(id: String) -> String:return MenuData.entry_state(game.progress.data,tab,id)
# "Appears in runs" row, or the locked block, shared by every tab.
func add_footer(e: Dictionary,toggle_label: String) -> void:
 var b=memo.body;var state=state_of(String(e.id))
 if state=="locked":
  var box=VBoxContainer.new();box.name="LockedBlock";box.add_theme_constant_override("separation",12);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(box)
  var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Locked";stamp.setup("Locked",MenuStyle.SILVER_RUST,18,0.24,3,-4.0,Color(0,0,0,0),Vector2(14,5));var holder=Control.new();holder.custom_minimum_size=stamp.custom_minimum_size+Vector2(10,14);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;stamp.position=Vector2(4,6);holder.add_child(stamp);box.add_child(holder)
  var need=MenuData.unlock_requirement(tab,e)
  if need!="":
   var line=memo.memo_label("To unlock: %s"%need,17,FogPalette.MEMO_INK_SOFT,box);line.name="Requirement"
  if tab in ["weapons","tomes"] and int(e.cost)>0:
   var buy=outlined_button("UNLOCK FOR %d SILVER"%int(e.cost),true);buy.name="Unlock";buy.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;box.add_child(buy)
   var id=String(e.id);var category=tab
   buy.pressed.connect(func():
    if MetaProgress.purchase(game.progress.data,category,id):
     sfx("confirm");game.progress.save();refresh_all()
    else:game.toast("Meet the kill milestone and silver cost"))
 elif state=="plain":
  var note=memo.memo_label("Always available for loadout selection.",18,FogPalette.MEMO_INK_SOFT);note.name="AlwaysAvailable"
 else:
  var row=HBoxContainer.new();row.name="ToggleRow";row.add_theme_constant_override("separation",20);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(row)
  var label=memo.memo_label(toggle_label,18,FogPalette.MEMO_INK_SOFT,row);label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  var toggle=MenuStyle.spawn("on_off_toggle") as OnOffToggle;toggle.name="Toggle";toggle.setup(state=="on");row.add_child(toggle)
  var id=String(e.id);var category=tab
  toggle.changed.connect(func(_on):toggle_entry_from_memo(category,id))
func toggle_entry_from_memo(category: String,id: String) -> void:
 # the switch already flipped itself; MetaProgress.toggle flips the stored flag to match
 if MetaProgress.toggle(game.progress.data,category,id):
  game.progress.save()
  if tile_by_id.has(id):tile_by_id[id].set_state(MenuData.entry_state(game.progress.data,category,id))
func dashed_rule(parent: Node) -> void:
 var r=Control.new();r.custom_minimum_size.y=1;r.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(r)
 r.draw.connect(func():
  var x=0.0
  while x<r.size.x:r.draw_rect(Rect2(x,0,5,1),Color("8F876F"));x+=9.0)
func fill_generic(e: Dictionary) -> void:
 var b=memo.body;b.add_theme_constant_override("separation",20)
 var locked=state_of(String(e.id))=="locked"
 var head=HBoxContainer.new();head.add_theme_constant_override("separation",24);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(head)
 var frame=PanelContainer.new();frame.name="IconFrame";frame.add_theme_stylebox_override("panel",FogTheme.flat(Color(0,0,0,0),FogPalette.MEMO_INK,3));frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(frame)
 frame.add_child(MenuStyle.icon_rect(tab,String(e.id),128,locked))
 var names=VBoxContainer.new();names.add_theme_constant_override("separation",8);names.size_flags_vertical=Control.SIZE_SHRINK_CENTER;names.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(names)
 names.add_child(SmallCapsLabel.new().setup(SINGULAR[tab],14,FogPalette.MEMO_INK_SOFT,800,0.3))
 var title=memo.memo_label(String(e.name),38,FogPalette.MEMO_INK,names);title.name="Name"
 var effect=memo.memo_label(MenuData.effect_text(tab,e),20,Color("2E2A22"));effect.name="Effect"
 dashed_rule(b)
 add_footer(e,"Appears in runs")
func fill_weapon(e: Dictionary) -> void:
 var b=memo.body;var id=int(e.id);var locked=state_of(String(e.id))=="locked"
 var outer=HBoxContainer.new();outer.add_theme_constant_override("separation",26);outer.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(outer)
 # Polaroid: paper print with tape, the looping lab recording, a caption and (when locked) a LOCKED stamp
 var holder=Control.new();holder.name="Polaroid";holder.custom_minimum_size=Vector2(480,459);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;outer.add_child(holder)
 var paper=Panel.new();paper.size=Vector2(480,459);paper.pivot_offset=paper.size*0.5;paper.rotation_degrees=-1.4;paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var ps=FogTheme.flat(Color("F1ECDD"));ps.shadow_color=Color(0,0,0,0.35);ps.shadow_size=1;ps.shadow_offset=Vector2(3,4);paper.add_theme_stylebox_override("panel",ps);holder.add_child(paper)
 var tape=ColorRect.new();tape.color=Color(0.91,0.886,0.816,0.75);tape.position=Vector2(24,-10);tape.size=Vector2(70,22);tape.rotation_degrees=-8;tape.mouse_filter=Control.MOUSE_FILTER_IGNORE;paper.add_child(tape)
 preview=MenuStyle.spawn("weapon_preview") as WeaponPreview;preview.position=Vector2(10,10);preview.size=Vector2(460,409);paper.add_child(preview);preview.show_weapon(id,locked)
 if locked:
  var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Locked";stamp.setup("Locked",FogPalette.RUST_TEXT,22,0.26,4,-8.0,Color(0.055,0.059,0.055,0.55),Vector2(30,8));stamp.position=Vector2(240-stamp.size.x*0.5,190);paper.add_child(stamp)
 var caption=memo.memo_label("%s — in action"%e.name,16,FogPalette.MEMO_INK_SOFT,null);b.remove_child(caption);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.position=Vector2(10,419);caption.size=Vector2(460,40);caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;paper.add_child(caption)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",14);col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;outer.add_child(col)
 col.add_child(SmallCapsLabel.new().setup("Weapon",13,FogPalette.MEMO_INK_SOFT,800,0.3))
 var title=memo.memo_label(String(e.name),34,FogPalette.MEMO_INK,col);title.name="Name"
 var blurb=memo.memo_label(MenuData.effect_text("weapons",e),17,Color("2E2A22"),col);blurb.name="Effect"
 dashed_rule(col)
 col.add_child(SmallCapsLabel.new().setup("Level-up options",12,FogPalette.MEMO_INK_SOFT,800,0.26))
 var flow=HFlowContainer.new();flow.name="LevelUpChips";flow.add_theme_constant_override("h_separation",6);flow.add_theme_constant_override("v_separation",6);flow.mouse_filter=Control.MOUSE_FILTER_IGNORE;col.add_child(flow)
 for option in MenuData.level_up_options(id):
  var chip=PanelContainer.new();chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var cs=FogTheme.flat(Color(0,0,0,0),FogPalette.MEMO_INK_SOFT,1);cs.content_margin_left=7;cs.content_margin_right=7;cs.content_margin_top=4;cs.content_margin_bottom=2;chip.add_theme_stylebox_override("panel",cs)
  chip.add_child(MenuStyle.label(option,MenuStyle.sans(800,0.12,11),11,Color("2E2A22")));flow.add_child(chip)
 var spacer=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(spacer)
 # the footer lives in the right-hand column for weapons, so temporarily point the memo body there
 var saved=memo.body;memo.body=col
 add_footer(e,"Appears in runs")
 var note=memo.memo_label("Starting weapons ignore this toggle.",13,Color("5A5446"));note.name="StartingNote"
 memo.body=saved
func fill_item(e: Dictionary) -> void:
 var b=memo.body;b.add_theme_constant_override("separation",18)
 var id=String(e.id);var tier=Catalog.item_tier(id);var rarity=MenuStyle.rarity_for_tier(tier)
 var locked=state_of(id)=="locked";var info=FogPalette.RARITY[rarity]
 var head=HBoxContainer.new();head.add_theme_constant_override("separation",24);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(head)
 var slot_holder=Control.new();slot_holder.custom_minimum_size=Vector2(160,160);slot_holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(slot_holder)
 var slot=MenuStyle.spawn("rarity_slot") as RaritySlot;slot.name="RarityFrame";slot.setup(rarity,UIAssets.icon("items",id),128,Vector2(152,152),false);slot.position=Vector2(4,4);slot_holder.add_child(slot)
 if locked:slot.icon.material=MenuStyle.shader_material("res://ui/shaders/grayscale.gdshader",{"brightness":0.5})
 var names=VBoxContainer.new();names.add_theme_constant_override("separation",10);names.size_flags_vertical=Control.SIZE_SHRINK_CENTER;names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;names.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(names)
 var unique=Catalog.item_unique(id)
 var chip_holder=HBoxContainer.new();chip_holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;names.add_child(chip_holder)
 var chip=PanelContainer.new();chip.name="TierChip";chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var cs=FogTheme.flat(info["color"]);cs.content_margin_left=8;cs.content_margin_right=8;cs.content_margin_top=4;cs.content_margin_bottom=2;chip.add_theme_stylebox_override("panel",cs)
 chip.add_child(MenuStyle.label(String(info["name"]).to_upper()+(" · UNIQUE" if unique else ""),MenuStyle.sans(800,0.24,12),12,info["on"]));chip_holder.add_child(chip)
 var title=memo.memo_label(String(e.name),36,FogPalette.MEMO_INK,names);title.name="Name"
 var weight=SmallCapsLabel.new().setup("%s drop weight"%MenuData.drop_percent(tier),13,FogPalette.MEMO_INK_SOFT,600,0.18);weight.name="DropWeight";names.add_child(weight)
 var effect=memo.memo_label(MenuData.effect_text("items",e),20,Color("2E2A22"));effect.name="Effect"
 var gem=MenuData.item_gem(id)
 if gem!="":
  var box=DashedPanel.new();box.name="GemNeeded";box.line_color=MenuData.GEM_ON_PAPER[gem]
  var bs=FogTheme.flat(Color(0,0,0,0));bs.content_margin_left=12;bs.content_margin_right=12;bs.content_margin_top=10;bs.content_margin_bottom=10;box.add_theme_stylebox_override("panel",bs)
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(row)
  var diamond=Control.new();diamond.custom_minimum_size=Vector2(18,18);diamond.size_flags_vertical=Control.SIZE_SHRINK_CENTER;var gem_color: Color=MenuData.GEM_ON_PAPER[gem]
  diamond.draw.connect(func():diamond.draw_colored_polygon(PackedVector2Array([Vector2(9,1),Vector2(17,9),Vector2(9,17),Vector2(1,9)]),gem_color));row.add_child(diamond)
  var need=memo.memo_label("Does nothing until you own the %s socket gem."%gem.capitalize(),16,Color("2E2A22"),row);need.name="GemText"
  b.add_child(box)
 if unique:
  var holder=Control.new();holder.custom_minimum_size=Vector2(0,44);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(holder)
  var stamp=MenuStyle.spawn("stamp") as Stamp;stamp.name="Unique";stamp.setup("Unique · once per run",MenuData.UNIQUE_INK,16,0.24,3,-3.0,Color(0,0,0,0),Vector2(12,5));stamp.position=Vector2(4,6);holder.add_child(stamp)
 dashed_rule(b)
 var spacer=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;b.add_child(spacer)
 add_footer(e,"Appears in vases, chests and shops")
