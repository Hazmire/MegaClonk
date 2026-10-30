class_name PickupPopups
extends Control
# World-space pickup numbers ("+12" gold, "+30 XP") as a fixed pool of Labels: nothing is allocated after setup. Pickups
# of the same kind arriving close together merge into one popup that keeps counting up. If every slot is busy the oldest
# is reused, so the cap is hard.
const CAP=10
const LIFE=0.9
const MERGE_WINDOW=0.6
const MERGE_RADIUS=140.0
const RISE=46.0
var slots: Array=[] # {label, kind, amount, age, origin, live}
func _init() -> void:
 name="PickupPopups";mouse_filter=Control.MOUSE_FILTER_IGNORE;set_process(false)
 for i in CAP:
  var l=MenuStyle.label("",MenuStyle.sans(800,0,30),30,FogPalette.BONE_BRIGHT,2,self);l.visible=false
  var icon=ColorRect.new();icon.size=Vector2(14,14);icon.pivot_offset=Vector2(7,7);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.visible=false;add_child(icon)
  slots.append({"icon":icon,"label":l,"kind":"","amount":0.0,"age":0.0,"origin":Vector2.ZERO,"live":false})
static func text_for(kind: String,amount: float) -> String:
 return ("+%d XP" if kind=="xp" else "+%d")%roundi(amount)
static func color_for(kind: String) -> Color:return FogPalette.XP_GLOW if kind=="xp" else FogPalette.GOLD
# `at` is in this control's coordinates (design pixels).
func add(kind: String,amount: float,at: Vector2) -> void:
 for s in slots:
  if s.live and s.kind==kind and s.age<MERGE_WINDOW and s.origin.distance_to(at)<MERGE_RADIUS:
   s.amount+=amount;s.age=0.0;s.origin=at;_paint(s);set_process(true);return
 var pick=null
 for s in slots:
  if not s.live:pick=s;break
 if pick==null:
  pick=slots[0]
  for s in slots:
   if s.age>pick.age:pick=s
 pick.kind=kind;pick.amount=amount;pick.age=0.0;pick.origin=at;pick.live=true;_paint(pick);pick.label.visible=true;pick.icon.visible=true;set_process(true)
func _paint(s: Dictionary) -> void:
 s.label.text=text_for(s.kind,s.amount);s.icon.color=color_for(s.kind) if s.kind!="xp" else Color("7FC4FF");s.icon.rotation_degrees=45.0 if s.kind=="xp" else 0.0;s.label.add_theme_color_override("font_color",color_for(s.kind))
func live_count() -> int:
 var n=0
 for s in slots:
  if s.live:n+=1
 return n
func _process(delta: float) -> void:
 var any=false
 for s in slots:
  if not s.live:continue
  s.age+=delta
  if s.age>=LIFE:s.live=false;s.label.visible=false;s.icon.visible=false;continue
  any=true;var k=s.age/LIFE;var pop=1.0+0.25*maxf(0.0,1.0-s.age/0.12)
  s.label.position=s.origin+Vector2(-s.label.size.x*0.5,-RISE*k);s.label.pivot_offset=s.label.size*0.5;s.label.scale=Vector2(pop,pop);s.label.modulate.a=1.0-maxf(0.0,(k-0.6)/0.4);s.icon.position=s.label.position+Vector2(-18,s.label.size.y*0.5-7);s.icon.modulate.a=s.label.modulate.a
 if not any:set_process(false)
