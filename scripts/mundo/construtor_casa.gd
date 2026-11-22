class_name ConstrutorCasa
extends RefCounted
## Monta uma casa a partir das peças modulares do Medieval Village MegaKit (CC0, Quaternius).
## Módulo = 2 m: paredes de 2 m de largura e 3,12 m de altura, pisos de 2x2 m.
## Planta: `colunas` módulos ao longo de X e `linhas` módulos ao longo de Z. A porta fica na fachada (+Z), no módulo do meio.
## A casa tem frontões fechados, janelas com esquadria e venezianas, porta aberta com batente, interior com luz e móveis,
## e colisão só nas paredes (com vão na porta): dá para entrar.

const PASTA := "res://assets/models/cenario/vila_mv/"
const MODULO := 2.0
const ALTURA_PAREDE := 3.12
const GIRO_FACHADA := 0.0
const ALTURA_TELHADO := 3.12
const ESPESSURA_COLISAO := 0.5
const LARGURA_VAO_PORTA := 1.7


static func peca(nome: String) -> Node3D:
	var cena: PackedScene = load(PASTA + nome + ".gltf")
	return cena.instantiate()


static func _colocar(pai: Node3D, nome: String, pos: Vector3, giro_graus: float) -> Node3D:
	var p := peca(nome)
	p.position = pos
	p.rotation_degrees.y = giro_graus
	pai.add_child(p)
	return p


static func _existe(nome: String) -> bool:
	return ResourceLoader.exists(PASTA + nome + ".gltf")


## estilo: {"parede", "porta", "janela", "piso", "canto", "telhado" (opcional)}
## interior: "moradia", "forja" ou "vazio"
static func montar(colunas: int, linhas: int, estilo: Dictionary, colisao := true, interior := "moradia") -> Node3D:
	var casa := Node3D.new()
	casa.name = "Casa"
	var meia_x := colunas * MODULO / 2.0
	var meia_z := linhas * MODULO / 2.0
	var i_porta := colunas / 2
	var x_porta := -meia_x + MODULO / 2.0 + i_porta * MODULO

	for i in colunas:
		for j in linhas:
			_colocar(casa, estilo["piso"], Vector3(-meia_x + MODULO / 2.0 + i * MODULO, 0.0, -meia_z + MODULO / 2.0 + j * MODULO), 0.0)

	# fachada (+Z) e fundos (-Z)
	for i in colunas:
		var x := -meia_x + MODULO / 2.0 + i * MODULO
		var eh_porta := i == i_porta
		var eh_janela_f := not eh_porta and i % 2 == 1
		var tipo_f: String = estilo["porta"] if eh_porta else (estilo["janela"] if eh_janela_f else estilo["parede"])
		_colocar(casa, tipo_f, Vector3(x, 0.0, meia_z), GIRO_FACHADA)
		var eh_janela_t := i % 2 == 1
		_colocar(casa, estilo["janela"] if eh_janela_t else estilo["parede"], Vector3(x, 0.0, -meia_z), GIRO_FACHADA + 180.0)
		if eh_porta:
			_porta(casa, Vector3(x, 0.0, meia_z))
		if eh_janela_f:
			_janela(casa, Vector3(x, 0.0, meia_z), GIRO_FACHADA)
		if eh_janela_t:
			_janela(casa, Vector3(x, 0.0, -meia_z), GIRO_FACHADA + 180.0)
	# laterais (±X)
	for j in linhas:
		var z := -meia_z + MODULO / 2.0 + j * MODULO
		var eh_janela := j % 2 == 1
		var tipo_l: String = estilo["janela"] if eh_janela else estilo["parede"]
		_colocar(casa, tipo_l, Vector3(meia_x, 0.0, z), GIRO_FACHADA + 90.0)
		_colocar(casa, tipo_l, Vector3(-meia_x, 0.0, z), GIRO_FACHADA - 90.0)
		if eh_janela:
			_janela(casa, Vector3(meia_x, 0.0, z), GIRO_FACHADA + 90.0)
			_janela(casa, Vector3(-meia_x, 0.0, z), GIRO_FACHADA - 90.0)

	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_colocar(casa, estilo["canto"], Vector3(sx * meia_x, 0.0, sz * meia_z), GIRO_FACHADA + (45.0 if sx * sz > 0 else -45.0))

	# telhado e frontões (a parede triangular sob a cumeeira, nas duas pontas)
	var nome_telhado: String = estilo.get("telhado", "Roof_RoundTiles_%dx%d" % [colunas * 2, linhas * 2])
	if _existe(nome_telhado):
		_colocar(casa, nome_telhado, Vector3(0.0, ALTURA_TELHADO, 0.0), 0.0)
	else:
		push_warning("ConstrutorCasa: telhado inexistente " + nome_telhado)
	var nome_frontao := "Roof_Front_Brick%d" % (colunas * 2)
	if _existe(nome_frontao):
		_colocar(casa, nome_frontao, Vector3(0.0, ALTURA_PAREDE, meia_z), 0.0)
		_colocar(casa, nome_frontao, Vector3(0.0, ALTURA_PAREDE, -meia_z), 180.0)

	casa.set_meta("colunas", colunas)
	casa.set_meta("linhas", linhas)
	casa.set_meta("x_porta", x_porta)
	_interior(casa, colunas, linhas, interior)
	if colisao:
		casa.add_child(_colisao(meia_x, meia_z, x_porta))
		casa.add_child(_teto_para_camera(colunas, linhas))
	return casa


