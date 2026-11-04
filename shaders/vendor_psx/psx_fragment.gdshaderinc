vec2 uv = mix(UV, v_uv / v_clip.w, psx_affine_strength);
	vec2 uv2 = mix(UV2, v_uv2 / v_clip.w, psx_affine_strength);
	float precision_uv = psx_precision_uv * i_precision_uv;

	if (precision_uv != 0.0) {
		uv = trunc(uv * precision_uv) / precision_uv;
		uv2 = trunc(uv2 * precision_uv) / precision_uv;
	}

	vec4 albedo = texture(u_albedo_texture, uv) * u_albedo_color;
	if (u_vertex_color_use_as_albedo) {
		albedo *= vec4(v_vertex_color, 1.0);
	}

#if !defined ALPHA_DISABLED
	ALPHA = albedo.a;
#if defined ALPHA_SCISSOR
	ALPHA_SCISSOR_THRESHOLD = u_alpha_scissor_threshold;
#endif
#endif

#if defined EMISSION_ADD
	vec3 emission = texture(u_emission_texture, u_emission_on_uv2 ? uv2 : uv).rgb + u_emission;
	EMISSION = emission * u_emission_energy_multiplier;
#elif defined EMISSION_MULTIPLY
	vec3 emission = texture(u_emission_texture, u_emission_on_uv2 ? uv2 : uv).rgb * u_emission;
	EMISSION = emission * u_emission_energy_multiplier;
#endif

	ALBEDO = albedo.rgb;

	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;

