class_name RunBuild
extends RunPanelScreen
# RunBuild: the build inspector (Tab / "Inspect build"): run totals and every weapon with the game's own tooltip text and sockets,
# between the Inventory and Stats panels. All text comes from RunData.build_details().
var back: MenuItem
func build() -> void:
 var d=RunData.build_details(game)
 build_panels();build_status();build_section()
 var head=Control.new();head.name="Header";head.position=Vector2(572,182);head.size=Vector2(776,100);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(head)
 head.add_child(SmallCapsLabel.new().setup("Inspect",14,Color("A9ADA4"),800,0.3))
 var title=MenuStyle.label("Your build",MenuStyle.serif(),52,FogPalette.BONE,0,head);title.name="Title";title.position=Vector2(0,22)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(0,94);rule.size=Vector2(48,5);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(rule)
 var row=HBoxContainer.new();row.name="Totals";row.position=Vector2(572,300);row.add_theme_constant_override("separation",44);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(row)
 for c in [["Level",str(d.level)],["Stage",str(d.stage)],["Kills",str(d.kills)],["Damage","%.0f"%d.damage],["Gold",str(d.gold)]]:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(cell)
  MenuStyle.label(str(c[0]).to_upper(),MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);cell.add_child(HudNumber.new().setup(str(c[1]),36,FogPalette.BONE_BRIGHT,3))
 var lines=MenuStyle.label("%d paid chests · %d free chests      Additional bosses +%d · %d per future encounter"%[d.paid_chests,d.free_chests,d.extra_bosses,d.per_boss],MenuStyle.sans(400,0,15),15,Color("8D9188"),0,content);lines.name="Counts";lines.position=Vector2(572,382)
 var scroll=ScrollContainer.new();scroll.name="Weapons";scroll.position=Vector2(572,430);scroll.size=Vector2(776,520);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
 var list=VBoxContainer.new();list.add_theme_constant_override("separation",14);list.custom_minimum_size=Vector2(760,0);scroll.add_child(list)
 for w in d.weapons:
  var card=VBoxContainer.new();card.add_theme_constant_override("separation",4);list.add_child(card)
  var h=HBoxContainer.new();h.add_theme_constant_override("separation",12);card.add_child(h)
  var ic=TextureRect.new();ic.texture=UIAssets.icon("weapons",str(w.id));ic.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ic.custom_minimum_size=Vector2(40,40);h.add_child(ic)
  MenuStyle.label("%s"%w.name,MenuStyle.serif(),28,FogPalette.BONE,0,h);MenuStyle.label("LV %d"%w.level,MenuStyle.sans(800,0.2,13),13,FogPalette.GOLD,0,h)
  var t=MenuStyle.label(str(w.text),MenuStyle.memo(),15,Color("C9C9BE"),0,card);t.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;t.custom_minimum_size.x=740
  var sk=MenuStyle.label(str(w.sockets),MenuStyle.memo(),14,Color("A9ADA4"),0,card);sk.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sk.custom_minimum_size.x=740
 if d.weapons.is_empty():MenuStyle.label("You have no weapons.",MenuStyle.sans(400,0,17),17,Color("B9BAB1"),0,list)
 back=MenuStyle.spawn("menu_item") as MenuItem;back.name="Resume";back.setup("Resume",30,30).make_primary("TAB",60,30);back.size=Vector2(240,48);back.position=Vector2(1108,966);back.indent=52.0
 back.chosen.connect(func():game.resume());content.add_child(back)
 set_hints([["TAB","Close"],["ESC","Resume","B"]]);focus_later(back)
