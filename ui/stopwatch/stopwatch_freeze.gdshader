// Stopwatch: the frozen world. A full-screen ColorRect on a CanvasLayer BELOW the HUD, so the HUD stays in
// colour. Inside the wave radius the world is desaturated and tinted cold; a small bubble around the player
// stays in colour; a glowing ice ring marks the wave front.
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(960.0, 540.0);    // player, in canvas (logical) pixels
uniform vec2 view_size = vec2(1920.0, 1080.0); // the canvas size those pixels are measured in (differs from the real pixel count when the window is scaled)
uniform float radius = 0.0;                  // wave radius in pixels (0 = off)
uniform float bubble = 64.0;                 // pocket of moving time around the player
uniform float zoom = 1.0;                    // zoom punch about the player (1 = none)
uniform float ring = 0.0;                    // 0..1 brightness of the wave-front ring
uniform vec4 tint : source_color = vec4(0.50, 0.66, 0.85, 1.0);
uniform float tint_amount = 0.4;
uniform float brightness = 1.35;
uniform float contrast = 1.1;
uniform vec4 ice : source_color = vec4(0.81, 0.91, 1.0, 1.0);
void fragment() {
	vec2 px = SCREEN_UV * view_size;
	vec2 cuv = center / view_size;
	vec3 col = texture(screen_tex, (SCREEN_UV - cuv) / zoom + cuv).rgb;
	float d = distance(px, center);
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	g = clamp((g - 0.5) * contrast + 0.5, 0.0, 1.0) * brightness;
	vec3 frozen = mix(vec3(g), vec3(g) * tint.rgb, tint_amount);
	// cold inner glow toward the screen edges
	vec2 e = min(SCREEN_UV, 1.0 - SCREEN_UV);
	frozen = mix(frozen, ice.rgb, 0.35 * (1.0 - smoothstep(0.0, 0.12, min(e.x, e.y))));
	float inside = step(d, radius) * smoothstep(bubble * 0.7, bubble, d);
	vec3 outc = mix(col, frozen, inside);
	// bubble rim and wave-front ring
	float bub_rim = (1.0 - smoothstep(0.0, 2.5, abs(d - bubble))) * step(bubble + 1.0, radius) * 0.5;
	float front = (1.0 - smoothstep(0.0, 4.0, abs(d - radius))) + 0.5 * (1.0 - smoothstep(0.0, 28.0, abs(d - radius)));
	outc += ice.rgb * (bub_rim + front * ring * step(1.0, radius));
	COLOR = vec4(outc, 1.0);
}
