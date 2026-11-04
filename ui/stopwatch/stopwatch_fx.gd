## Megaclonk: Stopwatch effect. The world freezes around the player, the screen edge becomes the clock.
## Ported from the handoff pack. Differences from the starter: it sits on layer 1 (the HUD is layer 2, so the HUD stays
## in colour), the zoom punch is done in the shader (so it moves the world and not the HUD), the extension makes the
## new time left the new total, and everything is driven by advance() so tests can step it without a scene tree.
## Feed it  update(freeze_time_left, player_screen_pos)  every frame. It detects start, extension and release itself.
class_name StopwatchFX
extends CanvasLayer

signal started
signal extended(added_s: float)
signal released

const STYLE_PATH := "res://ui/stopwatch/stopwatch_style.json"
const LAYER := 1 # strictly below FrontEnd (layer 2): the HUD is never under the effect
@export var reduce_motion := false
@export var timer_anchor := Vector2(960, 120) # bottom-centre of the HUD run timer, in screen px

var style: Dictionary
var total := 0.0 # the current freeze's full length (the new time left after an extension)
var remaining := 0.0
var active := false
var warn := false # red: only in the last warn_last_s seconds
var shown_frac := 0.0 # ticks animate toward the real fraction (refill sweep)
var tag := ""
var tag_t := -1.0
var wave_t := -1.0 # >=0 while the wave is expanding
var out_t := -1.0 # >=0 while colour floods back
var flash_a := 0.0
var punch_t := -1.0
var punch_target := 1.0
var radius := 0.0
var zoom := 1.0
var center := Vector2(960, 540)
var size_px := Vector2(1920, 1080)

var _rect: ColorRect
var _mat: ShaderMaterial
var _flash: ColorRect
var _clock: Control
var _font: Font
var _rng := RandomNumberGenerator.new() # presentation only: the rattle never touches the game's rngs

func _ready() -> void:
	load_style()
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new(); _rect.set_anchors_preset(Control.PRESET_FULL_RECT); _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new(); _mat.shader = load("res://ui/stopwatch/stopwatch_freeze.gdshader")
	_mat.set_shader_parameter("bubble", float(style.bubble_px)); _mat.set_shader_parameter("tint", Color(style.tint))
	_mat.set_shader_parameter("tint_amount", float(style.tint_amount)); _mat.set_shader_parameter("ice", Color(style.ice))
	_rect.material = _mat; _rect.visible = false; add_child(_rect)
	_flash = ColorRect.new(); _flash.set_anchors_preset(Control.PRESET_FULL_RECT); _flash.color = Color(0.91, 0.96, 1.0, 0.0); _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_clock = Control.new(); _clock.set_anchors_preset(Control.PRESET_FULL_RECT); _clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock.draw.connect(_draw_clock); add_child(_clock)
	_font = FogTheme.serif()
	if _font == null: _font = ThemeDB.fallback_font
	_rng.seed = 7

func load_style() -> void:
	if style.is_empty(): style = JSON.parse_string(FileAccess.get_file_as_string(STYLE_PATH))

## True while any part of the effect is on screen (the freeze, the flood back, the flash).
func visible_now() -> bool:
	return active or out_t >= 0.0 or flash_a > 0.001 or punch_t >= 0.0

## Call every frame with the freeze time left (0 when not frozen) and the player's screen position.
func update(remaining_s: float, player_screen_pos: Vector2) -> void:
	load_style()
	center = player_screen_pos
	if remaining_s > 0.0 and not active:
		active = true; total = remaining_s; remaining = remaining_s; shown_frac = 0.0
		wave_t = 0.0; out_t = -1.0; tag_t = -1.0
		if _rect: _rect.visible = true
		if not reduce_motion: _punch(float(style.punch_scale))
		flash_a = float(style.flash_alpha); started.emit()
	elif active and remaining_s > remaining + 0.05: # another pickup / an item added time
		var added := remaining_s - remaining
		total = remaining_s # the new time left is the new total; the ticks sweep up to full in refill_s
		tag = "+%.1fs" % added; tag_t = 0.0; extended.emit(added)
	if active and remaining_s <= 0.0:
		active = false; out_t = 0.0; flash_a = 0.25; released.emit()
		if not reduce_motion: _punch(0.985)
	remaining = maxf(remaining_s, 0.0)
	warn = active and remaining <= float(style.warn_last_s)

## Hard stop: a new run or stage was built, so nothing may linger.
func reset() -> void:
	active = false; remaining = 0.0; total = 0.0; warn = false; wave_t = -1.0; out_t = -1.0; flash_a = 0.0; punch_t = -1.0; zoom = 1.0
	radius = 0.0; shown_frac = 0.0; tag_t = -1.0
	if _rect: _rect.visible = false; _flash.color.a = 0.0; _clock.queue_redraw()

