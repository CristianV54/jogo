class_name VegetacaoRasteira
extends RefCounted
## Dá vida ao chão de uma clareira: manchas de cor no solo (capim seco, mato escuro, terra), tufos de grama em
## MultiMesh e anéis de flores de cores diferentes. `exclusoes` é uma lista de [centro Vector2 (x, z), raio] onde nada nasce.

const CORES_DE_FLOR := [Color(1.0, 0.85, 0.2), Color(0.95, 0.95, 0.9), Color(0.95, 0.4, 0.15), Color(0.5, 0.7, 0.95), Color(0.95, 0.55, 0.7)]
const CORES_DE_MANCHA := [Color(0.5, 0.44, 0.2, 0.55), Color(0.08, 0.22, 0.09, 0.55), Color(0.33, 0.24, 0.15, 0.6), Color(0.24, 0.38, 0.14, 0.5)]


static func espalhar(pai: Node3D, t: Terreno, rng: RandomNumberGenerator, raio: float, exclusoes: Array) -> void:
	_manchas(pai, t, rng, raio, exclusoes)
	_capim(pai, t, rng, raio, exclusoes)
	_flores(pai, t, rng, raio, exclusoes)


static func _livre(t: Terreno, x: float, z: float, exclusoes: Array) -> bool:
	for e in exclusoes:
		if Vector2(x, z).distance_to(e[0]) < e[1]:
			return false
	return t.distancia_caminho(x, z) > 1.8


static func _ponto(rng: RandomNumberGenerator, raio: float) -> Vector2:
	var ang := rng.randf() * TAU
	return Vector2(cos(ang), sin(ang)) * sqrt(rng.randf()) * raio


static func _manchas(pai: Node3D, t: Terreno, rng: RandomNumberGenerator, raio: float, exclusoes: Array) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.55, Color(1, 1, 1, 0.8))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var materiais: Array[StandardMaterial3D] = []
	for c in CORES_DE_MANCHA:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.albedo_texture = tex
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
		materiais.append(m)
	var plano := PlaneMesh.new()
	plano.size = Vector2(1.0, 1.0)
	for i in 34:
		var p := _ponto(rng, raio)
		if not _livre(t, p.x, p.y, exclusoes):
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = plano
		mi.material_override = materiais[rng.randi() % materiais.size()]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tam := rng.randf_range(4.0, 11.0)
		mi.scale = Vector3(tam, 1.0, tam * rng.randf_range(0.6, 1.0))
		mi.rotation.y = rng.randf() * TAU
		mi.position = Vector3(p.x, t.altura_em(p.x, p.y) + 0.04, p.y)
		pai.add_child(mi)


static func _malha_tufo() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 9:
		var ang := TAU * i / 9.0 + rng.randf() * 0.5
		var base := Vector3(cos(ang), 0.0, sin(ang)) * rng.randf_range(0.02, 0.1)
		var lado := Vector3(-sin(ang), 0.0, cos(ang)) * 0.035
		var h := rng.randf_range(0.22, 0.42)
		var ponta := base + Vector3(cos(ang), 0.0, sin(ang)) * rng.randf_range(0.04, 0.12) + Vector3(0.0, h, 0.0)
		st.set_color(Color(0.1, 0.24, 0.08))
		st.add_vertex(base - lado)
		st.add_vertex(base + lado)
		st.set_color(Color(0.3, 0.46, 0.17))
		st.add_vertex(ponta)
	st.generate_normals()
	return st.commit()


static func _capim(pai: Node3D, t: Terreno, rng: RandomNumberGenerator, raio: float, exclusoes: Array) -> void:
	var lista: Array[Transform3D] = []
	for i in 40:   # 40 moitas; cada uma com vários tufos juntos
		var c := _ponto(rng, raio)
		for j in rng.randi_range(6, 16):
			var p := c + Vector2(rng.randfn(0.0, 1.4), rng.randfn(0.0, 1.4))
			if p.length() > raio or not _livre(t, p.x, p.y, exclusoes):
				continue
			var s := rng.randf_range(0.7, 1.5)
			var base := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.4), s))
			lista.append(Transform3D(base, Vector3(p.x, t.altura_em(p.x, p.y) - 0.02, p.y)))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	_multimesh(pai, _malha_tufo(), mat, lista, "Capim")


static func _multimesh(pai: Node3D, malha: Mesh, mat: Material, transformacoes: Array[Transform3D], nome: String, cores: Array[Color] = []) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not cores.is_empty()
	mm.mesh = malha
	mm.instance_count = transformacoes.size()
	for i in transformacoes.size():
		mm.set_instance_transform(i, transformacoes[i])
		if mm.use_colors:
			mm.set_instance_color(i, cores[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(inst)


static func _flores(pai: Node3D, t: Terreno, rng: RandomNumberGenerator, raio: float, exclusoes: Array) -> void:
	var cabeca := CylinderMesh.new()   # corola: disco achatado de 6 lados
	cabeca.top_radius = 0.09
	cabeca.bottom_radius = 0.07
	cabeca.height = 0.03
	cabeca.radial_segments = 6
	cabeca.rings = 1
	var haste := CylinderMesh.new()
	haste.top_radius = 0.008
	haste.bottom_radius = 0.012
	haste.height = 0.26
	haste.radial_segments = 4
	haste.rings = 1
	var t_cabecas: Array[Transform3D] = []
	var t_hastes: Array[Transform3D] = []
	var cores: Array[Color] = []
	var plantar := func(x: float, z: float, cor: Color) -> void:
		var y := t.altura_em(x, z)
		var giro := Basis(Vector3.UP, rng.randf() * TAU)
		t_hastes.append(Transform3D(giro, Vector3(x, y + 0.12, z)))
		t_cabecas.append(Transform3D(giro, Vector3(x, y + 0.27, z)))
		cores.append(cor)
	for i in 14:   # anéis de flores da mesma cor
		var c := _ponto(rng, raio)
		var cor: Color = CORES_DE_FLOR[rng.randi() % CORES_DE_FLOR.size()]
		var r := rng.randf_range(1.1, 2.4)
		var n := rng.randi_range(12, 22)
		for k in n:
			var a := TAU * k / n + rng.randf() * 0.15
			var p := c + Vector2(cos(a), sin(a)) * (r + rng.randf_range(-0.15, 0.15))
			if p.length() < raio and _livre(t, p.x, p.y, exclusoes):
				plantar.call(p.x, p.y, cor)
	for i in 45:   # flores soltas
		var p := _ponto(rng, raio)
		if _livre(t, p.x, p.y, exclusoes):
			plantar.call(p.x, p.y, CORES_DE_FLOR[rng.randi() % CORES_DE_FLOR.size()])
	var mat_haste := StandardMaterial3D.new()
	mat_haste.albedo_color = Color(0.2, 0.42, 0.15)
	var mat_cabeca := StandardMaterial3D.new()
	mat_cabeca.vertex_color_use_as_albedo = true
	mat_cabeca.roughness = 0.9
	var so_hastes: Array[Color] = []
	_multimesh(pai, haste, mat_haste, t_hastes, "FloresHastes", so_hastes)
	_multimesh(pai, cabeca, mat_cabeca, t_cabecas, "FloresCorolas", cores)
