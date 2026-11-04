## Renders the timer states to PNG: godot --path . --script res://preview.gd -- state=<name> out=res://x.png
extends SceneTree
func arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(k + "="): return a.split("=")[1]
	return d
func _initialize() -> void:
	var root := Control.new(); root.size = Vector2(960, 220); get_root().add_child(root)
	var bg := TextureRect.new(); bg.texture = ImageTexture.create_from_image(Image.load_from_file("res://bg.jpg")); bg.size = Vector2(1920, 1080); bg.position = Vector2(-480, -60); root.add_child(bg)
	var et := EndlessTimer.new(); root.add_child(et); et.position = Vector2(180, 40)
	await process_frame
	var st := arg("state", "before")
	match st:
		"before": et.set_run_time(598)
		"glitch": et.set_run_time(600); et.start_endless()
		_:
			et.start_endless()
			for i in 40: await process_frame   # let the glitch and settle finish (fixed fps in the recording)
			et.set_endless_time({"t0": 107, "t1": 266, "t2": 531, "t3": 872, "hour": 3765}[st])
	for i in (6 if st == "glitch" else 60): await process_frame
	get_root().get_texture().get_image().save_png(arg("out", "res://et.png")); quit()
