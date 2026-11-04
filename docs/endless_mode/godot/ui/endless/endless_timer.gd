## Megaclonk — the run timer that becomes the endless timer.
## One node for the whole run: it shows the normal run timer, then at 10:00 it glitches and becomes the
## endless timer (blood red, counting up from 00:00), and escalates through the tiers in
## endless_timer_style.json. Particles sit behind the digits and the line, never over them.
## Starter code: wire set_run_time / start_endless / set_endless_time from RunData.
class_name EndlessTimer
extends Control

const STYLE_PATH := "res://ui/endless/endless_timer_style.json"
const SERIF := "res://ui/fonts/IMFellEnglish-Regular.ttf"
const SANS := "res://ui/fonts/Overpass-VariableFont_wght.ttf"

@export var reduce_motion := false

var style: Dictionary
var endless := false
var tier := -1
var stage_title := "THE VERDANT HOLLOW"
var stage_number := 1

var _digits: Label
var _glow: Label
var _ghost: Label
var _line_a: Label     # "STAGE 1" / "ENDLESS"
var _line_b: Label     # "· THE VERDANT HOLLOW"
var _rules: Array[ColorRect] = []
var _embers: CPUParticles2D
var _smoke: CPUParticles2D
var _glitch_t := -1.0
var _t := 0.0
var _last_text := ""
var _digit_settings: LabelSettings
var _glow_settings: LabelSettings


func _ready() -> void:
	style = JSON.parse_string(FileAccess.get_file_as_string(STYLE_PATH))
	custom_minimum_size = Vector2(600, 110)
	var serif := _font(SERIF, true)
	var sans := _font(SANS, false)
	# back to front: smoke, embers, glow, ghost, digits, line
	_smoke = _particles(true); add_child(_smoke)
	_embers = _particles(false); add_child(_embers)
	_glow_settings = LabelSettings.new(); _glow_settings.font = serif; _glow_settings.font_size = 68
	_glow_settings.font_color = Color(0, 0, 0, 0); _glow_settings.outline_size = 14
	_glow = _label(_glow_settings); add_child(_glow)
	var gs := LabelSettings.new(); gs.font = serif; gs.font_size = 68; gs.font_color = Color(style.glitch.ghost_color)
	_ghost = _label(gs); _ghost.visible = false; add_child(_ghost)
	_digit_settings = LabelSettings.new(); _digit_settings.font = serif; _digit_settings.font_size = 68
	_digit_settings.shadow_size = 0; _digit_settings.shadow_offset = Vector2(3, 3); _digit_settings.shadow_color = Color("050505")
	_digit_settings.outline_size = 2
	_digits = _label(_digit_settings); add_child(_digits)
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 12)
	row.position = Vector2(0, 78); row.size = Vector2(600, 20)
	add_child(row)
	var ls := LabelSettings.new(); ls.font = sans; ls.font_size = 13; ls.shadow_size = 0; ls.shadow_offset = Vector2(2, 2); ls.shadow_color = Color("050505")
	for k in 4:
		if k == 0 or k == 3:
			var r := ColorRect.new(); r.custom_minimum_size = Vector2(28, 3); r.color = Color(style.line.rule_color)
			r.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(r); _rules.append(r)
		elif k == 1:
			_line_a = Label.new(); _line_a.label_settings = ls.duplicate(); row.add_child(_line_a)
		else:
			_line_b = Label.new(); _line_b.label_settings = ls.duplicate(); row.add_child(_line_b)
	_apply_normal()
	set_run_time(0.0)


func _font(path: String, serif: bool) -> Font:
	if ResourceLoader.exists(path): return load(path)
	var f := SystemFont.new(); f.font_names = PackedStringArray(["IM Fell English", "Georgia", "DejaVu Serif"] if serif else ["Overpass", "DejaVu Sans"])
	if not serif: f.font_weight = 800
	return f


func _label(ls: LabelSettings) -> Label:
	var l := Label.new(); l.label_settings = ls; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2.ZERO; l.size = Vector2(600, 76); l.pivot_offset = Vector2(300, 38)
	return l


func _particles(smoke: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false; p.amount = int(style.caps.smoke if smoke else style.caps.embers)
	p.position = Vector2(300, 30); p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(130 if not smoke else 110, 18)
	p.direction = Vector2(0, -1); p.spread = 18.0; p.gravity = Vector2(0, -12 if smoke else -20)
	p.initial_velocity_min = 18.0 if smoke else 22.0; p.initial_velocity_max = 30.0 if smoke else 40.0
	p.lifetime = 3.0 if smoke else 2.0; p.preprocess = p.lifetime
	var fade := Gradient.new(); fade.set_color(0, Color(1, 1, 1, 0)); fade.add_point(0.15, Color(1, 1, 1, 0.9)); fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	if smoke:
		var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new(); tex.gradient = g; tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5); tex.fill_to = Vector2(1.0, 0.5); tex.width = 32; tex.height = 32
		p.texture = tex; p.scale_amount_min = 0.8; p.scale_amount_max = 1.4
		var grow := Curve.new(); grow.add_point(Vector2(0, 0.5)); grow.add_point(Vector2(1, 1.8)); p.scale_amount_curve = grow
	else:
		p.scale_amount_min = 4.0; p.scale_amount_max = 6.0   # untextured = pixel squares
	return p


