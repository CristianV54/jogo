class_name TerrenoMundo
extends Terreno
## Chão do mundo contínuo: uma grade (passo de 4 m, em blocos de 256 m) entre as áreas, com colinas suaves longe delas, estradas de terra,
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


## O chão é feito em BLOCOS de 256 m (o motor só desenha os que estão na tela), o mar fundo não ganha bloco, e o resultado
## fica guardado em disco (user://): só a primeira vez depois de uma mudança no mapa é que o chão é calculado de novo.
const LADO_DO_BLOCO := 64   # células por bloco (64 x 4 m = 256 m)
const MAR_SEM_CHAO := -120.0   # distância da costa (mar adentro) a partir da qual não há chão: só o oceano


func gerar() -> void:
	var blocos := _ler_cache()
	if blocos.is_empty():
		blocos = _blocos()
		_gravar_cache(blocos)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	corpo = StaticBody3D.new()
	corpo.name = "Colisao"
	add_child(corpo)
	for b in blocos:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = b[0]
		arrays[Mesh.ARRAY_NORMAL] = b[1]
		arrays[Mesh.ARRAY_COLOR] = b[2]
		arrays[Mesh.ARRAY_INDEX] = b[3]
		var malha := ArrayMesh.new()
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = "Superficie"
		mi.mesh = malha
		mi.material_override = mat
		add_child(mi, true)
		var cs := CollisionShape3D.new()
		cs.shape = malha.create_trimesh_shape()
		corpo.add_child(cs)
	print("TerrenoMundo: ", blocos.size(), " blocos de chão")
	for r in rios:
		for trecho in _trechos_fora_das_areas(r["pontos"]):
			var copia: Dictionary = r.duplicate()
			copia["pontos"] = trecho
			add_child(_agua(copia))


## Nome do arquivo de cache: muda sempre que muda algo de que o chão depende (planta do mundo, regras de altura e de cor).
func _arquivo_de_cache() -> String:
	var texto := str(limites, passo, semente, retangulos, planos, estradas_mundo.size(), Costa.protegidos)
	for arq in ["res://scripts/mundo/mundo_dados.gd", "res://scripts/mundo/terreno_mundo.gd", "res://scripts/mundo/terreno.gd", "res://scripts/mundo/costa.gd", "res://scripts/mundo/biomas.gd"]:
		texto += FileAccess.get_file_as_string(arq)
	return "user://chao_do_mundo_%s.bin" % texto.md5_text().left(12)


