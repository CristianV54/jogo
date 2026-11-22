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
	return casa


## Porta aberta: batente no vão e a folha girada para dentro, presa pela dobradiça do lado esquerdo.
static func _porta(casa: Node3D, pos: Vector3) -> void:
	if _existe("DoorFrame_Flat_WoodDark"):
		_colocar(casa, "DoorFrame_Flat_WoodDark", pos, GIRO_FACHADA)
	if _existe("Door_1_Flat"):
		var folha := _colocar(casa, "Door_1_Flat", pos + Vector3(-0.55, 0.0, -0.1), GIRO_FACHADA + 100.0)
		folha.name = "PortaAberta"


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


static func _interior(casa: Node3D, colunas: int, linhas: int, tipo: String) -> void:
	if tipo == "vazio":
		return
	var meia_x := colunas * MODULO / 2.0
	var meia_z := linhas * MODULO / 2.0
	var luz := OmniLight3D.new()
	luz.name = "LuzInterna"
	luz.light_color = Color(1.0, 0.78, 0.5)
	luz.light_energy = 1.3
	luz.omni_range = maxf(meia_x, meia_z) * 2.2
	luz.position = Vector3(0, 2.4, 0)
	casa.add_child(luz)
	var madeira := Color(0.36, 0.24, 0.14)
	if tipo == "moradia":
		# cama no canto do fundo, mesa no meio e duas caixas
		_caixa(casa, "Cama", Vector3(-meia_x + 1.0, 0.0, -meia_z + 1.5), Vector3(1.0, 0.45, 2.0), madeira)
		_caixa(casa, "Colchao", Vector3(-meia_x + 1.0, 0.45, -meia_z + 1.5), Vector3(0.9, 0.18, 1.85), Color(0.72, 0.68, 0.6))
		_caixa(casa, "Mesa", Vector3(meia_x - 1.6, 0.0, -0.4), Vector3(1.3, 0.8, 0.8), madeira)
		_caixa(casa, "Banco", Vector3(meia_x - 1.6, 0.0, 0.9), Vector3(1.1, 0.42, 0.34), madeira)
		if _existe("Prop_Crate"):
			var c1 := _colocar(casa, "Prop_Crate", Vector3(meia_x - 0.9, 0.0, -meia_z + 0.9), 15.0)
			c1.scale = Vector3.ONE * 0.7
			var c2 := _colocar(casa, "Prop_Crate", Vector3(meia_x - 0.9, 0.0, -meia_z + 2.0), -10.0)
			c2.scale = Vector3.ONE * 0.55
	elif tipo == "forja":
		# fornalha de pedra com brasa, bigorna e bancada
		_caixa(casa, "Fornalha", Vector3(-meia_x + 1.0, 0.0, -meia_z + 1.0), Vector3(1.5, 1.1, 1.1), Color(0.34, 0.33, 0.34))
		_caixa(casa, "Brasa", Vector3(-meia_x + 1.0, 1.1, -meia_z + 1.0), Vector3(1.1, 0.12, 0.8), Color(1.0, 0.4, 0.1), 3.0)
		var brasa := OmniLight3D.new()
		brasa.light_color = Color(1.0, 0.45, 0.15)
		brasa.light_energy = 2.2
		brasa.omni_range = 7.0
		brasa.position = Vector3(-meia_x + 1.0, 1.6, -meia_z + 1.0)
		casa.add_child(brasa)
		_caixa(casa, "BigornaBase", Vector3(0.6, 0.0, 0.0), Vector3(0.4, 0.7, 0.4), Color(0.2, 0.18, 0.17))
		_caixa(casa, "BigornaTopo", Vector3(0.6, 0.7, 0.0), Vector3(0.9, 0.22, 0.4), Color(0.12, 0.12, 0.13))
		_caixa(casa, "Bancada", Vector3(meia_x - 0.8, 0.0, -0.5), Vector3(0.7, 0.9, 2.2), madeira)
		if _existe("Prop_Crate"):
			var c := _colocar(casa, "Prop_Crate", Vector3(meia_x - 1.0, 0.0, -meia_z + 0.9), 20.0)
			c.scale = Vector3.ONE * 0.7
