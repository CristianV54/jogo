class_name Plantacao
extends Node3D
## Plantação de verdade: terra lavrada em sulcos, fileiras de trigo, milho, repolho, verduras e abóboras (cada fileira
## com plantas diferentes), as altas balançam ao vento (shader), com espantalho, fardos de feno, bebedouro e corvos
## pousados na cerca. A terra é plana: a plantação ocupa `largura` (x) por `profundidade` (z) centrada neste nó.

const ESPACO_FILEIRA := 1.15

var largura := 12.0
var profundidade := 9.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Clima.registrar_globais()
	set_meta("raio_capim", Vector2(largura, profundidade).length() / 2.0 + 3.0)   # o capim do mundo não nasce aqui
	_rng.seed = 5
	_terra()
	_fileiras()
	_espantalho(Vector3(0.0, 0.0, 0.0))
	_fardos()
	_bebedouro()
	for p in [Vector3(-largura / 2.0 + 0.3, 1.25, profundidade / 2.0), Vector3(largura / 2.0 - 0.3, 1.25, -profundidade / 2.0)]:   # corvos na cerca
		var corvo := Corvo.new()
		corvo.position = p
		add_child(corvo)


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	return m


func _terra() -> void:
	var chao := MeshInstance3D.new()   # terra batida de fundo: aparece nas trilhas entre os talhões
	var b := BoxMesh.new()
	b.size = Vector3(largura, 0.06, profundidade)
	b.material = _mat(Color(0.36, 0.26, 0.16))
	chao.mesh = b
	chao.position.y = 0.03
	add_child(chao)


## Faixa de terra revolvida de um talhão (mais escura que a trilha) com sulcos para os cultivos de fileira.
func _terra_do_talhao(x0: float, larg: float, sulcos: bool) -> void:
	var t := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(larg, 0.08, profundidade - 1.0)
	tb.material = _mat(Color(0.2, 0.13, 0.08))
	t.mesh = tb
	t.position = Vector3(x0 + larg / 2.0, 0.05, 0.0)
	add_child(t)
	if not sulcos:
		return
	for i in int((profundidade - 1.0) / 0.9):
		var s := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(larg - 0.3, 0.16, 0.45)
		sb.material = _mat(Color(0.3, 0.19, 0.11) if i % 2 == 0 else Color(0.25, 0.16, 0.1))
		s.mesh = sb
		s.position = Vector3(x0 + larg / 2.0, 0.1, -profundidade / 2.0 + 1.0 + i * 0.9)
		add_child(s)


# ---------------------------------------------------------------- malhas das plantas

