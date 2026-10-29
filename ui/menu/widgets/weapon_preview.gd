class_name WeaponPreview
extends Control
# The Polaroid photo on Unlocks > Weapons. Plays a short looping recording of the weapon firing in the Weapon Lab
# (res://assets/ui/weapon_previews/<id>.png, a sheet of COLUMNS x ROWS frames, made by tools/weapon_preview_capture.gd).
# It pauses itself whenever it is not visible, and shows the icon on black if a recording is missing.
const DIR="res://assets/ui/weapon_previews/"
const COLUMNS=4
const FPS=10.0
var weapon_id=-1
var sheet: Texture2D
var frames=0
var frame_size=Vector2.ZERO
var clock=0.0
var greyed=false
var recording=false
func show_weapon(id: int,grey: bool) -> void:
 greyed=grey;clock=0.0
 if id!=weapon_id:
  weapon_id=id;sheet=null;frames=0;recording=false
  var path="%s%d.png"%[DIR,id]
  if ResourceLoader.exists(path):
   sheet=load(path)
   frames=int(FileAccess.get_file_as_string("%s%d.txt"%[DIR,id]).strip_edges()) if FileAccess.file_exists("%s%d.txt"%[DIR,id]) else 16
   var rows=int(ceil(float(frames)/COLUMNS))
   frame_size=Vector2(sheet.get_width()/float(COLUMNS),sheet.get_height()/float(rows));recording=true
 material=MenuStyle.shader_material("res://ui/shaders/grayscale.gdshader",{"brightness":0.7}) if grey else null
 queue_redraw()
func _ready() -> void:
 clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _process(delta: float) -> void:
 if not recording or not is_visible_in_tree():return
 clock+=delta;queue_redraw()
func current_frame() -> int:return int(clock*FPS)%maxi(1,frames)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),FogPalette.NIGHT)
 if recording:
  var f=current_frame()
  var src=Rect2(Vector2(f%COLUMNS,f/COLUMNS)*frame_size,frame_size)
  draw_texture_rect_region(sheet,Rect2(Vector2.ZERO,size),src)
 elif weapon_id>=0:
  var tex=UIAssets.icon("weapons",str(weapon_id))
  draw_texture_rect(tex,Rect2((size-Vector2(128,128))*0.5,Vector2(128,128)),false)
  var f=MenuStyle.sans(600,0.2,14);var msg="NO RECORDING"
  var s=f.get_string_size(msg,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
  draw_string(f,Vector2((size.x-s.x)*0.5,size.y*0.5+110),msg,HORIZONTAL_ALIGNMENT_LEFT,-1,14,FogPalette.ASH_FAINT)
