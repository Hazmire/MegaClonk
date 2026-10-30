class_name RunChest
extends MenuScreen
# RunChest: the treasure chest. The item is already decided and in the bag when this opens (RewardDrops/grant_item); the screen is the
# show: chest wobbles -> Open chest -> jump (0.65 s) -> the reel turns for 6 s -> lands (1 s, marker blinks, screen shakes) -> the
# reveal card. Holding Enter / a click / Space skips ahead; ui.chest_skip does the same. Reduced motion goes straight to the reveal.
const OPEN_TIME=0.65
const SPIN_TIME=6.0
const LAND_TIME=1.0
var item_id=""
var info: Dictionary={}
const REVEAL_EVENTS=["ui.reveal_common","ui.reveal_uncommon","ui.reveal_rare","ui.reveal_epic","ui.reveal_legendary"]
var phase="closed"
var phase_time=0.0
var chest_sprite: TextureRect
var beam: Control
var reel: ChestReel
var reel_panel: Control
var open_group: Control
var open_button: MenuItem
var wait_label: Label
var headline: Label
var chests_value: HudNumber
var shake_root: Control
var reveal_layer: Control
var card: ChestCard
var take_button: MenuItem
var fx: ChestFx
var flash: ColorRect
var hold=0.0
var armed=false
var gem_found=""
func build() -> void:
 info=RunData.chest_data(game,item_id);gem_found=game.chest_gem;game.chest_gem=""
 allow_back=false
 shake_root=Control.new();shake_root.name="Shake";shake_root.size=Vector2(1920,1080);shake_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(shake_root)
 build_status();build_title();build_chest();build_reel();build_open()
 reveal_layer=Control.new();reveal_layer.name="Reveal";reveal_layer.size=Vector2(1920,1080);reveal_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;reveal_layer.hide();content.add_child(reveal_layer)
 frontend.chest_skip=skip
 set_hints([["ENTER","Open chest","A"]])
 focus_later(open_button)
 if game.settings.reduced:go_reveal()
func build_status() -> void:
 var row=HBoxContainer.new();row.name="Status";row.position=Vector2(72,36);row.add_theme_constant_override("separation",48);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;shake_root.add_child(row)
 var t=int(game.elapsed)
 for pair in [["LVL",str(game.level),FogPalette.GOLD],["GOLD",str(game.gold),FogPalette.BONE_BRIGHT],["CHESTS",str(game.chests_opened),FogPalette.BONE_BRIGHT],["TIME","%02d:%02d"%[t/60,t%60],FogPalette.BONE_BRIGHT]]:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(cell)
  MenuStyle.label(pair[0],MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);var n=HudNumber.new().setup(pair[1],32,pair[2],3);cell.add_child(n)
  if pair[0]=="CHESTS":chests_value=n
  if pair[0]=="TIME":MenuStyle.label("PAUSED",MenuStyle.sans(800,0.3,13),13,FogPalette.GOLD,0,cell)
func build_title() -> void:
 var caption=SmallCapsLabel.new().setup("Treasure chest",15,Color("A9ADA4"),800,0.4);caption.name="Caption";caption.position=Vector2(0,112);caption.size=Vector2(1920,22);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shake_root.add_child(caption)
 headline=MenuStyle.label("A chest, half-buried in the mud",MenuStyle.serif(),56,FogPalette.BONE,3,shake_root);headline.name="Headline";headline.position=Vector2(0,142);headline.size=Vector2(1920,70);headline.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func build_chest() -> void:
 beam=Control.new();beam.name="Beam";beam.position=Vector2(860,150);beam.size=Vector2(200,330);beam.mouse_filter=Control.MOUSE_FILTER_IGNORE;beam.modulate.a=0.0;shake_root.add_child(beam)
 beam.draw.connect(func():
  for i in 30:
   var k=float(i)/30.0;beam.draw_rect(Rect2(Vector2(0,beam.size.y*k),Vector2(beam.size.x,beam.size.y/30.0+1.0)),Color(0.95,0.76,0.3,0.55*pow(k,1.6))))
 chest_sprite=TextureRect.new();chest_sprite.name="Chest";chest_sprite.texture=load("res://assets/icons/misc/chest_closed.png");chest_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;chest_sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;chest_sprite.stretch_mode=TextureRect.STRETCH_SCALE
 chest_sprite.position=Vector2(832,236);chest_sprite.size=Vector2(256,256);chest_sprite.pivot_offset=Vector2(128,256);chest_sprite.mouse_filter=Control.MOUSE_FILTER_IGNORE;shake_root.add_child(chest_sprite)
