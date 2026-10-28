class_name PsxFx
extends Node3D

# Shared, pooled PSX effect framework for every weapon.
# - Hard-edged billboard squares (sparks, embers, smoke, pixels), low-poly shards and angular
#   stepped segments (bolts, slash arcs, tracers) are CPU-simulated in struct-of-arrays pools and
#   drawn by three MultiMeshes that share two materials. No per-effect nodes, no per-effect
#   materials, no transparency or smooth ribbons: size and colour change in discrete steps.
# - Cosmetic randomness uses its own RNG so seeded runs stay deterministic.
# - Caps are hard: when a pool is nearly full, new cosmetic particles are thinned, then dropped.
const SQUARE_CAP=1400
const SHARD_CAP=260
const SEGMENT_CAP=720
const THIN_AT=0.72
const SIZE_SCALE=1.4 # world-size multiplier for squares so they stay readable at 640x360
var rng=RandomNumberGenerator.new()
var intensity=1.0 # 0..1 from settings.visual_intensity; reduced mode lowers it
var squares: MultiMeshInstance3D
var shard_mesh_node: MultiMeshInstance3D
var segment_node: MultiMeshInstance3D
var square_buffer=PackedFloat32Array()
var shard_buffer=PackedFloat32Array()
var segment_buffer=PackedFloat32Array()
# square pool
var sq_n=0
var sq_pos=PackedVector3Array();var sq_vel=PackedVector3Array()
var sq_age=PackedFloat32Array();var sq_life=PackedFloat32Array();var sq_delay=PackedFloat32Array()
var sq_size0=PackedFloat32Array();var sq_size1=PackedFloat32Array()
var sq_grav=PackedFloat32Array();var sq_drag=PackedFloat32Array()
var sq_c0=PackedColorArray();var sq_c1=PackedColorArray()
# shard pool
var sh_n=0
var sh_pos=PackedVector3Array();var sh_vel=PackedVector3Array();var sh_axis=PackedVector3Array()
var sh_angle=PackedFloat32Array();var sh_spin=PackedFloat32Array()
var sh_age=PackedFloat32Array();var sh_life=PackedFloat32Array();var sh_size=PackedFloat32Array()
var sh_grav=PackedFloat32Array();var sh_col=PackedColorArray()
# segment pool (basis precomputed at spawn)
var sg_n=0
var sg_xform: Array[Transform3D]=[]
var sg_age=PackedFloat32Array();var sg_life=PackedFloat32Array();var sg_delay=PackedFloat32Array()
var sg_c0=PackedColorArray();var sg_c1=PackedColorArray();var sg_taper=PackedFloat32Array()
# immediate layer: redrawn by owners every frame (moving projectile bodies, the aura circle), cleared after tick
var im_sq_n=0
var im_sq_pos=PackedVector3Array();var im_sq_size=PackedFloat32Array();var im_sq_col=PackedColorArray()
var im_sg_n=0
var im_sg_xform: Array[Transform3D]=[];var im_sg_col=PackedColorArray()
var stats={"squares_peak":0,"shards_peak":0,"segments_peak":0,"dropped":0}

func _init() -> void:
 name="PsxFx";rng.seed=90210
 sq_pos.resize(SQUARE_CAP);sq_vel.resize(SQUARE_CAP);sq_age.resize(SQUARE_CAP);sq_life.resize(SQUARE_CAP);sq_delay.resize(SQUARE_CAP)
 sq_size0.resize(SQUARE_CAP);sq_size1.resize(SQUARE_CAP);sq_grav.resize(SQUARE_CAP);sq_drag.resize(SQUARE_CAP);sq_c0.resize(SQUARE_CAP);sq_c1.resize(SQUARE_CAP)
 sh_pos.resize(SHARD_CAP);sh_vel.resize(SHARD_CAP);sh_axis.resize(SHARD_CAP);sh_angle.resize(SHARD_CAP);sh_spin.resize(SHARD_CAP)
 sh_age.resize(SHARD_CAP);sh_life.resize(SHARD_CAP);sh_size.resize(SHARD_CAP);sh_grav.resize(SHARD_CAP);sh_col.resize(SHARD_CAP)
 sg_xform.resize(SEGMENT_CAP);sg_age.resize(SEGMENT_CAP);sg_life.resize(SEGMENT_CAP);sg_delay.resize(SEGMENT_CAP);sg_c0.resize(SEGMENT_CAP);sg_c1.resize(SEGMENT_CAP);sg_taper.resize(SEGMENT_CAP)
 im_sq_pos.resize(SQUARE_CAP);im_sq_size.resize(SQUARE_CAP);im_sq_col.resize(SQUARE_CAP);im_sg_xform.resize(SEGMENT_CAP);im_sg_col.resize(SEGMENT_CAP)
 square_buffer.resize(SQUARE_CAP*16);shard_buffer.resize(SHARD_CAP*16);segment_buffer.resize(SEGMENT_CAP*16)
 var billboard=ShaderMaterial.new();billboard.shader=preload("res://shaders/psx_fx_billboard.gdshader")
 var solid=ShaderMaterial.new();solid.shader=preload("res://shaders/psx_fx_solid.gdshader")
 var quad=QuadMesh.new();quad.size=Vector2.ONE;quad.material=billboard
 squares=_instances("Squares",quad,SQUARE_CAP)
 shard_mesh_node=_instances("Shards",shard_mesh(solid),SHARD_CAP)
 var box=BoxMesh.new();box.size=Vector3.ONE;box.material=solid
 segment_node=_instances("Segments",box,SEGMENT_CAP)