func _ler_cache() -> Array:
	var caminho := _arquivo_de_cache()
	if not FileAccess.file_exists(caminho):
		return []
	var f := FileAccess.open_compressed(caminho, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return []
	var dados: Variant = f.get_var()
	return dados if dados is Array else []


func _gravar_cache(blocos: Array) -> void:
	for velho in DirAccess.get_files_at("user://"):   # um cache só: o do mapa atual
		if velho.begins_with("chao_do_mundo_"):
			DirAccess.remove_absolute("user://" + velho)
	var f := FileAccess.open_compressed(_arquivo_de_cache(), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f:
		f.store_var(blocos)


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
	amp *= smoothstep(-30.0, 160.0, Vector2(x, z).distance_to(MundoDados.REINO["centro"]) - float(MundoDados.REINO["raio"]))   # o reino fica numa planície: cidade não se ergue em ladeira
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
		var h_eixo := (_ruido_mundo.get_noise_2d(eixo.x, eixo.y) * 0.5 + 0.5) * 10.0 * smoothstep(30.0, 220.0, _distancia_a_area(eixo)) * smoothstep(-30.0, 160.0, eixo.distance_to(MundoDados.REINO["centro"]) - float(MundoDados.REINO["raio"]))
		h = lerpf(h, h_eixo, 1.0 - smoothstep(2.5, 7.0, melhor))
	for id in MundoDados.REGIOES:   # rochedo do Castelo: o chão sobe até a altura da região (encosta de pedra em volta, a cidade embaixo)
		var alto := MundoDados.altura(id)
		if alto > 0.0:
			var rr := MundoDados.retangulo(id)
			var fora := Vector2(maxf(maxf(rr.position.x - x, x - rr.end.x), 0.0), maxf(maxf(rr.position.y - z, z - rr.end.y), 0.0)).length()
			h += alto * smoothstep(55.0, 0.0, fora)   # rochedo: 30 m de subida em 55 m
	var costa := Costa.distancia(x, z)
	if costa < 70.0:   # a terra se achata até a praia (0,6 m), desce para um raso onde dá para andar (água pela canela) e, 30 m mar adentro, afunda
		h = lerpf(h, 0.6, smoothstep(70.0, 30.0, costa))
		h = lerpf(h, Costa.NIVEL_MAR - Costa.FUNDO_RASO, smoothstep(14.0, 0.0, costa))
		h = lerpf(h, Costa.NIVEL_MAR - 6.0, smoothstep(-Costa.LARGURA_RASO, -Costa.LARGURA_RASO - 30.0, costa))
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
	var c := Biomas.cor_do_chao(x, z, _ruido_fino.get_noise_2d(x * 1.7, z * 1.7) * 0.5 + 0.5)
	var ao_reino := Vector2(x, z).distance_to(MundoDados.REINO["centro"]) - float(MundoDados.REINO["raio"])
	return c.lerp(Color(0.42, 0.38, 0.31), 0.6 * smoothstep(8.0, -12.0, ao_reino))   # dentro da muralha o chão é de cidade (terra batida e pedra), inclusive na beirada das regiões


func _cor_vertice(x: float, z: float, n: Vector3) -> Color:
	var c := cor_do_mundo(x, z)
	var costa := Costa.distancia(x, z)
	if costa < 24.0:   # praia de areia, mais escura onde a água molha
		c = c.lerp(Color(0.84, 0.76, 0.56).lerp(Color(0.6, 0.52, 0.38), smoothstep(12.0, 2.0, costa)), smoothstep(24.0, 14.0, costa))
	c = c.lerp(Color(0.42, 0.42, 0.4), smoothstep(0.2, 0.42, 1.0 - n.y))
	c = c.lerp(Color(0.1, 0.24, 0.34), smoothstep(-Costa.LARGURA_RASO, -Costa.LARGURA_RASO - 25.0, costa))   # fundo do mar: azul escuro, igual ao oceano de longe
	var dc := distancia_caminho(x, z)
	if Vector2(x, z).distance_to(MundoDados.REINO["centro"]) < float(MundoDados.REINO["raio"]):
		c = c.lerp(Color(0.56, 0.53, 0.47), 1.0 - smoothstep(3.2, 6.5, dc))   # rua de cidade: calçada de pedra clara, mais larga que estrada de terra
	else:
		c = c.lerp(Color(0.45, 0.34, 0.22), 1.0 - smoothstep(1.6, 4.2, dc))
	var dr := distancia_rio(x, z)
	if dr < 3.5:
		c = c.lerp(Color(0.34, 0.29, 0.2), 1.0 - smoothstep(0.0, 3.5, dr))
	return c


## Calcula o chão: devolve um Array de blocos [vértices, normais, cores, índices].
func _blocos() -> Array:
	var nx := int(limites.size.x / passo)
	var nz := int(limites.size.y / passo)
	var lx := nx + 1
	var lz := nz + 1
	var fundo := Costa.NIVEL_MAR - 6.0
	var alturas := PackedFloat32Array()
	alturas.resize(lx * lz)
	var costas := PackedFloat32Array()   # distância da costa em cada vértice (usada 3 vezes: calcula uma)
	costas.resize(lx * lz)
	for i in lx:
		for j in lz:
			var x := limites.position.x + i * passo
			var z := limites.position.y + j * passo
			var c := Costa.distancia(x, z)
			costas[i * lz + j] = c
			alturas[i * lz + j] = fundo if c < MAR_SEM_CHAO else altura_em(x, z)
	var blocos: Array = []
	var bi := 0
	while bi < nx:
		var bj := 0
		while bj < nz:
			var i_fim := mini(bi + LADO_DO_BLOCO, nx)
			var j_fim := mini(bj + LADO_DO_BLOCO, nz)
			var tem_terra := false
			for i in range(bi, i_fim + 1, 8):
				for j in range(bj, j_fim + 1, 8):
					if costas[i * lz + j] > MAR_SEM_CHAO:
						tem_terra = true
			if tem_terra:
				var b := _bloco(bi, bj, i_fim, j_fim, nx, nz, lz, alturas)
				if not (b[3] as PackedInt32Array).is_empty():
					blocos.append(b)
			bj += LADO_DO_BLOCO
		bi += LADO_DO_BLOCO
	return blocos


func _bloco(bi: int, bj: int, i_fim: int, j_fim: int, nx: int, nz: int, lz: int, alturas: PackedFloat32Array) -> Array:
	var li := i_fim - bi + 1
	var lj := j_fim - bj + 1
	var vertices := PackedVector3Array()
	var normais := PackedVector3Array()
	var cores := PackedColorArray()
	vertices.resize(li * lj)
	normais.resize(li * lj)
	cores.resize(li * lj)
	for a in li:
		for b in lj:
			var i := bi + a
			var j := bj + b
			var x := limites.position.x + i * passo
			var z := limites.position.y + j * passo
			var i0 := maxi(i - 1, 0)
			var i1 := mini(i + 1, nx)
			var j0 := maxi(j - 1, 0)
			var j1 := mini(j + 1, nz)
			var dx := (alturas[i1 * lz + j] - alturas[i0 * lz + j]) / ((i1 - i0) * passo)
			var dz := (alturas[i * lz + j1] - alturas[i * lz + j0]) / ((j1 - j0) * passo)
			var normal := Vector3(-dx, 1.0, -dz).normalized()
			var k := a * lj + b
			# A parte da célula que cai DENTRO da área fica logo abaixo do chão dela. O vértice que cai exatamente na borda não desce:
			# descendo, o chão do mundo chegava 0,2 m abaixo do chão da área e a beirada virava um degrau que travava o Torin
			# (lados oeste e norte de cada região; a trava de x=-160 na entrada do Refúgio vinda do Pomar).
			vertices[k] = Vector3(x, alturas[i * lz + j] - (0.2 if _dentro_de_area(Vector2(x, z), -0.01) else 0.0), z)
			normais[k] = normal
			cores[k] = _cor_vertice(x, z, normal).srgb_to_linear()
	var indices := PackedInt32Array()
	for a in li - 1:
		for b in lj - 1:
			var celula := Rect2(limites.position.x + (bi + a) * passo, limites.position.y + (bj + b) * passo, passo, passo)
			if _celula_dentro_de_area(celula):
				continue   # o chão desta célula é o da área (só some a célula inteira: célula cortada ao meio abria uma fresta no chão)
			var p00 := a * lj + b
			var p10 := (a + 1) * lj + b
			var p01 := a * lj + b + 1
			var p11 := (a + 1) * lj + b + 1
			indices.append_array([p00, p10, p01, p10, p11, p01])
	return [vertices, normais, cores, indices]
