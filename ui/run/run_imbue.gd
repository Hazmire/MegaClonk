class_name RunImbue
extends RunPanelScreen
# RunImbue: the Imbue Station. Three steps on one page: 1 pick up a gem, 2 pick an open socket on a weapon that can take it, 3 confirm and
# fuse. Cost, gems, sockets and the "different element" rule all come from ImbueRules / WeaponSockets; installing goes through
# ImbueRules.install() (atomic) and the Imbued Amulet through GemRewards.use_amulet().
const FUSE_TIME=0.9
var object: Dictionary={}
var data: Dictionary={}
var held=""
var target_weapon=-1
var target_slot=-1
var phase="idle" # idle | poor | confirm | fusing | done
var phase_time=0.0
var done_text=""
var done_color=Color.WHITE
var just_fused_weapon=-1
var tiles={}
var slots={}
var action_box: Control
var dynamic: Control
var leave_button: MenuItem
var fuse_button: MenuItem
var cancel_button: MenuItem
func build() -> void:
 build_panels();build_status();build_section();build_dynamic()
 set_hints([["←→↑↓","Move","D-PAD"],["ENTER","Select","A"],["ESC","Leave","B"]])
func build_dynamic() -> void:
 data=RunData.imbue(game)
 if dynamic!=null:
  content.remove_child(dynamic);dynamic.queue_free();tiles.clear();slots.clear()
 dynamic=Control.new();dynamic.name="Imbue";dynamic.position=Vector2(572,182);dynamic.size=Vector2(776,806);dynamic.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(dynamic)
 var head=Control.new();head.name="Header";head.size=Vector2(776,110);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;dynamic.add_child(head)
 head.add_child(SmallCapsLabel.new().setup("Imbue station",14,Color("A9ADA4"),800,0.3))
 var title=MenuStyle.label("Socket a gem",MenuStyle.serif(),52,FogPalette.BONE,0,head);title.name="Title";title.position=Vector2(0,22)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(0,94);rule.size=Vector2(48,5);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(rule)
 var price=MenuStyle.label("%d gold per gem %s permanent"%[data.cost,"·"],MenuStyle.sans(800,0.2,14),14,Color("A9ADA4"),0,head);price.name="Price";price.position=Vector2(396,32);price.size=Vector2(380,20);price.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var have=MenuStyle.label("You have %d"%data.gold,MenuStyle.sans(800,0.2,14),14,Color("9BC48A") if data.gold>=data.cost else Color("E07B83"),0,head);have.name="YouHave";have.position=Vector2(396,56);have.size=Vector2(380,20);have.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var step=1 if held=="" else (3 if phase in ["confirm","fusing"] else 2)
 _step_label("1 · Pick up a gem",1,step,Vector2(0,126))
 var tray=Control.new();tray.name="Tray";tray.position=Vector2(0,154);tray.size=Vector2(776,110);tray.mouse_filter=Control.MOUSE_FILTER_IGNORE;dynamic.add_child(tray)
 for i in data.tray.size():
  var d: Dictionary=data.tray[i];var t=GemTile.new().setup(d);t.position=Vector2(i*198,0);tray.add_child(t);tiles[str(d.element)]=t
  t.set_state(held==str(d.element),held!="" and held!=str(d.element))
  t.pressed.connect(func():pick_gem(str(d.element)))
 _step_label("2 · Click a glowing socket",2,step,Vector2(0,284))
 var rows=Control.new();rows.name="Weapons";rows.position=Vector2(0,312);rows.size=Vector2(776,390);rows.mouse_filter=Control.MOUSE_FILTER_IGNORE;dynamic.add_child(rows)
 for i in data.weapons.size():_weapon_row(rows,data.weapons[i],i)
 if data.weapons.is_empty():MenuStyle.label("You have no weapons.",MenuStyle.sans(400,0,17),17,Color("B9BAB1"),0,rows)
 _step_label("3 · Fuse",3,step,Vector2(0,704))
 action_box=Control.new();action_box.name="Action";action_box.position=Vector2(0,732);action_box.size=Vector2(776,70);action_box.mouse_filter=Control.MOUSE_FILTER_IGNORE;dynamic.add_child(action_box)
 _build_action()
 leave_button=MenuStyle.spawn("menu_item") as MenuItem;leave_button.name="Leave";leave_button.setup("Leave",26,26).make_primary("ESC",60,26);leave_button.size=Vector2(200,48);leave_button.position=Vector2(576,810);leave_button.indent=44.0
 leave_button.chosen.connect(func():game.resume());dynamic.add_child(leave_button)
 leave_button.visible=phase!="fusing"
 _wire_focus()
