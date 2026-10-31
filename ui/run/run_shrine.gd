class_name RunShrine
extends RunPanelScreen
# RunShrine: choose 1 of 3 permanent stat boosts, each rolled at a rarity by ShrineRewards. The three cards are the real choices of the
# active shrine reward; focusing one previews "old → new" on the Stats panel; taking one goes through ShrineRewards.select().
var reward: Dictionary={}
var cards_data: Array=[]
var cards: Array=[]
var accept: MenuItem
func build() -> void:
 cards_data=RunData.shrine_cards(reward)
 build_panels();build_status();build_section()
 var golden=bool(reward.get("golden",false))
 var head=Control.new();head.name="Header";head.position=Vector2(572,182);head.size=Vector2(776,110);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(head)
 head.add_child(SmallCapsLabel.new().setup("Golden shrine" if golden else "Shrine",14,FogPalette.GOLD if golden else Color("A9ADA4"),800,0.3))
 var title=MenuStyle.label("Choose one stat",MenuStyle.serif(),52,FogPalette.BONE,0,head);title.name="Title";title.position=Vector2(0,22)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(0,94);rule.size=Vector2(48,5);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(rule)
 var note=MenuStyle.label("Permanent for this run.",MenuStyle.sans(400,0,17),17,Color("B9BAB1"),0,head);note.position=Vector2(776-220,34);note.size=Vector2(220,24);note.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var list=VBoxContainer.new();list.name="Choices";list.position=Vector2(572,330);list.size=Vector2(776,500);list.add_theme_constant_override("separation",22);list.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(list)
 for i in cards_data.size():
  var card=ShrineCard.new().setup(cards_data[i],i);list.add_child(card);cards.append(card)
  card.pressed.connect(func():take(i));card.focus_entered.connect(func():select(i))
 var foot=Control.new();foot.name="Footer";foot.position=Vector2(572,850);foot.size=Vector2(776,138);foot.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(foot)
 accept=MenuStyle.spawn("menu_item") as MenuItem;accept.setup("Accept",36,36).make_primary("ENTER",72,36);accept.size=Vector2(776,72);accept.position=Vector2(0,66);accept.indent=60.0;foot.add_child(accept)
 if cards.is_empty():
  var none=MenuStyle.label("All eligible stats are capped. No invalid upgrade has been generated.",MenuStyle.sans(400,0,18),18,Color("B9BAB1"),0,content);none.name="Capped";none.position=Vector2(572,340)
  accept.label_text="Continue";accept.chosen.connect(func():game.active_shrine_reward={};game.resume())
  focus_later(accept)
 else:
  MenuStyle.label("Preview shown in Stats →",MenuStyle.sans(400,0,15),15,Color("8D9188"),0,foot).position=Vector2(0,30)
  accept.chosen.connect(func():take(selected_index()))
  for i in cards.size():
   var c: Control=cards[i];c.focus_neighbor_top=c.get_path_to(cards[maxi(0,i-1)]);c.focus_neighbor_bottom=c.get_path_to(cards[i+1] if i+1<cards.size() else accept);c.focus_neighbor_left=c.get_path_to(c);c.focus_neighbor_right=c.get_path_to(c)
  accept.focus_neighbor_top=accept.get_path_to(cards[cards.size()-1]);accept.focus_neighbor_bottom=accept.get_path_to(accept)
  select(0);focus_later(cards[0])
 set_hints([["↑↓","Choose","D-PAD"],["1–3","Select"],["ENTER","Accept","A"]])
func selected_index() -> int:
 for i in cards.size():
  if cards[i].has_focus():return i
 return 0
func select(i: int) -> void:
 if i<0 or i>=cards_data.size():return
 var d: Dictionary=cards_data[i]
 if accept!=null:accept.label_text="Accept: %s %s"%[d.stat_name,d.bonus];accept.queue_redraw()
 stats_panel.preview(str(d.stat),float(d.before),float(d.after))
var taken=false
func take(i: int) -> void:
 if taken or i<0 or i>=cards_data.size() or not is_same(game.active_shrine_reward,reward):return
 taken=true
 ShrineRewards.select(game,i)
func _unhandled_input(event: InputEvent) -> void:
 super._unhandled_input(event)
 if event is InputEventKey and event.pressed and not event.echo:
  var n=event.keycode-KEY_1
  if n>=0 and n<cards.size():cards[n].grab_focus();get_viewport().set_input_as_handled()
