class_name RunStage
extends Control
# 1920x1080 design stage for new in-run UI, scaled to fit the window exactly like MenuScreen's stage, so HUD and panels
# are laid out once in design pixels and follow the 1280x720 project viewport or any window size.
var stage: Control
func _init() -> void:
 name="RunStage";set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE;theme=MenuStyle.theme()
 stage=Control.new();stage.name="Stage";stage.size=Vector2(MenuStyle.W,MenuStyle.H);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(stage)
 resized.connect(fit)
func _ready() -> void:fit()
func fit() -> void:
 var s=minf(size.x/MenuStyle.W,size.y/MenuStyle.H)
 stage.scale=Vector2(s,s);stage.position=((size-stage.size*s)*0.5).floor()
