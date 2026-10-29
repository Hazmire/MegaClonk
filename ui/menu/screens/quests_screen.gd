class_name QuestsScreen
extends FrameScreen
# Quests: a grid of memo cards (counted / pass-fail / complete, the three Fog-Kit variants) per category. No mockup exists for
# this screen. Judgement calls are listed in docs/menu-overhaul-report.md.
const CATEGORIES=[{"id":"Hunting","label":"Hunting"},{"id":"Arsenal","label":"Arsenal"},{"id":"Survival","label":"Survival"},{"id":"Exploration","label":"Exploration"}]
const PAPERS=[Color("D3CBB2"),Color("CFC7AD")]
const TILTS=[-1.0,0.8,-0.6,1.1]
const COLUMNS=4
var category="Hunting"
var scroll: ScrollContainer
var grid: GridContainer
var cards: Array=[]
static var last_category="Hunting"
func build() -> void:
 category=last_category
 build_frame("Quests","Complete them to earn silver",CATEGORIES,category)
 tab_bar.tab_selected.connect(func(id: String):category=id;last_category=id;fill())
 scroll=ScrollContainer.new();scroll.name="Scroll";scroll.position=Vector2(120,322);scroll.size=Vector2(1690,700);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;scroll.follow_focus=true;content.add_child(scroll)
 var pad=MarginContainer.new();pad.add_theme_constant_override("margin_top",24);pad.add_theme_constant_override("margin_bottom",40);pad.add_theme_constant_override("margin_left",14);pad.add_theme_constant_override("margin_right",14);pad.mouse_filter=Control.MOUSE_FILTER_IGNORE;scroll.add_child(pad)
 grid=GridContainer.new();grid.name="Grid";grid.columns=COLUMNS;grid.add_theme_constant_override("h_separation",28);grid.add_theme_constant_override("v_separation",36);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE;pad.add_child(grid)
 fill()
 set_hints([["ARROWS","Browse","D-PAD"],["Q / E","Category"],["ENTER","Claim"],["ESC","Home"]])
# Claimable first, then open quests (closest to done first), then claimed ones; catalogue order inside each group.
func ordered(cat: String) -> Array:
 var groups={"completed":[],"active":[],"claimed":[]}
 for q in frontend.quest_definitions:
  if q.category==cat:groups[MetaProgress.quest_state(progress(),q)].append(q)
 groups["active"].sort_custom(func(a,b):return MenuData.quest_ratio(progress(),a)>MenuData.quest_ratio(progress(),b))
 return groups.completed+groups.active+groups.claimed
func fill(keep_index: int=0) -> void:
 for c in grid.get_children():grid.remove_child(c);c.queue_free()
 cards.clear()
 var list=ordered(category);var done=0
 var card_w=floorf((1690.0-28.0-28.0*(COLUMNS-1))/COLUMNS)
 for i in list.size():
  var q: Dictionary=list[i]
  var state=MetaProgress.quest_state(progress(),q);if state=="claimed":done+=1
  var card=MenuStyle.spawn("memo_card") as MemoCard;card.name="Quest_"+String(q.id);card.custom_minimum_size.x=card_w;card.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
  card.set_look(TILTS[i%TILTS.size()]).set_paper(PAPERS[i%PAPERS.size()])
  var reward=LoadoutCatalog.quest_reward(q)
  card.fill_quest(q.name,MenuData.quest_description(q),state,MetaProgress.quest_value(progress(),q.metric),q.target,MenuData.is_pass_fail(q),"%d SILVER"%reward)
  if state=="active":
   var r=card.memo_label("Reward: %d silver"%reward,15,FogPalette.MEMO_INK_SOFT);r.name="Reward"
  card.make_focusable();grid.add_child(card);cards.append(card)
  var id=String(q.id);card.claim_pressed.connect(func():claim(id))
  if card.claim_button!=null:card.claim_button.pressed.connect(func():claim(id))
 tab_bar.set_note("%d / %d CLAIMED"%[done,list.size()])
 if not cards.is_empty():cards[clampi(keep_index,0,cards.size()-1)].grab_focus.call_deferred()
func claim(id: String) -> void:
 var index=0
 for i in cards.size():
  if cards[i].name=="Quest_"+id:index=i
 if MetaProgress.claim(progress(),id):
  sfx("purchase");game.progress.save();refresh_silver();fill(index)
