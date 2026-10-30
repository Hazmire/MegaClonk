class_name RunToasts
extends Control
# Pickup notifications for socket gems, Imbued Amulets and items (RunGemPickup). One reusable card, no per-toast nodes.
# Sequence per toast: burst at the pickup (0.5 s, rings + sparks + screen-edge glow 1.1 s) -> the glyph flies to the
# card's socket (0.42 s) -> the card shows (2.6 s, or at least 1.2 s while others wait) -> collect (0.45 s): the card
# shrinks and the glyph flies to its slot on the HUD, which bumps and shows "+1". Same-key pickups merge into "×n" and the
# waiting line is capped (ToastQueue). Never blocks input and never touches game time: all timing is real time.
const CARD=Vector2(660,136)
const CARD_POS=Vector2(630,216)
const BURST=0.5
const FLY=0.42
const COLLECT=0.45
const EDGE_GLOW=1.1
var queue=ToastQueue.new()
var hud: RunHud
var phase="idle" # idle | burst | fly | show | collect
var t=0.0
var glow_t=99.0
var entry: Dictionary={}
var origin=Vector2(960,520)
var edge: Array=[]
var fx: Control
var glyph: Control
var card: Control
var socket: Control
var caption: Label
var title: Label
var detail: Label
var hint: Label
var stamp: Stamp
var count_label: Label
var palette={} # color, light, mid
var shown_count=0
var card_y=216.0 # set by RunHud each update: sits under the boss bars when there are any
func setup(owner_hud: RunHud) -> RunToasts:
 hud=owner_hud;name="RunToasts";mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(MenuStyle.W,MenuStyle.H);set_process(false)
 for i in 4:
  var g=TextureRect.new();g.mouse_filter=Control.MOUSE_FILTER_IGNORE;g.stretch_mode=TextureRect.STRETCH_SCALE;g.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;g.modulate.a=0.0;add_child(g);edge.append(g)
 edge[0].position=Vector2.ZERO;edge[0].size=Vector2(size.x,140) # top
 edge[1].position=Vector2(0,size.y-140);edge[1].size=Vector2(size.x,140) # bottom
 edge[2].position=Vector2.ZERO;edge[2].size=Vector2(140,size.y) # left
 edge[3].position=Vector2(size.x-140,0);edge[3].size=Vector2(140,size.y) # right
 fx=Control.new();fx.mouse_filter=Control.MOUSE_FILTER_IGNORE;fx.size=size;fx.draw.connect(_draw_fx);add_child(fx)
 card=Control.new();card.name="ToastCard";card.size=CARD;card.position=CARD_POS;card.pivot_offset=CARD*0.5;card.visible=false;card.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.draw.connect(_draw_card);add_child(card)
 socket=Control.new();socket.size=Vector2(92,92);socket.position=Vector2(22,22);socket.pivot_offset=Vector2(46,46);socket.mouse_filter=Control.MOUSE_FILTER_IGNORE;socket.draw.connect(_draw_socket);card.add_child(socket)
 caption=MenuStyle.label("",MenuStyle.sans(800,0.28,13),13,FogPalette.ASH_DIM,0,card);caption.position=Vector2(138,16)
 stamp=MenuStyle.spawn("stamp") as Stamp;card.add_child(stamp)
 count_label=MenuStyle.label("",MenuStyle.sans(800,0.1,14),14,FogPalette.BONE_BRIGHT,0,card)
 title=MenuStyle.label("",MenuStyle.serif(),38,FogPalette.BONE_BRIGHT,2,card);title.position=Vector2(138,32)
 detail=MenuStyle.label("",MenuStyle.sans(400,0,14),14,FogPalette.ASH,0,card);detail.position=Vector2(138,82);detail.size=Vector2(500,20);detail.clip_text=true;detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 hint=MenuStyle.label("",MenuStyle.sans(600,0.12,12),12,FogPalette.ASH_DIM,0,card);hint.position=Vector2(138,108)
 glyph=Control.new();glyph.size=Vector2(24,24);glyph.pivot_offset=Vector2(12,12);glyph.visible=false;glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE;glyph.draw.connect(_draw_glyph);add_child(glyph)
 return self
# ---- entry points (called by FrontEnd) --------------------------------------------------------------------------------
func push_gem(element: String,count_now: int,at: Vector2) -> void:
 origin=at;queue.push("gem:"+element,{"kind":"gem","element":element,"owned":count_now,"new":count_now<=1,"name":"%s Gem"%Elements.display_name(element),"detail":Elements.summary(element),"color":Elements.color(element)});_wake()
