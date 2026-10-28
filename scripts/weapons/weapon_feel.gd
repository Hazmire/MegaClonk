class_name WeaponFeel
extends RefCounted

# Palettes, impact particles and audio routing for the eight weapons. Everything draws through the
# pooled PsxFx framework (squares, shards, stepped segments); nothing here creates a node or material.
# Palettes are deliberately tiny (3-4 colours each) so the 640x360 5-bit composite keeps them distinct.
const SLASH_WHITE=Color("f7f7f1");const SLASH_EDGE=Color("cfe3ff");const SLASH_GHOST=Color("9aa0aa")
const FIRE_CORE=Color("fff09a");const FIRE_MID=Color("ffb52e");const FIRE_OUTER=Color("f2551d");const FIRE_DEEP=Color("b32a14");const EMBER_DEAD=Color("3a2118")
const BOLT_OUTER=Color("3f7be8");const BOLT_INNER=Color("eaf4ff");const BOLT_SPARK=Color("86b8ff")
const ARROW_SHAFT=Color("231f1c");const ARROW_FIN=Color("4a4038");const ARROW_TIP=Color("ffffff");const ARROW_GLOW=Color("d6e6ff");const ARROW_DUST=Color("b9bcae")
const BULLET_BODY=Color("d9dce2");const BULLET_HEAD=Color("ffffff");const SMOKE_LIGHT=Color("8d9096");const SMOKE_DARK=Color("55585d");const SPARK_GOLD=Color("ffe08a")
const AURA_DARK=Color("1f5a2a");const AURA_MID=Color("2f8a3c");const AURA_LIGHT=Color("9be88a");const AURA_FLASH=Color("d4ffb8");const AURA_SMOKE=Color("17381d")
const DUST_LIGHT=Color("d9c79e");const DUST_MID=Color("b99a6a");const DUST_DARK=Color("7c5f3c");const BLADE_STEEL=Color("b9bfc9")
const SHOT_FLASH=Color("fff6c8");const SHOT_SPARK=Color("ffd24a");const SHOT_SMOKE=Color("7b7d82");const SHOT_SMOKE_DARK=Color("4c4e52")
const CRIT=Color("fff0a0")
# source id -> [hit sound event, crit sound event]
const AUDIO={
 "slash":["weapon.sword.hit","weapon.sword.crit"],
 "fireball":["weapon.firestaff.impact","weapon.firestaff.crit"],
 "strike":["","weapon.lightning.crit"],
 "chain":["weapon.lightning.chain","weapon.lightning.crit"],
 "arrow":["weapon.bow.hit","weapon.bow.crit"],
 "bullet":["weapon.revolver.hit","weapon.revolver.crit"],
 "ricochet":["weapon.revolver.hit","weapon.revolver.crit"],
 "pulse":["","weapon.aura.crit"],
 "scythe_out":["weapon.scythes.hit","weapon.scythes.crit"],
 "scythe_back":["weapon.scythes.hit","weapon.scythes.crit"],
 "pellet":["weapon.shotgun.hit","weapon.shotgun.crit"]
}
static func cam_pos(rt: WeaponRuntime) -> Vector3:
 var camera=rt.game.get_viewport().get_camera_3d()
 return camera.global_position if camera!=null else rt.game.player.position+Vector3(0,6,8)
# Called from Game.hit for every damaging weapon hit, after crit has been rolled.
static func impact(rt: WeaponRuntime,id: int,source: String,pos: Vector3,dir: Vector3,critical: bool,e: Dictionary) -> void:
 var psx=rt.psx
 var sound=AUDIO.get(source,["",""])
 var home=rt.game.audio
 match source:
  "slash":
   psx.burst(pos,6,[SLASH_WHITE,SLASH_WHITE,SLASH_EDGE],7.0,0.2,0.28,6.0,1.5,dir,1.2)
   psx.shards(pos,2,SLASH_WHITE,6.0,0.16,0.35,14.0,dir,1.6)
  "fireball":
   fire_burst(rt,pos,dir,1.0)
  "strike","chain":
   psx.burst(pos+Vector3.UP*0.2,7,[BOLT_OUTER,BOLT_SPARK,BOLT_INNER],8.0,0.2,0.3,4.0,1.0,Vector3.UP,1.6)
  "arrow":
   psx.burst(pos,4,[ARROW_DUST,ARROW_GLOW,ARROW_TIP],5.0,0.16,0.26,8.0,1.4,dir,1.4)
  "bullet","ricochet":
   psx.burst(pos,5,[SPARK_GOLD,BULLET_HEAD,SMOKE_LIGHT],7.5,0.14,0.22,9.0,1.2,-dir,1.4)
  "pulse":
   if rt.pulse_budget>0:
    rt.pulse_budget-=1;psx.ring(Vector3(pos.x,rt.game.terrain_height(pos.x,pos.z)+0.1,pos.z),0.5,8,AURA_LIGHT,0.16,0.35,1.8)
  "scythe_out","scythe_back":
   psx.burst(pos,5,[DUST_LIGHT,DUST_MID,DUST_DARK],5.0,0.2,0.4,5.0,1.5,Vector3.UP,1.5)
   psx.shards(pos,1,DUST_MID,4.5,0.14,0.45,12.0,Vector3.UP,1.5)
  "pellet":
   psx.burst(pos,3,[SHOT_SPARK,SHOT_FLASH],6.0,0.13,0.2,8.0,1.5,-dir,1.5)
 if critical:
  # Restrained crit accent: a small upward pop of four bright squares, nothing screen-filling.
  psx.burst(pos+Vector3.UP*0.5,4,[CRIT,SLASH_WHITE],5.0,0.2,0.3,3.0,1.0,Vector3.UP,0.9)
 if home!=null:
  var event=str(sound[1] if critical else sound[0])
  if event!="":home.emit(event,pos,1.0,1.0)
static func fire_burst(rt: WeaponRuntime,pos: Vector3,dir: Vector3,power: float) -> void:
 var psx=rt.psx
 # flame burst (short lived), then embers that arc and extinguish (colour steps to dead brown)
 psx.burst(pos,int(9*power),[FIRE_CORE,FIRE_MID,FIRE_OUTER],5.0*power,0.42,0.3,-2.0,2.5,Vector3.UP,1.4,FIRE_DEEP)
 psx.burst(pos,int(7*power),[FIRE_MID,FIRE_OUTER,FIRE_DEEP],7.5*power,0.17,0.9,13.0,0.6,Vector3.UP,1.3,EMBER_DEAD)
 if dir!=Vector3.ZERO:psx.burst(pos,int(4*power),[FIRE_OUTER,FIRE_MID],8.0,0.2,0.5,9.0,0.8,dir,0.7,EMBER_DEAD)
 psx.burst(pos,int(2*power),[SMOKE_DARK],2.0,0.3,0.6,-1.5,1.0,Vector3.UP,0.6)
# Casting-side feedback ------------------------------------------------------------------
static func sword_arc(rt: WeaponRuntime,origin: Vector3,dir: Vector3,reach: float,half: float,index: int,tilt: float) -> void:
 var psx=rt.psx
 var flip=-1.0 if index%2==1 else 1.0
 var right=dir.cross(Vector3.UP).normalized()
 var f=dir
 var pieces=9
 var points=[];var ghost_points=[]
 for k in pieces+1:
  var a=-half+2.0*half*float(k)/pieces
  var local=(f*cos(a)+right*sin(a))*reach*0.86
  local=Basis(f,tilt)*local
  points.append(origin+local+Vector3.UP*0.15)
  ghost_points.append(origin+Basis(f,tilt)*((f*cos(a)+right*sin(a))*reach*0.7)+Vector3.UP*0.1)
 for k in pieces:
  var order=k if flip>0.0 else pieces-1-k
  var delay=order*0.0105 # stepped sweep: each facet appears a tick after the last
  var mid=1.0-absf(float(k)-pieces*0.5+0.5)/(pieces*0.5)
  var width=0.2+0.55*mid
  psx.segment(points[k],points[k+1],width,SLASH_WHITE,SLASH_EDGE,0.12,delay,0.45)
  psx.segment(points[k]+Vector3.UP*0.08,points[k+1]+Vector3.UP*0.08,width*0.4,Color.WHITE,Color.WHITE,0.07,delay,0.5)
  psx.segment(ghost_points[k],ghost_points[k+1],width*0.55,SLASH_GHOST,SLASH_GHOST.darkened(0.4),0.2,delay+0.09,0.35) # afterimage
 for k in 6:
  var a=-half+2.0*half*(float(k)+0.5)/6.0
  var outward=(f*cos(a)+right*sin(a))
  var tangent=outward.cross(Vector3.UP).normalized()*flip
  var base=origin+Basis(f,tilt)*(outward*reach*0.9)
  psx.spark(base,outward*6.0+tangent*7.0,SLASH_WHITE,SLASH_EDGE,0.2,0.07,0.26,3.0,1.2,0.012*k)
  psx.segment(base,base+outward*0.9+tangent*0.5,0.06,Color.WHITE,SLASH_EDGE,0.08,0.012*k,0.4) # speed streaks
# Flickering blocky flame: orange body, red satellites that re-roll at ~14 fps, hot yellow core.
static func draw_fireball(rt: WeaponRuntime,pos: Vector3,s: float,age: float,cam: Vector3) -> void:
 var camera=rt.game.get_viewport().get_camera_3d()
 var right=camera.global_transform.basis.x if camera!=null else Vector3.RIGHT
 var up=camera.global_transform.basis.y if camera!=null else Vector3.UP
 var toward=(cam-pos).normalized()
 var step=int(age*14.0)
 var psx=rt.psx
 psx.draw_square(pos,1.0*s,FIRE_OUTER)
 for k in 4:
  var jitter=fposmod(sin(float(step)*12.9898+float(k)*78.233)*43758.5453,1.0)
  var jitter2=fposmod(sin(float(step)*39.346+float(k)*11.135)*24634.6345,1.0)
  var offset=(right*(1.0 if k%2==0 else -1.0)*(0.45+0.2*jitter)+up*(1.0 if k<2 else -1.0)*(0.4+0.25*jitter2))*s
  psx.draw_square(pos+offset+toward*0.02,(0.45+0.2*jitter)*s,FIRE_OUTER if k%2==0 else FIRE_DEEP)
 psx.draw_square(pos+toward*0.05,0.72*s,FIRE_MID)
 psx.draw_square(pos+toward*0.09,0.4*s,FIRE_CORE)
static func fire_muzzle(rt: WeaponRuntime,pos: Vector3,dir: Vector3) -> void:
 rt.psx.burst(pos,5,[FIRE_CORE,FIRE_MID,FIRE_OUTER],4.0,0.3,0.2,-1.0,2.0,dir,0.8,FIRE_DEEP)
static func bolt_strike(rt: WeaponRuntime,target: Vector3,radius: float) -> void:
 var psx=rt.psx
 var top=target+Vector3(rt.rng.randf_range(-1.2,1.2),19.0,rt.rng.randf_range(-1.2,1.2))
 psx.bolt(top,target,BOLT_OUTER,BOLT_INNER,0.42,1.5,11,3,0.05)
 var ground=Vector3(target.x,rt.game.terrain_height(target.x,target.z)+0.12,target.z)
 psx.ring(ground,radius*0.9,int(14+radius*6),BOLT_SPARK,0.2,0.3,radius*1.4)
 psx.burst(target,8,[BOLT_OUTER,BOLT_SPARK,BOLT_INNER],9.0,0.22,0.32,6.0,1.0,Vector3.UP,1.5)
 psx.shards(ground,3,BOLT_INNER,6.0,0.17,0.4,14.0,Vector3.UP,1.4)
static func chain_link(rt: WeaponRuntime,a: Vector3,b: Vector3) -> void:
 rt.psx.bolt(a,b,BOLT_OUTER,BOLT_INNER,0.26,0.55,6,2,0.05)
 rt.psx.burst(b,4,[BOLT_SPARK,BOLT_INNER],6.0,0.16,0.25,3.0,1.0,Vector3.UP,1.5)
