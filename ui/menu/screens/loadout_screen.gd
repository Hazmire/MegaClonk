class_name LoadoutScreen
extends MenuScreen
# Fog-Loadout "Prepare your run": Weapon / Trait / Ultimate slots with dropdowns, the destination sign, Enter / Back
# and the Personal bests memo. All values come from the catalogues (WeaponStats.resolve for weapon numbers).
const CATEGORIES=[["weapons","Weapon"],["traits","Trait"],["ultimates","Ultimate"]]
var slots: Dictionary={}
var dropdown: SlotDropdown
var enter_button: MenuItem
var back_button: MenuItem
var resume_button: MenuItem
var bests: MemoCard
var open_category=""
func _init() -> void:
 super._init();backdrop_kind="world";right_dark=true;left_stop=0.52
func selected_id(category: String) -> String:
 match category:
  "weapons":return str(game.selected_weapon)
  "traits":return String(game.selected_trait)
 return String(game.selected_ultimate)
# Option rows for a category: real catalogue entries, unlocked state from the profile, stats from the game's own numbers.
func options_for(category: String) -> Array:
 var list=[]
 for e in LoadoutCatalog.entries(category):
  var o={"id":String(e.id),"name":String(e.name),"category":category,"unlocked":MetaProgress.unlocked(game.progress.data,category,String(e.id)),"stats":"","tag":"All"}
  if category=="weapons":
   var r=WeaponStats.resolve(null,int(e.id),{})
   o["stats"]="%s · %d dmg · %.2fs"%[String(r.kind).capitalize(),int(round(r.damage)),r.interval];o["tag"]=MenuData.weapon_tag(e.id)
  elif category=="ultimates":
   o["stats"]="%ds cooldown"%int(e.cooldown)
  list.append(o)
 return list
func chips_for(category: String,id: String) -> Array:
 if category=="weapons":
  var r=WeaponStats.resolve(null,int(id),{})
  return [String(r.kind).to_upper(),"%d DMG"%int(round(r.damage)),"%.2fs CD"%r.interval]
 return []
func build() -> void:
 var column=VBoxContainer.new();column.name="Column";column.position=Vector2(120,80);column.size=Vector2(660,900);column.add_theme_constant_override("separation",28);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(column)
 var header=VBoxContainer.new();header.add_theme_constant_override("separation",12);header.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(header)
 header.add_child(MenuStyle.label("Prepare your run",MenuStyle.serif(),76,FogPalette.BONE,3))
 var sub=HBoxContainer.new();sub.add_theme_constant_override("separation",16);sub.mouse_filter=Control.MOUSE_FILTER_IGNORE;header.add_child(sub)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.custom_minimum_size=Vector2(48,6);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;sub.add_child(rule)
 sub.add_child(SmallCapsLabel.new().setup("One adventurer · one loadout",17,Color("A9ADA4"),600,0.3))
 var stack=VBoxContainer.new();stack.name="Slots";stack.add_theme_constant_override("separation",18);stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(stack)
 for pair in CATEGORIES:
  var block=VBoxContainer.new();block.add_theme_constant_override("separation",8);block.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(block)
  block.add_child(SmallCapsLabel.new().setup(pair[1],15,FogPalette.BONE if pair[0]=="weapons" else FogPalette.ASH_DIM,800,0.3))
  var slot=MenuStyle.spawn("loadout_slot") as LoadoutSlot;slot.setup(pair[0],pair[1]);block.add_child(slot);slots[pair[0]]=slot
  var cat: String=pair[0]
  slot.open_requested.connect(func():open_list(cat))
  slot.start_requested.connect(start_run)
  refresh_slot(cat)
 build_destination(column)
 var actions=VBoxContainer.new();actions.name="Actions";actions.add_theme_constant_override("separation",8);actions.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(actions)
 enter_button=MenuStyle.spawn("menu_item") as MenuItem;enter_button.setup("Enter the "+MenuData.stage_short(game.selected_biome)).make_primary("ENTER",80,42);enter_button.chosen.connect(start_run);actions.add_child(enter_button)
 if FileAccess.file_exists("user://active-run.json"):
  resume_button=MenuStyle.spawn("menu_item") as MenuItem;resume_button.setup("Resume saved run",32,32,false,Vector2(56,56));resume_button.chosen.connect(func():
   if not game.load_run():game.toast("Saved run could not be read"));actions.add_child(resume_button)
 back_button=MenuStyle.spawn("menu_item") as MenuItem;back_button.setup("Back",32,32,false,Vector2(56,56));back_button.hint_text="ESC";back_button.indent=60.0;back_button.chosen.connect(go_back);actions.add_child(back_button)
 build_bests()
 dropdown=MenuStyle.spawn("slot_dropdown") as SlotDropdown;dropdown.z_index=20;content.add_child(dropdown)
 dropdown.picked.connect(on_picked);dropdown.closed.connect(on_closed)
 set_hints([["↑↓","Slot","D-PAD"],["SPACE","Open list","A"],["ENTER","Start","START"]])
 focus_later(slots["weapons"])
