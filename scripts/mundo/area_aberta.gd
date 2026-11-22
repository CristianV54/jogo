class_name AreaAberta
extends AreaBase
## Base das áreas grandes ao ar livre dos capítulos III em diante: terreno gerado, corpo sólido da área, paredes
## invisíveis na borda e os ajudantes de cenário (rocha, placa, tenda, muralha, torre, bandeira) e de gente (NPC, inimigo).

var terreno: Terreno
var tam := 300.0
var _rng := RandomNumberGenerator.new()
var _solidos: StaticBody3D


func altura_em(x: float, z: float) -> float:
	return terreno.altura_em(x, z)


func _y(p: Vector2) -> float:
	return altura_em(p.x, p.y)


func _montar_terreno(semente: int, amplitude: float, planos: Array[Vector3], caminho: PackedVector2Array, cor_grama: Color, cor_mata: Color) -> void:
	terreno = Terreno.new()
	terreno.name = "Terreno"
	terreno.tamanho = tam
	terreno.semente = semente
	terreno.amplitude = amplitude
	terreno.clareira_raio = 1.0
	terreno.cor_grama = cor_grama
	terreno.cor_mata = cor_mata
	terreno.cor_terra = Color(0.36, 0.3, 0.22)
	terreno.cor_pedra = Color(0.4, 0.4, 0.4)
	terreno.planos = planos
	terreno.caminhos = [caminho]
	add_child(terreno)
	terreno.gerar()
	_solidos = StaticBody3D.new()
	_solidos.name = "SolidosDaArea"
	add_child(_solidos)
	VilaRefugio.preparar(self, altura_em, _solidos)
	var meio := tam / 2.0
	for lado in [[Vector3(0, 8, -meio), Vector3(tam, 16, 2)], [Vector3(0, 8, meio), Vector3(tam, 16, 2)], [Vector3(-meio, 8, 0), Vector3(2, 16, tam)], [Vector3(meio, 8, 0), Vector3(2, 16, tam)]]:
		var cs := CollisionShape3D.new()   # paredes invisíveis na borda do mapa
		var caixa := BoxShape3D.new()
		caixa.size = lado[1]
		cs.shape = caixa
		cs.position = lado[0]
		_solidos.add_child(cs)