func _step_label(text: String,n: int,current: int,pos: Vector2) -> void:
 var l=MenuStyle.label(text.to_upper(),MenuStyle.sans(800,0.28,14),14,Color("E8E2D0") if n==current else Color("6E726A"),0,dynamic);l.name="Step%d"%n;l.position=pos
func _weapon_row(parent: Control,w: Dictionary,i: int) -> void:
 var row=Control.new();row.name="Weapon_%d"%w.id;row.position=Vector2(0,i*98);row.size=Vector2(776,90);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(row)
 var is_target=int(w.id)==target_weapon
 row.draw.connect(func():
  row.draw_rect(Rect2(Vector2.ZERO,row.size),Color("1E1A1A") if is_target else Color("1A1C19"));row.draw_rect(Rect2(Vector2.ZERO,row.size),FogPalette.RUST_BRIGHT if is_target else Color("3A3D38"),false,2.0 if is_target else 1.0))
 var tex=UIAssets.icon("weapons",str(w.id));var ic=TextureRect.new();ic.texture=tex;ic.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;ic.position=Vector2(14,13);ic.size=Vector2(64,64);ic.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(ic)
 var nm=MenuStyle.label("%s"%w.name,MenuStyle.serif(),26,FogPalette.BONE,0,row);nm.position=Vector2(94,10)
 var lv=MenuStyle.label("LV %d"%w.level,MenuStyle.sans(800,0.2,12),12,FogPalette.GOLD,0,row);lv.position=Vector2(94,46)
 var sub="Sockets %d/%d%s"%[w.used,w.open,(" · "+w.combo) if w.combo!="" else (" · amulets %d"%data.amulets if w.can_unlock_second else "")]
 var sl=MenuStyle.label(sub,MenuStyle.sans(400,0,13),13,Color("A9ADA4"),0,row);sl.position=Vector2(94,66);sl.size=Vector2(250,18)
 sl.clip_text=true;sl.tooltip_text=sub
 for s in w.sockets.size():
  var slot=SocketSlot.new().setup("Slot_%d_%d"%[w.id,s]);slot.position=Vector2(776-2*208+8+s*208-0.0,13);slot.position.x=776.0-(2.0-float(s))*208.0+4.0;slot.position.y=13.0;row.add_child(slot);slots[slot.name]=slot
  _style_slot(slot,w,s)
  var wid=int(w.id);var si=s
  slot.pressed.connect(func():pick_socket(wid,si))
func _style_slot(slot: SocketSlot,w: Dictionary,s: int) -> void:
 var sk: Dictionary=w.sockets[s]
 if just_fused_weapon==int(w.id) and sk.kind=="gem":slot.justfused=true
 match str(sk.kind):
  "gem":slot.set_state("gem",Elements.color(str(sk.element)),str(sk.name))
  "locked":
   var can=data.amulets>0 and w.can_unlock_second and (s==w.used or true)
   slot.set_state("locked",Color.WHITE,"Use amulet" if can else "Amulet");slot.disabled=not can
   slot.tooltip_text="Permanently adds a second socket to this weapon. Two different elements form a combination." if can else "Second socket: needs an Imbued Amulet (you have %d)"%data.amulets
  _:
   if held=="":slot.set_state("empty",Color.WHITE,"")
   else:
    var problem=ImbueRules.problem_for_slot(game,int(w.id),held)
    var col=Elements.color(held)
    if problem=="" or problem=="insufficient_gold":
     slot.set_state("target" if int(w.id)==target_weapon and s==target_slot else "ready",col,"")
    else:slot.set_state("blocked",col,"",ImbueRules.reason_text(problem));slot.disabled=false