func _punch(s: float) -> void:
	punch_target = s; punch_t = 0.0

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if _rect == null: return
	size_px = get_viewport().get_visible_rect().size
	var full := size_px.length() + 40.0
	var ring := 0.0
	if wave_t >= 0.0:
		wave_t += delta
		var k := clampf(wave_t / float(style.wave_in_s), 0.0, 1.0)
		radius = full * (1.0 - pow(1.0 - k, 2.0)) if not reduce_motion else full
		ring = 0.0 if reduce_motion else 1.0 - k
		if k >= 1.0: wave_t = -1.0
	elif out_t >= 0.0:
		out_t += delta
		var k := clampf(out_t / float(style.wave_out_s), 0.0, 1.0)
		radius = full * pow(1.0 - k, 1.5); ring = 1.0
		if k >= 1.0: out_t = -1.0; radius = 0.0
	elif active:
		radius = full
	if punch_t >= 0.0:
		punch_t += delta
		var k := clampf(punch_t / float(style.punch_s), 0.0, 1.0)
		zoom = lerpf(punch_target, 1.0, k * k * (3.0 - 2.0 * k))
		if k >= 1.0: punch_t = -1.0; zoom = 1.0
	if flash_a > 0.0: flash_a = maxf(0.0, flash_a - delta * float(style.flash_alpha) / float(style.flash_s))
	_flash.color.a = flash_a
	var frac := remaining / total if active and total > 0.0 else 0.0
	var rate := delta / float(style.extend.refill_s)
	shown_frac = minf(shown_frac + rate, frac) if shown_frac < frac else frac # a refill sweeps up, a drain is exact
	if tag_t >= 0.0:
		tag_t += delta
		if tag_t > float(style.extend.tag_s): tag_t = -1.0
	_rect.visible = active or out_t >= 0.0 or punch_t >= 0.0
	_mat.set_shader_parameter("center", center); _mat.set_shader_parameter("radius", radius)
	_mat.set_shader_parameter("ring", ring); _mat.set_shader_parameter("zoom", zoom)
	_clock.queue_redraw()

## Where the i-th of the 60 edge ticks sits: clockwise from top centre. Returns the centre point and whether it is on a vertical edge.
func tick_point(k: int, vs: Vector2) -> Array:
	var n := int(style.ticks); var m := float(style.tick_margin_px)
	var w := vs.x - 2.0 * m; var h := vs.y - 2.0 * m; var per := 2.0 * (w + h)
	var d := fmod(per * k / n + w / 2.0, per)
	if d < w: return [Vector2(m + d, m), false]
	if d < w + h: return [Vector2(m + w, m + d - w), true]
	if d < 2.0 * w + h: return [Vector2(m + w - (d - w - h), m + h), false]
	return [Vector2(m, m + h - (d - 2.0 * w - h)), true]

## Number of ticks still lit for a fraction of the total.
func lit_ticks(frac: float) -> int:
	return int(ceil(frac * int(style.ticks)))

func watch_text() -> String:
	return ("%.1f" % remaining) if remaining < 10.0 else str(int(ceil(remaining)))

func _draw_clock() -> void:
	if not active and out_t < 0.0: return
	var vs := _clock.size
	var ice := Color(style.ice); var glow := Color(style.ice_glow); var red := Color(style.warn)
	var col := red if warn else ice
	var n := int(style.ticks)
	var lit := lit_ticks(shown_frac)
	for k in n:
		if k < n - lit: continue # tick k goes out when the fraction passes it, so the ticks go out clockwise from the top
		var tp := tick_point(k, vs); var p: Vector2 = tp[0]; var vertical: bool = tp[1]
		var sz: Array = style.tick_major if k % 5 == 0 else style.tick_minor
		var r := Rect2(p - Vector2(sz[0], sz[1]) / 2.0, Vector2(sz[0], sz[1])) if not vertical else Rect2(p - Vector2(sz[1], sz[0]) / 2.0, Vector2(sz[1], sz[0]))
		_clock.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.55))
		_clock.draw_rect(r.grow(3.0), Color(glow if not warn else red, 0.25))
		_clock.draw_rect(r, col)
	if not active: return
	# the brass pocket watch under the run timer: an ice wedge drains, red in the last second. No ticking hand.
	var ws := float(style.watch.size_px); var c := timer_anchor + Vector2(0, float(style.watch.offset_below_timer_px) + ws / 2.0)
	if warn and not reduce_motion: c += Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * float(style.watch.rattle_px)
	var pulse := 1.0
	if tag_t >= 0.0: pulse = 1.0 + 0.15 * (1.0 - tag_t / float(style.extend.tag_s))
	var R := ws / 2.0 * pulse
	_clock.draw_circle(c, R + 7.0, Color(0.23, 0.16, 0.08)); _clock.draw_circle(c, R + 5.0, Color(style.watch.brass))
	_clock.draw_circle(c, R, Color(style.watch.face))
	_clock.draw_rect(Rect2(c + Vector2(-6, -R - 16), Vector2(12, 10)), Color(style.watch.brass)) # the crown
	var pts := PackedVector2Array([c]); var segs := 48
	var a1 := -PI / 2.0 + TAU * shown_frac
	for i in segs + 1:
		var a := lerpf(-PI / 2.0, a1, float(i) / segs); pts.append(c + Vector2(cos(a), sin(a)) * (R - 8.0))
	if shown_frac > 0.002: _clock.draw_colored_polygon(pts, Color(col, 0.9))
	var txt := watch_text()
	var fs := int(ws * 0.27)
	var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_clock.draw_string_outline(_font, c + Vector2(-tw / 2.0, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 7, Color(0, 0, 0, 0.95))
	_clock.draw_string(_font, c + Vector2(-tw / 2.0, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	if tag_t >= 0.0:
		var a := clampf(1.0 - (tag_t - 0.8) / 0.4, 0.0, 1.0)
		_clock.draw_string_outline(_font, c + Vector2(R + 14, 10), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color(0, 0, 0, a))
		_clock.draw_string(_font, c + Vector2(R + 14, 10), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(Color(style.extend.tag_color), a))
