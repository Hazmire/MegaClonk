class_name ScoutVisual
extends Node3D
# A small blended pose state machine. Geometry/rig is independent of physics.
var animation_state="idle"
var clock=0.0
func animate(state: String, speed: float, delta: float) -> void:
 animation_state=state
 clock+=delta
 var hips=get_node("Hips")
 var torso=hips.get_node("Torso")
 var low=state in ["crouch","slide"]
 var blend=clampf(delta*14,0,1)
 hips.position.y=lerpf(hips.position.y,0.32 if low else 0.92,blend)
 var lean=0.0
 if state=="run": lean=0.13
 if state=="slide": lean=-1.05
 if state=="crouch": lean=0.9
 if state=="jump": lean=-0.15
 if state=="fall": lean=0.2
 if state=="hit": lean=-0.35+sin(clock*55)*0.1
 if state=="death": lean=1.5
 torso.rotation.x=lerpf(torso.rotation.x,lean,blend)
 var stride=sin(clock*minf(16,speed*1.65)) * minf(speed/9,1)*0.8 if state in ["run","crouch"] else 0.0
 for side in [-1,1]:
  var leg=hips.get_node("LegL" if side<0 else "LegR")
  var arm=torso.get_node("ArmL" if side<0 else "ArmR")
  var angle=stride*side
  if state=="slide": angle=-1.25+side*0.12
  elif state=="crouch": angle=1.25+stride*side*0.16
  elif state=="jump": angle=0.5*side
  elif state=="fall": angle=0.25
  leg.position.y=lerpf(leg.position.y,-0.12 if low else -0.3,blend)
  leg.rotation.x=lerpf(leg.rotation.x,angle,blend)
  arm.rotation.x=lerpf(arm.rotation.x,-stride*side if not low else -1.2,blend)
  arm.rotation.z=lerpf(arm.rotation.z,side*(0.65 if state=="fall" else 0.1),blend)
 torso.rotation.y=lerpf(torso.rotation.y,sin(clock*5)*0.15 if state=="turn" else 0,blend)
 hips.position.y+=sin(clock*3)*0.0008 if state=="idle" else 0