func _build_action() -> void:
 for c in action_box.get_children():action_box.remove_child(c);c.queue_free()
 fuse_button=null;cancel_button=null
 var panel=Control.new();panel.size=action_box.size;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;action_box.add_child(panel)
 var bcol=FogPalette.RUST_BRIGHT if phase=="confirm" else (Elements.color(held) if phase=="fusing" and held!="" else Color("3A3D38"))
 panel.draw.connect(func():panel.draw_rect(Rect2(Vector2.ZERO,panel.size),Color("121311"));panel.draw_rect(Rect2(Vector2.ZERO,panel.size),bcol,false,2.0))
 var f=MenuStyle.sans(400,0,17)
 match phase:
  "confirm":
   var g=Elements.display_name(held);var wn=weapon_name(target_weapon)
   var q=MenuStyle.label("Fuse %s into %s?"%[g,wn],MenuStyle.serif(),26,FogPalette.BONE,0,panel);q.name="Question";q.position=Vector2(20,6)
   # What the gem does (and the combination it completes with the weapon's other gem), then the price.
   var q_y=2.0;q.position=Vector2(20,q_y)
   var fx=MenuStyle.label(Elements.short_summary(held),MenuStyle.sans(400,0,13),13,Elements.color(held),0,panel);fx.name="Effect";fx.position=Vector2(20,34);fx.size=Vector2(396,16);fx.clip_text=true;fx.tooltip_text=Elements.summary(held)
   var combo_text="";for w in data.weapons:
    if int(w.id)==target_weapon:
     for sk in w.sockets:
      if sk.kind=="gem" and combo_text=="":combo_text=Elements.combo_summary(held,str(sk.element))
   var sm_text=("With %s — %s"%[combo_text.get_slice(":",0),combo_text.get_slice(":",1).strip_edges()]) if combo_text!="" else "−%d gold · −1 gem · can't be undone"%data.cost
   var sm=MenuStyle.label(sm_text,MenuStyle.sans(400,0,12),12,FogPalette.GOLD if combo_text!="" else Color("B9BAB1"),0,panel);sm.name="Detail";sm.position=Vector2(20,51);sm.size=Vector2(396,16);sm.clip_text=true;sm.tooltip_text=sm_text
   cancel_button=MenuStyle.spawn("menu_item") as MenuItem;cancel_button.name="Cancel";cancel_button.setup("Cancel",20,20);cancel_button.size=Vector2(130,52);cancel_button.position=Vector2(420,9);cancel_button.indent=18.0;cancel_button.chosen.connect(cancel);panel.add_child(cancel_button)
   fuse_button=MenuStyle.spawn("menu_item") as MenuItem;fuse_button.name="Fuse";fuse_button.setup("Fuse",28,28).make_primary("ENTER",60,28);fuse_button.size=Vector2(200,52);fuse_button.position=Vector2(560,9);fuse_button.indent=44.0;fuse_button.chosen.connect(fuse);panel.add_child(fuse_button)
  "fusing":
   var t=MenuStyle.label("FUSING %s INTO %s…"%[Elements.display_name(held).to_upper(),weapon_name(target_weapon).to_upper()],MenuStyle.sans(800,0.2,15),15,Elements.color(held),0,panel);t.position=Vector2(20,10)
   var bar=Control.new();bar.name="Progress";bar.position=Vector2(20,40);bar.size=Vector2(736,10);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(bar);var col=Elements.color(held)
   bar.draw.connect(func():bar.draw_rect(Rect2(Vector2.ZERO,bar.size),Color("2A2C28"));bar.draw_rect(Rect2(Vector2.ZERO,Vector2(bar.size.x*clampf(phase_time/FUSE_TIME,0.0,1.0),bar.size.y)),col))
   fuse_bar=bar
  "done":
   var l=MenuStyle.label("%s now runs through your %s."%[done_text.get_slice("|",0),done_text.get_slice("|",1)],MenuStyle.serif(),24,done_color,0,panel);l.name="Done";l.position=Vector2(20,6)
   var el=Elements.IDS[0];for e in Elements.IDS:
    if Elements.display_name(e)==done_text.get_slice("|",0):el=e
   var dd=MenuStyle.label(Elements.short_summary(el),MenuStyle.sans(400,0,13),13,Color("B9BAB1"),0,panel);dd.name="DoneEffect";dd.position=Vector2(20,44)
  "poor":
   var l=MenuStyle.label("Not enough gold — fusing costs %d and you have %d."%[data.cost,data.gold],f,18,Color("E07B83"),0,panel);l.name="Poor";l.position=Vector2(20,20)
  _:
   var any_empty=data.weapons.any(func(w):return w.sockets.any(func(s):return s.kind=="empty"))
   var any_gems=data.tray.any(func(g):return g.count>0)
   var txt="Pick up a gem to see where it can go."
   if not any_empty:txt="Every open socket is filled. Find an imbued amulet to open a second one."
   elif not any_gems:txt="No gems left. Buy socket gems from shops."
   elif held!="":txt="%s gem in hand — %s"%[Elements.display_name(held),Elements.short_summary(held)]
   var l=MenuStyle.label(txt,f,18,Color("B9BAB1"),0,panel);l.name="Idle";l.position=Vector2(20,20)
func weapon_name(id: int) -> String:
 for w in data.weapons:
  if int(w.id)==id:return str(w.name)
 return ""
