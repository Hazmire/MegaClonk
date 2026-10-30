class_name MainMenuScreen
extends MenuScreen
# Fog-Menu: logo, tagline, Play / Unlocks / Quests / Settings, silver, and the four quests "Within reach".
const PAPERS=[Color("D3CBB2"),Color("CFC7AD"),Color("D3CBB2"),Color("CFC7AD")]
const TILTS=[-1.0,0.8,-0.6,1.1]
var items: Dictionary={}
var reach: VBoxContainer
var reach_cards: Array=[]
var silver_number: HudNumber
func _init() -> void:
 super._init();backdrop_kind="world";hint_side="left";allow_back=false
func build() -> void:
 var title=MenuStyle.label("Megaclonk",MenuStyle.serif_sc(),150,FogPalette.BONE,4,content);title.name="Logo"
 title.position=Vector2(120,96-(MenuStyle.serif_sc().get_height(150)-127.5)*0.5)
 var rule=ColorRect.new();rule.name="Rule";rule.color=FogPalette.RUST;rule.position=Vector2(120,248);rule.size=Vector2(64,6);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(rule)
 if MenuData.MENU_TAGLINE!="":
  var tag=SmallCapsLabel.new().setup(MenuData.MENU_TAGLINE,18,Color("A9ADA4"),600,0.32);tag.name="Tagline";tag.position=Vector2(200,236);content.add_child(tag)
 var nav=VBoxContainer.new();nav.name="Nav";nav.position=Vector2(120,380);nav.size=Vector2(480,300);nav.add_theme_constant_override("separation",6);nav.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(nav)
 var entries=[["play","Play",frontend.play_screen],["unlocks","Unlocks",frontend.unlocks],["quests","Quests",frontend.quests],["settings","Settings",func():frontend.settings(frontend.home)]]
 for e in entries:
  var item=MenuStyle.spawn("menu_item") as MenuItem;item.setup(e[1]);if e[0]=="play":item.sound="play";nav.add_child(item);items[e[0]]=item
  var target: Callable=e[2]
  item.chosen.connect(func():navigate(target))
 var silver=Control.new();silver.name="Silver";silver.position=Vector2(MenuStyle.W-96-320,84);silver.size=Vector2(320,80);silver.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(silver)
 var cap=SmallCapsLabel.new().setup("Silver",16,Color("A9ADA4"),600,0.3,2);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;cap.size=Vector2(320,22);silver.add_child(cap)
 silver_number=HudNumber.new().setup(game.progress.data.silver,44,FogPalette.BONE_BRIGHT,3);silver_number.name="SilverAmount";silver_number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;silver_number.position=Vector2(0,24);silver_number.size=Vector2(320,56);silver.add_child(silver_number)
 build_reach()
 set_hints([["↑↓","Navigate"],["ENTER","Select"]])
 focus_later(items["play"])
func build_reach() -> void:
 var quests=MenuData.within_reach(game.progress.data,frontend.quest_definitions,4)
 reach=VBoxContainer.new();reach.name="WithinReach";reach.add_theme_constant_override("separation",18);reach.mouse_filter=Control.MOUSE_FILTER_IGNORE
 content.add_child(reach)
 # pinned to the bottom edge (92px up) and grows upward, so it never depends on the cards' final height
 reach.anchor_left=0.0;reach.anchor_right=0.0;reach.anchor_top=1.0;reach.anchor_bottom=1.0
 reach.offset_left=120;reach.offset_right=MenuStyle.W-96;reach.offset_bottom=-92;reach.offset_top=-92
 reach.grow_vertical=Control.GROW_DIRECTION_BEGIN
 if quests.is_empty():reach.hide();return
 var head=HBoxContainer.new();head.mouse_filter=Control.MOUSE_FILTER_IGNORE;reach.add_child(head)
 var label=SmallCapsLabel.new().setup("Within reach",18,Color("A9ADA4"),800,0.32);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(label)
 var all=Button.new();all.name="AllQuests";all.text="ALL QUESTS ›";all.flat=true;all.focus_mode=Control.FOCUS_ALL
 all.add_theme_font_override("font",MenuStyle.sans(600,0.24,16));all.add_theme_font_size_override("font_size",16)
 for k in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:all.add_theme_color_override(k,FogPalette.BONE)
 var focus=FogTheme.flat(Color(0.494,0.094,0.125,0.6));all.add_theme_stylebox_override("focus",focus)
 all.pressed.connect(func():sfx("confirm");navigate(frontend.quests));head.add_child(all);items["all"]=all
 var row=HBoxContainer.new();row.name="Cards";row.add_theme_constant_override("separation",28);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;reach.add_child(row)
 for i in quests.size():
  var q: Dictionary=quests[i]
  var card=MenuStyle.spawn("memo_card") as MemoCard;card.name="Quest_"+String(q.id)
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;card.custom_minimum_size.x=((MenuStyle.W-120-96)-3*28)/4.0
  card.set_look(TILTS[i]).set_paper(PAPERS[i])
  card.fill_quest(q.name,MenuData.quest_description(q),"active",MetaProgress.quest_value(game.progress.data,q.metric),q.target,MenuData.is_pass_fail(q))
  row.add_child(card);reach_cards.append(card)