func build_destination(column: VBoxContainer) -> void:
 var block=VBoxContainer.new();block.name="Destination";block.add_theme_constant_override("separation",8);block.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(block)
 block.add_child(SmallCapsLabel.new().setup("Destination",15,FogPalette.ASH_DIM,800,0.3))
 var outer=PanelContainer.new();outer.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;outer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var sign_style=FogTheme.flat(Color("1D5536"));sign_style.set_corner_radius_all(10);sign_style.set_content_margin_all(6);sign_style.shadow_color=Color(0,0,0,0.5);sign_style.shadow_size=1;sign_style.shadow_offset=Vector2(4,6)
 outer.add_theme_stylebox_override("panel",sign_style);block.add_child(outer)
 var inner=PanelContainer.new();inner.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var inner_style=FogTheme.flat(Color(0,0,0,0),Color("F4F1E8"),3);inner_style.set_corner_radius_all(6);inner_style.content_margin_left=20;inner_style.content_margin_right=26;inner_style.content_margin_top=14;inner_style.content_margin_bottom=12
 inner.add_theme_stylebox_override("panel",inner_style);outer.add_child(inner)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",22);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;inner.add_child(row)
 var arrow=SignArrow.new();arrow.custom_minimum_size=Vector2(40,40);arrow.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(arrow)
 var texts=VBoxContainer.new();texts.add_theme_constant_override("separation",4);texts.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(texts)
 var stage=MenuStyle.label(MenuData.stage_name(game.selected_biome),MenuStyle.sans(800,0.04,32),32,Color("F4F1E8"),0,texts);stage.name="StageName"
 var biome=SmallCapsLabel.new().setup(MenuData.biome_name(game.selected_biome),16,Color("CFE0D3"),600,0.3);biome.name="BiomeName";texts.add_child(biome)
func build_bests() -> void:
 bests=MenuStyle.spawn("memo_card") as MemoCard;bests.name="PersonalBests";bests.position=Vector2(MenuStyle.W-110-540,96);bests.custom_minimum_size.x=540;bests.size.x=540
 bests.tape_angle=-3.0;bests.set_look(1.2,Vector4(36,34,36,30));content.add_child(bests)
 var b=bests.body;b.add_theme_constant_override("separation",0)
 var title=bests.memo_label("PERSONAL BESTS",20);title.add_theme_font_override("font",MenuStyle.sans(800,0.3,20));title.name="Title"
 var records=MenuData.personal_bests(game.progress.data,5)
 if records.is_empty():
  var gap=Control.new();gap.custom_minimum_size.y=6;b.add_child(gap)
  var none=bests.memo_label("No runs yet",24);none.name="NoRuns"
  var hint=bests.memo_label("Your greatest runs will be recorded here.",15,Color("5A5446"));hint.name="NoRunsHint"
  return
 var note=bests.memo_label("Ranked by kills.",15,Color("5A5446"));note.add_theme_constant_override("line_spacing",0)
 var gap=Control.new();gap.custom_minimum_size.y=18;b.add_child(gap)
 b.add_child(bests_row(["#","KILLS · LOADOUT","TIME"],null,true,0))
 for i in records.size():
  b.add_child(bests_row([str(i+1),"%d kills"%int(records[i].kills),MenuData.clock(float(records[i].time))],records[i],false,i,i==records.size()-1))
func bests_row(cells: Array,record: Variant,header: bool,index: int,last: bool=false) -> Control:
 var holder=VBoxContainer.new();holder.name="Best_%d"%index if not header else "Header";holder.add_theme_constant_override("separation",0);holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var grid=HBoxContainer.new();grid.add_theme_constant_override("separation",12);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if not header:
  var pad=Control.new();pad.custom_minimum_size.y=14;holder.add_child(pad)
 holder.add_child(grid)
 if header:
  var f=MenuStyle.sans(800,0.2,13)
  var a=MenuStyle.label(cells[0],f,13,FogPalette.MEMO_INK_SOFT);a.custom_minimum_size.x=44;grid.add_child(a)
  var m=MenuStyle.label(cells[1],f,13,FogPalette.MEMO_INK_SOFT);m.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(m)
  var t=MenuStyle.label(cells[2],f,13,FogPalette.MEMO_INK_SOFT);t.custom_minimum_size.x=72;t.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;grid.add_child(t)
  var under=ColorRect.new();under.color=FogPalette.MEMO_INK;under.custom_minimum_size.y=2;var gap=Control.new();gap.custom_minimum_size.y=8;holder.add_child(gap);holder.add_child(under)
  return holder
 var rank=RankMark.new();rank.rank=index+1;rank.custom_minimum_size=Vector2(44,34);rank.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;grid.add_child(rank)
 var mid=VBoxContainer.new();mid.add_theme_constant_override("separation",4);mid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;mid.mouse_filter=Control.MOUSE_FILTER_IGNORE;grid.add_child(mid)
 for text_pair in [[cells[1],22,FogPalette.MEMO_INK],[loadout_line(record),15,FogPalette.MEMO_INK_SOFT]]:
  var l=MenuStyle.label(text_pair[0],MenuStyle.memo(),text_pair[1],text_pair[2]);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;mid.add_child(l)
 var time=MenuStyle.label(cells[2],MenuStyle.memo(),20,FogPalette.MEMO_INK);time.custom_minimum_size.x=72;time.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;grid.add_child(time)
 var bottom=Control.new();bottom.custom_minimum_size.y=14 if not last else 0;holder.add_child(bottom)
 if not last:holder.add_child(DashedRule.new())
 return holder
