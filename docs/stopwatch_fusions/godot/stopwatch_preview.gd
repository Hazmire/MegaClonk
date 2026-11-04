## Renders the Stopwatch states over a gameplay frame. godot --path . --script res://preview.gd -- t=3.0 out=res://x.png
## Timeline: an 8 s freeze starts at 0.5 s; a second pickup at 4.0 s refreshes it to full; it runs out at 12.0 s.
extends SceneTree
func arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(k + "="): return a.split("=")[1]
	return d
func _initialize() -> void:
	var world := CanvasLayer.new(); world.layer = 0; get_root().add_child(world)
	var bg := TextureRect.new(); bg.texture = ImageTexture.create_from_image(Image.load_from_file("res://bg.jpg"))
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.size = Vector2(1280, 720); world.add_child(bg)
	var fx := StopwatchFX.new(); get_root().add_child(fx); fx.timer_anchor = Vector2(640, 72)
	var frames := int(round(float(arg("t", "3.0")) * 30.0)); var dur := float(arg("dur", "8.0")); var dt := 1.0 / 30.0
	var left := 0.0
	for f in frames:
		if f == 15: left = dur
		elif f == 120 and arg("extend", "1") == "1": left = dur     # a second pickup refreshes it to full
		elif f > 15: left = maxf(left - dt, 0.0)
		fx.update(left, Vector2(640, 382))
		await process_frame
	for i in 2: await process_frame
	get_root().get_texture().get_image().save_png(arg("out", "res://sw.png")); quit()
