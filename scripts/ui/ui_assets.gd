class_name UIAssets
extends RefCounted
static var cache: Dictionary={}
const WEAPON_ICONS=[15,20,35,29,30,18,12,7,31,18,33,25,13,37,26,9,38,12,24,28,43,14,2,5,15,10,30,25,48,25,27,24,35,22,25,36]
# Licensed supplied ability demo icons take precedence; original temporary glyphs
# remain for weapon/item/tome packs whose usage terms are not yet verified.
# weapons.png keeps its original cell order; ids 0, 1 and 15 (Sword, Firestaff, Shotgun) use the vendor fallback until icons are supplied.
const LEGACY_WEAPON_ICON={2:2,6:5,7:6,9:7,10:8}
static func icon(category: String, id: String) -> Texture2D:
 var key=category+":"+id
 if category=="weapons" and LEGACY_WEAPON_ICON.has(int(id)):
  if cache.has(key):return cache[key]
  var atlas=load("res://assets/art_reset/icons/weapons.png") as Texture2D
  var index=int(LEGACY_WEAPON_ICON[int(id)]);var texture=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2(Vector2(index%5,int(index/5))*Vector2(atlas.get_width()/5.0,atlas.get_height()/2.0),Vector2(atlas.get_width()/5.0,atlas.get_height()/2.0));texture.filter_clip=true;cache[key]=texture;return texture
 if category=="tomes" and id in Catalog.ACTIVE_TOMES:
  if cache.has(key):return cache[key]
  var atlas=load("res://assets/ui/tomes/dusk_tomes.png") as Texture2D
  var index=Catalog.ACTIVE_TOMES.find(id);var cell=Vector2(atlas.get_width()/5.0,atlas.get_height()/2.0)
  var texture=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2(Vector2(index%5,int(index/5))*cell,cell);texture.filter_clip=true
  cache[key]=texture;return texture
 if category=="tomes":
  var path="res://assets/vendor/items/Icon"+("35" if posmod(id.hash(),2)==0 else "43")+".png"
  return load(path)
 if cache.has(key): return cache[key]
 if category=="items" and Catalog.item_exists(id):
  # Item Overhaul: the final 32x32 art, one file per item id. No placeholders.
  cache[key]=load("res://assets/icons/items/%s.png"%id);return cache[key]
 if category=="weapons":
  var vendor="res://assets/vendor/weapons/Icon"+str(WEAPON_ICONS[posmod(int(id),WEAPON_ICONS.size())])+".png"
  if ResourceLoader.exists(vendor):cache[key]=load(vendor);return cache[key]
 var imported_path="res://assets/ui/icons/"+category+"/"+id+".png"
 if ResourceLoader.exists(imported_path):
  cache[key]=load(imported_path);return cache[key]
 var image=Image.create(32,32,false,Image.FORMAT_RGBA8)
 image.fill(Color("182b33"))
 var color=Color.from_hsv(float(posmod(key.hash(),360))/360,0.45,0.95)
 var light=Color("fff0c3")
 if category=="tomes":
  image.fill_rect(Rect2i(8,5,16,23),Color("d5be8c"))
  image.fill_rect(Rect2i(6,4,20,5),light); image.fill_rect(Rect2i(6,24,20,4),light)
  for y in [12,16,20]: image.fill_rect(Rect2i(11,y,10,1),Color("8c7561"))
 elif category=="items":
  image.fill_rect(Rect2i(13,5,6,5),light);image.fill_rect(Rect2i(10,11,12,15),color)
  image.fill_rect(Rect2i(12,13,2,8),color.lightened(0.4))
 elif category=="weapons":
  if id in ["1","2","23","33"]:
   for y in range(6,24): image.fill_rect(Rect2i(16-(y-4)/3,y,maxi(2,(y-4)*2/3),1),color)
   image.fill_rect(Rect2i(14,15,4,9),light)
  else:
   image.fill_rect(Rect2i(14,5,5,18),light);image.fill_rect(Rect2i(9,21,15,3),color);image.fill_rect(Rect2i(15,24,3,6),Color("aa7e4e"))
 elif category=="ultimates":
  for y in 32:
   for x in 32:
    var d=Vector2(x-16,y-16).length()
    if d<8 or (d<13 and (abs(x-16)<2 or abs(y-16)<2 or abs(abs(x-16)-abs(y-16))<2)):image.set_pixel(x,y,color)
 else:
  image.fill_rect(Rect2i(13,6,6,21),color);image.fill_rect(Rect2i(6,13,21,6),color)
  image.fill_rect(Rect2i(14,14,4,4),light)
 cache[key]=ImageTexture.create_from_image(image)
 return cache[key]