func _wire_focus() -> void:
 var order=[]
 for e in Elements.IDS:order.append(tiles[e])
 var first_focus: Control=null
 for e in Elements.IDS:
  if int(data.tray[Elements.IDS.find(e)].count)>0:first_focus=tiles[e];break
 var last: Control=leave_button
 if fuse_button!=null:last=fuse_button
 for k in order.size():
  var t: Control=order[k];t.focus_neighbor_left=t.get_path_to(order[maxi(0,k-1)]);t.focus_neighbor_right=t.get_path_to(order[mini(order.size()-1,k+1)])
 if fuse_button!=null:
  fuse_button.focus_neighbor_left=fuse_button.get_path_to(cancel_button);cancel_button.focus_neighbor_right=cancel_button.get_path_to(fuse_button)
  fuse_button.focus_neighbor_bottom=fuse_button.get_path_to(leave_button);cancel_button.focus_neighbor_bottom=cancel_button.get_path_to(leave_button)
  fuse_button.focus_neighbor_top=fuse_button.get_path_to(first_slot());cancel_button.focus_neighbor_top=cancel_button.get_path_to(first_slot())
  leave_button.focus_neighbor_top=leave_button.get_path_to(fuse_button)
 if target_weapon>=0 and fuse_button!=null:focus_later(fuse_button)
 elif held!="" and tiles.has(held):focus_later(tiles[held])
 elif first_focus!=null:focus_later(first_focus)
 else:focus_later(leave_button)
func first_slot() -> Control:
 for k in slots:return slots[k]
 return leave_button
func pick_gem(element: String) -> void:
 if phase=="fusing":return
 if int(game.gems.count(element))<1:return
 held="" if held==element else element;target_weapon=-1;target_slot=-1;phase="idle";just_fused_weapon=-1;build_dynamic()
 if held!="":MenuScreen.sfx("gem_pickup")
func pick_socket(weapon: int,slot: int) -> void:
 if phase=="fusing":return
 for w in data.weapons:
  if int(w.id)!=weapon:continue
  var sk: Dictionary=w.sockets[slot]
  if sk.kind=="locked":
   var used=GemRewards.use_amulet(game,weapon)
   if used.ok:MenuScreen.sfx("socket_place");game.toast("%s gained a second socket"%w.name)
   else:game.toast(ImbueRules.reason_text(str(used.reason)))
   build_dynamic();return
  if sk.kind!="empty" or held=="":return
  var problem=ImbueRules.problem_for_slot(game,weapon,held)
  if problem=="insufficient_gold":phase="poor";target_weapon=-1;build_dynamic();return
  if problem!="":game.toast(ImbueRules.reason_text(problem));return
  MenuScreen.sfx("socket_place");target_weapon=weapon;target_slot=slot;phase="confirm";build_dynamic();return
func cancel() -> void:
 target_weapon=-1;target_slot=-1;phase="idle";build_dynamic()
func fuse() -> void:
 if phase!="confirm" or held=="" or target_weapon<0:return
 var element=held;var wid=target_weapon;var price=int(data.cost)
 var result=ImbueRules.install(game,wid,element)
 if not result.ok:
  game.toast(ImbueRules.reason_text(str(result.reason)));phase="idle";target_weapon=-1;build_dynamic();return
 game.play_sound(fuse_event(wid,element));done_text="%s|%s"%[Elements.display_name(element),weapon_name(wid)];done_color=Elements.color(element)
 phase="fusing";phase_time=0.0;just_fused_weapon=wid;target_slot=-1;_build_action();leave_button.hide()
 spent=price
var spent=0
# First gem: imbue_fuse_<element>; the second gem of a weapon completes a combo and plays imbue_combo_<combo> instead.
func fuse_event(wid: int,element: String) -> String:
 var combo=WeaponSockets.combo(game.weapons[wid])
 if not combo.is_empty():return "imbue.imbue_combo_"+str(combo.id)
 return "imbue.imbue_fuse_"+RetroAudio.element_id(element)
var fuse_bar: Control
func finish_fuse() -> void:
 phase="done";held="";target_weapon=-1;phase_time=0.0
 var strip=content.get_node_or_null("Status")
 if strip!=null:content.remove_child(strip);strip.queue_free()
 build_status();inventory_panel.refresh();build_dynamic()
 var float_label=MenuStyle.label("−%d"%spent,MenuStyle.sans(800,0,22),22,Color("E07B83"),0,content);float_label.name="Spent";float_label.position=Vector2(560,40)
 var tw=create_tween();tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);tw.tween_property(float_label,"position:y",0.0,1.2);tw.parallel().tween_property(float_label,"modulate:a",0.0,1.2);tw.tween_callback(float_label.queue_free)
func _process(delta: float) -> void:
 if phase=="fusing":
  phase_time+=delta
  if is_instance_valid(fuse_bar):fuse_bar.queue_redraw()
  if phase_time>=FUSE_TIME:finish_fuse()