## Pinheiros em MultiMesh com colisão nos primeiros troncos; `livre(x, z)` diz onde NÃO nasce árvore.
func _floresta(tentativas: int, livre: Callable) -> void:
	var pinheiros: Array[Transform3D] = []
	var colisoes := 0
	for k in tentativas:
		var x := _rng.randf_range(-tam / 2.0 * 0.97, tam / 2.0 * 0.97)
		var z := _rng.randf_range(-tam / 2.0 * 0.97, tam / 2.0 * 0.97)
		if livre.call(x, z) or terreno.distancia_caminho(x, z) < 4.0 or terreno.normal_em(x, z).y < 0.72:
			continue
		var s := _rng.randf_range(0.8, 1.6)
		var h := altura_em(x, z)
		pinheiros.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s)), Vector3(x, h - 0.15, z)))
		if colisoes < 350:
			colisoes += 1
			var cs := CollisionShape3D.new()
			var cil := CylinderShape3D.new()
			cil.radius = 0.45 * s
			cil.height = 4.0
			cs.shape = cil
			cs.position = Vector3(x, h + 2.0, z)
			_solidos.add_child(cs)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = FabricaNatureza.pinheiro()
	mm.instance_count = pinheiros.size()
	for i in pinheiros.size():
		mm.set_instance_transform(i, pinheiros[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "Pinheiros"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)


# ---------------------------------------------------------------- cenário

func _rocha(pos: Vector2, escala: float, colidir := true, semente := 1.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = FabricaNatureza.pedra(semente)
	mi.material_override = FabricaNatureza.material()
	mi.scale = Vector3(escala, escala * 1.1, escala)
	mi.position = Vector3(pos.x, _y(pos) - 0.2, pos.y)
	mi.rotation.y = _rng.randf() * TAU
	add_child(mi)
	if colidir:
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = escala * 0.55
		cil.height = escala * 1.6
		cs.shape = cil
		cs.position = Vector3(pos.x, _y(pos) + escala * 0.6, pos.y)
		_solidos.add_child(cs)


func _placa_em_poste(pos: Vector2, texto: String) -> void:
	var y := _y(pos)
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	VilaRefugio._caixa(Vector3(pos.x, y + 1.3, pos.y), Vector3(0.18, 2.6, 0.18), madeira, true)
	VilaRefugio._caixa(Vector3(pos.x, y + 2.2, pos.y + 0.12), Vector3(2.6, 0.5, 0.06), madeira)
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.font_size = 44
	rotulo.pixel_size = 0.0048
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.position = Vector3(pos.x, y + 2.2, pos.y + 0.17)
	add_child(rotulo)


func _tenda(pos: Vector2, giro: float, cor: Color) -> void:
	var y := _y(pos)
	VilaRefugio._telhado(Vector3(pos.x, y + 1.2, pos.y), Vector3(3.6, 2.4, 3.8), VilaRefugio._mat(cor), giro)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.2, 2.2, 3.4)
	cs.shape = caixa
	cs.transform = Transform3D(Basis(Vector3.UP, giro), Vector3(pos.x, y + 1.1, pos.y))
	_solidos.add_child(cs)
	var frente := Vector3(sin(giro), 0.0, cos(giro)) * 1.9
	VilaRefugio._caixa(Vector3(pos.x + frente.x, y + 0.8, pos.y + frente.z), Vector3(0.9, 1.4, 0.06), VilaRefugio._mat(Color(0.08, 0.06, 0.05)), false, giro)


func _bandeira(pos: Vector2, cor := Color(0.65, 0.1, 0.08)) -> void:
	var y := _y(pos)
	VilaRefugio._caixa(Vector3(pos.x, y + 2.0, pos.y), Vector3(0.1, 4.0, 0.1), VilaRefugio._mat(Color(0.2, 0.15, 0.1)), true)
	VilaRefugio._caixa(Vector3(pos.x + 0.55, y + 3.3, pos.y), Vector3(1.0, 1.2, 0.04), VilaRefugio._mat(Color(0.08, 0.07, 0.09)))
	VilaRefugio._caixa(Vector3(pos.x + 0.55, y + 3.3, pos.y + 0.03), Vector3(0.4, 0.4, 0.02), VilaRefugio._mat(cor))


func _fogueira(pos: Vector2, escala := 0.9, luz := 12.0) -> void:
	var fogo := Fogo.new()
	fogo.escala = escala
	fogo.energia_luz = 2.0
	fogo.alcance_luz = luz
	fogo.position = Vector3(pos.x, _y(pos) + 0.15, pos.y)
	add_child(fogo)
	for i in 8:
		var a := TAU * i / 8.0
		_rocha(pos + Vector2(cos(a), sin(a)) * 1.2, 0.3, false, 2.0 + i)


## Trecho de muralha de pedra entre dois pontos (x, z), com ameias e colisão.
func _muralha(de: Vector2, para: Vector2, altura := 7.0, cor := Color(0.32, 0.32, 0.35)) -> void:
	var dir := para - de
	var meio := (de + para) / 2.0
	var giro := atan2(dir.x, dir.y)
	var y := minf(_y(de), _y(para))
	var pedra := VilaRefugio._mat(cor)
	VilaRefugio._caixa(Vector3(meio.x, y + altura / 2.0, meio.y), Vector3(1.6, altura, dir.length()), pedra, true, giro)
	var n := int(dir.length() / 3.0)
	for i in n:   # ameias
		var p := de + dir.normalized() * (1.5 + i * 3.0)
		VilaRefugio._caixa(Vector3(p.x, y + altura + 0.5, p.y), Vector3(1.7, 1.0, 1.4), pedra, false, giro)


## Torre de vigia quadrada com plataforma no topo; devolve a posição 3D do piso do topo.
func _torre_de_vigia(pos: Vector2, altura := 9.0) -> Vector3:
	var y := _y(pos)
	var pedra := VilaRefugio._mat(Color(0.3, 0.3, 0.33))
	VilaRefugio._caixa(Vector3(pos.x, y + altura / 2.0, pos.y), Vector3(5.0, altura, 5.0), pedra, true)
	VilaRefugio._caixa(Vector3(pos.x, y + altura + 0.1, pos.y), Vector3(6.0, 0.4, 6.0), VilaRefugio._mat(Color(0.34, 0.23, 0.13)), true)
	for dx in [-2.7, 2.7]:
		for dz in [-2.7, 2.7]:
			VilaRefugio._caixa(Vector3(pos.x + dx, y + altura + 1.0, pos.y + dz), Vector3(0.6, 1.6, 0.6), pedra)
	return Vector3(pos.x, y + altura + 0.3, pos.y)


# ---------------------------------------------------------------- gente

func _inimigo(caminho: String, pos: Vector3, nome_novo := "", especie_nova := "", drops_novos := {}) -> Inimigo:
	var ini := (load(caminho) as PackedScene).instantiate() as Inimigo
	if nome_novo != "":
		ini.nome = nome_novo
	if especie_nova != "":
		ini.especie = especie_nova
	if not drops_novos.is_empty():
		ini.drops = drops_novos
	ini.position = pos
	add_child(ini)
	return ini


func _npc(nome_npc: String, papel: String, cena: String, pos: Vector2, falas: PackedStringArray, rotina: Array, oferece := "") -> Npc:
	var n := Npc.new()
	n.nome = nome_npc
	n.papel = papel
	n.falas = falas
	n.cena = load(cena)
	n.oferece_missao = oferece
	for passo in rotina:   # as rotinas pedem pontos 3D; aqui escrevemos em (x, z)
		for chave in ["ir", "olhar"]:
			if passo.has(chave) and passo[chave] is Vector2:
				var v: Vector2 = passo[chave]
				passo[chave] = Vector3(v.x, _y(v), v.y)
	n.rotina = rotina
	n.altura_em = altura_em
	n.position = Vector3(pos.x, _y(pos), pos.y)
	add_child(n)
	npcs.append(n)
	return n
