shader_type canvas_item;
// Stopwatch bullet-time grade: desaturate towards blue-grey, posterise with a small ordered
// dither shift and darken the corners. strength 0 leaves the screen untouched, and the overlay
// is hidden at 0 so there is no cost outside the effect. It sits behind the HUD layer.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint_color : source_color = vec3(0.62, 0.72, 0.86);

void fragment() {
	vec3 source = texture(screen_texture, SCREEN_UV).rgb;
	float grey = dot(source, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(source, vec3(grey), 0.62 * strength);
	graded = mix(graded, graded * tint_color * 1.18, 0.55 * strength);
	float levels = mix(48.0, 14.0, strength);
	vec2 pixel = floor(FRAGCOORD.xy);
	float dither = fract(dot(pixel, vec2(0.5, 0.25))) - 0.375;
	graded = floor(graded * levels + 0.5 + dither * 0.6 * strength) / levels;
	float edge = smoothstep(0.35, 0.95, length(SCREEN_UV - vec2(0.5)) * 1.25);
	graded *= 1.0 - edge * 0.28 * strength;
	COLOR = vec4(graded, 1.0);
}