func _tri(st: SurfaceTool, a: Vector3, ca: Color, b: Vector3, cb: Color, c: Vector3, cc: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	for par in [[a, ca], [b, cb], [c, cc]]:
		st.set_normal(n)
		st.set_color(par[1])
		st.add_vertex(par[0])


func _malha_trigo() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_cor := Color(0.5, 0.45, 0.14)
	var ponta := Color(0.92, 0.76, 0.26)
	for k in 7:
		var a := k * TAU / 7.0 + 0.3
		var r := 0.05 + (k % 2) * 0.05
		var dir := Vector3(cos(a), 0.0, sin(a))
		var lado := Vector3(-dir.z, 0.0, dir.x) * 0.025
		var raiz := dir * r
		var topo := raiz + dir * 0.07 + Vector3(0.0, 1.0 + (k % 3) * 0.1, 0.0)
		_tri(st, raiz - lado, base_cor, raiz + lado, base_cor, topo, ponta)
		var espiga := topo + Vector3(0.0, 0.17, 0.0)   # espiga dourada no topo
		_tri(st, topo - lado * 1.8, ponta, topo + lado * 1.8, ponta, espiga, Color(0.98, 0.84, 0.35))
		_tri(st, topo - dir * 0.03, ponta, topo + dir * 0.03, ponta, espiga, Color(0.98, 0.84, 0.35))
	return st.commit()


func _malha_milho() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verde := Color(0.2, 0.45, 0.14)
	var claro := Color(0.45, 0.7, 0.25)
	for k in 2:   # caule em cruz
		var d := Vector3(cos(k * PI / 2.0), 0.0, sin(k * PI / 2.0)) * 0.035
		_tri(st, -d, verde, d, verde, Vector3(0.0, 1.7, 0.0), claro)
	for k in 6:   # folhas longas que pendem para fora
		var a := k * TAU / 6.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		var lado := Vector3(-dir.z, 0.0, dir.x) * 0.07
		var h := 0.55 + (k % 3) * 0.35
		_tri(st, Vector3(0.0, h, 0.0) - lado, verde, Vector3(0.0, h, 0.0) + lado, verde, dir * 0.6 + Vector3(0.0, h - 0.12, 0.0), claro)
	for k in 2:   # espigas de milho amarelas presas ao caule
		var a := k * PI + 0.6
		var dir := Vector3(cos(a), 0.0, sin(a))
		var lado := Vector3(-dir.z, 0.0, dir.x) * 0.06
		var o := dir * 0.1 + Vector3(0.0, 0.95 + k * 0.15, 0.0)
		_tri(st, o - lado, Color(0.85, 0.7, 0.2), o + lado, Color(0.85, 0.7, 0.2), o + dir * 0.12 + Vector3(0.0, 0.3, 0.0), Color(0.95, 0.85, 0.35))
	return st.commit()


func _malha_verdura() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 9:   # rosetas de folhas largas (alface, cenoura)
		var a := k * TAU / 9.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		var lado := Vector3(-dir.z, 0.0, dir.x) * 0.09
		var tom := Color(0.25 + (k % 3) * 0.08, 0.6 + (k % 2) * 0.1, 0.22)
		_tri(st, -lado * 0.3, tom * 0.7, lado * 0.3, tom * 0.7, dir * 0.32 + Vector3(0.0, 0.28 + (k % 3) * 0.05, 0.0), tom)
		_tri(st, -lado * 0.3, tom * 0.7, lado * 0.3, tom * 0.7, dir * 0.2 + Vector3(0.0, 0.34, 0.0), tom)
	return st.commit()


func _material_vento(forca: float, tinta := Color(1, 1, 1)) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform float forca = 0.08;
uniform vec3 tinta = vec3(1.0);
global uniform float vento_forca;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float t = TIME * 1.7 + w.x * 0.55 + w.z * 0.35;
	VERTEX.x += sin(t) * forca * vento_forca * h;
	VERTEX.z += cos(t * 0.8) * forca * 0.6 * vento_forca * h;
}
void fragment() {
	ALBEDO = COLOR.rgb * tinta;
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("forca", forca)
	m.set_shader_parameter("tinta", Vector3(tinta.r, tinta.g, tinta.b))
	return m


func _espalhar(malha: Mesh, mat: Material, transf: Array[Transform3D], nome: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha
	mm.instance_count = transf.size()
	for i in transf.size():
		mm.set_instance_transform(i, transf[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	inst.material_override = mat
	inst.visibility_range_end = 160.0
	inst.visibility_range_end_margin = 20.0
	add_child(inst)


## Divide o campo em talhões lado a lado (trilha de 1 m entre eles), cada um com um cultivo só e bem denso, como numa
## fazenda de verdade: trigo maduro (dourado), trigo novo (verde), milho alto, repolho, verduras, abóboras e terra em pousio.
func _fileiras() -> void:
	var n := maxi(1, int(round(largura / 7.0)))
	var larg_t := (largura - (n - 1) * 1.0 - 1.0) / n
	var ordem := ["trigo", "milho", "trigo", "repolho", "trigo_novo", "verdura", "pousio", "abobora", "trigo", "milho"]
	var grupos: Dictionary = {}
	var primeiro := _rng.randi() % ordem.size()
	for i in n:
		var tipo: String = ordem[(primeiro + i) % ordem.size()]
		var x0 := -largura / 2.0 + 0.5 + i * (larg_t + 1.0)
		_terra_do_talhao(x0, larg_t, tipo != "trigo" and tipo != "trigo_novo" and tipo != "milho")
		var passo: float = {"trigo": 0.16, "trigo_novo": 0.16, "milho": 0.5, "repolho": 0.62, "verdura": 0.34, "abobora": 1.15, "pousio": 99.0}[tipo]
		if not grupos.has(tipo):
			grupos[tipo] = []
		var lista: Array = grupos[tipo]
		var z := -profundidade / 2.0 + 1.0
		var fila := 0
		while z < profundidade / 2.0 - 0.9:
			var x := x0 + 0.3
			while x < x0 + larg_t - 0.25:
				var p := Vector3(x + _rng.randf_range(-0.07, 0.07), 0.14, z + _rng.randf_range(-0.07, 0.07))
				var giro := Basis(Vector3.UP, _rng.randf() * TAU)
				var esc := _rng.randf_range(0.85, 1.25)
				match tipo:
					"trigo", "trigo_novo":
						lista.append(Transform3D(giro.scaled(Vector3(esc, esc * _rng.randf_range(0.9, 1.25), esc)), p))
					"milho":
						lista.append(Transform3D(giro.scaled(Vector3(esc, esc * _rng.randf_range(0.85, 1.15), esc)), p))
					"verdura":
						lista.append(Transform3D(giro.scaled(Vector3(esc, esc, esc)), p))
					"repolho":
						lista.append(Transform3D(Basis().scaled(Vector3(esc, esc * 0.8, esc)), p + Vector3(0, 0.2, 0)))
					"abobora":
						lista.append(Transform3D(giro.scaled(Vector3(esc * 1.2, esc, esc * 1.2)), p + Vector3(0, 0.22, 0)))
				x += passo if tipo != "trigo" and tipo != "trigo_novo" else passo
			z += 0.9 if tipo in ["repolho", "verdura", "abobora", "pousio"] else (0.16 if tipo.begins_with("trigo") else 0.5)
			fila += 1
	for tipo in grupos:
		var lista: Array[Transform3D] = []
		lista.assign(grupos[tipo])
		match tipo:
			"trigo":
				_espalhar(_malha_trigo(), _material_vento(0.09), lista, "TrigoMaduro")
			"trigo_novo":
				_espalhar(_malha_trigo(), _material_vento(0.09, Color(0.55, 0.78, 0.38)), lista, "TrigoNovo")
			"milho":
				_espalhar(_malha_milho(), _material_vento(0.07), lista, "Milho")
			"verdura":
				_espalhar(_malha_verdura(), _material_vento(0.05), lista, "Verduras")
			"repolho":
				var cabeca := SphereMesh.new()
				cabeca.radius = 0.26
				cabeca.height = 0.52
				cabeca.radial_segments = 8
				cabeca.rings = 4
				cabeca.material = _mat(Color(0.28, 0.48, 0.2))
				_espalhar(cabeca, null, lista, "Repolhos")
				var disco := CylinderMesh.new()   # folhas externas, mais escuras, abertas em volta da cabeça
				disco.top_radius = 0.42
				disco.bottom_radius = 0.46
				disco.height = 0.05
				disco.radial_segments = 8
				disco.material = _mat(Color(0.14, 0.3, 0.11))
				var folhas: Array[Transform3D] = []
				for t in lista:
					folhas.append(Transform3D(t.basis, t.origin - Vector3(0, 0.12, 0)))
				_espalhar(disco, null, folhas, "FolhasDoRepolho")
			"abobora":
				var fruto := SphereMesh.new()
				fruto.radius = 0.3
				fruto.height = 0.5
				fruto.radial_segments = 8
				fruto.rings = 4
				fruto.material = _mat(Color(0.7, 0.3, 0.06))
				_espalhar(fruto, null, lista, "Aboboras")


# ---------------------------------------------------------------- vida em volta

func _espantalho(pos: Vector3) -> void:
	var p := Node3D.new()
	p.name = "Espantalho"
	p.position = Vector3(pos.x, 0.0, -profundidade / 2.0 - 0.8)
	add_child(p)
	var madeira := _mat(Color(0.32, 0.22, 0.12))
	for it in [[Vector3(0, 1.0, 0), Vector3(0.1, 2.0, 0.1), madeira], [Vector3(0, 1.55, 0), Vector3(1.5, 0.1, 0.1), madeira],
			[Vector3(0, 1.3, 0), Vector3(0.5, 0.7, 0.3), _mat(Color(0.5, 0.2, 0.15))]]:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = it[1]
		b.material = it[2]
		mi.mesh = b
		mi.position = it[0]
		p.add_child(mi)
	var cabeca := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.2
	s.height = 0.4
	s.material = _mat(Color(0.85, 0.72, 0.4))
	cabeca.mesh = s
	cabeca.position = Vector3(0, 1.95, 0)
	p.add_child(cabeca)
	var chapeu := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.05
	c.bottom_radius = 0.34
	c.height = 0.3
	c.material = _mat(Color(0.35, 0.25, 0.12))
	chapeu.mesh = c
	chapeu.position = Vector3(0, 2.2, 0)
	p.add_child(chapeu)
	var cs := CollisionShape3D.new()
	var f := CylinderShape3D.new()
	f.radius = 0.3
	f.height = 2.2
	cs.shape = f
	cs.position.y = 1.1
	var corpo := StaticBody3D.new()
	corpo.add_child(cs)
	p.add_child(corpo)


func _fardos() -> void:
	var feno := _mat(Color(0.6, 0.46, 0.17))
	for k in 3:
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.55
		c.bottom_radius = 0.55
		c.height = 0.9
		c.material = feno
		mi.mesh = c
		mi.rotation_degrees.x = 90.0
		mi.position = Vector3(largura / 2.0 + 1.4, 0.55 + (0.9 if k == 2 else 0.0), -1.2 + (k % 2) * 1.0)
		add_child(mi)
	var cs := CollisionShape3D.new()
	var f := BoxShape3D.new()
	f.size = Vector3(1.2, 1.8, 2.4)
	cs.shape = f
	cs.position = Vector3(largura / 2.0 + 1.4, 0.9, -0.7)
	var corpo := StaticBody3D.new()
	corpo.add_child(cs)
	add_child(corpo)


func _bebedouro() -> void:
	var tronco := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.8, 0.5, 0.7)
	b.material = _mat(Color(0.3, 0.2, 0.11))
	tronco.mesh = b
	tronco.position = Vector3(-largura / 2.0 - 1.6, 0.25, 1.0)
	add_child(tronco)
	var agua := MeshInstance3D.new()
	var a := BoxMesh.new()
	a.size = Vector3(1.5, 0.04, 0.45)
	var m := _mat(Color(0.12, 0.3, 0.5, 0.85))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	a.material = m
	agua.mesh = a
	agua.position = Vector3(-largura / 2.0 - 1.6, 0.48, 1.0)
	add_child(agua)
	var cs := CollisionShape3D.new()
	var f := BoxShape3D.new()
	f.size = Vector3(1.8, 0.5, 0.7)
	cs.shape = f
	cs.position = Vector3(-largura / 2.0 - 1.6, 0.25, 1.0)
	var corpo := StaticBody3D.new()
	corpo.add_child(cs)
	add_child(corpo)