func push_item(id: String,owned: int,at: Vector2) -> void:
 var amulet=id=="imbued_amulet";var data: Dictionary=Catalog.ITEMS.get(id,{});var tier=RunData.tier_index(str(data.get("tier","common")))
 queue.push("item:"+id,{"kind":"amulet" if amulet else "item","id":id,"owned":owned,"new":owned<=1,"tier":tier,"name":Catalog.item_name(id),"detail":Catalog.item_description(id,false),"color":MenuStyle.rarity_color(tier)});origin=at;_wake()
func _wake() -> void:set_process(true)
# ---- state machine ------------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
 glow_t+=delta
 var glow=clampf(1.0-glow_t/EDGE_GLOW,0.0,1.0)
 for g in edge:g.modulate.a=glow*0.9
 match phase:
  "idle":
   if queue.start_next():_begin(queue.current)
   elif glow<=0.0 and not queue.busy():set_process(false)
  "burst":
   t+=delta;fx.queue_redraw();glyph.position=origin-Vector2(12,12);glyph.visible=true;var k=clampf(t/BURST,0.0,1.0);var s=1.0+0.25*sin(k*PI)+(0.0);glyph.scale=Vector2(s,s)
   if t>=BURST:phase="fly";t=0.0
  "fly":
   t+=delta;var k=clampf(t/FLY,0.0,1.0);var e=k*k*(3.0-2.0*k)
   var target=Vector2(CARD_POS.x,card_y)+socket.position+Vector2(46,46)-Vector2(12,12);glyph.position=(origin-Vector2(12,12)).lerp(target,e);var s=lerpf(1.25,1.6,e);glyph.scale=Vector2(s,s);fx.queue_redraw()
   if t>=FLY:phase="show";t=0.0;glyph.visible=false;_open_card()
  "show":
   t+=delta;_animate_show()
   var done=queue.tick(delta)
   if not done.is_empty():entry=done;phase="collect";t=0.0
  "collect":
   t+=delta;var k=clampf(t/COLLECT,0.0,1.0)
   card.scale=Vector2(1.0-0.45*k,1.0-0.45*k);card.modulate.a=1.0-k;card.queue_redraw()
   var from=Vector2(CARD_POS.x,card_y)+socket.position+Vector2(46,46)-Vector2(12,12);var to=hud.slot_center(entry)-Vector2(12,12);glyph.visible=true
   var e=k*k;glyph.position=from.lerp(to,e);var s=lerpf(1.6,0.8,e);glyph.scale=Vector2(s,s)
   if t>=COLLECT:
    card.visible=false;glyph.visible=false;hud.bump(entry);phase="idle";t=0.0;entry={}
func _begin(e: Dictionary) -> void:
 entry=e;var d: Dictionary=e.data;var c: Color=d.color
 palette={"color":c,"light":c.lightened(0.4),"mid":c.darkened(0.1)}
 phase="burst";t=0.0;glow_t=0.0;shown_count=0
 var edge_color=Color(c.r,c.g,c.b,0.55)
 edge[0].texture=MenuStyle.gradient(edge_color,Color(c.r,c.g,c.b,0.0),true);edge[1].texture=MenuStyle.gradient(Color(c.r,c.g,c.b,0.0),edge_color,true)
 edge[2].texture=MenuStyle.gradient(edge_color,Color(c.r,c.g,c.b,0.0),false);edge[3].texture=MenuStyle.gradient(Color(c.r,c.g,c.b,0.0),edge_color,false)
 glyph.queue_redraw();card.visible=false
func _open_card() -> void:
 var d: Dictionary=queue.current.data
 var kind=str(d.kind)
 caption.text={"gem":"SOCKET GEM FOUND","amulet":"LEGENDARY FIND","item":"ITEM FOUND"}[kind]
 title.text=str(d.name);detail.text=str(d.detail)
 hint.text={"gem":"Socket it at an Imbue Station · Tab view build","amulet":"Use it at an Imbue Station · Tab view build","item":"Stacks with copies you already hold · Tab view build"}[kind]
 card.position=Vector2(CARD_POS.x,card_y);card.visible=true;card.modulate.a=1.0;card.scale=Vector2(0.0,1.0);card.queue_redraw();socket.queue_redraw();_refresh_count(true)
func _refresh_count(force: bool=false) -> void:
 var e: Dictionary=queue.current
 if e.is_empty():return
 var n=int(e.count)
 if not force and n==shown_count:return
 shown_count=n;var d: Dictionary=e.data
 var owned=int(d.owned)+(n-1)
 if bool(d.new):stamp.setup("NEW ELEMENT" if d.kind=="gem" else "NEW",FogPalette.GOLD,13,0.22,2,-3.0,Color(0.16,0.12,0.03,0.9))
 else:stamp.setup("OWNED ×%d"%owned,FogPalette.ASH,13,0.22,1,-2.0)
 stamp.position=Vector2(CARD.x-stamp.size.x-22,12)
 count_label.text="×%d"%n if n>1 else "";count_label.position=Vector2(CARD.x-70,50);count_label.visible=n>1
 if n>1:count_label.add_theme_color_override("font_color",palette.light)
