class_name UIAssets
extends RefCounted
static var cache: Dictionary={}
# Original temporary pixel glyphs. Provider packs remain unlicensed/unavailable
# until fetched; no provider preview sheets are copied into the game.
static func icon(category: String, id: String) -> Texture2D:
 var key=category+":"+id
 if cache.has(key): return cache[key]
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