func _instances(label: String,mesh: Mesh,capacity: int) -> MultiMeshInstance3D:
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=mesh;mm.instance_count=capacity;mm.visible_instance_count=0
 var node=MultiMeshInstance3D.new();node.name=label;node.multimesh=mm;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.extra_cull_margin=200.0;add_child(node);return node
# Faceted low-poly shard (a squashed octahedron). Face tints are baked into vertex colours.
func shard_mesh(material: Material) -> Mesh:
 var top=Vector3(0,0.9,0);var bottom=Vector3(0,-0.5,0)
 var ring=[Vector3(0.5,0,0),Vector3(0,0,0.32),Vector3(-0.5,0,0),Vector3(0,0,-0.32)]
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 4:
  var a=ring[i];var b=ring[(i+1)%4]
  var shade_up=Color.WHITE*(0.62+0.38*float(i%2));shade_up.a=1.0
  var shade_down=Color.WHITE*(0.35+0.25*float(i%2));shade_down.a=1.0
  for v in [top,b,a]:tool.set_color(shade_up);tool.add_vertex(v)
  for v in [bottom,a,b]:tool.set_color(shade_down);tool.add_vertex(v)
 var mesh=tool.commit();mesh.surface_set_material(0,material);return mesh

func room(used: int,capacity: int) -> bool:
 if used>=capacity:stats.dropped+=1;return false
 if float(used)>capacity*THIN_AT and rng.randf()>0.35:stats.dropped+=1;return false
 return true
func rand_dir() -> Vector3:
 var z=rng.randf_range(-1.0,1.0);var a=rng.randf()*TAU;var r=sqrt(1.0-z*z)
 return Vector3(r*cos(a),z,r*sin(a))
# One square: shown with colour c0 for the first third of its life, c1 after; size steps down in 3 stages.
func spark(pos: Vector3,vel: Vector3,c0: Color,c1: Color,size0: float,size1: float,life: float,gravity: float=0.0,drag: float=0.0,delay: float=0.0) -> void:
 if not room(sq_n,SQUARE_CAP):return
 var i=sq_n;sq_n+=1
 sq_pos[i]=pos;sq_vel[i]=vel;sq_age[i]=0.0;sq_life[i]=maxf(0.04,life);sq_delay[i]=delay
 sq_size0[i]=size0*SIZE_SCALE;sq_size1[i]=size1*SIZE_SCALE;sq_grav[i]=gravity;sq_drag[i]=drag;sq_c0[i]=c0;sq_c1[i]=c1
# Radial or cone burst of squares. `palette` colours are picked at random per square.
func burst(pos: Vector3,count: int,palette: Array,speed: float,size: float,life: float,gravity: float=9.0,drag: float=1.2,direction: Vector3=Vector3.ZERO,cone: float=PI,end_color: Color=Color(0,0,0,0)) -> void:
 count=int(ceil(count*clampf(intensity,0.25,1.0)))
 for n in count:
  if sq_n>=SQUARE_CAP:stats.dropped+=1;return
  var v=rand_dir()
  if direction!=Vector3.ZERO:
   var axis=direction.normalized();v=axis.slerp(v,clampf(cone/PI,0.0,1.0)*rng.randf()).normalized()
  var c=palette[rng.randi()%palette.size()]
  var tail=end_color if end_color.a>0.0 else c.darkened(0.55)
  spark(pos,v*speed*rng.randf_range(0.45,1.0),c,tail,size*rng.randf_range(0.7,1.25),size*0.35,life*rng.randf_range(0.7,1.2),gravity,drag)