func _animate_show() -> void:
 _refresh_count()
 var k=clampf(t/0.35,0.0,1.0);var back=1.0+2.70158*pow(k-1.0,3.0)+1.70158*pow(k-1.0,2.0) # ease out back
 card.scale=Vector2(maxf(0.0,back),1.0)
 socket.scale=Vector2(1.0,1.0);socket.queue_redraw();card.queue_redraw()
# ---- drawing --------------------------------------------------------------------------------------------------------
func _draw_card() -> void:
 if palette.is_empty():return
 var c: Color=palette.color;var r=Rect2(Vector2.ZERO,CARD)
 for i in 6:draw_glow(card,r.grow(4+i*5),Color(c.r,c.g,c.b,0.05*(1.0-i/6.0)))
 card.draw_rect(r,Color(0.055,0.059,0.055,0.94));card.draw_rect(r.grow(-0.5),FogPalette.BORDER,false,1.0);card.draw_rect(Rect2(0,0,CARD.x,4),c)
 var shine=clampf((t-0.35)/0.5,0.0,1.0)
 if phase=="show" and shine>0.0 and shine<1.0:
  var x=lerpf(-120.0,CARD.x+60.0,shine);card.draw_colored_polygon(PackedVector2Array([Vector2(x,4),Vector2(x+60,4),Vector2(x+20,CARD.y),Vector2(x-40,CARD.y)]),Color(1,1,1,0.10))
func draw_glow(node: Control,rect: Rect2,color: Color) -> void:node.draw_rect(rect,color,false,5.0)
func _draw_socket() -> void:
 if palette.is_empty() or queue.current.is_empty():return
 var d: Dictionary=queue.current.data;var c: Color=palette.color;var r=Rect2(Vector2.ZERO,socket.size)
 var pulse=0.5+0.5*sin(Time.get_ticks_msec()/1000.0*4.0)
 for i in 5:socket.draw_rect(r.grow(2+i*3),Color(c.r,c.g,c.b,(0.20+0.15*pulse)*(1.0-i/5.0)),false,3.0)
 socket.draw_rect(r,FogPalette.NIGHT_TILE if d.kind=="gem" else FogPalette.RARITY[d.get("tier",0)].bg);socket.draw_rect(r.grow(-1),c,false,2.0)
 if d.kind=="gem":
  var spin=absf(cos(Time.get_ticks_msec()/1000.0*1.6));var ctr=r.get_center();var hw=30.0*maxf(0.12,spin);var hh=30.0
  var poly=PackedVector2Array([ctr+Vector2(0,-hh),ctr+Vector2(hw,0),ctr+Vector2(0,hh),ctr+Vector2(-hw,0)])
  socket.draw_colored_polygon(poly,Color(c.r,c.g,c.b,0.55));socket.draw_polyline(poly+PackedVector2Array([poly[0]]),palette.light,3.0)
 else:
  var tex=UIAssets.icon("items",str(d.id));if tex!=null:socket.draw_texture_rect(tex,Rect2(14,14,64,64),false)
func _draw_glyph() -> void:
 if palette.is_empty():return
 var d: Dictionary=entry.get("data",{}) if not entry.is_empty() else {}
 var c: Color=palette.color
 if d.get("kind","gem")=="gem":
  var poly=PackedVector2Array([Vector2(12,0),Vector2(24,12),Vector2(12,24),Vector2(0,12)]);glyph.draw_colored_polygon(poly,c);glyph.draw_polyline(poly+PackedVector2Array([poly[0]]),palette.light,2.0)
 else:
  var tex=UIAssets.icon("items",str(d.get("id","")));if tex!=null:glyph.draw_texture_rect(tex,Rect2(0,0,24,24),false)
func _draw_fx() -> void:
 if palette.is_empty() or phase=="idle" or phase=="show" or phase=="collect":return
 var k=clampf(t/BURST,0.0,1.0) if phase=="burst" else 1.0
 for ring in [[0.6,64.0],[0.7,96.0]]:
  var rk=clampf(t/ring[0],0.0,1.0) if phase=="burst" else 1.0
  if rk<1.0:fx.draw_arc(origin,ring[1]*rk,0,TAU,32,Color(palette.light.r,palette.light.g,palette.light.b,1.0-rk),3.0)
 if phase=="burst":
  for i in 10:
   var a=TAU*float(i)/10.0+0.3;var dist=80.0*k;var col=palette.light if i%2==0 else palette.mid
   fx.draw_rect(Rect2(origin+Vector2(cos(a),sin(a))*dist-Vector2(2,2),Vector2(4,4)),Color(col.r,col.g,col.b,1.0-k))