## Porta aberta: batente no vão e a folha girada para dentro, presa pela dobradiça do lado esquerdo.
static func _porta(casa: Node3D, pos: Vector3) -> void:
	if _existe("DoorFrame_Flat_WoodDark"):
		_colocar(casa, "DoorFrame_Flat_WoodDark", pos, GIRO_FACHADA)
	if not _existe("Door_1_Flat"):
		return
	var porta := PortaCasa.new()
	porta.name = "Porta"
	porta.position = pos + Vector3(-0.55, 0.0, -0.1)   # a dobradiça fica na esquerda do vão
	porta.giro_base = GIRO_FACHADA
	casa.add_child(porta)
	var folha := peca("Door_1_Flat")
	folha.name = "Folha"
	porta.add_child(folha)
	porta.folha = folha
	var corpo := StaticBody3D.new()   # fecha o vão enquanto a porta está fechada
	corpo.name = "ColisaoPorta"
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(LARGURA_VAO_PORTA, 2.3, 0.2)
	cs.shape = bx
	corpo.add_child(cs)
	corpo.position = pos + Vector3(0.0, 1.15, -0.1)
	casa.add_child(corpo)
	porta.corpo = corpo


## Janela com esquadria e venezianas abertas, na mesma posição e giro da parede.
static func _janela(casa: Node3D, pos: Vector3, giro: float) -> void:
	if _existe("Window_Wide_Flat1"):
		_colocar(casa, "Window_Wide_Flat1", pos, giro)
	if _existe("WindowShutters_Wide_Flat_Open"):
		_colocar(casa, "WindowShutters_Wide_Flat_Open", pos, giro)


## Colisão só nas paredes. O vão da porta (1,7 m) fica livre.
static func _colisao(meia_x: float, meia_z: float, x_porta: float) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.name = "Colisao"
	var e := ESPESSURA_COLISAO
	var altura := ALTURA_PAREDE + 0.5
	var recuo := 0.11   # o plano da parede fica um pouco para dentro da borda da peça

	var caixas: Array = []   # [centro, tamanho]
	caixas.append([Vector3(0, altura / 2.0, -(meia_z - recuo)), Vector3(meia_x * 2.0, altura, e)])
	caixas.append([Vector3(meia_x - recuo, altura / 2.0, 0), Vector3(e, altura, meia_z * 2.0)])
	caixas.append([Vector3(-(meia_x - recuo), altura / 2.0, 0), Vector3(e, altura, meia_z * 2.0)])
	var esq_fim := x_porta - LARGURA_VAO_PORTA / 2.0
	var dir_ini := x_porta + LARGURA_VAO_PORTA / 2.0
	var larg_esq := esq_fim - (-meia_x)
	var larg_dir := meia_x - dir_ini
	if larg_esq > 0.05:
		caixas.append([Vector3(-meia_x + larg_esq / 2.0, altura / 2.0, meia_z - recuo), Vector3(larg_esq, altura, e)])
	if larg_dir > 0.05:
		caixas.append([Vector3(dir_ini + larg_dir / 2.0, altura / 2.0, meia_z - recuo), Vector3(larg_dir, altura, e)])
	for c in caixas:
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = c[1]
		cs.shape = bx
		cs.position = c[0]
		corpo.add_child(cs)
	return corpo


