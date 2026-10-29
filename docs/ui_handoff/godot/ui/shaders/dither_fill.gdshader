// Dithered bar fill (HP, XP, quest progress). Apply to the ProgressBar's fill via a
// TextureProgressBar, or to a ColorRect sized by code. 4px checker like the mockups.
shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.494, 0.094, 0.125, 1.0); // RUST
uniform float checker_px = 2.0;          // one cell; 2 -> 4px repeat
uniform float light = 0.06;              // rgba(255,255,255,0.06)
uniform float dark = 0.06;               // rgba(0,0,0,0.06)
uniform float glow = 0.0;                // XP bar uses a soft outer glow; 0 for HP

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / checker_px);
	float check = mod(cell.x + cell.y, 2.0);
	vec3 c = fill_color.rgb + (check > 0.5 ? vec3(light) : vec3(-dark));
	COLOR = vec4(c + glow * 0.15, fill_color.a * texture(TEXTURE, UV).a);
}
