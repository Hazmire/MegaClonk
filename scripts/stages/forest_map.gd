class_name ForestMap
extends RefCounted
const CELL=18.0
static func vertex_height(seed_value: int, x: int, z: int) -> float:
 # Seeded, broad elevation bands; no high frequency noise or enclosed pits.
 var phase=float(posmod(seed_value,997))/997.0*TAU
 return (sin(x*0.65+phase)*cos(z*0.55-phase)*5+sin(z*0.35+phase)*4)*smoothstep(0,2,Vector2(x,z).length())
static func height(seed_value: int, x: float, z: float) -> float:
 var edge=maxf(absf(x),absf(z))
 var cx=floori(x/CELL);var cz=floori(z/CELL)
 var u=(x-cx*CELL)/CELL;var v=(z-cz*CELL)/CELL
 var a=vertex_height(seed_value,cx,cz);var b=vertex_height(seed_value,cx+1,cz);var c=vertex_height(seed_value,cx,cz+1);var d=vertex_height(seed_value,cx+1,cz+1)
 var h=a+(b-a)*u+(c-a)*v if u+v<=1 else d+(c-d)*(1-u)+(b-d)*(1-v)
 return h+maxf(0,edge-72)*1.65
static func reachable(seed_value: int, target: Vector2) -> bool:
 # Grid BFS respects the same planar height function, with 45 degree slope budget.
 var todo=[Vector2i.ZERO];var seen={Vector2i.ZERO:true};var goal=Vector2i(roundi(target.x/6),roundi(target.y/6));var head=0
 while head<todo.size():
  var p: Vector2i=todo[head];head+=1
  if p==goal:return true
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var n=p+d
   if seen.has(n) or maxi(absi(n.x),absi(n.y))>11:continue
   if absf(height(seed_value,n.x*6,n.y*6)-height(seed_value,p.x*6,p.y*6))>5.5:continue
   seen[n]=true;todo.append(n)
 return false
