class_name MovementAudio
extends RefCounted
var distance=0.0
var grounded=false
var sliding=false
var airborne_speed=0.0
var scrape_clock=0.0
func reset():
 distance=0;grounded=false;sliding=false;airborne_speed=0;scrape_clock=0
func tick(game: Node,delta: float):
 var player=game.player;var on_ground=player.is_on_floor();var speed=Vector2(player.velocity.x,player.velocity.z).length();var slide=on_ground and player.posture=="sliding"
 if not on_ground:airborne_speed=minf(airborne_speed,player.velocity.y)
 elif not grounded and airborne_speed< -3:game.audio.emit("player.land",player.position,clampf(-airborne_speed/12,0.3,1));airborne_speed=0
 if slide:
  scrape_clock-=delta
  if not sliding or scrape_clock<=0:game.audio.stop_event("player.slide");game.audio.emit("player.slide",player.position,0.65);scrape_clock=0.65
 elif sliding:game.audio.stop_event("player.slide");scrape_clock=0;game.audio.emit("movement.slide_recover",player.position,0.8)
 if on_ground and not slide and speed>0.5:
  distance+=speed*delta
  if distance>=2.1:
   distance=fmod(distance,2.1)
   var rock=game.player.get_floor_normal().y<0.92
   # Surfaces: steep ground is stone, stage 1 is grass, every later stage is dirt (stages have no ground-material data).
   game.audio.emit("player.footstep.rock" if rock else ("player.footstep.grass" if int(game.get("stage") if game.get("stage")!=null else 1)==1 else "movement.step_dirt"),player.position,0.75 if player.posture=="standing" else 0.4)
 else:distance=0
 grounded=on_ground;sliding=slide
