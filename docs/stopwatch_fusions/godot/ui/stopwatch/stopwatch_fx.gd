## Megaclonk — Stopwatch effect: the world freezes around the player, the screen edge becomes the clock.
## Starter code. Feed it the hostile-time freeze every frame:   fx.update(remaining_s, player_screen_pos)
## It works out start, extension (remaining jumps up) and release (remaining hits 0) by itself, so the Stopwatch,
## longer-stopwatch items, refresh-on-pickup and the Hourglass all drive it the same way.
## Put it on a CanvasLayer BELOW the HUD's layer (it reads the screen behind it).
class_name StopwatchFX
extends CanvasLayer

signal started
signal extended(added_s: float)
signal released

const STYLE_PATH := "res://ui/stopwatch/stopwatch_style.json"
@export var reduce_motion := false
@export var timer_anchor := Vector2(960, 120)   # bottom-centre of the HUD run timer, in screen px

var style: Dictionary
var total := 0.0          # the current freeze's full length (grows when extended)
var remaining := 0.0
var active := false

var _rect: ColorRect
var _mat: ShaderMaterial
var _flash: ColorRect
var _clock: Control       # edge ticks + watch, drawn in _draw
var _font: Font
var _radius := 0.0
var _wave_t := -1.0       # >=0 while the wave is expanding
var _out_t := -1.0        # >=0 while colour floods back
var _shown_frac := 0.0    # ticks animate toward the real fraction (refill sweep)
var _tag := ""
var _tag_t := -1.0
var _t := 0.0
var _center := Vector2(960, 540)


func _ready() -> void:
	style = JSON.parse_string(FileAccess.get_file_as_string(STYLE_PATH))
	layer = 5
	_rect = ColorRect.new(); _rect.set_anchors_preset(Control.PRESET_FULL_RECT); _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new(); _mat.shader = load("res://ui/stopwatch/stopwatch_freeze.gdshader")
	_mat.set_shader_parameter("bubble", float(style.bubble_px)); _mat.set_shader_parameter("tint", Color(style.tint))
	_mat.set_shader_parameter("tint_amount", float(style.tint_amount)); _mat.set_shader_parameter("ice", Color(style.ice))
	_rect.material = _mat; _rect.visible = false; add_child(_rect)
	_flash = ColorRect.new(); _flash.set_anchors_preset(Control.PRESET_FULL_RECT); _flash.color = Color(0.91, 0.96, 1.0, 0.0); _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_clock = Control.new(); _clock.set_anchors_preset(Control.PRESET_FULL_RECT); _clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock.draw.connect(_draw_clock); add_child(_clock)
	_font = ThemeDB.fallback_font


## Call every frame with the freeze time left (0 when not frozen) and the player's screen position.
func update(remaining_s: float, player_screen_pos: Vector2) -> void:
	_center = player_screen_pos
	if remaining_s > 0.0 and not active:
		active = true; total = remaining_s; remaining = remaining_s; _shown_frac = 0.0
		_wave_t = 0.0; _out_t = -1.0; _rect.visible = true
		if not reduce_motion: _punch()
		_flash_now(float(style.flash_alpha)); started.emit()
	elif active and remaining_s > remaining + 0.05:    # picked up another / an item added time
		var added := remaining_s - remaining
		total = maxf(total, remaining_s) if remaining_s > total else remaining_s + (total - remaining)
		total = maxf(remaining_s, total)
		_tag = "+%.1fs" % added; _tag_t = 0.0; extended.emit(added)
	if active and remaining_s <= 0.0:
		active = false; _out_t = 0.0; _flash_now(0.25); released.emit()
		if not reduce_motion: _punch(0.985)
	remaining = maxf(remaining_s, 0.0)


func _flash_now(a: float) -> void:
	_flash.color.a = a
	create_tween().tween_property(_flash, "color:a", 0.0, float(style.flash_s))


func _punch(s := -1.0) -> void:
	# the HUD and world zoom punch belongs on the game camera; here we only nudge our own layer
	if s < 0.0: s = float(style.punch_scale)
	scale = Vector2.ONE * s; offset = _center * (1.0 - s)
	var tw := create_tween(); tw.tween_property(self, "scale", Vector2.ONE, float(style.punch_s)); tw.parallel().tween_property(self, "offset", Vector2.ZERO, float(style.punch_s))


