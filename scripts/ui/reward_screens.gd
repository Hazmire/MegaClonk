class_name RewardScreens
extends RefCounted
# Original framed UI inspired by the supplied composition; all content is live.
static func style(color: Color=Color("b8b09a"),background: Color=Color("202626")) -> StyleBoxFlat:
 var box=StyleBoxFlat.new();box.bg_color=background;box.border_color=color;box.set_border_width_all(2)
 box.shadow_color=Color(0,0,0,0.7);box.shadow_size=5
 box.content_margin_left=12;box.content_margin_right=12;box.content_margin_top=10;box.content_margin_bottom=10
 return box
static func button(ui: FrontEnd,parent: Node,label: String,callback: Callable,tint: Color=Color("51585a")) -> Button:
 var generation=ui.reward_generation
 var control=ui.action(label,parent,func():
  if ui.reward_generation==generation:callback.call())
 control.custom_minimum_size=Vector2(120,44)
 for state in ["normal","hover","pressed","focus","disabled"]:
  var box=style(Color("a6a89f") if state=="normal" else Color("fff0bf"),tint.darkened(0.25) if state=="pressed" else tint.lightened(0.15) if state in ["hover","focus"] else tint.darkened(0.55) if state=="disabled" else tint)
  box.set_corner_radius_all(2);box.border_width_bottom=5;box.shadow_size=2
  control.add_theme_stylebox_override(state,box)
 return control
static func world_map(ui: FrontEnd,from_pause: bool) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="map";ui.clear();ui.map_return_to_pause=from_pause;ui.minimap.reveal(game.player.position)
 var screen=RunMap.new();screen.from_pause=from_pause;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)
static func icon(ui: FrontEnd,parent: Node,category: String,id: String,rank: String="",edge: Color=Color("786f60"),size: int=48) -> Control:
 var slot=PanelContainer.new();slot.custom_minimum_size=Vector2(size,size+16);slot.add_theme_stylebox_override("panel",style(edge,Color("152321")));parent.add_child(slot)
 if size<=48:
  var padding=slot.get_theme_stylebox("panel").duplicate();padding.content_margin_left=4;padding.content_margin_right=4;padding.content_margin_top=4;padding.content_margin_bottom=4;slot.add_theme_stylebox_override("panel",padding)
 var body=VBoxContainer.new();body.add_theme_constant_override("separation",1);slot.add_child(body)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;body.add_child(image)
 var inner=size-12
 if category=="items":inner=32*maxi(1,int((size-12)/32)) # 32x32 pixel art is only ever shown at whole-number scales
 image.custom_minimum_size=Vector2(inner,inner);image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if rank!="":
  var label=ui.text(rank,body,12);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return slot
static func descendants(node: Node) -> Array:
 var result=[]
 for child in node.get_children():result.append(child);result.append_array(descendants(child))
 return result
static func upgrades(ui: FrontEnd,fixed_choices: Array=[],quick: bool=false) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="upgrade";ui.clear();ui.reward_focus={}
 game.choices=fixed_choices if not fixed_choices.is_empty() else game.upgrade_choices()
 var screen=RunLevelUp.new();MenuScreen.set_audio_owner(game);screen.bind(ui);screen.choices=game.choices;screen.quick=quick;ui.menu.add_child(screen)
static func inventory(ui: FrontEnd) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="build";ui.clear()
 var screen=RunBuild.new();MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)
static func imbue_station(ui: FrontEnd,object: Dictionary) -> void:
 SocketScreens.imbue_station(ui,object)
static func shop(ui: FrontEnd,object: Dictionary) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="shop";ui.shop_object=object
 if not object.has("offers"):
  object.offers=ShopSystem.offers(object.get("tier","Common"),game.available_items(),game.rng,float(game.stats.luck),game.world_content_version>=2)
 ui.shop_offers=object.offers
 ui.clear()
 var screen=RunShop.new();screen.object=object;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)
static func reward(ui: FrontEnd,id: String) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="reward";ui.clear()
 var screen=RunChest.new();screen.item_id=id;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)

static func shrine(ui: FrontEnd,reward: Dictionary) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="shrine";ui.clear()
 var screen=RunShrine.new();screen.reward=reward;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)