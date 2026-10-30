class_name RunResults
extends MenuScreen
# RunResults: the end-of-run screen (death or victory). All figures come from RunData.results(); the screen only lays them out.
var info: Dictionary={}
var again: MenuItem
var home: MenuItem
func _init() -> void:
 super._init();backdrop_kind="fog";allow_back=false
func build() -> void:
 var win=bool(info.victory)
 var panel=Panel.new();panel.name="Panel";panel.position=Vector2(432,120);panel.size=Vector2(1056,840);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",FogTheme.flat(Color(0.055,0.059,0.055,0.94),FogPalette.GOLD if win else FogPalette.BORDER,1));content.add_child(panel)
 var cap=SmallCapsLabel.new().setup("Victory" if win else "Run over",16,FogPalette.GOLD if win else Color("A9ADA4"),800,0.4);cap.name="Caption";cap.position=Vector2(480,156);content.add_child(cap)
 var title=MenuStyle.label("Infinity broken" if win else "The wild claims another",MenuStyle.serif(),72,FogPalette.BONE,3,content);title.name="Title";title.position=Vector2(480,182)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(480,282);rule.size=Vector2(56,6);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(rule)
 var cells=[["Survived",info.time],["Stage",str(info.stage)],["Level",str(info.level)],["Kills",str(info.kills)],["Damage","%.0f"%info.damage],["Gold",str(info.gold)]]
 var grid=GridContainer.new();grid.name="Figures";grid.columns=3;grid.position=Vector2(480,320);grid.add_theme_constant_override("h_separation",64);grid.add_theme_constant_override("v_separation",22);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(grid)
 for c in cells:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.custom_minimum_size=Vector2(280,0);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;grid.add_child(cell)
  MenuStyle.label(str(c[0]).to_upper(),MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);cell.add_child(HudNumber.new().setup(str(c[1]),44,FogPalette.BONE_BRIGHT,3))
 var dm=SmallCapsLabel.new().setup("Highest damage: %s"%info.best,15,Color("A9ADA4"),800,0.26);dm.name="Best";dm.position=Vector2(480,520);content.add_child(dm)
 var top=0.0
 for w in info.per_weapon:top=maxf(top,float(w.damage))
 for i in mini(4,info.per_weapon.size()):
  var w: Dictionary=info.per_weapon[i];var y=552+i*36
  MenuStyle.label(str(w.name),MenuStyle.serif(),22,FogPalette.BONE,0,content).position=Vector2(480,y)
  var bar=Control.new();bar.position=Vector2(780,y+8);bar.size=Vector2(560,16);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(bar)
  var frac=float(w.damage)/maxf(1.0,top);var amount=float(w.damage)
  bar.draw.connect(func():bar.draw_rect(Rect2(Vector2.ZERO,bar.size),Color("2A1416"));bar.draw_rect(Rect2(Vector2.ZERO,Vector2(bar.size.x*frac,bar.size.y)),FogPalette.RUST);bar.draw_string(MenuStyle.sans(800,0,12),Vector2(bar.size.x+10.0,13.0),"%.0f"%amount,HORIZONTAL_ALIGNMENT_LEFT,120,12,Color("B9BAB1")))
 var note="Sandbox: no progression written" if info.sandbox else "Quest progress saved"
 var nl=MenuStyle.label(note,MenuStyle.sans(400,0,16),16,Color("8D9188"),0,content);nl.name="Note";nl.position=Vector2(480,716)
 if info.unlocked.size()>0:
  var u=MenuStyle.label("Requirements met: "+", ".join(info.unlocked),MenuStyle.sans(600,0,17),17,FogPalette.GOLD,0,content);u.name="Unlocked";u.position=Vector2(480,744);u.size=Vector2(960,50);u.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 again=MenuStyle.spawn("menu_item") as MenuItem;again.name="RunAgain";again.setup("Run again",34,34).make_primary("ENTER",72,34);again.size=Vector2(440,60);again.position=Vector2(480,826);again.indent=44.0;content.add_child(again)
 home=MenuStyle.spawn("menu_item") as MenuItem;home.name="MainMenu";home.setup("Main menu",30,30);home.size=Vector2(320,60);home.position=Vector2(960,826);home.indent=30.0;content.add_child(home)
 again.chosen.connect(func():game.begin_run());home.chosen.connect(func():game.build_menu_world();game.main_menu())
 again.focus_neighbor_right=again.get_path_to(home);home.focus_neighbor_left=home.get_path_to(again);again.focus_neighbor_left=again.get_path_to(again);home.focus_neighbor_right=home.get_path_to(home)
 set_hints([["←→","Choose","D-PAD"],["ENTER","Select","A"]]);focus_later(again)
