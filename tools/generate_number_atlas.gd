extends SceneTree
func _initialize():
 var patterns=[['01110','11011','11011','11011','11011','11011','01110'],['00100','01100','00100','00100','00100','00100','01110'],['01110','11011','00011','00110','01100','11000','11111'],['11110','00011','00011','01110','00011','00011','11110'],['00011','00111','01111','11011','11111','00011','00011'],['11111','11000','11000','11110','00011','00011','11110'],['01110','11000','11000','11110','11011','11011','01110'],['11111','00011','00110','00110','01100','01100','01100'],['01110','11011','11011','01110','11011','11011','01110'],['01110','11011','11011','01111','00011','00011','01110'],['00100','00100','00100','00100','00100','00000','00100']]
 var image=Image.create(256,16,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
 for glyph in patterns.size():
  var pixels=[]
  for y in 7:
   for x in 5:
    if patterns[glyph][y][x]=='1':
     for dy in 2:
      for dx in 2:pixels.append(Vector2i(glyph*16+3+x*2,1+y*2)+Vector2i(dx,dy))
  for p in pixels:
   for dy in range(-1,2):
    for dx in range(-1,2):
     var q=p+Vector2i(dx,dy)
     if q.y>=0 and q.y<16:image.set_pixelv(q,Color(0.06,0.07,0.09,1))
  for p in pixels:image.set_pixelv(p,Color.WHITE)
 print('Number atlas: ',image.save_png('res://assets/config/combat_digits.png'));quit()
