class_name FrameScreen
extends MenuScreen
# Shared frame of the Fog screens that have a title, silver, a Home button and optionally a tab bar (Unlocks, Quests, Settings).
var tab_bar: MenuTabBar
var silver_number: HudNumber
var home_button: MenuItem
func progress() -> Dictionary:return game.progress.data
func build_frame(title: String,subtitle: String,tabs: Array=[],current: String="",show_silver: bool=true,home_text: String="Home") -> void:
 var header=VBoxContainer.new();header.name="Header";header.position=Vector2(120,72);header.add_theme_constant_override("separation",12);header.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(header)
 header.add_child(MenuStyle.label(title,MenuStyle.serif(),FogPalette.SIZE_TITLE,FogPalette.BONE,3))
 var sub=HBoxContainer.new();sub.add_theme_constant_override("separation",16);sub.mouse_filter=Control.MOUSE_FILTER_IGNORE;header.add_child(sub)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.custom_minimum_size=Vector2(48,6);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;sub.add_child(rule)
 sub.add_child(SmallCapsLabel.new().setup(subtitle,17,Color("A9ADA4"),600,0.3))
 home_button=MenuStyle.spawn("menu_item") as MenuItem;home_button.setup(home_text,30,30,false,Vector2(60,60));home_button.hint_text="ESC";home_button.indent=22.0;home_button.outlined=true
 home_button.position=Vector2(MenuStyle.W-110-190,121);home_button.custom_minimum_size=Vector2(190,60);home_button.size=Vector2(190,60);home_button.chosen.connect(go_back);content.add_child(home_button)
 if show_silver:
  var cap=SmallCapsLabel.new().setup("Silver",15,Color("8D9188"),600,0.3);cap.name="SilverCaption";cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;cap.position=Vector2(MenuStyle.W-110-190-40-240,122);cap.size=Vector2(240,22);content.add_child(cap)
  silver_number=HudNumber.new().setup(progress().silver,42,FogPalette.BONE_BRIGHT);silver_number.name="SilverAmount";silver_number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;silver_number.position=Vector2(MenuStyle.W-110-190-40-240,138);silver_number.size=Vector2(240,50);content.add_child(silver_number)
 if not tabs.is_empty():
  tab_bar=MenuTabBar.new();tab_bar.name="Tabs";tab_bar.position=Vector2(120,232);content.add_child(tab_bar);tab_bar.set_tabs(tabs,current)
func step_tabs(direction: int) -> void:
 if tab_bar!=null:tab_bar.step(direction)
func refresh_silver() -> void:
 if silver_number!=null:silver_number.set_value(progress().silver)
func go_back() -> void:navigate(frontend.home)
