class_name TerrenoMundo
extends Terreno
## Chão do mundo contínuo: uma grade grande (passo de 8 m) entre as áreas, com colinas suaves longe delas, estradas de terra,
## rios escavados com água viva e a cor mudando de região em região. Onde há uma área o chão não é desenhado (a área
## tem o seu terreno, que na borda se mistura com este). Reaproveita os rios do `Terreno`.

var limites := Rect2()
var retangulos: Array[Rect2] = []   # áreas (sem chão aqui)
var estradas_mundo: Array[PackedVector2Array] = []
var _ruido_mundo := FastNoiseLite.new()
var _caixas_estradas: Array[Rect2] = []


## Liga os ruídos e as caixas de busca. Precisa rodar antes das áreas pedirem alturas emprestadas a este chão.
func preparar() -> void:
	_ruido.seed = semente
	_ruido.frequency = frequencia
	_ruido.fractal_octaves = 4
	_ruido_fino.seed = semente + 1
	_ruido_fino.frequency = frequencia * 7.0
	_ruido_mundo.seed = semente + 7
	_ruido_mundo.frequency = 0.0035
	_ruido_mundo.fractal_octaves = 3
	caminhos = estradas_mundo
	_caixas_estradas.clear()
	for c in estradas_mundo:
		var menor: Vector2 = c[0]
		var maior: Vector2 = c[0]
		for p in c:
			menor = menor.min(p)
			maior = maior.max(p)
		_caixas_estradas.append(Rect2(menor - Vector2(10, 10), maior - menor + Vector2(20, 20)))
	_preparar_rios()


func gerar() -> void:
	var malha := _malha()
	var mi := MeshInstance3D.new()
	mi.name = "Superficie"
	mi.mesh = malha
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)
	corpo = StaticBody3D.new()
	corpo.name = "Colisao"
	var cs := CollisionShape3D.new()
	cs.shape = malha.create_trimesh_shape()
	corpo.add_child(cs)
	add_child(corpo)
	for r in rios:
		for trecho in _trechos_fora_das_areas(r["pontos"]):
			var copia: Dictionary = r.duplicate()
			copia["pontos"] = trecho
			add_child(_agua(copia))


## Uma ponta de rio encontra água se está perto de outro rio, da borda de uma região (onde o rio da região continua) ou do mar.
func _ponta_encontra_agua(p: Vector2) -> bool:
	if Costa.distancia(p.x, p.y) < 14.0:
		return true
	for r in retangulos:
		var dx := maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
		var dz := maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
		if sqrt(dx * dx + dz * dz) < 8.0:
			return true
	for rio in rios:
		var pts: PackedVector2Array = rio["pontos"]
		if p == pts[0] or p == pts[pts.size() - 1]:
			pass
		var par := _eixo_mais_perto(p, pts)
		if float(par[0]) < 1.0 and not (p.distance_to(pts[0]) < 0.5 or p.distance_to(pts[pts.size() - 1]) < 0.5):
			return true   # o ponto está no meio de outro rio
		if float(par[0]) < 14.0 and (p.distance_to(pts[0]) > 0.5 and p.distance_to(pts[pts.size() - 1]) > 0.5):
			return true   # foz num rio maior
	return false


func _celula_dentro_de_area(c: Rect2) -> bool:
	for r in retangulos:
		if r.encloses(c):
			return true
	return false


func _dentro_de_area(p: Vector2, folga := 0.0) -> bool:
	for r in retangulos:
		if r.grow(folga).has_point(p):
			return true
	return false


## Parte o rio nos pedaços que ficam fora das áreas (dentro delas o rio é o da própria área).
func _trechos_fora_das_areas(pts: PackedVector2Array) -> Array:
	var saida: Array = []
	var atual := PackedVector2Array()
	for i in pts.size():
		var dentro := _dentro_de_area(pts[i], -3.0)
		if dentro:
			if atual.size() >= 2:
				saida.append(atual)
			atual = PackedVector2Array()
		else:
			atual.append(pts[i])
	if atual.size() >= 2:
		saida.append(atual)
	return saida


func _distancia_a_area(p: Vector2) -> float:
	var melhor := 1e9
	for r in retangulos:
		var dx := maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
		var dz := maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
		melhor = minf(melhor, sqrt(dx * dx + dz * dz))
	return melhor