# Tumbling low-poly shards (debris, spent casings, rock chips).
func shards(pos: Vector3,count: int,color: Color,speed: float,size: float,life: float,gravity: float=12.0,direction: Vector3=Vector3.ZERO,cone: float=PI) -> void:
 count=int(ceil(count*clampf(intensity,0.25,1.0)))
 for n in count:
  if not room(sh_n,SHARD_CAP):return
  var i=sh_n;sh_n+=1
  var v=rand_dir()
  if direction!=Vector3.ZERO:v=direction.normalized().slerp(v,clampf(cone/PI,0.0,1.0)*rng.randf()).normalized()
  sh_pos[i]=pos;sh_vel[i]=v*speed*rng.randf_range(0.5,1.0);sh_axis[i]=rand_dir();sh_angle[i]=rng.randf()*TAU;sh_spin[i]=rng.randf_range(-14.0,14.0)
  sh_age[i]=0.0;sh_life[i]=life*rng.randf_range(0.7,1.2);sh_size[i]=size*rng.randf_range(0.6,1.3);sh_grav[i]=gravity;sh_col[i]=color
# One angular box segment from a to b. It holds colour c0 then c1 (second half) and thins in discrete steps.
func segment(a: Vector3,b: Vector3,width: float,c0: Color,c1: Color,life: float,delay: float=0.0,taper: float=0.5) -> void:
 if not room(sg_n,SEGMENT_CAP):return
 var along=b-a;var length=along.length()
 if length<0.01:return
 var z=along/length
 var ref=Vector3.UP if absf(z.dot(Vector3.UP))<0.95 else Vector3.RIGHT
 var x=ref.cross(z).normalized();var y=z.cross(x).normalized()
 var i=sg_n;sg_n+=1
 sg_xform[i]=Transform3D(Basis(x*width,y*width,z*length),(a+b)*0.5)
 sg_age[i]=0.0;sg_life[i]=maxf(0.03,life);sg_delay[i]=delay;sg_c0[i]=c0;sg_c1[i]=c1;sg_taper[i]=taper
# Jagged lightning: every flicker frame re-rolls the polyline and shows for ~0.045s with hard cuts,
# an outer coloured core plus a white inner core. Returns the polyline of the first frame.
func bolt(from: Vector3,to: Vector3,outer: Color,inner: Color,width: float,jag: float,pieces: int,frames: int=3,frame_time: float=0.05) -> PackedVector3Array:
 var first=PackedVector3Array()
 var axis=to-from;var length=axis.length()
 if length<0.05:return first
 var dir=axis/length
 var ref=Vector3.UP if absf(dir.dot(Vector3.UP))<0.95 else Vector3.RIGHT
 var p1=ref.cross(dir).normalized();var p2=dir.cross(p1).normalized()
 for f in frames:
  var points=PackedVector3Array();points.append(from)
  for k in range(1,pieces):
   var t=float(k)/pieces;var swing=jag*sin(PI*t)
   points.append(from.lerp(to,t)+p1*rng.randf_range(-swing,swing)+p2*rng.randf_range(-swing,swing))
  points.append(to)
  if f==0:first=points
  var life=frame_time if f<frames-1 else frame_time*1.8;var delay=f*frame_time
  for k in points.size()-1:
   segment(points[k],points[k+1],width,outer,outer.darkened(0.35),life,delay)
   segment(points[k],points[k+1],width*0.42,inner,inner,life,delay)
  if f==0 and pieces>=5:
   var fork_at=rng.randi_range(2,pieces-2);var tip=points[fork_at]+(p1*rng.randf_range(-1.0,1.0)+dir*0.5).normalized()*length*0.14
   segment(points[fork_at],tip,width*0.6,outer,outer.darkened(0.35),life*1.4,delay)
 return first
# A ring of squares expanding on the ground plane (pulse feedback).
func ring(center: Vector3,radius: float,count: int,color: Color,size: float,life: float,outward: float=0.0) -> void:
 count=int(ceil(count*clampf(intensity,0.35,1.0)))
 for n in count:
  var a=TAU*float(n)/count+rng.randf()*0.1
  var d=Vector3(cos(a),0,sin(a))
  spark(center+d*radius,d*outward,color,color.darkened(0.5),size,size*0.4,life)