static func arrow_launch(rt: WeaponRuntime,pos: Vector3,dir: Vector3) -> void:
 rt.psx.burst(pos,3,[ARROW_DUST,ARROW_GLOW],3.5,0.14,0.2,2.0,2.0,dir,0.8)
static func revolver_muzzle(rt: WeaponRuntime,pos: Vector3,dir: Vector3) -> void:
 var psx=rt.psx
 var right=dir.cross(Vector3.UP).normalized()
 for k in 4: # small angular star flash
  var spread=(float(k)-1.5)*0.35
  psx.segment(pos,pos+(dir+right*spread).normalized()*(1.1-absf(spread)*0.3),0.1,SHOT_FLASH,SPARK_GOLD,0.07,0.0,0.4)
 psx.burst(pos+dir*0.4,5,[SPARK_GOLD,BULLET_HEAD],7.0,0.12,0.18,6.0,1.5,dir,0.5)
 psx.burst(pos+dir*0.3,3,[SMOKE_LIGHT,SMOKE_DARK],1.6,0.2,0.5,-0.6,1.0,dir+Vector3.UP*0.6,0.9)
static func ricochet_spark(rt: WeaponRuntime,pos: Vector3,dir: Vector3) -> void:
 rt.psx.burst(pos,9,[SPARK_GOLD,BULLET_HEAD,BULLET_BODY],9.0,0.13,0.28,10.0,1.0,Vector3.ZERO,PI)
 rt.psx.shards(pos,1,BULLET_BODY,5.0,0.12,0.4,12.0)
static func shotgun_blast(rt: WeaponRuntime,origin: Vector3,dir: Vector3,half: float,pellets: int) -> void:
 var psx=rt.psx
 var right=dir.cross(Vector3.UP).normalized()
 for k in 6: # angular muzzle flash, hard-edged
  var a=TAU*float(k)/6.0
  var offset=(right*cos(a)+Vector3.UP*sin(a))*0.5
  psx.segment(origin+dir*0.3,origin+dir*(1.0+0.3*(k%2))+offset*0.5,0.09,SHOT_FLASH,SHOT_SPARK,0.06,0.0,0.4)
 psx.burst(origin+dir*0.8,int(8+pellets*0.7),[SHOT_SPARK,SHOT_FLASH,FIRE_MID],12.0,0.15,0.22,5.0,2.2,dir,half*1.2)
 psx.burst(origin+dir*0.5,7,[SHOT_SMOKE,SHOT_SMOKE_DARK],3.2,0.34,0.8,-0.8,1.4,dir+Vector3.UP*0.5,1.1)
 psx.shards(origin+dir*0.2+Vector3.UP*0.2,1,Color("c9a24a"),3.0,0.14,0.6,14.0,right+Vector3.UP,0.8) # ejected hull
static func shotgun_tracer(rt: WeaponRuntime,origin: Vector3,dir: Vector3,length: float,index: int) -> void:
 var psx=rt.psx
 var delay=0.004*(index%5)
 psx.segment(origin+dir*0.9,origin+dir*minf(length,3.4),0.06,SHOT_FLASH,SHOT_SPARK,0.2,delay,0.4)
 if length>3.4:psx.segment(origin+dir*3.6,origin+dir*minf(length,5.2),0.045,SHOT_SPARK,SHOT_SPARK.darkened(0.3),0.16,delay+0.02,0.4)
 psx.burst(origin+dir*minf(length,5.2),2,[SHOT_FLASH,SHOT_SPARK],1.5,0.2,0.2,0.0,1.0,dir,0.5) # pellet end mark
static func scythe_dust(rt: WeaponRuntime,pos: Vector3,count: int) -> void:
 rt.psx.burst(pos,count,[DUST_LIGHT,DUST_MID,DUST_DARK],3.0,0.2,0.45,2.0,1.5,Vector3.UP,1.8)
