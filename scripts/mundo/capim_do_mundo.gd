class_name CapimDoMundo
extends Node3D
## Capim e mato em todo o chão do mundo (dentro e fora das regiões), gerado em blocos de 40 m em volta do jogador e
## descartado quando ele se afasta. A cor segue o chão do lugar; a quantidade segue o bioma (denso nos campos do sul,
## ralo e seco rumo à fortaleza, quase nada na cratera). Não nasce em casas, estradas, trilhas nem na água.

const CELULA := 40.0
const RAIO_CELULAS := 2
const RAIO_DESCARTE := 4

var mundo: Mundo
var _blocos: Dictionary = {}   # Vector2i -> MultiMeshInstance3D
var _malha: ArrayMesh
var _mat: StandardMaterial3D
var _ruido := FastNoiseLite.new()
var _exclusoes: Array = []     # [Vector2 (x, z do mundo), raio]
var _t := 0.0
var _pronto := false


func _ready() -> void:
	name = "CapimDoMundo"
	_ruido.seed = 91
	_ruido.frequency = 0.012
	_malha = _fazer_malha()
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.roughness = 1.0


func iniciar() -> void:
	_exclusoes.clear()
	for no in mundo.find_children("*", "Node3D", true, false):
		var n3 := no as Node3D
		if n3.has_meta("colunas"):
			_exclusoes.append([Vector2(n3.global_position.x, n3.global_position.z), Vector2(n3.get_meta("colunas"), n3.get_meta("linhas")).length() + 1.8])
		elif n3.has_meta("raio_capim"):
			_exclusoes.append([Vector2(n3.global_position.x, n3.global_position.z), float(n3.get_meta("raio_capim"))])
	_pronto = true
	_t = 0.0


func _process(delta: float) -> void:
	if not _pronto:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.4
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog == null:
		return
	var c := Vector2i(int(floor(jog.global_position.x / CELULA)), int(floor(jog.global_position.z / CELULA)))
	var feitos := 0
	for r in range(0, RAIO_CELULAS + 1):   # de dentro para fora: o mais perto primeiro
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var k := Vector2i(c.x + dx, c.y + dz)
				if not _blocos.has(k) and feitos < 3:
					_blocos[k] = _construir(k)
					feitos += 1
	for k in _blocos.keys():
		if maxi(absi(k.x - c.x), absi(k.y - c.y)) > RAIO_DESCARTE:
			if _blocos[k]:
				(_blocos[k] as Node).queue_free()
			_blocos.erase(k)


## Devolve o terreno que vale no ponto (o da região, em coordenadas locais, ou o chão do mundo) e o ponto nele.
func _terreno_em(p: Vector2) -> Array:
	for id in MundoDados.REGIOES:
		var c := MundoDados.centro(id)
		if MundoDados.retangulo(id, -1.0).has_point(p):
			var area: Node3D = mundo.regioes.get(id)
			if area and area.get("terreno") is Terreno:
				return [area.get("terreno"), p - c]
			return [null, p]
	return [mundo.terreno, p]


func _densidade(x: float, z: float) -> float:
	var d := lerpf(0.95, 0.5, smoothstep(-450.0, -800.0, z))
	d = lerpf(d, 0.22, smoothstep(-800.0, -1000.0, z))
	d = lerpf(d, 0.07, smoothstep(-1050.0, -1250.0, z))
	d = lerpf(d, 0.4, smoothstep(-1550.0, -1750.0, z))
	d = lerpf(d, 0.95, smoothstep(-1900.0, -2050.0, z))
	return d * (0.55 + 0.9 * (_ruido.get_noise_2d(x, z) * 0.5 + 0.5))


func _construir(k: Vector2i) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = k.x * 73856093 ^ k.y * 19349663
	var x0 := k.x * CELULA
	var z0 := k.y * CELULA
	var lim := MundoDados.LIMITES
	if x0 + CELULA < lim.position.x or x0 > lim.end.x or z0 + CELULA < lim.position.y or z0 > lim.end.y:
		return null
	var dens := _densidade(x0 + CELULA / 2.0, z0 + CELULA / 2.0)
	var n := int(CELULA * CELULA * dens * 0.55)
	var t: Array[Transform3D] = []
	var cores: Array[Color] = []
	for i in n:
		var p := Vector2(x0 + rng.randf() * CELULA, z0 + rng.randf() * CELULA)
		if not lim.has_point(p):
			continue
		var bom := true
		for e in _exclusoes:
			if p.distance_squared_to(e[0]) < e[1] * e[1]:
				bom = false
				break
		if not bom:
			continue
		var par := _terreno_em(p)
		var ter: Terreno = par[0]
		if ter == null:
			continue
		var q: Vector2 = par[1]
		if ter.distancia_caminho(q.x, q.y) < 2.4 or ter.na_agua(q.x, q.y, 1.6) or Costa.distancia(p.x, p.y) < 7.0:
			continue
		if MundoDados.ate_a_muralha(p.x, p.y) < 1.0:
			continue   # dentro da muralha do reino o chão é calçado de pedra: não cresce capim
		if p.y < -2000.0 and (p.distance_to(MundoDados.LAGO_CONGELADO) < MundoDados.LAGO_RAIO + 4.0 or Biomas.em(p.x, p.y) == "gelo"):
			continue   # nas Terras do Gelo o chão é neve e o lago é gelo: sem capim
		var y := mundo.chao_em(p.x, p.y)   # altura no MUNDO (o Castelo fica no alto: a altura de dentro da região não serve aqui)
		var s := rng.randf_range(0.5, 1.1)   # moita de 15 a 55 cm: bem abaixo do joelho do Torin
		var base := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.5), s))
		t.append(Transform3D(base, Vector3(p.x, y - 0.02, p.y)))
		var c := ter.cor_em(q.x, q.y)
		cores.append(Color(c.r * 1.25, c.g * 1.32, c.b * 1.0).lightened(rng.randf_range(-0.05, 0.12)))
	if t.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _malha
	mm.instance_count = t.size()
	for i in t.size():
		mm.set_instance_transform(i, t[i])
		mm.set_instance_color(i, cores[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "Capim_%d_%d" % [k.x, k.y]
	inst.multimesh = mm
	inst.material_override = _mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.visibility_range_end = 120.0
	inst.visibility_range_end_margin = 25.0
	inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(inst)
	return inst


## Moita de 12 folhas finas e curvas (base escura, ponta clara).
func _fazer_malha() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 12:
		var ang := TAU * i / 12.0 + rng.randf() * 0.4
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var base := dir * rng.randf_range(0.02, 0.14)
		var lado := Vector3(-dir.z, 0.0, dir.x) * 0.04
		var h := rng.randf_range(0.28, 0.5)
		var meio := base + dir * rng.randf_range(0.02, 0.06) + Vector3(0.0, h * 0.55, 0.0)
		var ponta := base + dir * rng.randf_range(0.08, 0.2) + Vector3(0.0, h, 0.0)
		st.set_color(Color(0.55, 0.62, 0.45))
		st.add_vertex(base - lado)
		st.add_vertex(base + lado)
		st.set_color(Color(0.78, 0.84, 0.55))
		st.add_vertex(meio - lado * 0.5)
		st.add_vertex(base + lado)
		st.add_vertex(meio + lado * 0.5)
		st.add_vertex(meio - lado * 0.5)
		st.set_color(Color(0.95, 0.98, 0.65))
		st.add_vertex(meio - lado * 0.5)
		st.add_vertex(meio + lado * 0.5)
		st.add_vertex(ponta)
	st.generate_normals()
	return st.commit()