func build_reel() -> void:
 reel_panel=Control.new();reel_panel.name="ReelPanel";reel_panel.position=Vector2(0,548);reel_panel.size=Vector2(1920,300);reel_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;reel_panel.modulate.a=0.0;shake_root.add_child(reel_panel)
 var back=ColorRect.new();back.color=Color(0.055,0.059,0.055,0.88);back.size=reel_panel.size;back.mouse_filter=Control.MOUSE_FILTER_IGNORE;reel_panel.add_child(back)
 for y in [0.0,299.0]:
  var rule=ColorRect.new();rule.color=Color("3A3D38");rule.position=Vector2(0,y);rule.size=Vector2(1920,1);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;reel_panel.add_child(rule)
 reel=ChestReel.new().setup(info.strip,int(info.win_index),float(info.land_offset));reel.name="Reel";reel.position=Vector2(0,30);reel_panel.add_child(reel);reel.set_progress(0.0,false)
 for side in 2:
  var fade=TextureRect.new();var g=Gradient.new();var solid=Color(0.055,0.059,0.055,1.0);var clear=Color(0.055,0.059,0.055,0.0);var mid=Color(0.055,0.059,0.055,0.85)
  g.offsets=PackedFloat32Array([0.0,0.4,1.0]);g.colors=PackedColorArray([solid,mid,clear] if side==0 else [clear,mid,solid])
  if side==1:g.offsets=PackedFloat32Array([0.0,0.6,1.0])
  var gt=GradientTexture2D.new();gt.gradient=g;gt.fill_from=Vector2(0,0);gt.fill_to=Vector2(1,0);gt.width=64;gt.height=4;fade.texture=gt;fade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;fade.stretch_mode=TextureRect.STRETCH_SCALE
  fade.position=Vector2(0 if side==0 else 1400,0);fade.size=Vector2(520,300);fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;reel_panel.add_child(fade)
 for y in [-2.0,278.0]:
  var tri=Control.new();tri.position=Vector2(945,y);tri.size=Vector2(30,22);tri.mouse_filter=Control.MOUSE_FILTER_IGNORE;reel_panel.add_child(tri)
  var down=y<0.0;tri.draw.connect(func():
   var pts=PackedVector2Array([Vector2(0,0),Vector2(30,0),Vector2(15,22)]) if down else PackedVector2Array([Vector2(0,22),Vector2(30,22),Vector2(15,0)])
   tri.draw_colored_polygon(pts,Color("F2C14E"));tri.draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[0]]),Color("0E0F0E"),2.0))
 wait_label=MenuStyle.label("THE REEL IS TURNING…     SPACE / ENTER HOLD  SKIP",MenuStyle.sans(600,0.24,15),15,Color("8D9188"),0,shake_root);wait_label.name="Waiting";wait_label.position=Vector2(0,880);wait_label.size=Vector2(1920,24);wait_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;wait_label.hide()
