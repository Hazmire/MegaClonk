## Smoke test used to check this pack in Godot 4.7.2: builds a few themed controls over the
## reference screenshot and saves shot.png. Run: godot --path . -s res://ui/example_usage.gd
## (expects res://bg.jpg; copy reference/hud_background.jpg there first).
extends SceneTree
func _initialize():
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.size = Vector2(1280,720)
	root.theme = FogTheme.build()
	get_root().add_child(root)
	var bg := TextureRect.new(); bg.texture = ImageTexture.create_from_image(Image.load_from_file("res://bg.jpg")); bg.size = Vector2(1280,720); bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; root.add_child(bg)
	var p := Panel.new(); p.position = Vector2(40,60); p.size = Vector2(300,400); root.add_child(p)
	var cap := Label.new(); cap.theme_type_variation = "CapsLabel"; cap.text = "WEAPONS · 1/4"; cap.position = Vector2(60,80); root.add_child(cap)
	var t := Label.new(); t.theme_type_variation = "TitleLabel"; t.text = "Paused"; t.position = Vector2(520,40); root.add_child(t)
	var b1 := Button.new(); b1.text = "Resume"; b1.position = Vector2(480,180); b1.size = Vector2(320,56); root.add_child(b1); b1.grab_focus()
	var b2 := Button.new(); b2.text = "Settings"; b2.position = Vector2(480,240); b2.size = Vector2(320,48); root.add_child(b2)
	var hp := ProgressBar.new(); hp.value = 64; hp.position = Vector2(40,620); hp.size = Vector2(360,26); root.add_child(hp)
	var xp := ProgressBar.new(); xp.theme_type_variation = "XPBar"; xp.value = 78; xp.show_percentage = false; xp.position = Vector2(40,680); xp.size = Vector2(1200,12); root.add_child(xp)
	var n := Label.new(); n.theme_type_variation = "HudNumber"; n.text = "22"; n.position = Vector2(1180,30); root.add_child(n)
	var m := PanelContainer.new(); m.add_theme_stylebox_override("panel", FogTheme.memo_style()); m.position = Vector2(900,200); var ml := Label.new(); ml.theme_type_variation="MemoLabel"; ml.text="Scythes mastery\n63/100"; m.add_child(ml); root.add_child(m)
	var slot := Panel.new(); slot.add_theme_stylebox_override("panel", FogTheme.rarity_slot(FogPalette.Rarity.LEGENDARY)); slot.position = Vector2(60,120); slot.size = Vector2(84,84); var sh := ShaderMaterial.new(); sh.shader = load("res://ui/shaders/legendary_shimmer.gdshader"); slot.material = sh; root.add_child(slot)
	var fill := ColorRect.new(); fill.position = Vector2(40,580); fill.size = Vector2(360,20); var dm := ShaderMaterial.new(); dm.shader = load("res://ui/shaders/dither_fill.gdshader"); fill.material = dm; root.add_child(fill)
	var pop := PickupPopup.new(); pop.position = Vector2(640,330); root.add_child(pop); pop.setup("gold", 22)
	var ov := ColorRect.new(); ov.size = Vector2(1280,720); ov.mouse_filter = Control.MOUSE_FILTER_IGNORE; var om := ShaderMaterial.new(); om.shader = load("res://ui/shaders/fog_overlay.gdshader"); om.set_shader_parameter("low_hp", 1.0); ov.material = om; root.add_child(ov)
	await create_timer(0.35).timeout
	await process_frame; await process_frame
	get_root().get_texture().get_image().save_png("res://shot.png")
	print("SHOT_OK")
	quit()
