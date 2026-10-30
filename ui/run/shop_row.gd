class_name ShopRow
extends Control
# One offer in the shop (RunShop): rarity-framed icon, tier / kind tag, name, effect, "Owned ×a → ×b", a paper price tag and the buy
# button. Everything shown is the RunData.shop_rows() entry; the screen decides what a purchase does.
signal buy_requested
signal denied
const SIZE_PX=Vector2(776,156)
var data: Dictionary={}
var number=1
var tag: PriceTag
var slot: RaritySlot
var gem: GemIcon
func setup(row: Dictionary,index: int) -> ShopRow:
 data=row;number=index+1;name="Row%d"%number;custom_minimum_size=SIZE_PX;size=SIZE_PX;focus_mode=Control.FOCUS_ALL;mouse_filter=Control.MOUSE_FILTER_STOP
 slot=MenuStyle.spawn("rarity_slot") as RaritySlot;slot.position=Vector2(16,16);add_child(slot)
 if data.kind=="gem":
  slot.setup(int(data.tier),null,64,Vector2(104,104))
  gem=GemIcon.new();gem.element=str(data.id);gem.size=Vector2(72,72);gem.position=Vector2(32,32);gem.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(gem)
 else:slot.setup(int(data.tier),UIAssets.icon("items",str(data.id)),64,Vector2(104,104))
 tag=PriceTag.new().setup(int(data.price),bool(data.affordable) and not data.sold,30,(-3.0 if number%2==1 else 2.0));add_child(tag)
 tag.position=Vector2(SIZE_PX.x-20-168+(168-tag.size.x)*0.5,16)
 tooltip_text=str(data.description)
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw);mouse_entered.connect(func():if not has_focus():grab_focus())
 return self
func buy_rect() -> Rect2:return Rect2(Vector2(SIZE_PX.x-20-168,SIZE_PX.y-16-40),Vector2(168,40))
func can_buy() -> bool:return not data.sold and not data.closed and data.available and data.affordable
func button_text() -> String:
 if data.sold:return "SOLD"
 if data.closed:return "CLOSED"
 if not data.available:return "UNAVAILABLE"
 if not data.affordable:return "NEED %d MORE"%int(data.need)
 return "BUY · ENTER" if has_focus() else "BUY"
func _gui_input(event: InputEvent) -> void:
 var activate=event.is_action_pressed("ui_accept") and not event.is_echo()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  grab_focus()
  if buy_rect().has_point(event.position):activate=true
 if activate:
  accept_event()
  if can_buy():buy_requested.emit()
  else:denied.emit()
func _draw() -> void:
 var tier=int(data.tier);var info=FogPalette.RARITY[tier];var color: Color=info["color"];var r=Rect2(Vector2.ZERO,size);var focused=has_focus()
 var dim=data.sold or data.closed or not data.available
 if tier>=FogPalette.Rarity.UNCOMMON and RaritySlot.GLOW.has(tier) and not dim:
  var g: Array=RaritySlot.GLOW[tier];var reach: float=g[1]*0.9;var col: Color=g[0]
  for i in 5:
   var k=float(i+1)/5.0;draw_rect(r.grow(reach*k*0.5),Color(col.r,col.g,col.b,col.a*0.1*(1.0-k)),false,reach/5.0)
 draw_rect(r,Color("1F1A1A") if focused else info["bg"])
 draw_rect(r.grow(-1.0),FogPalette.RUST_BRIGHT if focused else (color if tier>0 else Color("3A3D38")),false,2.0 if (focused or tier>0) else 1.0)
 var x=140.0;var cw=SIZE_PX.x-20.0-168.0-22.0-x
 var tag_font=MenuStyle.sans(800,0.24,12);var label=str(data.tier_name).to_upper()
 var tx=x
 if tier>0:
  var w=tag_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+28.0
  draw_rect(Rect2(Vector2(tx,22),Vector2(w,20)),color);draw_string(tag_font,Vector2(tx+22,37),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,info["on"])
  draw_colored_polygon(PackedVector2Array([Vector2(tx+12,26),Vector2(tx+14,31),Vector2(tx+19,32),Vector2(tx+14,33),Vector2(tx+12,38),Vector2(tx+10,33),Vector2(tx+5,32),Vector2(tx+10,31)]),info["on"])
  draw_string(tag_font,Vector2(tx+w+10,37),str(data.kind_label).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color.lightened(0.45))
 else:draw_string(tag_font,Vector2(tx,37),"%s ∙ %s"%[label,str(data.kind_label).to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("A9ADA4"))
 draw_string(MenuStyle.serif(),Vector2(x,78),str(data.name),HORIZONTAL_ALIGNMENT_LEFT,cw,30,FogPalette.BONE)
 draw_multiline_string(MenuStyle.sans(400,0,16),Vector2(x,102),str(data.description),HORIZONTAL_ALIGNMENT_LEFT,cw,16,2,Color("B9BAB1"))
 draw_string(MenuStyle.sans(600,0.14,13),Vector2(x,SIZE_PX.y-14),"OWNED ×%d → ×%d"%[int(data.owned),int(data.owned_after)],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("8D9188"))
 draw_string(MenuStyle.sans(800,0.2,12),Vector2(SIZE_PX.x-20-168-30,SIZE_PX.y-14),"[%d]"%number,HORIZONTAL_ALIGNMENT_RIGHT,30,12,Color("5A5D56"))
 var b=buy_rect();var text=button_text();var f=MenuStyle.sans(800,0.2,13)
 if can_buy():
  if focused:draw_rect(b,FogPalette.RUST)
  else:draw_rect(b.grow(-0.5),Color("5A5D56"),false,1.0)
  var ink=Color("F4EFE2") if focused else Color("D9D4C4")
  draw_string(f,b.position+Vector2((b.size.x-f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)*0.5,26),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
 else:
  var xx=0.0;var line=Color("5A5D56")
  while xx<b.size.x:draw_line(b.position+Vector2(xx,0.5),b.position+Vector2(minf(xx+5.0,b.size.x),0.5),line);draw_line(b.position+Vector2(xx,b.size.y-0.5),b.position+Vector2(minf(xx+5.0,b.size.x),b.size.y-0.5),line);xx+=10.0
  var yy=0.0
  while yy<b.size.y:draw_line(b.position+Vector2(0.5,yy),b.position+Vector2(0.5,minf(yy+5.0,b.size.y)),line);draw_line(b.position+Vector2(b.size.x-0.5,yy),b.position+Vector2(b.size.x-0.5,minf(yy+5.0,b.size.y)),line);yy+=10.0
  var ink=FogPalette.RUST_TEXT if (not data.affordable and not data.sold and not data.closed) else Color("8D9188")
  draw_string(f,b.position+Vector2((b.size.x-f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)*0.5,26),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