static func format_time(sec: float) -> String:
	var s := int(floor(sec))
	if s >= 3600: return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%02d:%02d" % [s / 60, s % 60]


## Before 10:00: the normal run timer.
func set_run_time(sec: float) -> void:
	if endless: return
	_set_text(format_time(sec))


## At 10:00: glitch, then become the endless timer at 00:00. Call once (RunData's endless signal).
func start_endless() -> void:
	if endless: return
	endless = true
	_glitch_t = 0.0
	_set_text("10:00")


## Endless time in seconds since the 10:00 mark. Cheap to call every frame; only redraws when the text changes.
func set_endless_time(sec: float) -> void:
	if not endless or _glitch_t >= 0.0 and _glitch_t < float(style.glitch.duration_s): return
	var want := 0
	for i in style.tiers.size():
		if sec >= float(style.tiers[i].from_s): want = i
	if want != tier:
		var first := tier == -1
		tier = want; _apply_tier()
		if not first: _glitch_t = 0.0   # every tier change replays the glitch
	_set_text(format_time(sec))


func _set_text(t: String) -> void:
	if t == _last_text: return
	_last_text = t; _digits.text = t; _glow.text = t; _ghost.text = t


func _apply_normal() -> void:
	_digit_settings.font_color = Color(style.normal.digits); _digit_settings.outline_color = Color(0, 0, 0, 0)
	_glow_settings.outline_color = Color(0, 0, 0, 0.35)
	_line_a.text = "STAGE %d" % stage_number; _line_a.label_settings.font_color = Color(style.line.title_color)
	_line_b.text = "· " + stage_title; _line_b.label_settings.font_color = Color(style.line.title_color)


func _apply_tier() -> void:
	var tt: Dictionary = style.tiers[tier]
	_digit_settings.font_color = Color(tt.digits); _digit_settings.outline_color = Color(tt.edge)
	var gc := Color(tt.glow); gc.a = float(tt.glow_alpha); _glow_settings.outline_color = gc
	_line_a.text = "ENDLESS"; _line_a.label_settings.font_color = Color(style.line.endless_color)
	var e := int(tt.embers); var s := int(tt.smoke)
	_embers.emitting = e > 0 and not reduce_motion
	if e > 0: _embers.amount = mini(e, int(style.caps.embers)); _embers.color = Color(tt.get("ember_color", "#FF6A3A"))
	_smoke.emitting = s > 0 and not reduce_motion
	if s > 0: _smoke.amount = mini(s, int(style.caps.smoke)); _smoke.color = Color(tt.get("smoke_color", "#120808"))


func _process(delta: float) -> void:
	_t += delta
	var g: Dictionary = style.glitch
	if _glitch_t >= 0.0:
		_glitch_t += delta
		var d := float(g.duration_s)
		if _glitch_t < d:
			_ghost.visible = true
			_ghost.position = Vector2(g.ghost_offset[0], g.ghost_offset[1])
			var step := int(_glitch_t / float(g.shake_step_s))
			var sx := float(g.shake_px) * (1.0 if step % 2 == 0 else -1.0)
			_digits.position.x = 0.0 if reduce_motion else sx
			return
		_ghost.visible = false; _digits.position.x = 0.0
		if tier == -1:
			tier = 0; _apply_tier(); _set_text("00:00")
		var k := clampf((_glitch_t - d) / float(g.settle_s), 0.0, 1.0)
		var sc := lerpf(float(g.settle_scale), 1.0, 1.0 - pow(1.0 - k, 3.0)) if not reduce_motion else 1.0
		_digits.scale = Vector2.ONE * sc; _glow.scale = _digits.scale
		if k >= 1.0: _glitch_t = -1.0
	if not endless or tier < 0 or reduce_motion: return
	var tt: Dictionary = style.tiers[tier]
	if bool(tt.smoulder):   # stepped flicker of the edge between coal colours
		var cols: Array = tt.smoulder_colors; var n := int(tt.smoulder_steps)
		var i := int(fmod(_t, float(tt.smoulder_s)) / float(tt.smoulder_s) * n) % cols.size()
		_digit_settings.outline_color = Color(cols[i]); var gc := Color(cols[i]); gc.a = float(tt.glow_alpha); _glow_settings.outline_color = gc
	elif float(tt.pulse_s) > 0.0:
		var p := 0.5 + 0.5 * sin(_t / float(tt.pulse_s) * TAU)
		var gc := Color(tt.glow); gc.a = float(tt.glow_alpha) * (0.6 + 0.4 * p); _glow_settings.outline_color = gc
	if float(tt.twitch_s) > 0.0:
		var ph := fmod(_t, float(tt.twitch_s)) / float(tt.twitch_s)
		_digits.position = Vector2(-2, 1) if ph > 0.92 and ph < 0.95 else (Vector2(2, -1) if ph >= 0.95 and ph < 0.97 else Vector2.ZERO)
