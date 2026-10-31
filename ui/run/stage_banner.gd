class_name StageBanner
extends Control
# The stage announcement over the run: a small-caps "STAGE n" line, the stage's name in serif tinted with its accent colour and a rust
# rule. It fades and settles in, then out; reduced motion skips the pop. The caller keeps one reference (FrontEnd.stage_banner).
func setup(number: int,reduced: bool) -> StageBanner:
 var cfg=StageThemes.config(number)
 name="StageBanner";mouse_filter=Control.MOUSE_FILTER_IGNORE;process_mode=Node.PROCESS_MODE_ALWAYS;position=Vector2(0,84);size=Vector2(1280,110);pivot_offset=Vector2(640,50)
 var cap=SmallCapsLabel.new().setup("Stage %d"%number,13,Color("A9ADA4"),800,0.4);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cap.position=Vector2(0,0);cap.size=Vector2(1280,18);add_child(cap)
 var title=MenuStyle.label(str(cfg.title),MenuStyle.serif(),46,cfg.accent,2,self);title.name="Title";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.position=Vector2(0,20);title.size=Vector2(1280,60)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(616,88);rule.size=Vector2(48,4);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(rule)
 modulate.a=0.0;scale=Vector2.ONE*0.94
 var tween=create_tween();tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 tween.tween_property(self,"modulate:a",1.0,0.3)
 if not reduced:tween.parallel().tween_property(self,"scale",Vector2.ONE,0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tween.tween_interval(1.5);tween.tween_property(self,"modulate:a",0.0,0.6);tween.tween_callback(queue_free)
 return self