## Colinas suaves: planas junto das áreas (para as bordas se encontrarem) e mais altas longe delas.
func _altura_crua(x: float, z: float) -> float:
	var d := _distancia_a_area(Vector2(x, z))
	var amp := smoothstep(30.0, 220.0, d)
	var colinas := (_ruido_mundo.get_noise_2d(x, z) * 0.5 + 0.5) * 10.0 + _ruido_fino.get_noise_2d(x * 0.6, z * 0.6) * 0.8
	var h := colinas * amp
	var melhor := 1e9   # as estradas ficam niveladas com o terreno em volta do eixo
	var eixo := Vector2.ZERO
	var p := Vector2(x, z)
	for k in estradas_mundo.size():
		if not _caixas_estradas[k].has_point(p):
			continue
		var par := _eixo_mais_perto(p, estradas_mundo[k])
		if float(par[0]) < melhor:
			melhor = par[0]
			eixo = par[1]
	if melhor < 7.0:
		var h_eixo := (_ruido_mundo.get_noise_2d(eixo.x, eixo.y) * 0.5 + 0.5) * 10.0 * smoothstep(30.0, 220.0, _distancia_a_area(eixo))
		h = lerpf(h, h_eixo, 1.0 - smoothstep(2.5, 7.0, melhor))
	var costa := Costa.distancia(x, z)
	if costa < 70.0:   # a terra vai se achatando até a praia (0,6 m) e só nos últimos 14 m desce para o mar: encosta suave, sem penhasco
		h = lerpf(h, 0.6, smoothstep(70.0, 30.0, costa))
		h = lerpf(h, -3.0, smoothstep(14.0, 0.0, costa))
	return h


func distancia_caminho(x: float, z: float) -> float:
	var melhor := 1e9
	var p := Vector2(x, z)
	for k in estradas_mundo.size():
		if _caixas_estradas[k].has_point(p):
			melhor = minf(melhor, float(_eixo_mais_perto(p, estradas_mundo[k])[0]))
	return melhor


## Cor do chão do mundo: capim nos campos, cinza e seco rumo à fortaleza, vulcânico perto da cratera, ocre perto de Valdoria.
func cor_do_mundo(x: float, z: float) -> Color:
	return Biomas.cor_do_chao(x, z, _ruido_fino.get_noise_2d(x * 1.7, z * 1.7) * 0.5 + 0.5)


func _cor_vertice(x: float, z: float, n: Vector3) -> Color:
	var c := cor_do_mundo(x, z)
	var costa := Costa.distancia(x, z)
	if costa < 24.0:   # praia de areia, mais escura onde a água molha
		c = c.lerp(Color(0.84, 0.76, 0.56).lerp(Color(0.6, 0.52, 0.38), smoothstep(12.0, 2.0, costa)), smoothstep(24.0, 14.0, costa))
	c = c.lerp(Color(0.42, 0.42, 0.4), smoothstep(0.2, 0.42, 1.0 - n.y))
	c = c.lerp(Color(0.45, 0.34, 0.22), 1.0 - smoothstep(1.6, 4.2, distancia_caminho(x, z)))
	var dr := distancia_rio(x, z)
	if dr < 3.5:
		c = c.lerp(Color(0.34, 0.29, 0.2), 1.0 - smoothstep(0.0, 3.5, dr))
	return c


func _malha() -> ArrayMesh:
	var nx := int(limites.size.x / passo)
	var nz := int(limites.size.y / passo)
	var lx := nx + 1
	var lz := nz + 1
	var alturas := PackedFloat32Array()
	alturas.resize(lx * lz)
	for i in lx:
		for j in lz:
			alturas[i * lz + j] = altura_em(limites.position.x + i * passo, limites.position.y + j * passo)
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var cores := PackedColorArray()
	vertices.resize(lx * lz)
	normais.resize(lx * lz)
	cores.resize(lx * lz)
	for i in lx:
		for j in lz:
			var x := limites.position.x + i * passo
			var z := limites.position.y + j * passo
			var i0 := maxi(i - 1, 0)
			var i1 := mini(i + 1, nx)
			var j0 := maxi(j - 1, 0)
			var j1 := mini(j + 1, nz)
			var dx := (alturas[i1 * lz + j] - alturas[i0 * lz + j]) / ((i1 - i0) * passo)
			var dz := (alturas[i * lz + j1] - alturas[i * lz + j0]) / ((j1 - j0) * passo)
			var normal := Vector3(-dx, 1.0, -dz).normalized()
			var k := i * lz + j
			vertices[k] = Vector3(x, alturas[k] - (0.2 if _dentro_de_area(Vector2(x, z)) else 0.0), z)   # a parte da célula que cai dentro da área fica logo abaixo do chão dela
			normais[k] = normal
			cores[k] = _cor_vertice(x, z, normal).srgb_to_linear()
	var indices := PackedInt32Array()
	for i in nx:
		for j in nz:
			var celula := Rect2(limites.position.x + i * passo, limites.position.y + j * passo, passo, passo)
			if _celula_dentro_de_area(celula):
				continue   # o chão desta célula é o da área (só some a célula inteira: célula cortada ao meio abria uma fresta no chão)
			var p00 := i * lz + j
			var p10 := (i + 1) * lz + j
			var p01 := i * lz + j + 1
			var p11 := (i + 1) * lz + j + 1
			indices.append_array([p00, p10, p01, p10, p11, p01])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normais
	arrays[Mesh.ARRAY_COLOR] = cores
	arrays[Mesh.ARRAY_INDEX] = indices
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha
