class_name StopwatchOverlay
extends Control

# Visual feedback for the Stopwatch: a short activation flash
# and a remaining-time bar with a label. The screen edge glow lives in the shared RunOverlay (stopwatch uniform).
# Purely presentational: it only reads WorldTime.
const FADE_IN=0.25
const FADE_OUT=0.6
const FLASH_TIME=0.35
var flash: ColorRect
var bar: ProgressBar
var label: Label
var strength=0.0
var last_remaining=0.0
var flash_left=0.0

# `front_parent` receives the flash, bar and label.
func setup(front_parent: Control) -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 flash=ColorRect.new();flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;flash.color=Color(0.85,0.93,1.0,0.0);flash.hide()
 front_parent.add_child(flash)
 bar=ProgressBar.new();bar.position=Vector2(28,300);bar.size=Vector2(270,12);bar.show_percentage=false;bar.max_value=1.0;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var fill=StyleBoxFlat.new();fill.bg_color=Color("8fb8e8");bar.add_theme_stylebox_override("fill",fill)
 var track=StyleBoxFlat.new();track.bg_color=Color("1b2433");track.border_color=Color("5b7490");track.set_border_width_all(1);bar.add_theme_stylebox_override("background",track)
 bar.hide();front_parent.add_child(bar)
 label=Label.new();label.position=Vector2(28,318);label.add_theme_font_size_override("font_size",15);label.add_theme_color_override("font_color",Color("bcd6f5"));label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.hide();front_parent.add_child(label)

# Called every HUD update with the game's WorldTime and the real frame time.
func update_state(time: WorldTime,delta: float) -> void:
 var remaining=time.remaining
 if remaining>last_remaining+0.01:flash_left=FLASH_TIME # picked up or refreshed
 last_remaining=remaining
 var rate=(1.0/FADE_IN) if remaining>0.0 else (1.0/FADE_OUT)
 strength=move_toward(strength,1.0 if remaining>0.0 else 0.0,delta*rate)
 bar.visible=remaining>0.0;label.visible=remaining>0.0
 bar.value=time.fraction()
 label.text="STOPWATCH  %.1fs"%maxf(0.0,remaining)
 flash_left=maxf(0.0,flash_left-delta)
 flash.visible=flash_left>0.0
 flash.color.a=0.5*flash_left/FLASH_TIME
# Hides everything at once; used when a run ends, a stage is built or a run starts.
func reset() -> void:
 strength=0.0;last_remaining=0.0;flash_left=0.0
 if is_instance_valid(flash):flash.hide()
 if is_instance_valid(bar):bar.hide()
 if is_instance_valid(label):label.hide()