func build_open() -> void:
 open_group=Control.new();open_group.name="OpenGroup";open_group.position=Vector2(0,560);open_group.size=Vector2(1920,140);open_group.mouse_filter=Control.MOUSE_FILTER_IGNORE;shake_root.add_child(open_group)
 open_button=MenuStyle.spawn("menu_item") as MenuItem;open_button.name="OpenChest";open_button.setup("Open chest",44,44).make_primary("ENTER",72,44);open_button.size=Vector2(440,84);open_button.position=Vector2(740,0);open_button.indent=44.0;open_group.add_child(open_button)
 open_button.chosen.connect(open_chest)
 var line=MenuStyle.label("One item inside. Rarer items are rarer for a reason.",MenuStyle.sans(400,0,17),17,Color("8D9188"),0,open_group);line.position=Vector2(0,100);line.size=Vector2(1920,24);line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func open_chest() -> void:
 if phase!="closed":return
 phase="opening";phase_time=0.0;open_group.hide();chest_sprite.texture=load("res://assets/icons/misc/chest_open.png");headline.text="Something stirs inside…"
 hold=0.0;armed=false;set_hints([["HOLD ENTER","Skip","A"]])
 game.play_sound("ui.chest_hop")
func skip() -> void:
 if phase=="reveal":return
 if phase=="closed":phase="opening"
 go_reveal()
