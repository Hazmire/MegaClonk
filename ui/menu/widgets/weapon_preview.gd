class_name WeaponPreview
extends Control
# Looping "in action" clip inside the Polaroid on Unlocks > Weapons. The clips are the pixel effect boards from the UI handoff
# (W-*.dc.html), rendered by tools/weapon_preview_from_mockups.py into sprite sheets in res://assets/ui/weapon_previews/ and drawn 1:1.
# Reduced-motion shows one still frame instead of the loop.
const DIR="res://assets/ui/weapon_previews/"
static var meta: Dictionary={}
static var sheets: Dictionary={}
static var still=false
var weapon_id=-1
var info: Dictionary={}
var shown=-1
func _init() -> void:
 custom_minimum_size=Vector2(460,408);size=custom_minimum_size;mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;clip_contents=true
static func load_meta() -> void:
 if not meta.is_empty():return
 var path=DIR+"previews.json"
 if FileAccess.file_exists(path):
  var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
  if parsed is Dictionary:meta=parsed
static func has_preview(id: int) -> bool:
 load_meta();return meta.has(str(id)) and ResourceLoader.exists(DIR+"%d.png"%id)
func setup(id: int,locked: bool=false) -> WeaponPreview:
 load_meta();weapon_id=id;info=meta.get(str(id),{})
 if has_preview(id) and not sheets.has(id):sheets[id]=load(DIR+"%d.png"%id)
 material=MenuStyle.shader_material("res://ui/shaders/grayscale.gdshader") if locked else null
 set_process(not info.is_empty() and not still);queue_redraw();return self
func frame_index() -> int:
 if info.is_empty():return 0
 var count=int(info.frames)
 if still:return count/3
 return int(Time.get_ticks_msec()/1000.0*float(info.fps))%count
func _process(_delta: float) -> void:
 var f=frame_index()
 if f!=shown:queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),FogPalette.NIGHT)
 if info.is_empty() or not sheets.has(weapon_id):
  var font=MenuStyle.sans(800,0.2,14);var text="NO PREVIEW RECORDED"
  var s=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
  draw_string(font,(size-s)*0.5+Vector2(0,font.get_ascent(14)*0.5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,FogPalette.ASH_FAINT);return
 shown=frame_index()
 var cols=int(info.columns);var w=int(info.w);var h=int(info.h)
 draw_texture_rect_region(sheets[weapon_id],Rect2(Vector2.ZERO,Vector2(w,h)),Rect2((shown%cols)*w,(shown/cols)*h,w,h))
