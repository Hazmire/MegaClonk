class_name RunShop
extends RunPanelScreen
# RunShop: a seller's stock with the Inventory panel on the left and the Stats panel on the right. The title names the shop type
# (Standard / Rare / Legendary) and the frame follows it. Hovering or focusing a row previews what it would do to the stats.
# Prices come from ShopSystem / Economy; buying goes through the same game calls as before (one purchase per seller).
var object: Dictionary={}
var rows_data: Array=[]
var rows: Array=[]
var leave_button: MenuItem
var gold_value: HudNumber
func build() -> void:
 rows_data=RunData.shop_rows(game,object)
 build_panels();build_status();build_section()
 var type_name=Economy.shop_display_name(str(object.get("tier","Common")))
 var frame=shop_color(str(object.get("tier","Common")))
 var head=Control.new();head.name="Header";head.position=Vector2(572,182);head.size=Vector2(776,110);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(head)
 head.add_child(SmallCapsLabel.new().setup("Shop · One purchase per seller",14,Color("A9ADA4"),800,0.3))
 var title=MenuStyle.label("%s shop"%type_name,MenuStyle.serif(),52,FogPalette.BONE,0,head);title.name="Title";title.position=Vector2(0,22)
 var rule=ColorRect.new();rule.color=frame;rule.position=Vector2(0,94);rule.size=Vector2(48,5);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(rule)
 var box=Control.new();box.name="YourGold";box.size=Vector2(190,70);box.position=Vector2(776-190,0);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(box)
 box.draw.connect(func():box.draw_rect(Rect2(Vector2.ZERO,box.size).grow(-0.5),frame,false,1.0))
 var cap=SmallCapsLabel.new().setup("Your gold",12,Color("A9ADA4"),600,0.26);cap.position=Vector2(0,8);cap.size=Vector2(174,16);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;box.add_child(cap)
 gold_value=HudNumber.new().setup(game.gold,30,FogPalette.BONE_BRIGHT);gold_value.position=Vector2(0,26);gold_value.size=Vector2(174,38);gold_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;box.add_child(gold_value)
 var list=VBoxContainer.new();list.name="Offers";list.position=Vector2(572,316);list.size=Vector2(776,560);list.add_theme_constant_override("separation",18);list.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(list)
 for i in rows_data.size():
  var row=ShopRow.new().setup(rows_data[i],i);list.add_child(row);rows.append(row)
  row.buy_requested.connect(func():buy(i));row.denied.connect(func():deny(i))
  row.focus_entered.connect(func():preview(i))
 if rows_data.is_empty():
  var none=MenuStyle.label("No enabled items available",MenuStyle.sans(400,0,18),18,FogPalette.ASH_FAINT,0,list);none.name="Empty"
 leave_button=MenuStyle.spawn("menu_item") as MenuItem;leave_button.setup("Leave shop",32,32,false,Vector2(64,64));leave_button.hint_text="ESC";leave_button.outlined=true;leave_button.indent=26.0
 leave_button.position=Vector2(572,860);leave_button.size=Vector2(776,64);content.add_child(leave_button);leave_button.chosen.connect(game.resume)
 wire_focus()
 set_hints([["↑↓","Offer","D-PAD"],["ENTER","Buy","A"],["ESC","Leave","B"]])
 if not rows.is_empty():focus_later(first_buyable())
 else:focus_later(leave_button)
static func shop_color(tier_name: String) -> Color:
 match tier_name:
  "Rare":return FogPalette.RARITY[FogPalette.Rarity.RARE]["color"]
  "Legendary":return FogPalette.RARITY[FogPalette.Rarity.LEGENDARY]["color"]
 return FogPalette.RUST
func first_buyable() -> Control:
 for r in rows:
  if r.can_buy():return r
 return rows[0]
func wire_focus() -> void:
 for i in rows.size():
  var r: Control=rows[i]
  r.focus_neighbor_top=r.get_path_to(rows[maxi(0,i-1)]);r.focus_neighbor_bottom=r.get_path_to(rows[i+1] if i+1<rows.size() else leave_button);r.focus_neighbor_left=r.get_path_to(r);r.focus_neighbor_right=r.get_path_to(r)
 leave_button.focus_neighbor_top=leave_button.get_path_to(rows[rows.size()-1] if not rows.is_empty() else leave_button);leave_button.focus_neighbor_bottom=leave_button.get_path_to(leave_button)
func preview(i: int) -> void:
 stats_panel.clear_preview()
 if i>=0 and i<rows_data.size() and not rows_data[i].preview.is_empty():stats_panel.preview_many(rows_data[i].preview)
func buy(i: int) -> void:
 var d: Dictionary=rows_data[i]
 if d.kind=="gem":
  if not GemRewards.buy_offer(game,object,int(d.code)).ok:game.toast("Purchase unavailable")
  return
 if not game.buy_shop(object,d.id,int(d.price)):game.toast("Purchase unavailable")
func deny(_i: int) -> void:
 MenuScreen.sfx("deny")
func _unhandled_input(event: InputEvent) -> void:
 super._unhandled_input(event)
 if event is InputEventKey and event.pressed and not event.echo:
  var n=event.keycode-KEY_1
  if n>=0 and n<rows.size():rows[n].grab_focus();get_viewport().set_input_as_handled()
