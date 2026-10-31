## World-space pickup number ("+22" gold, "+4" XP) from the HUD mockup.
## Pop to 115%, settle, hold, then drift up 46px and fade over 2.4 s.
## Rapid pickups of the same kind should call add() on the live popup instead of spawning a new one.
class_name PickupPopup
extends Label

const LIFETIME := 2.4
var amount := 0
var _tween: Tween

func setup(kind: String, value: int) -> void:
	amount = value
	text = "+%d" % amount
	add_theme_color_override("font_color", FogPalette.GOLD_PALE if kind == "gold" else Color("DDF1FF"))
	add_theme_color_override("font_outline_color", FogPalette.NIGHT)
	add_theme_constant_override("outline_size", 4)        # the 2px ink outline in the mockup
	add_theme_font_size_override("font_size", 30 if kind == "gold" else 22)
	var f := FogTheme.sans(800)
	if f:
		add_theme_font_override("font", f)
	pivot_offset = size / 2.0
	_play()

func add(value: int) -> void:
	amount += value
	text = "+%d" % amount
	_play()

func _play() -> void:
	if _tween:
		_tween.kill()
	var start_y := position.y
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.15, 1.15), LIFETIME * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "modulate:a", 1.0, LIFETIME * 0.12)
	_tween.tween_property(self, "scale", Vector2.ONE, LIFETIME * 0.10)
	_tween.tween_interval(LIFETIME * 0.50)
	_tween.tween_property(self, "position:y", start_y - 46.0, LIFETIME * 0.28)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, LIFETIME * 0.28)
	_tween.tween_callback(queue_free)
