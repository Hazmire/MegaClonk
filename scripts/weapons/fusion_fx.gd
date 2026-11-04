class_name FusionFx
extends RefCounted

# What a Fusion looks like in combat. Everything draws through the pooled PsxFx (squares, shards, segments): no node, mesh or material is
# created per hit, and PsxFx's hard caps bound it. The palettes, shapes and signatures come from the Fusion effects pack
# (res://vfx/weapons/scripts/fusion_layer.gd); that script allocates nodes per effect, so it is used only for the one-off forging moment.
#   tint     every colour a Fusion weapon draws is re-hued to the Fusion's two tones (PsxFx.tint_begin / tint_end)
#   trail    the fused trail on anything that travels
#   impact   the Fusion's signature hit; the impacts share the 24/s combo budget, above it only the small status look plays
#   status   the small fused look on an enemy (also what an over-budget impact falls back to)
#   motes    two gem motes that orbit the player while a Fusion is held
const MOTE_ORBIT_SPEED=2.6
static func budget_per_second() -> float:return float(Elements.TUNING.combos.budget_per_second)
# Takes one token from the runtime's per-second bucket (refilled in WeaponRuntime.update).
static func take(rt: WeaponRuntime) -> bool:
 if rt.fusion_budget<1.0:rt.counters.fusion_skipped=int(rt.counters.get("fusion_skipped",0))+1;return false
 rt.fusion_budget-=1.0;rt.counters.fusion_impacts=int(rt.counters.get("fusion_impacts",0))+1;return true
static func begin(rt: WeaponRuntime,fusion: String) -> void:
 if fusion=="":return
 var p=Fusions.palette(fusion);rt.psx.tint_begin(p.mid,p.acc,p.core)
static func finish(rt: WeaponRuntime) -> void:
 rt.psx.tint_end()
static func trail(rt: WeaponRuntime,fusion: String,pos: Vector3,scale: float=1.0) -> void:
 var was=rt.psx.tint_on;rt.psx.tint_on=false # the Fusion's own colours are already exact: never re-hue them
 _trail(rt,fusion,pos,scale)
 rt.psx.tint_on=was
static func _trail(rt: WeaponRuntime,fusion: String,pos: Vector3,scale: float=1.0) -> void:
 if fusion=="":return
 var p=Fusions.palette(fusion);var psx=rt.psx;var r=rt.psx.rng
 var up=Vector3(r.randf_range(-0.6,0.6),r.randf_range(0.0,1.2),r.randf_range(-0.6,0.6))
 match fusion:
  "steamforged":
   psx.spark(pos,up*0.8+Vector3.UP*1.1,p.smoke,p.smoke.darkened(0.3),0.34*scale,0.16*scale,0.5,-1.0,0.8)
   psx.spark(pos,up,p.acc,p.deep,0.1*scale,0.04*scale,0.35,4.0,0.5)
  "plasma":
   psx.spark(pos,up*0.5,p.core,p.mid,0.2*scale,0.08*scale,0.14)
   psx.spark(pos,up*5.0,p.mid,p.deep,0.08*scale,0.03*scale,0.2,0.0,1.0)
  "aurora":
   psx.spark(pos,up*0.3,p.mid,p.deep,0.1*scale,0.05*scale,0.9,-0.4,0.6)
   psx.spark(pos,up*0.2,p.acc,p.deep,0.07*scale,0.03*scale,0.7,-0.3,0.6)
  "livewire":
   psx.spark(pos,Vector3(up.x,-1.0,up.z)*0.8,p.mid,p.deep,0.1*scale,0.04*scale,0.5,12.0,0.2)
   psx.spark(pos,up*3.5,p.acc,p.core,0.07*scale,0.03*scale,0.14)
  "pyrebile":
   psx.spark(pos,up*0.7+Vector3.UP*1.0,p.acc,p.mid,0.2*scale,0.08*scale,0.4,-1.5,0.8)
   psx.spark(pos,up*0.5+Vector3.UP*1.4,p.smoke,p.smoke,0.34*scale,0.22*scale,0.8,-1.2,0.8)
  "rimerot":
   psx.spark(pos,up*0.3,p.smoke,p.deep,0.3*scale,0.12*scale,0.9,-0.1,0.7)
   psx.spark(pos,up*0.2,p.acc,p.mid,0.07*scale,0.03*scale,0.8,-0.3,0.6)
# The small fused status look on an enemy.
static func status(rt: WeaponRuntime,fusion: String,pos: Vector3) -> void:
 var was=rt.psx.tint_on;rt.psx.tint_on=false # the Fusion's own colours are already exact: never re-hue them
 _status(rt,fusion,pos)
 rt.psx.tint_on=was
static func _status(rt: WeaponRuntime,fusion: String,pos: Vector3) -> void:
 if fusion=="":return
 var p=Fusions.palette(fusion);var psx=rt.psx
 psx.burst(pos+Vector3.UP*0.7,2,[p.mid,p.acc],2.0,0.1,0.28,1.0,1.2,Vector3.UP,1.0)
# The Fusion's signature hit. `k` scales the size (forms use it for bigger moments).
static func impact(rt: WeaponRuntime,fusion: String,pos: Vector3,dir: Vector3=Vector3.UP,k: float=1.0) -> void:
 var was=rt.psx.tint_on;rt.psx.tint_on=false # the Fusion's own colours are already exact: never re-hue them
 _impact(rt,fusion,pos,dir,k)
 rt.psx.tint_on=was