func loadout_line(record: Dictionary) -> String:
 var trait_name=LoadoutCatalog.entry("traits",str(record.trait)).get("name",record.trait)
 var ultimate_name=LoadoutCatalog.entry("ultimates",str(record.ultimate)).get("name",record.ultimate)
 return "%s — %s / %s"%[Catalog.weapon_name(int(record.weapon)),trait_name,ultimate_name]
func refresh_slot(category: String) -> void:
 var id=selected_id(category)
 var entry=LoadoutCatalog.entry(category,id)
 if entry.is_empty():entry=LoadoutCatalog.entries(category)[0]
 slots[category].show_entry(entry,chips_for(category,String(entry.id)),String(entry.description))
func open_list(category: String) -> void:
 if dropdown.visible and open_category==category:dropdown.close();return
 if dropdown.visible:dropdown.close()
 open_category=category
 var slot: LoadoutSlot=slots[category]
 var inverse=content.get_global_transform().affine_inverse()
 var top_left=inverse*slot.get_global_position()
 dropdown.position=top_left+Vector2(0,104);dropdown.size=Vector2(660,0);dropdown.custom_minimum_size.x=660
 slot.set_open(true)
 dropdown.open(options_for(category),selected_id(category),MenuData.TAG_ORDER if category=="weapons" else [])
func on_closed() -> void:
 if slots.has(open_category):
  slots[open_category].set_open(false);slots[open_category].grab_focus()
func on_picked(id: String) -> void:
 match open_category:
  "weapons":game.selected_weapon=int(id)
  "traits":game.selected_trait=id
  _:game.selected_ultimate=id
 game.progress.data.loadout={"weapon":game.selected_weapon,"trait":game.selected_trait,"ultimate":game.selected_ultimate};game.progress.save()
 refresh_slot(open_category)
func start_run() -> void:
 game.selected_biome=0;game.selected_tier=1;game.sandbox=false;sfx("confirm");game.begin_run()
func go_back() -> void:
 if dropdown!=null and dropdown.visible:dropdown.close();return
 navigate(frontend.home)
func _input(event: InputEvent) -> void:
 super._input(event)
 if dropdown!=null and dropdown.visible and event is InputEventMouseButton and event.pressed:
  var local=dropdown.get_global_transform().affine_inverse()*event.position
  var slot_hit=slots[open_category].get_global_rect().has_point(event.position)
  if not Rect2(Vector2.ZERO,dropdown.size).has_point(local) and not slot_hit:dropdown.close()
class SignArrow extends Control:
 func _draw() -> void:
  var c=Color("F4F1E8");draw_line(Vector2(20,38),Vector2(20,8),c,4.0);draw_polyline(PackedVector2Array([Vector2(8,20),Vector2(20,8),Vector2(32,20)]),c,4.0)
class RankMark extends Control:
 var rank=1
 func _draw() -> void:
  var f=MenuStyle.memo()
  if rank==1:
   draw_arc(Vector2(17,15),16.0,0,TAU,32,MenuStyle.SILVER_RUST,2.0)
   var s=f.get_string_size("1",HORIZONTAL_ALIGNMENT_LEFT,-1,18)
   draw_string(f,Vector2(17-s.x*0.5,15+f.get_ascent(18)*0.5-1),"1",HORIZONTAL_ALIGNMENT_LEFT,-1,18,MenuStyle.SILVER_RUST)
  else:
   draw_string(f,Vector2(11,22),str(rank),HORIZONTAL_ALIGNMENT_LEFT,-1,18,FogPalette.MEMO_INK)
class DashedRule extends Control:
 func _init() -> void:custom_minimum_size.y=1;mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var x=0.0
  while x<size.x:draw_rect(Rect2(x,0,4,1),Color("8F876F"));x+=7.0
