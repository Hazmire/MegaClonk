v_vertex_color = COLOR.rgb;

#if !defined BILLBOARD_DISABLED
#if defined BILLBOARD_KEEP_SCALE
	mat3 model_basis = mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz);
	bool mirrored = determinant(model_basis) < 0.0;
	vec3 model_scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	) * (mirrored ? -1.0 : 1.0);
#else
	vec3 model_scale = vec3(1.0);
#endif

#if (defined BILLBOARD_ENABLED) || (defined BILLBOARD_PARTICLES)
	MODELVIEW_MATRIX = mat4(
		vec4(model_scale.x, 0.0, 0.0, 0.0),
		vec4(0.0, model_scale.y, 0.0, 0.0),
		vec4(0.0, 0.0, model_scale.z, 0.0),
		MODELVIEW_MATRIX[3]
	);
	MODELVIEW_NORMAL_MATRIX = mat3(
		MODELVIEW_MATRIX[0].xyz,
		MODELVIEW_MATRIX[1].xyz,
		MODELVIEW_MATRIX[2].xyz
	);

#elif defined BILLBOARD_FIXED_Y
	vec3 vr = vec3(1.0, 0.0, 0.0);
	vec3 vu = VIEW_MATRIX[1].xyz;

	MODELVIEW_MATRIX = mat4(
		vec4(vr, 0.0),
		vec4(vu, 0.0),
		vec4(cross(vr, vu), 0.0),
		MODELVIEW_MATRIX[3]
	) * mat4(
		vec4(model_scale.x, 0, 0, 0),
		vec4(0, model_scale.y, 0, 0),
		vec4(0, 0, model_scale.z, 0),
		vec4(0, 0, 0, MODEL_MATRIX[3][3])
	);
	MODELVIEW_NORMAL_MATRIX = mat3(
		MODELVIEW_MATRIX[0].xyz,
		MODELVIEW_MATRIX[1].xyz,
		MODELVIEW_MATRIX[2].xyz
	);
#endif
#endif

	float precision_xy = psx_precision_xy * i_precision_xy;
	float precision_z = psx_precision_z * i_precision_z;

	v_clip = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float fov = 2.0 * atan(1.0 / PROJECTION_MATRIX[1][1]);
	float clip_depth = v_clip.z * fov;

	if (precision_xy != 0.0) {
		v_clip.xy = trunc((v_clip.xy / clip_depth) * precision_xy) * clip_depth / precision_xy;
	}
	if (precision_z != 0.0) {
		v_clip.z = trunc((v_clip.z / fov) * precision_z) * fov / precision_z;
	}

	VERTEX = (inverse(MODELVIEW_MATRIX) * v_clip).xyz;
	// Godot view-space w is one; affine interpolation/fog need actual depth.
	v_clip.w = max(abs(v_clip.z), 0.001);

	v_uv = UV * v_clip.w;
	v_uv2 = UV2 * v_clip.w;

#if defined VERTEX_FOG_ENABLED
	v_fog_strength = psx_fog_near != psx_fog_far ?
		psx_fog_color.a * clamp((v_clip.w - psx_fog_near) / (psx_fog_far - psx_fog_near), 0.0, 1.0) :
		0.0;
	v_fog_color = psx_fog_color.rgb;
#elif defined VERTEX_FOG_ALWAYS
	v_fog_strength = psx_fog_color.a;
	v_fog_color = psx_fog_color.rgb;
#endif

