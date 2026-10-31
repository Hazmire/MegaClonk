// Diagonal light sweep for Legendary cards and the chest reveal
// (the mockup uses 115-degree stripes; the rarity board says "add a shimmer in-engine").
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 0.945, 0.761, 1.0); // GOLD_PALE
uniform float strength : hint_range(0.0, 1.0) = 0.35;
uniform float speed = 0.6;        // sweeps per second
uniform float width = 0.12;
uniform float angle_deg = 115.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float a = radians(angle_deg);
	float p = dot(UV - 0.5, vec2(cos(a), sin(a)));
	float t = fract(TIME * speed) * 2.4 - 1.2;
	float band = 1.0 - smoothstep(0.0, width, abs(p - t));
	COLOR = vec4(mix(base.rgb, tint.rgb, band * strength * base.a), base.a);
}