# Stepped trail dot used by moving projectiles: pass the weapon's palette.
func trail(pos: Vector3,color: Color,size: float,life: float,drift: Vector3=Vector3.ZERO) -> void:
 spark(pos,drift,color,color.darkened(0.6),size,size*0.3,life,0.0,0.0)

# Immediate-mode helpers: call every frame while the thing exists; nothing persists afterwards.
func draw_square(pos: Vector3,size: float,color: Color) -> void:
 if im_sq_n>=SQUARE_CAP-sq_n:return
 im_sq_pos[im_sq_n]=pos;im_sq_size[im_sq_n]=size;im_sq_col[im_sq_n]=color;im_sq_n+=1
func draw_segment(a: Vector3,b: Vector3,width: float,color: Color) -> void:
 if im_sg_n>=SEGMENT_CAP-sg_n:return
 var along=b-a;var length=along.length()
 if length<0.01:return
 var z=along/length
 var ref=Vector3.UP if absf(z.dot(Vector3.UP))<0.95 else Vector3.RIGHT
 var x=ref.cross(z).normalized();var y=z.cross(x).normalized()
 im_sg_xform[im_sg_n]=Transform3D(Basis(x*width,y*width,z*length),(a+b)*0.5);im_sg_col[im_sg_n]=color;im_sg_n+=1
func clear() -> void:
 im_sq_n=0;im_sg_n=0
 sq_n=0;sh_n=0;sg_n=0
 squares.multimesh.visible_instance_count=0;shard_mesh_node.multimesh.visible_instance_count=0;segment_node.multimesh.visible_instance_count=0
func live_count() -> int:return sq_n+sh_n+sg_n

func tick(delta: float) -> void:
 stats.squares_peak=maxi(stats.squares_peak,sq_n);stats.shards_peak=maxi(stats.shards_peak,sh_n);stats.segments_peak=maxi(stats.segments_peak,sg_n)
 _tick_squares(delta);_tick_shards(delta);_tick_segments(delta)
func _tick_squares(delta: float) -> void:
 var i=0;var shown=0;var buf=square_buffer
 while i<sq_n:
  var d=sq_delay[i]
  if d>0.0:
   sq_delay[i]=d-delta;i+=1;continue
  var age=sq_age[i]+delta
  var life=sq_life[i]
  if age>=life:
   sq_n-=1
   if i<sq_n:
    sq_pos[i]=sq_pos[sq_n];sq_vel[i]=sq_vel[sq_n];sq_age[i]=sq_age[sq_n];sq_life[i]=sq_life[sq_n];sq_delay[i]=sq_delay[sq_n]
    sq_size0[i]=sq_size0[sq_n];sq_size1[i]=sq_size1[sq_n];sq_grav[i]=sq_grav[sq_n];sq_drag[i]=sq_drag[sq_n];sq_c0[i]=sq_c0[sq_n];sq_c1[i]=sq_c1[sq_n]
   continue
  sq_age[i]=age
  var v=sq_vel[i]
  v.y-=sq_grav[i]*delta
  var drag=sq_drag[i]
  if drag>0.0:v*=maxf(0.0,1.0-drag*delta)
  sq_vel[i]=v
  var p=sq_pos[i]+v*delta;sq_pos[i]=p
  var step=mini(2,int(age/life*3.0))
  var size=sq_size0[i] if step==0 else (sq_size1[i] if step==2 else (sq_size0[i]+sq_size1[i])*0.5)
  var c=sq_c0[i] if step==0 else sq_c1[i]
  var o=shown*16
  buf[o]=size;buf[o+3]=p.x;buf[o+5]=size;buf[o+7]=p.y;buf[o+10]=size;buf[o+11]=p.z
  buf[o+12]=c.r;buf[o+13]=c.g;buf[o+14]=c.b;buf[o+15]=1.0
  shown+=1;i+=1
 for k in im_sq_n:
  var o=shown*16;var size=im_sq_size[k];var p=im_sq_pos[k];var c=im_sq_col[k]
  buf[o]=size;buf[o+3]=p.x;buf[o+5]=size;buf[o+7]=p.y;buf[o+10]=size;buf[o+11]=p.z
  buf[o+12]=c.r;buf[o+13]=c.g;buf[o+14]=c.b;buf[o+15]=1.0;shown+=1
 im_sq_n=0
 square_buffer=buf
 squares.multimesh.buffer=buf
 squares.multimesh.visible_instance_count=shown
