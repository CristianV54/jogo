class_name FabricaNatureza
extends RefCounted
## Árvores, pedras e arbustos procedurais, pintados por vértice (sem textura): um estilo só, leves e fáceis de espalhar.
## Todos os modelos têm a base em y = 0 e os eixos de um objeto em pé.

static func material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	return m


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, para_fora: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.dot(para_fora) < 0.0:   # garante a face voltada para fora (o Godot desenha o lado horário)
		var t := b; b = c; c = t
		var tc := cb; cb = cc; cc = tc
		n = -n
	n = n.normalized()
	st.set_color(ca.srgb_to_linear()); st.set_normal(n); st.add_vertex(a)
	st.set_color(cb.srgb_to_linear()); st.set_normal(n); st.add_vertex(c)
	st.set_color(cc.srgb_to_linear()); st.set_normal(n); st.add_vertex(b)


static func _cone(st: SurfaceTool, y0: float, altura: float, raio: float, lados: int, c_base: Color, c_topo: Color) -> void:
	var topo := Vector3(0, y0 + altura, 0)
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var p0 := Vector3(cos(a0) * raio, y0, sin(a0) * raio)
		var p1 := Vector3(cos(a1) * raio, y0, sin(a1) * raio)
		var centro := (p0 + p1 + topo) / 3.0
		_tri(st, p0, p1, topo, c_base, c_base, c_topo, Vector3(centro.x, 0.3, centro.z))
		_tri(st, p1, p0, Vector3(0, y0, 0), c_base * 0.7, c_base * 0.7, c_base * 0.7, Vector3.DOWN)   # fundo


static func _cilindro(st: SurfaceTool, y0: float, y1: float, r0: float, r1: float, lados: int, c0: Color, c1: Color) -> void:
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var b0 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var b1 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
		var t0 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
		var t1 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
		var f := Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0))
		_tri(st, b0, b1, t1, c0, c0, c1, f)
		_tri(st, b0, t1, t0, c0, c1, c1, f)


## Pinheiro de ~7,7 m: tronco marrom e cinco camadas de agulhas, mais claras no alto.
static func pinheiro() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cilindro(st, 0.0, 2.6, 0.28, 0.18, 6, Color(0.30, 0.20, 0.13), Color(0.25, 0.17, 0.11))
	var camadas := [[1.2, 2.6, 2.0], [2.5, 2.4, 1.6], [3.8, 2.2, 1.25], [5.0, 2.0, 0.9], [6.1, 1.6, 0.55]]
	for k in camadas.size():
		var c: Array = camadas[k]
		var t := float(k) / (camadas.size() - 1)
		_cone(st, c[0], c[1], c[2], 8, Color(0.10, 0.27, 0.15).lerp(Color(0.16, 0.36, 0.18), t), Color(0.17, 0.38, 0.2).lerp(Color(0.26, 0.5, 0.26), t))
	return st.commit()


static func _ruido(i: int, j: int, semente: float) -> float:
	return fposmod(sin(i * 12.9898 + j * 78.233 + semente) * 43758.5453, 1.0)


## Esfera irregular achatada, em tons de cinza (pedra) ou verde (arbusto).
static func _blob(semente: float, raio: float, achatar: float, c_baixo: Color, c_alto: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aneis := 5
	var lados := 8
	var pts: Array = []
	for i in aneis + 1:
		var fila: Array = []
		var phi := PI * i / aneis
		for j in lados:
			var th := TAU * j / lados
			var r := raio * (0.82 + 0.38 * _ruido(i, j, semente))
			var p := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th)) * r
			p.y = maxf(p.y * achatar, 0.0)
			fila.append(p)
		pts.append(fila)
	for i in aneis:
		for j in lados:
			var a: Vector3 = pts[i][j]
			var b: Vector3 = pts[i][(j + 1) % lados]
			var c: Vector3 = pts[i + 1][j]
			var d: Vector3 = pts[i + 1][(j + 1) % lados]
			var centro := (a + b + c + d) / 4.0
			var ta := clampf(a.y / (raio * achatar), 0.0, 1.0)
			var tb := clampf(b.y / (raio * achatar), 0.0, 1.0)
			var tc := clampf(c.y / (raio * achatar), 0.0, 1.0)
			var td := clampf(d.y / (raio * achatar), 0.0, 1.0)
			_tri(st, a, b, c, c_baixo.lerp(c_alto, ta), c_baixo.lerp(c_alto, tb), c_baixo.lerp(c_alto, tc), centro)
			_tri(st, b, d, c, c_baixo.lerp(c_alto, tb), c_baixo.lerp(c_alto, td), c_baixo.lerp(c_alto, tc), centro)
	return st.commit()


static func pedra(semente := 1.0) -> ArrayMesh:
	return _blob(semente, 1.0, 0.75, Color(0.36, 0.35, 0.34), Color(0.58, 0.57, 0.54))


static func arbusto(semente := 2.0) -> ArrayMesh:
	return _blob(semente, 0.9, 0.8, Color(0.14, 0.28, 0.12), Color(0.26, 0.45, 0.2))


static func toras() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cilindro(st, 0.0, 1.6, 0.18, 0.18, 6, Color(0.40, 0.28, 0.17), Color(0.36, 0.25, 0.15))
	return st.commit()