static func _impact(rt: WeaponRuntime,fusion: String,pos: Vector3,dir: Vector3=Vector3.UP,k: float=1.0) -> void:
 if fusion=="":return
 if not take(rt):status(rt,fusion,pos);return
 var p=Fusions.palette(fusion);var psx=rt.psx;var r=rt.psx.rng
 var ground=Vector3(pos.x,rt.game.terrain_height(pos.x,pos.z)+0.1,pos.z)
 match fusion:
  "steamforged": # an ice shell snaps shut over the hit, then cracks into a steam cloud with embers
   psx.shards(pos,int(6*k),p.acc,6.0,0.2,0.45,10.0,Vector3.UP,1.6)
   psx.burst(pos+Vector3.UP*0.3,int(5*k),[p.smoke,p.core],2.2,0.5*k,0.9,-1.4,1.4,Vector3.UP,1.0)
   psx.burst(pos,int(4*k),[p.mid,p.core],5.0,0.13,0.7,8.0,0.8,Vector3.UP,1.4)
  "plasma": # white-hot core, violet corona ring, a crackle line
   psx.burst(pos,int(5*k),[p.core,p.mid],8.0,0.22*k,0.3,0.0,2.0)
   psx.ring(ground,0.5*k,int(10*k),p.mid,0.2,0.32,5.0)
   var d=Vector3(r.randf_range(-1,1),0,r.randf_range(-1,1)).normalized()
   psx.bolt(pos,pos+d*2.0*k,p.mid,p.core,0.08,0.18,4,2,0.05)
  "aurora": # crystals hang where the hit landed and zap each other
   psx.shards(pos+Vector3.UP*0.4,int(4*k),p.acc,1.6,0.26,1.1,-0.4,Vector3.UP,1.2)
   psx.burst(pos,int(4*k),[p.core,p.mid],6.0,0.12,0.35,0.0,1.5)
   psx.bolt(pos+Vector3(0.7,0.8,0),pos+Vector3(-0.7,0.6,0.3),p.mid,p.core,0.06,0.15,4,2,0.05)
  "livewire": # dripping green lightning and a fizzing puddle
   psx.bolt(pos+Vector3.UP*1.6,pos,p.mid,p.core,0.1,0.35,6,2,0.045)
   psx.burst(pos+Vector3.UP*0.5,int(4*k),[p.mid,p.deep],3.0,0.11,0.6,14.0,0.4,Vector3.DOWN,1.2)
   psx.ring(ground,0.4*k,int(6*k),p.acc,0.13,0.35,1.6)
  "pyrebile": # sticky burning globs under black smoke
   psx.burst(pos,int(5*k),[p.acc,p.mid,p.core],4.0,0.32*k,0.55,-1.0,1.5,Vector3.UP,1.1)
   psx.burst(pos+Vector3.UP*0.5,int(3*k),[p.smoke],2.0,0.55*k,1.0,-1.8,1.0,Vector3.UP,0.6)
   psx.burst(ground,2,[p.mid],0.4,0.4*k,0.9,0.0,0.5)
  "rimerot": # black ice spikes grow from the ground, frost-rot spreads
   for i in int(3*k):
    var a=r.randf()*TAU;var at=ground+Vector3(cos(a),0,sin(a))*r.randf_range(0.2,0.8)*k
    psx.segment(at,at+Vector3(r.randf_range(-0.15,0.15),r.randf_range(0.8,1.4)*k,r.randf_range(-0.15,0.15)),0.2,p.deep,p.acc,0.9,0.03*i,0.2)
   psx.burst(pos,int(4*k),[p.smoke,p.deep],2.0,0.4*k,0.9,-0.4,1.2,Vector3.UP,1.2)
   psx.ring(ground,0.6*k,int(8*k),p.mid,0.15,0.5,2.0)
# Two gem motes orbit the player while a Fusion is held. Drawn immediate-mode each frame, so nothing persists.
static func motes(rt: WeaponRuntime,fusion: String,t: float) -> void:
 var was=rt.psx.tint_on;rt.psx.tint_on=false # the Fusion's own colours are already exact: never re-hue them
 _motes(rt,fusion,t)
 rt.psx.tint_on=was
static func _motes(rt: WeaponRuntime,fusion: String,t: float) -> void:
 if fusion=="":return
 var game=rt.game;var center: Vector3=game.player.position+Vector3(0,1.3,0)
 var gems: Array=Fusions.TABLE[fusion].gems
 for i in 2:
  var a=t*MOTE_ORBIT_SPEED+PI*i
  var at=center+Vector3(cos(a)*0.85,sin(t*1.7+i)*0.15,sin(a)*0.85)
  rt.psx.draw_square(at,0.16,Elements.color(str(gems[i])))
# A tether between two points (Livewire-style; any Fusion's forms may call it).
static func tether(rt: WeaponRuntime,fusion: String,a: Vector3,b: Vector3) -> void:
 var was=rt.psx.tint_on;rt.psx.tint_on=false # the Fusion's own colours are already exact: never re-hue them
 _tether(rt,fusion,a,b)
 rt.psx.tint_on=was
static func _tether(rt: WeaponRuntime,fusion: String,a: Vector3,b: Vector3) -> void:
 var p=Fusions.palette(fusion)
 rt.psx.bolt(a,b,p.mid,p.core,0.07,0.3,5,2,0.06)
