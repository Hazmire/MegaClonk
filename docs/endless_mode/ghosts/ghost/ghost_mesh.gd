## Megaclonk — builds the ghost mesh in code (one ArrayMesh, ~1.9k triangles, faces -Z).
## A long gaunt head hung forward and lolling, empty drooping eye sockets, a jaw that hangs far too long, a thin
## hunched shroud tattered into strands, and over-long arms with hooked fingers reaching ahead of the face.
## Vertex colours drive the shader:  R = tail weight  G = arm weight  B = face (0.5 socket, 1.0 eye).
##     var mesh := preload("res://ghost/ghost_mesh.gd").build()
## Build it once and share it between every ghost.
extends RefCounted

static func _ring(st: SurfaceTool, c: Vector3, r: float, segs: int, col: Color, ragged := 0.0, t := 0.0, sy := 1.1) -> Array:
	var pts := []
	for i in segs:
		var a := TAU * i / segs
		var rr := r * (1.0 + ragged * sin(a * 5.0 + t * 14.0) + ragged * 0.6 * sin(a * 3.0 - t * 9.0))
		pts.append(c + Vector3(cos(a) * rr, sin(a) * rr * sy, 0))
	return pts


static func _tube(st: SurfaceTool, path: Array, radii: Array, segs: int, cols: Array, ragged: Array = []) -> void:
	var rings := []
	for k in path.size():
		var rg: float = ragged[k] if ragged.size() > k else 0.0
		var ring := []
		var fwd: Vector3 = (path[min(k + 1, path.size() - 1)] - path[max(k - 1, 0)]).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		if side.length() < 0.1: side = Vector3.RIGHT
		var up := side.cross(fwd).normalized()
		for i in segs:
			var a := TAU * i / segs
			var rr: float = radii[k] * (1.0 + rg * sin(a * 5.0 + k * 1.7) + rg * 0.6 * sin(a * 3.0 - k * 1.1))
			ring.append(path[k] + (side * cos(a) + up * sin(a) * 1.1) * rr)
		rings.append(ring)
	for k in rings.size() - 1:
		for i in segs:
			var j := (i + 1) % segs
			var a: Vector3 = rings[k][i]; var b: Vector3 = rings[k][j]; var c: Vector3 = rings[k + 1][j]; var d: Vector3 = rings[k + 1][i]
			var c0: Color = cols[k]; var c1: Color = cols[k + 1]
			for v in [[a, c0], [b, c0], [c, c1], [a, c0], [c, c1], [d, c1]]:
				st.set_color(v[1]); st.add_vertex(v[0])


static func _blob(st: SurfaceTool, c: Vector3, r: float, scale: Vector3, col: Color, lat := 8, lon := 12, rot := Basis()) -> void:
	for i in lat:
		var t0 := PI * i / lat; var t1 := PI * (i + 1) / lat
		for j in lon:
			var p0 := TAU * j / lon; var p1 := TAU * (j + 1) / lon
			var q := [Vector3(sin(t0) * cos(p0), cos(t0), sin(t0) * sin(p0)), Vector3(sin(t0) * cos(p1), cos(t0), sin(t0) * sin(p1)),
				Vector3(sin(t1) * cos(p1), cos(t1), sin(t1) * sin(p1)), Vector3(sin(t1) * cos(p0), cos(t1), sin(t1) * sin(p0))]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(col); st.add_vertex(c + rot * (q[idx] * r * scale))


static func build() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# head: long, gaunt and skull-like, hung forward below the shoulders and lolling to one side
	var head := Vector3(0, 1.36, -0.16)
	var hb := Basis(Vector3.FORWARD, 0.38) * Basis(Vector3.RIGHT, 0.32)
	_blob(st, head, 0.24, Vector3(0.74, 1.5, 0.92), Color(0, 0, 0), 12, 14, hb)
	var f := func(local: Vector3) -> Vector3: return head + hb * local
	# eyes: long drooping black sockets, uneven, with a pin-prick glint deep inside and streaks running down
	for e in [[-1.0, 1.0], [1.0, 0.8]]:
		var sx: float = e[0]; var k: float = e[1]
		_blob(st, f.call(Vector3(sx * 0.07, 0.11, -0.19)), 0.06 * k, Vector3(0.9, 2.0, 0.6), Color(0, 0, 0.5), 8, 12, hb)
		_blob(st, f.call(Vector3(sx * 0.07, 0.07, -0.215)), 0.011, Vector3.ONE, Color(0, 0, 1.0), 4, 6, hb)
		_blob(st, f.call(Vector3(sx * 0.075, -0.06, -0.205)), 0.018, Vector3(0.6, 4.0, 0.5), Color(0, 0, 0.5), 4, 6, hb)
	# the jaw hangs far too long: a black slot from the nose to below the chin
	_blob(st, f.call(Vector3(0, -0.2, -0.17)), 0.07, Vector3(0.95, 4.4, 0.6), Color(0, 0, 0.5), 10, 12, hb)
	# the shroud: hunched, thin, tattered into long strands at the tail
	var path := []; var radii := []; var cols := []; var rag := []
	var n := 22
	var keys := [[0.0, 0.11], [0.08, 0.2], [0.18, 0.31], [0.3, 0.28], [0.45, 0.21], [0.65, 0.13], [0.85, 0.07], [1.0, 0.012]]   # neck, hunched shoulders, then wasting away
	for k in n + 1:
		var t := float(k) / n
		path.append(Vector3(sin(t * 2.6) * 0.07, 1.42 + sin(t * 3.4) * 0.12 - 0.78 * pow(t, 1.3), 0.02 + 2.2 * t))
		var r := 0.0
		for q in keys.size() - 1:
			if t >= keys[q][0] and t <= keys[q + 1][0]:
				r = lerpf(keys[q][1], keys[q + 1][1], smoothstep(keys[q][0], keys[q + 1][0], t))
		radii.append(r)
		cols.append(Color(clampf((t - 0.05) / 0.95, 0.0, 1.0), 0, 0))
		rag.append(clampf((t - 0.2) / 0.8, 0.0, 1.0) * 0.55)
	_tube(st, path, radii, 14, cols, rag)
	# arms: too long, elbows splayed out, reaching ahead of the face with four long hooked fingers
	for sx in [-1.0, 1.0]:
		var sh := Vector3(sx * 0.32, 1.38, 0.12)
		var el := Vector3(sx * 0.5, 1.22, -0.28)
		var wr := Vector3(sx * 0.3, 1.16, -0.86)
		var arm := [sh, sh.lerp(el, 0.5), el, el.lerp(wr, 0.5), wr]
		_tube(st, arm, [0.07, 0.055, 0.05, 0.04, 0.034], 8,
			[Color(0.1, 0.0, 0), Color(0.1, 0.25, 0), Color(0.1, 0.5, 0), Color(0.1, 0.75, 0), Color(0.1, 1.0, 0)])
		for fi in 4:
			var off := Vector3((fi - 1.5) * 0.032 * sx, (1.5 - absf(fi - 1.5)) * 0.01, 0)
			var tip := wr + off * 2.6 + Vector3(sx * 0.03, -0.16, -0.4)
			var knuckle := (wr + off).lerp(tip, 0.45) + Vector3(0, 0.05, 0)
			_tube(st, [wr + off, knuckle, tip], [0.016, 0.012, 0.003], 5,
				[Color(0.1, 1.0, 0), Color(0.1, 1.0, 0), Color(0.1, 1.0, 0)])
	st.index()
	st.generate_normals()
	return st.commit()