func _process(delta: float) -> void:
	_t += delta
	var vs := get_viewport().get_visible_rect().size
	var full := vs.length() + 40.0
	if _wave_t >= 0.0:
		_wave_t += delta
		var k := clampf(_wave_t / float(style.wave_in_s), 0.0, 1.0)
		_radius = full * (1.0 - pow(1.0 - k, 2.0)) if not reduce_motion else full
		_mat.set_shader_parameter("ring", 1.0 - k)
		if k >= 1.0: _wave_t = -1.0
	elif _out_t >= 0.0:
		_out_t += delta
		var k := clampf(_out_t / float(style.wave_out_s), 0.0, 1.0)
		_radius = full * pow(1.0 - k, 1.5)
		_mat.set_shader_parameter("ring", 1.0)
		if k >= 1.0: _out_t = -1.0; _rect.visible = false; _radius = 0.0
	elif active:
		_radius = full; _mat.set_shader_parameter("ring", 0.0)
	_mat.set_shader_parameter("center", _center); _mat.set_shader_parameter("radius", _radius)
	var frac := remaining / total if active and total > 0.0 else 0.0
	var rate := delta / float(style.extend.refill_s)
	_shown_frac = minf(_shown_frac + rate, frac) if _shown_frac < frac else frac   # refill sweeps up, drains exactly
	if _tag_t >= 0.0:
		_tag_t += delta
		if _tag_t > float(style.extend.tag_s): _tag_t = -1.0
	_clock.queue_redraw()


func _draw_clock() -> void:
	if not active and _out_t < 0.0: return
	var vs := _clock.size
	var warn := active and remaining <= float(style.warn_last_s)
	var ice := Color(style.ice); var glow := Color(style.ice_glow); var red := Color(style.warn)
	var col := red if warn else ice
	# 60 ticks around the screen edge, clockwise from top centre; tick k goes out when the fraction passes it
	var n := int(style.ticks); var m := float(style.tick_margin_px)
	var w := vs.x - 2.0 * m; var h := vs.y - 2.0 * m; var per := 2.0 * (w + h)
	var lit := int(ceil(_shown_frac * n))
	for k in n:
		var d := fmod(per * k / n + w / 2.0, per)
		var p: Vector2; var vertical := false
		if d < w: p = Vector2(m + d, m)
		elif d < w + h: p = Vector2(m + w, m + d - w); vertical = true
		elif d < 2.0 * w + h: p = Vector2(m + w - (d - w - h), m + h)
		else: p = Vector2(m, m + h - (d - 2.0 * w - h)); vertical = true
		var on := k >= n - lit
		if not on: continue
		var sz: Array = style.tick_major if k % 5 == 0 else style.tick_minor
		var r := Rect2(p - Vector2(sz[0], sz[1]) / 2.0, Vector2(sz[0], sz[1])) if not vertical else Rect2(p - Vector2(sz[1], sz[0]) / 2.0, Vector2(sz[1], sz[0]))
		_clock.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.55))
		_clock.draw_rect(r.grow(3.0), Color(glow if not warn else red, 0.25))
		_clock.draw_rect(r, col)
	if not active: return
	# the brass pocket watch under the run timer: an ice wedge drains, red in the last second
	var ws := float(style.watch.size_px); var c := timer_anchor + Vector2(0, float(style.watch.offset_below_timer_px) + ws / 2.0)
	if warn and not reduce_motion: c += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * float(style.watch.rattle_px)
	var pulse := 1.0
	if _tag_t >= 0.0: pulse = 1.0 + 0.15 * (1.0 - _tag_t / float(style.extend.tag_s))
	var R := ws / 2.0 * pulse
	_clock.draw_circle(c, R + 7.0, Color(0.23, 0.16, 0.08)); _clock.draw_circle(c, R + 5.0, Color(style.watch.brass))
	_clock.draw_circle(c, R, Color(style.watch.face))
	_clock.draw_rect(Rect2(c + Vector2(-6, -R - 16), Vector2(12, 10)), Color(style.watch.brass))   # the crown
	var pts := PackedVector2Array([c]); var segs := 48
	var a1 := -PI / 2.0 + TAU * _shown_frac
	for i in segs + 1:
		var a := lerpf(-PI / 2.0, a1, float(i) / segs); pts.append(c + Vector2(cos(a), sin(a)) * (R - 8.0))
	if _shown_frac > 0.002: _clock.draw_colored_polygon(pts, Color(col, 0.9))
	var txt := ("%.1f" % remaining) if remaining < 10.0 else str(int(ceil(remaining)))
	var fs := int(ws * 0.27)
	var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_clock.draw_string_outline(_font, c + Vector2(-tw / 2.0, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 7, Color(0, 0, 0, 0.95))
	_clock.draw_string(_font, c + Vector2(-tw / 2.0, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	if _tag_t >= 0.0:
		var a := clampf(1.0 - (_tag_t - 0.8) / 0.4, 0.0, 1.0)
		_clock.draw_string_outline(_font, c + Vector2(R + 14, 10), _tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color(0, 0, 0, a))
		_clock.draw_string(_font, c + Vector2(R + 14, 10), _tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(Color(style.extend.tag_color), a))
