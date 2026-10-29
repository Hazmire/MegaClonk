class_name MenuStyle
extends RefCounted
# One source of truth for the Fog County menus: reference size, cached fonts, scene registry, small helpers.
# Colours come from FogPalette, the theme from FogTheme; nothing is typed twice.
const W=1920
const H=1080
const SCENES={
 "menu_screen":"res://ui/menu/menu_screen.tscn",
 "menu_item":"res://ui/menu/widgets/menu_item.tscn",
 "memo_card":"res://ui/menu/widgets/memo_card.tscn",
 "stamp":"res://ui/menu/widgets/stamp.tscn",
 "rarity_slot":"res://ui/menu/widgets/rarity_slot.tscn",
 "collection_tile":"res://ui/menu/widgets/collection_tile.tscn",
 "on_off_toggle":"res://ui/menu/widgets/on_off_toggle.tscn",
 "tab_bar":"res://ui/menu/widgets/tab_bar.tscn",
 "caps_label":"res://ui/menu/widgets/caps_label.tscn",
 "hud_number":"res://ui/menu/widgets/hud_number.tscn",
 "dropdown_option":"res://ui/menu/widgets/dropdown_option.tscn",
 "slot_dropdown":"res://ui/menu/widgets/slot_dropdown.tscn",
 "loadout_slot":"res://ui/menu/widgets/loadout_slot.tscn",
 "filter_chip":"res://ui/menu/widgets/filter_chip.tscn",
 "weapon_preview":"res://ui/menu/widgets/weapon_preview.tscn",
}
const SILVER_RUST=Color("8E1B22") # stamp red on paper
const PAPER_LINE=Color("8F876F")
const PAPER_TRACK=Color("B2A98E")
const LOCKED_TEXT=Color("6A6D66")
const OUTLINE=Color("4A4D47")
static var cache: Dictionary={}
static func spawn(kind: String) -> Node:return load(SCENES[kind]).instantiate()
static func theme() -> Theme:
 if not cache.has("theme"):cache["theme"]=FogTheme.build()
 return cache["theme"]
static func serif() -> Font:
 if not cache.has("serif"):cache["serif"]=FogTheme.serif()
 return cache["serif"]
static func serif_sc() -> Font:
 if not cache.has("serif_sc"):cache["serif_sc"]=FogTheme.serif_sc()
 return cache["serif_sc"]
static func memo() -> Font:
 if not cache.has("memo"):cache["memo"]=FogTheme.memo()
 return cache["memo"]
# Overpass at a weight with letter-spacing given in em of `size` (the mockups quote tracking in em).
static func sans(weight: int=600,tracking_em: float=0.0,size: int=16) -> Font:
 var key="sans:%d:%d"%[weight,roundi(tracking_em*size)]
 if not cache.has(key):
  var base=FogTheme.sans(weight)
  if base==null:return null
  if tracking_em>0.0:
   var spaced=FontVariation.new();spaced.base_font=base;spaced.spacing_glyph=roundi(tracking_em*size);base=spaced
  cache[key]=base
 return cache[key]
static func label(text: String,font: Font,size: int,color: Color,shadow: int=0,parent: Node=null) -> Label:
 var l=Label.new();l.text=text;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if font!=null:l.add_theme_font_override("font",font)
 l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color)
 l.add_theme_color_override("font_shadow_color",FogPalette.INK if shadow>0 else Color(0,0,0,0))
 l.add_theme_constant_override("shadow_offset_x",shadow);l.add_theme_constant_override("shadow_offset_y",shadow)
 if parent!=null:parent.add_child(l)
 return l
static func checker(a: Color,b: Color,cell: int=8) -> ImageTexture:
 var key="checker:%s:%s:%d"%[a.to_html(),b.to_html(),cell]
 if not cache.has(key):
  var img=Image.create(cell*2,cell*2,false,Image.FORMAT_RGBA8)
  for y in cell*2:
   for x in cell*2:img.set_pixel(x,y,a if (x<cell)==(y<cell) else b)
  cache[key]=ImageTexture.create_from_image(img)
 return cache[key]
static func gradient(from: Color,to: Color,vertical: bool,from_offset: float=0.0,to_offset: float=1.0) -> GradientTexture2D:
 var g=Gradient.new();g.colors=PackedColorArray([from,to]);g.offsets=PackedFloat32Array([from_offset,to_offset])
 var t=GradientTexture2D.new();t.gradient=g;t.width=64;t.height=64
 t.fill_from=Vector2(0,0);t.fill_to=Vector2(0,1) if vertical else Vector2(1,0)
 return t
static func shader_material(path: String,params: Dictionary={}) -> ShaderMaterial:
 var m=ShaderMaterial.new();m.shader=load(path)
 for k in params:m.set_shader_parameter(k,params[k])
 return m
static func icon_rect(category: String,id: String,pixels: int,locked: bool=false) -> TextureRect:
 # Pixel art is always scaled by whole numbers: `pixels` must be a multiple of 32.
 var t=TextureRect.new();t.texture=UIAssets.icon(category,id);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_SCALE;t.custom_minimum_size=Vector2(pixels,pixels);t.size=Vector2(pixels,pixels);t.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if locked:t.material=shader_material("res://ui/shaders/grayscale.gdshader")
 return t
static func rarity_color(r: int) -> Color:return FogPalette.RARITY[r]["color"]
static func rarity_for_tier(name: String) -> int:
 match name.to_lower():
  "common":return FogPalette.Rarity.COMMON
  "uncommon":return FogPalette.Rarity.UNCOMMON
  "rare":return FogPalette.Rarity.RARE
  "epic":return FogPalette.Rarity.EPIC
  "legendary":return FogPalette.Rarity.LEGENDARY
 return FogPalette.Rarity.COMMON
