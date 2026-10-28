class_name GrimdarkRenderer
extends Node
var game: Node
var viewport: SubViewport
var proxy: Camera3D
var image: TextureRect
var material: ShaderMaterial
func setup(owner_game: Node):
 game=owner_game;process_priority=40
 viewport=SubViewport.new();viewport.name="RetroWorld640x360";viewport.world_3d=game.get_viewport().world_3d;viewport.audio_listener_enable_3d=false;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
 proxy=Camera3D.new();viewport.add_child(proxy);proxy.current=true
 var layer=CanvasLayer.new();layer.layer=-20;add_child(layer);image=TextureRect.new();image.texture=viewport.get_texture();image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(image)
 material=ShaderMaterial.new();material.shader=preload("res://shaders/grimdark_composite.gdshader");image.material=material
 game.get_viewport().disable_3d=true;apply_settings();_process(0)
func apply_settings():
 var size=game.get_viewport().get_visible_rect().size
 var scale_value=clampf(float(game.settings.get("retro_scale",.5))*float(game.settings.render_scale),.125,1)
 viewport.size=Vector2i(maxi(160,roundi(size.x*scale_value)),maxi(90,roundi(size.y*scale_value)));image.size=size
 material.set_shader_parameter("dither_enabled",game.settings.get("psx_dither",true));material.set_shader_parameter("bit_depth",5)
 RenderingServer.global_shader_parameter_set("psx_affine_strength",float(game.settings.get("psx_warp",.25)))
 var snap=float(game.settings.get("psx_snap",.35));RenderingServer.global_shader_parameter_set("psx_precision_xy",512/maxf(snap,.01) if snap>0 else 0.0)
func _process(_delta: float):
 if not is_instance_valid(game):return
 var source=game.get_viewport().get_camera_3d()
 if source==null:return
 proxy.global_transform=source.global_transform;proxy.fov=source.fov;proxy.near=source.near;proxy.far=source.far;proxy.h_offset=source.h_offset;proxy.v_offset=source.v_offset;proxy.cull_mask=source.cull_mask
 var size=game.get_viewport().get_visible_rect().size
 if image.size!=size:apply_settings()
func _exit_tree():
 if is_instance_valid(game) and game.is_inside_tree():game.get_viewport().set_deferred("disable_3d",false)