## Duas placas inclinadas no lugar das águas do telhado, na camada 2: só a câmera as enxerga. Sem isso a câmera
## atravessa o telhado quando o jogador está dentro da casa. (Altura da cumeeira ajustada às medidas do kit.)
static func _teto_para_camera(colunas: int, linhas: int) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.name = "TetoParaCamera"
	corpo.collision_layer = 2
	corpo.collision_mask = 0
	var largura := colunas * MODULO
	var profundidade := linhas * MODULO + 1.6
	var a := Vector2(-(largura / 2.0 + 1.1), ALTURA_TELHADO - 0.9)   # abaixo da face de baixo do forro, para a lente nunca encostar nele
	var b := Vector2(0.0, ALTURA_TELHADO + 0.75 + 0.585 * largura)
	var v := b - a
	var angulo := atan2(v.y, v.x)
	for lado in [-1, 1]:
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(v.length(), 0.3, profundidade)
		cs.shape = bx
		var centro := (a + b) / 2.0
		cs.transform = Transform3D(Basis(Vector3(0, 0, 1), angulo * -lado), Vector3(centro.x * -lado, centro.y, 0.0))
		corpo.add_child(cs)
	return corpo


# ---------------------------------------------------------------- interior
static func _material(cor: Color, brilho := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.9
	if brilho > 0.0:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = brilho
	return m


static func _caixa(pai: Node3D, nome: String, pos: Vector3, tamanho: Vector3, cor: Color, brilho := 0.0, giro := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	var bm := BoxMesh.new()
	bm.size = tamanho
	bm.material = _material(cor, brilho)
	mi.mesh = bm
	mi.position = pos + Vector3(0, tamanho.y / 2.0, 0)
	mi.rotation_degrees.y = giro
	pai.add_child(mi)
	return mi


const PASTA_MOVEIS := "res://assets/models/cenario/moveis/"
const CAMADA_MOVEIS := 4   # bit 3: o jogador colide com os móveis, a câmera (máscara 1+2) atravessa


## Coloca um móvel (Fantasy Props MegaKit) e, se `colide`, cria uma caixa de colisão do tamanho dele no corpo `corpo`.
static func _movel(casa: Node3D, corpo: StaticBody3D, nome: String, x: float, z: float, giro: float, y := 0.0, colide := true) -> Node3D:
	var m: Node3D = (load(PASTA_MOVEIS + nome + ".gltf") as PackedScene).instantiate()
	m.name = nome
	m.position = Vector3(x, y, z)
	m.rotation_degrees.y = giro
	casa.add_child(m)
	if colide:
		var uniao := AABB()
		var primeiro := true
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			var t := Transform3D.IDENTITY
			var no: Node = mi
			while no != m:
				t = (no as Node3D).transform * t
				no = no.get_parent()
			var a: AABB = t * (mi as MeshInstance3D).get_aabb()
			uniao = a if primeiro else uniao.merge(a)
			primeiro = false
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = uniao.size
		cs.shape = bx
		cs.transform = m.transform * Transform3D(Basis(), uniao.get_center())
		corpo.add_child(cs)
	return m


static func _interior(casa: Node3D, colunas: int, linhas: int, tipo: String) -> void:
	if tipo == "vazio":
		return
	var meia_x := colunas * MODULO / 2.0
	var meia_z := linhas * MODULO / 2.0
	var ix := meia_x - 0.45   # limite interno livre: a parede de colisão ocupa uns 0,4 m
	var iz := meia_z - 0.45
	var luz := OmniLight3D.new()
	luz.name = "LuzInterna"
	luz.light_color = Color(1.0, 0.78, 0.5)
	luz.light_energy = 1.3
	luz.omni_range = maxf(meia_x, meia_z) * 2.2
	luz.position = Vector3(0, 2.4, 0)
	casa.add_child(luz)
	var corpo := StaticBody3D.new()
	corpo.name = "ColisaoMoveis"
	corpo.collision_layer = CAMADA_MOVEIS
	corpo.collision_mask = 0
	casa.add_child(corpo)
	if tipo == "moradia":
		_moradia(casa, corpo, colunas, ix, iz)
	elif tipo == "forja":
		_forja(casa, corpo, ix, iz)


static func _moradia(casa: Node3D, corpo: StaticBody3D, colunas: int, ix: float, iz: float) -> void:
	# canto do fundo à esquerda: cama, criado-mudo e baú no pé da cama
	_movel(casa, corpo, "Bed_Twin1", -ix + 0.94, -iz + 1.21, 0.0)
	_movel(casa, corpo, "Nightstand_Shelf", -ix + 2.3, -iz + 0.2, 0.0)
	_movel(casa, corpo, "Candle_1", -ix + 2.3, -iz + 0.2, 0.0, 0.62, false)
	_movel(casa, corpo, "Chest_Wood", -ix + 0.94, -iz + 2.85, 0.0)
	# barril no canto da frente oposto à porta
	var lado_barril := 1.0 if colunas % 2 == 1 else -1.0
	_movel(casa, corpo, "Barrel", lado_barril * (ix - 0.4), iz - 0.4, 0.0)
	if colunas >= 3:
		# armário alto no fundo, cômoda na parede esquerda, mesa com cadeiras à direita
		_movel(casa, corpo, "Bookcase_2", ix - 0.95, -iz + 0.22, 0.0)
		_movel(casa, corpo, "Cabinet", -ix + 0.2, iz - 1.2, 90.0)
		_movel(casa, corpo, "CandleStick_Triple", -ix + 0.2, iz - 1.2, 90.0, 1.0, false)
		var tx := ix - 0.9
		var tz := 0.4
		_movel(casa, corpo, "Table_Large", tx, tz, 90.0)
		_movel(casa, corpo, "Chair_1", tx - 0.95, tz - 0.6, 90.0)
		_movel(casa, corpo, "Chair_1", tx - 0.95, tz + 0.6, 90.0)
		_movel(casa, corpo, "Table_Plate", tx, tz - 0.55, 0.0, 0.81, false)
		_movel(casa, corpo, "Table_Plate", tx, tz + 0.55, 0.0, 0.81, false)
		_movel(casa, corpo, "Mug", tx + 0.1, tz, 0.0, 0.81, false)
		if colunas >= 4:
			# casa grande: segunda cama, arsenal e mais um armário
			_movel(casa, corpo, "Bed_Twin2", -ix + 0.94, -iz + 5.0, 0.0)
			_movel(casa, corpo, "WeaponStand", ix - 0.8, iz - 2.6, -90.0)
			_movel(casa, corpo, "Bookcase_2", ix - 2.6, -iz + 0.22, 0.0)
			_movel(casa, corpo, "Bench", 0.0, -iz + 0.4, 0.0)
	else:
		# casa estreita: armário alto na parede direita e um banco
		_movel(casa, corpo, "Bookcase_2", ix - 0.22, -0.4, -90.0)
		_movel(casa, corpo, "Stool", -0.2, 0.9, 20.0)
		_movel(casa, corpo, "Bucket_Wooden_1", -ix + 0.35, iz - 0.3, 0.0, 0.0, false)


## Material (cópia, com a textura repetida) da primeira malha de uma peça do kit.
static func _material_do_kit(nome_peca: String) -> StandardMaterial3D:
	var p := peca(nome_peca)
	var mi := p.find_child("*", true, false) as MeshInstance3D
	for no in p.find_children("*", "MeshInstance3D", true, false):
		mi = no as MeshInstance3D
		break
	var m: StandardMaterial3D = null
	if mi and mi.mesh:
		var base := mi.mesh.surface_get_material(0) as StandardMaterial3D
		if base:
			m = base.duplicate()
			m.uv1_scale = Vector3(2.0, 2.0, 2.0)
	p.free()
	return m


static func _forja(casa: Node3D, corpo: StaticBody3D, ix: float, iz: float) -> void:
	# forja de pedra (geometria simples com a pedra do kit): base, borda, leito de brasas, painel de fundo, pilares,
	# coifa e chaminé até o teto. Bigorna, bancada e arsenal vêm do pacote de móveis.
	var hx := -ix + 0.75
	var hz := -iz + 0.6
	var pedra := _material_do_kit("Floor_UnevenBrick")
	var partes: Array[MeshInstance3D] = []
	partes.append(_caixa(casa, "Fornalha", Vector3(hx, 0.0, hz), Vector3(1.5, 0.95, 1.1), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "BordaFrente", Vector3(hx, 0.95, hz + 0.46), Vector3(1.5, 0.12, 0.18), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "BordaFundo", Vector3(hx, 0.95, hz - 0.46), Vector3(1.5, 0.12, 0.18), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "BordaEsq", Vector3(hx - 0.66, 0.95, hz), Vector3(0.18, 0.12, 0.74), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "BordaDir", Vector3(hx + 0.66, 0.95, hz), Vector3(0.18, 0.12, 0.74), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "PainelDeFundo", Vector3(hx, 1.07, hz - 0.5), Vector3(1.5, 0.8, 0.12), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "PilarEsq", Vector3(hx - 0.66, 1.07, hz + 0.46), Vector3(0.18, 0.8, 0.18), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "PilarDir", Vector3(hx + 0.66, 1.07, hz + 0.46), Vector3(0.18, 0.8, 0.18), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "Coifa", Vector3(hx, 1.87, hz), Vector3(1.6, 0.22, 1.2), Color(0.34, 0.33, 0.34)))
	partes.append(_caixa(casa, "Chamine", Vector3(hx, 2.09, hz - 0.25), Vector3(0.7, 1.0, 0.6), Color(0.34, 0.33, 0.34)))
	if pedra:
		for parte in partes:
			parte.material_override = pedra
	_caixa(casa, "LeitoDeCarvao", Vector3(hx, 0.95, hz), Vector3(1.14, 0.05, 0.74), Color(0.05, 0.04, 0.04))
	var sorte := RandomNumberGenerator.new()
	sorte.seed = 3
	for i in 8:   # brasas acesas espalhadas no leito
		_caixa(casa, "Brasa%d" % i, Vector3(hx + sorte.randf_range(-0.45, 0.45), 0.99, hz + sorte.randf_range(-0.27, 0.27)),
			Vector3(0.13, 0.05, 0.1), Color(1.0, 0.3, 0.06), 2.0, sorte.randf() * 90.0)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(1.5, 0.95, 1.1)
	cs.shape = bx
	cs.position = Vector3(hx, 0.475, hz)
	corpo.add_child(cs)
	var fogo := Fogo.new()   # chama baixa sobre as brasas, sob a coifa (só visual: o leito fica a 1 m)
	fogo.name = "FogoDaForja"
	fogo.escala = 0.5
	fogo.com_fumaca = false   # a coifa e a chaminé escondem a fumaça; sem ela some a bola cinza na frente da chama
	fogo.energia_luz = 2.2
	fogo.alcance_luz = 7.0
	fogo.position = Vector3(hx, 1.0, hz)
	casa.add_child(fogo)
	_movel(casa, corpo, "Anvil", -ix + 1.4, -iz + 2.0, 90.0)
	_movel(casa, corpo, "Workbench", ix - 0.52, -0.3, -90.0)
	_movel(casa, corpo, "Pot_1", ix - 0.5, 0.2, 0.0, 0.89, false)
	_movel(casa, corpo, "WeaponStand", -ix + 0.5, 0.9, 90.0)
	_movel(casa, corpo, "Barrel", ix - 0.4, iz - 0.4, 0.0)
	_movel(casa, corpo, "Bucket_Wooden_1", -ix + 0.4, -iz + 1.9, 0.0, 0.0, false)
	_movel(casa, corpo, "Bag", ix - 0.4, -iz + 0.4, 0.0)