func _tick_shards(delta: float) -> void:
 var i=0;var shown=0;var buf=shard_buffer
 while i<sh_n:
  var age=sh_age[i]+delta
  if age>=sh_life[i]:
   sh_n-=1
   if i<sh_n:
    sh_pos[i]=sh_pos[sh_n];sh_vel[i]=sh_vel[sh_n];sh_axis[i]=sh_axis[sh_n];sh_angle[i]=sh_angle[sh_n];sh_spin[i]=sh_spin[sh_n]
    sh_age[i]=sh_age[sh_n];sh_life[i]=sh_life[sh_n];sh_size[i]=sh_size[sh_n];sh_grav[i]=sh_grav[sh_n];sh_col[i]=sh_col[sh_n]
   continue
  sh_age[i]=age
  var v=sh_vel[i];v.y-=sh_grav[i]*delta;sh_vel[i]=v
  var p=sh_pos[i]+v*delta;sh_pos[i]=p
  # Stepped tumble: the angle only updates ~16 times a second so shards read as low-framerate PSX props.
  var a=sh_angle[i]+sh_spin[i]*delta;sh_angle[i]=a
  var snapped=floorf(a*2.5)/2.5
  var s=sh_size[i]*(1.0 if age<sh_life[i]*0.66 else 0.55)
  var basis=Basis(sh_axis[i],snapped).scaled(Vector3(s,s,s))
  var o=shown*16
  buf[o]=basis.x.x;buf[o+1]=basis.y.x;buf[o+2]=basis.z.x;buf[o+3]=p.x
  buf[o+4]=basis.x.y;buf[o+5]=basis.y.y;buf[o+6]=basis.z.y;buf[o+7]=p.y
  buf[o+8]=basis.x.z;buf[o+9]=basis.y.z;buf[o+10]=basis.z.z;buf[o+11]=p.z
  var c=sh_col[i];buf[o+12]=c.r;buf[o+13]=c.g;buf[o+14]=c.b;buf[o+15]=1.0
  shown+=1;i+=1
 shard_buffer=buf
 shard_mesh_node.multimesh.buffer=buf
 shard_mesh_node.multimesh.visible_instance_count=shown
func _tick_segments(delta: float) -> void:
 var i=0;var shown=0;var buf=segment_buffer
 while i<sg_n:
  var d=sg_delay[i]
  if d>0.0:
   sg_delay[i]=d-delta;i+=1;continue
  var age=sg_age[i]+delta;var life=sg_life[i]
  if age>=life:
   sg_n-=1
   if i<sg_n:
    sg_xform[i]=sg_xform[sg_n];sg_age[i]=sg_age[sg_n];sg_life[i]=sg_life[sg_n];sg_delay[i]=sg_delay[sg_n];sg_c0[i]=sg_c0[sg_n];sg_c1[i]=sg_c1[sg_n];sg_taper[i]=sg_taper[sg_n]
   continue
  sg_age[i]=age
  var t=sg_xform[i]
  var late=age>life*0.55
  var b=t.basis
  if late:
   var k=sg_taper[i];b=Basis(b.x*k,b.y*k,b.z)
  var c=sg_c1[i] if late else sg_c0[i]
  var o=shown*16
  buf[o]=b.x.x;buf[o+1]=b.y.x;buf[o+2]=b.z.x;buf[o+3]=t.origin.x
  buf[o+4]=b.x.y;buf[o+5]=b.y.y;buf[o+6]=b.z.y;buf[o+7]=t.origin.y
  buf[o+8]=b.x.z;buf[o+9]=b.y.z;buf[o+10]=b.z.z;buf[o+11]=t.origin.z
  buf[o+12]=c.r;buf[o+13]=c.g;buf[o+14]=c.b;buf[o+15]=1.0
  shown+=1;i+=1
 for k in im_sg_n:
  var o=shown*16;var b=im_sg_xform[k].basis;var origin=im_sg_xform[k].origin;var c=im_sg_col[k]
  buf[o]=b.x.x;buf[o+1]=b.y.x;buf[o+2]=b.z.x;buf[o+3]=origin.x
  buf[o+4]=b.x.y;buf[o+5]=b.y.y;buf[o+6]=b.z.y;buf[o+7]=origin.y
  buf[o+8]=b.x.z;buf[o+9]=b.y.z;buf[o+10]=b.z.z;buf[o+11]=origin.z
  buf[o+12]=c.r;buf[o+13]=c.g;buf[o+14]=c.b;buf[o+15]=1.0;shown+=1
 im_sg_n=0
 segment_buffer=buf
 segment_node.multimesh.buffer=buf
 segment_node.multimesh.visible_instance_count=shown
