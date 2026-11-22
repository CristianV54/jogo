class_name ConstrutorCasa
extends RefCounted
## Monta uma casa a partir das peças modulares do Medieval Village MegaKit (CC0, Quaternius).
## Módulo = 2 m: paredes de 2 m de largura e 3,12 m de altura, pisos de 2x2 m.
## Planta: `colunas` módulos ao longo de X e `linhas` módulos ao longo de Z. A porta fica no meio da fachada (+Z).

const PASTA := "res://assets/models/cenario/vila_mv/"
const MODULO := 2.0

# Calibração (conferida por captura): giro em Y para a face externa da parede olhar para fora, e altura do telhado.
const GIRO_FACHADA := 0.0
const ALTURA_TELHADO := 3.12


static func peca(nome: String) -> Node3D:
	var cena: PackedScene = load(PASTA + nome + ".gltf")
	return cena.instantiate()


static func _colocar(pai: Node3D, nome: String, pos: Vector3, giro_graus: float) -> Node3D:
	var p := peca(nome)
	p.position = pos
	p.rotation_degrees.y = giro_graus
	pai.add_child(p)
	return p


## estilo: {"parede": "Wall_Plaster_Straight", "porta": "Wall_Plaster_Door_Flat", "janela": "Wall_Plaster_Window_Wide_Flat",
##          "piso": "Floor_WoodDark", "canto": "Corner_Exterior_Wood", "telhado": "Roof_RoundTiles_6x8"}
static func montar(colunas: int, linhas: int, estilo: Dictionary, colisao := true) -> Node3D:
	var casa := Node3D.new()
	casa.name = "Casa"
	var meia_x := colunas * MODULO / 2.0
	var meia_z := linhas * MODULO / 2.0

	# piso
	for i in colunas:
		for j in linhas:
			_colocar(casa, estilo["piso"], Vector3(-meia_x + MODULO / 2.0 + i * MODULO, 0.0, -meia_z + MODULO / 2.0 + j * MODULO), 0.0)

	# paredes: fachada (+Z) com porta no meio, fundos (-Z), laterais (±X)
	for i in colunas:
		var x := -meia_x + MODULO / 2.0 + i * MODULO
		var tipo_f: String = estilo["porta"] if i == colunas / 2 else (estilo["janela"] if i % 2 == 1 else estilo["parede"])
		_colocar(casa, tipo_f, Vector3(x, 0.0, meia_z), GIRO_FACHADA)
		var tipo_t: String = estilo["janela"] if i % 2 == 1 else estilo["parede"]
		_colocar(casa, tipo_t, Vector3(x, 0.0, -meia_z), GIRO_FACHADA + 180.0)
	for j in linhas:
		var z := -meia_z + MODULO / 2.0 + j * MODULO
		var tipo_l: String = estilo["janela"] if j % 2 == 1 else estilo["parede"]
		_colocar(casa, tipo_l, Vector3(meia_x, 0.0, z), GIRO_FACHADA + 90.0)
		_colocar(casa, tipo_l, Vector3(-meia_x, 0.0, z), GIRO_FACHADA - 90.0)

	# cantos
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_colocar(casa, estilo["canto"], Vector3(sx * meia_x, 0.0, sz * meia_z), GIRO_FACHADA + (45.0 if sx * sz > 0 else -45.0))

	# telhado: o kit tem Roof_RoundTiles_<largura>x<profundidade> em metros
	var nome_telhado: String = estilo.get("telhado", "Roof_RoundTiles_%dx%d" % [colunas * 2, linhas * 2])
	if not ResourceLoader.exists(PASTA + nome_telhado + ".gltf"):
		push_warning("ConstrutorCasa: telhado inexistente " + nome_telhado)
	else:
		_colocar(casa, nome_telhado, Vector3(0.0, ALTURA_TELHADO, 0.0), 0.0)

	if colisao:   # a casa é um bloco sólido: ninguém atravessa as paredes
		var corpo := StaticBody3D.new()
		corpo.name = "Colisao"
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(colunas * MODULO, 4.0, linhas * MODULO)
		cs.shape = caixa
		cs.position.y = 2.0
		corpo.add_child(cs)
		casa.add_child(corpo)
	return casa