func go_reveal() -> void:
 if phase=="reveal":return
 phase="reveal";phase_time=0.0;frontend.chest_skip=Callable();game.audio.stop_event("reward.chest.tick");game.audio.stop_event("ui.chest_hop");game.audio.stop_event("ui.chest_open");game.audio.stop_event("ui.reel_stop")
 open_group.hide();wait_label.hide();headline.hide();shake_root.get_node("Caption").hide();chest_sprite.texture=load("res://assets/icons/misc/chest_open.png");chest_sprite.rotation=0.0;chest_sprite.position.y=236.0;chest_sprite.scale=Vector2.ONE
 beam.modulate.a=1.0;reel_panel.modulate.a=1.0;reel.set_progress(1.0,true)
 var t=int(info.tier);var tint: Color=FogPalette.RARITY[t]["color"];var legendary=t==FogPalette.Rarity.LEGENDARY
 headline.text="The bells toll" if legendary else "The chest gives up its secret"
 var dim=ColorRect.new();dim.color=Color(0.02,0.024,0.02,0.9);dim.size=Vector2(1920,1080);dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;reveal_layer.add_child(dim)
 var power=float(Rarity.definition(Catalog.item_tier(item_id)).celebration)*game.settings.visual_intensity
 fx=ChestFx.new().setup(Color("F2C14E") if legendary else tint,clampf(0.35+power*0.65,0.0,1.0) if not game.settings.reduced else 0.0,t>=FogPalette.Rarity.EPIC);fx.name="Fx";reveal_layer.add_child(fx)
 var cap=SmallCapsLabel.new().setup(("A legendary find" if legendary else ("A %s find"%str(info.tier_name).to_lower() if t>=FogPalette.Rarity.RARE else "You found")),22 if legendary else 18,Color("F2C14E") if legendary else FogPalette.BONE,800,0.6 if legendary else 0.4)
 cap.name="FindCaption";cap.position=Vector2(0,120);cap.size=Vector2(1920,30);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;reveal_layer.add_child(cap)
 card=ChestCard.new().setup(info);card.name="ChestReveal";card.position=Vector2(760,186)
 if gem_found!="":card.gem_line="◆ %s socket gem found!"%Elements.display_name(gem_found);card.gem_color=Elements.color(gem_found)
 card.set_meta("revealed",true);card.set_meta("final_id",item_id);reveal_layer.add_child(card)
 if t>=FogPalette.Rarity.RARE:
  var stamp=SmallCapsLabel.new().setup("★ %s"%str(info.tier_name).to_upper(),22,Color("1C1A15"),800,0.24);stamp.name="Stamp";stamp.position=Vector2(1180,246);stamp.rotation=deg_to_rad(-8.0)
  var sb=StyleBoxFlat.new();sb.bg_color=Color("F2C14E") if legendary else tint;sb.content_margin_left=16;sb.content_margin_right=16;sb.content_margin_top=10;sb.content_margin_bottom=7;sb.shadow_color=Color("050505");sb.shadow_offset=Vector2(4,4)
  stamp.add_theme_stylebox_override("normal",sb);reveal_layer.add_child(stamp)
 take_button=MenuStyle.spawn("menu_item") as MenuItem;take_button.name="TakeIt";take_button.setup("Take it",36,36).make_primary("ENTER",72,36);take_button.size=Vector2(300,72);take_button.position=Vector2(810,740);take_button.indent=48.0
 take_button.sound="item_take";take_button.chosen.connect(func():game.resume());reveal_layer.add_child(take_button)
 flash=ColorRect.new();flash.color=Color("FFEDC2");flash.size=Vector2(1920,1080);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;reveal_layer.add_child(flash)
 reveal_layer.show();set_hints([["ENTER","Take it","A"]]);focus_later(take_button)
 if not game.settings.reduced:
  card.scale=Vector2(0.35,0.35);card.rotation=deg_to_rad(-8.0);card.modulate.a=0.0
  var tw=create_tween();tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);tw.set_parallel(true)
  tw.tween_property(card,"scale",Vector2.ONE,0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  tw.tween_property(card,"rotation",0.0,0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  tw.tween_property(card,"modulate:a",1.0,0.25)
  tw.tween_property(flash,"modulate:a",0.0,0.45*maxf(0.3,game.settings.visual_intensity))
  take_button.modulate.a=0.0;tw.tween_property(take_button,"modulate:a",1.0,0.4).set_delay(1.0)
 else:flash.hide()
 var cel=float(Rarity.definition(Catalog.item_tier(item_id)).celebration)
 game.play_sound("applause",0.25+0.75*cel);game.play_sound(REVEAL_EVENTS[clampi(t,0,4)])
func _input(event: InputEvent) -> void:
 super._input(event)
 if phase=="spinning" and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_SPACE:skip();get_viewport().set_input_as_handled()
func _held() -> bool:return Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
func _process(delta: float) -> void:
 phase_time+=delta
 match phase:
  "closed":
   var w=sin(phase_time*TAU/2.4);chest_sprite.rotation=deg_to_rad(1.5)*w
  "opening":
   var k=clampf(phase_time/OPEN_TIME,0.0,1.0)
   var jump=-36.0*sin(minf(k/0.55,1.0)*PI) if k<0.55 else -8.0*sin(clampf((k-0.55)/0.45,0.0,1.0)*PI)
   chest_sprite.position.y=236.0+jump;chest_sprite.scale=Vector2(1.0+0.08*sin(k*PI),1.0-0.06*sin(k*PI))
   beam.modulate.a=clampf(k*1.6,0.0,1.0);reel_panel.modulate.a=clampf(phase_time/0.4,0.0,1.0)
   if phase_time>=OPEN_TIME:game.play_sound("ui.chest_open");phase="spinning";phase_time=0.0;chest_sprite.position.y=236.0;chest_sprite.scale=Vector2.ONE;wait_label.show()
  "spinning":
   var p=clampf(phase_time/SPIN_TIME,0.0,1.0);reel.set_progress(p,false)
   var under=reel.under_marker(p)
   if under!=reel.last_tick:reel.last_tick=under;game.play_sound("reward.chest.tick",0.35)
   if p>=1.0:phase="landed";phase_time=0.0;reel.set_progress(1.0,true);wait_label.hide();game.audio.stop_event("reward.chest.tick");game.play_sound("ui.reel_stop")
  "landed":
   var s=maxf(0.0,1.0-phase_time/0.4)*float(game.settings.visual_intensity) if not game.settings.reduced else 0.0
   shake_root.position=Vector2(sin(phase_time*90.0)*10.0,cos(phase_time*70.0)*6.0)*s
   if phase_time>=LAND_TIME:shake_root.position=Vector2.ZERO;go_reveal()
 if phase in ["opening","spinning","landed"]:
  if not _held():armed=true;hold=0.0
  elif armed:
   hold+=delta
   if hold>=0.35:skip()
func is_revealed() -> bool:return phase=="reveal"
