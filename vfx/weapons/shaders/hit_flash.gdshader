// Megaclonk — hit flash overlay.
// Put on an enemy's material_overlay (hit_flash.gd does this for you)
// and animate `amount` from 1 to 0 to flash the whole mesh one colour.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = flash_color.rgb;
	ALPHA = amount * flash_color.a;
}
