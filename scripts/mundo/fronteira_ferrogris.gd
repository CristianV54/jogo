extends AreaAberta
## Fortaleza de Ferrogris (Capítulo III). De sul a norte: Muralha externa com a Brecha (torres e arqueiros) -> Pátio
## Externo (Quartel, Depósito de Aço, Canil de cães de guerra) -> Prisão dos civis e dos soldados, Jaulas dos Dragões
## -> Pátio Central (arena do General Kaelor) -> Sala de Comando -> Portão dos Fundos, que leva à Cratera de Ignis.
## Kaelor aparece quando a missão C3-M3 termina e muda de fase: aos 66% chama cães, aos 33% chama guardas.

signal chefe_vida(nome: String, atual: int, maximo: int)
signal chefe_morreu(id: String)

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const CENTRO := Vector2(0.0, -2.0)
const NORTE_Z := -100.0
const SUL_Z := 95.0
const LADO := 70.0

var chefe: Inimigo
var engajado := false
var portao_fundos: Portao
var _fase := 0


func _ready() -> void:
	nome_area = "Fortaleza de Ferrogris"
	tipo_de_arvore = "morta"   # chão frio e militar: só árvores secas
	paleta_casas = {"parede": Color(0.62, 0.62, 0.66), "telhado": Color(0.3, 0.3, 0.36)}   # fortaleza de ferro e pedra cinza
	tam = 300.0
	_rng.seed = 67
	_ambiente_padrao()
	var we := get_node("Ambiente") as WorldEnvironment
	we.environment.fog_light_color = Color(0.6, 0.6, 0.64)
	we.environment.fog_density = 0.006
	(get_node("Sol") as DirectionalLight3D).light_energy = 0.9
	var planos: Array[Vector3] = [Vector3(0, 110, 30), Vector3(0, 70, 40), Vector3(0, 25, 42), Vector3(0, -20, 42), Vector3(0, -62, 36), Vector3(0, -105, 20)]
	_montar_terreno(29, 6.0, planos, PackedVector2Array([Vector2(0, 155), Vector2(0, 140), Vector2(0, 95), Vector2(0, 40), Vector2(0, -40), Vector2(0, -100), Vector2(0, -125), Vector2(0, -155)]), Color(0.27, 0.3, 0.22), Color(0.17, 0.22, 0.15))
	_floresta(1800, func(x: float, z: float) -> bool:
		return absf(x) < LADO + 8.0 and z > NORTE_Z - 12.0 and z < SUL_Z + 40.0)
	_horizonte(Color(0.4, 0.4, 0.45), 130.0, true, -6.0)
	_muralhas()
	_patio_externo()
	_prisao_e_jaulas()
	_patio_central()
	_sala_de_comando()
	_divisorias_e_entulho()
	_novo_spawn("Entrada", Vector3(0, altura_em(0, 128), 128), Vector3(0, 0, 90))
	_novo_spawn("Principal", Vector3(0, altura_em(0, 128), 128), Vector3(0, 0, 90))
	_novo_spawn("DaCratera", Vector3(0, altura_em(0, NORTE_Z - 6.0), NORTE_Z - 6.0), Vector3(0, 0, 0))
	_portal(Vector3(0, altura_em(0, 136), 136), "acampamento_ruptura", "DaFortaleza", 16.0)
	_portal(Vector3(0, altura_em(0, NORTE_Z - 14.0), NORTE_Z - 14.0), "cratera_ignis", "Entrada", 10.0)
	var m := GerenciadorMissoes.instancia
	if m:
		m.missao_concluida.connect(_ao_missao_concluida)
		if m.concluidas.has("C3-M4"):
			portao_fundos.abrir()
		elif m.concluidas.has("C3-M3"):
			_spawn_kaelor()


# ---------------------------------------------------------------- muralhas, torres, brecha

func _muralhas() -> void:
	_muralha(Vector2(-LADO, SUL_Z), Vector2(-9.0, SUL_Z))
	_muralha(Vector2(9.0, SUL_Z), Vector2(LADO, SUL_Z))
	_muralha(Vector2(-LADO, SUL_Z), Vector2(-LADO, NORTE_Z))
	_muralha(Vector2(LADO, SUL_Z), Vector2(LADO, NORTE_Z))
	_muralha(Vector2(-LADO, NORTE_Z), Vector2(-6.0, NORTE_Z))
	_muralha(Vector2(6.0, NORTE_Z), Vector2(LADO, NORTE_Z))
	portao_fundos = Portao.new()
	portao_fundos.position = Vector3(0, altura_em(0, NORTE_Z), NORTE_Z)
	portao_fundos.largura = 12.0
	add_child(portao_fundos)
	_placa_em_poste(Vector2(8.0, 119.0), "Fortaleza de Ferrogris")
	_placa_em_poste(Vector2(-9.0, 106.0), "Brecha: entrada dos mensageiros")
	var posto_arqueiro: Array[Vector3] = []
	for t in [Vector2(-13.0, SUL_Z), Vector2(13.0, SUL_Z), Vector2(-LADO, SUL_Z), Vector2(LADO, SUL_Z)]:
		posto_arqueiro.append(_torre_de_vigia(t))
	for p in posto_arqueiro:
		_inimigo("res://scenes/inimigos/arqueiro.tscn", p + Vector3(0, 0.3, 0), "Arqueiro Imperial", "arqueiro")
	for t in [Vector2(-LADO, NORTE_Z), Vector2(LADO, NORTE_Z), Vector2(-LADO, -2.0), Vector2(LADO, -2.0)]:
		_torre_de_vigia(t, 10.0)
	for b in [Vector2(-5.0, SUL_Z + 4.0), Vector2(5.0, SUL_Z + 4.0), Vector2(-30.0, SUL_Z - 4.0), Vector2(30.0, SUL_Z - 4.0)]:
		_bandeira(b)
	for k in 5:   # escombros da brecha
		_rocha(Vector2(-7.0 + k * 3.5, SUL_Z + 1.0 + sin(k)), 0.9 + (k % 2) * 0.5, k % 2 == 0, 90.0 + k)


# ---------------------------------------------------------------- pátio externo

func _guarda(pos: Vector2, com_chave := false, nome_g := "Guarda de Ferrogris") -> void:
	_inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(pos.x, _y(pos) + 0.2, pos.y), nome_g, "guarda_ferrogris", {"chave": [1, 1]} if com_chave else {})


func _patio_externo() -> void:
	_edificio("Quartel", Vector2(-48.0, 68.0), PI / 2.0, REF.ESTILO_PEDRA, "Quartel", "moradia")
	_edificio("DepositoDeAco", Vector2(48.0, 68.0), -PI / 2.0, REF.ESTILO_MADEIRA, "Depósito de Aço")
	for k in 4:   # as pilhas de aço ao lado do depósito
		var pilha := PilhaDeItem.new()
		pilha.item = "aco_imperial"
		pilha.position = Vector3(40.0 + (k % 2) * 2.4, _y(Vector2(40.0, 56.0 + (k / 2) * 2.6)), 56.0 + (k / 2) * 2.6)
		add_child(pilha)
	ConstrutorCasa._movel(self, _solidos, "Barrel", 36.0, 60.0, 0.0, _y(Vector2(36, 60)))
	ConstrutorCasa._movel(self, _solidos, "Chest_Wood", 36.0, 62.0, 25.0, _y(Vector2(36, 62)))
	# canil dos cães de guerra: cerca baixa de três lados e os dois cães dentro
	var canil := Vector2(-42.0, 36.0)
	_muralha(canil + Vector2(-8, -6), canil + Vector2(8, -6), 1.6, Color(0.3, 0.2, 0.11))
	_muralha(canil + Vector2(-8, -6), canil + Vector2(-8, 6), 1.6, Color(0.3, 0.2, 0.11))
	_muralha(canil + Vector2(8, -6), canil + Vector2(8, 6), 1.6, Color(0.3, 0.2, 0.11))
	_placa_em_poste(canil + Vector2(0, 8.0), "Canil")
	for p in [canil + Vector2(-3, 0), canil + Vector2(3, 1)]:
		_inimigo("res://scenes/inimigos/cao_de_guerra.tscn", Vector3(p.x, _y(p) + 0.3, p.y), "Cão de Guerra", "cao_guerra")
	for p in [Vector2(-22, 76), Vector2(22, 76), Vector2(-26, 50), Vector2(26, 50)]:
		_guarda(p)
	for p in [Vector2(-8, 60), Vector2(8, 60)]:   # braseiros no caminho
		_fogueira(p, 0.7, 10.0)
	for p in [Vector2(-30, 85), Vector2(30, 85), Vector2(-60, 40), Vector2(60, 40)]:
		ConstrutorCasa._movel(self, _solidos, "WeaponStand", p.x, p.y, 0.0, _y(p))


# ---------------------------------------------------------------- prisão e jaulas

func _cela(tipo: String, pos: Vector2, ocupantes_cenas: Array) -> void:
	var c := CelaTrancada.new()
	c.tipo = tipo
	c.position = Vector3(pos.x, _y(pos), pos.y + (4.0 if tipo != "dragao" else 7.0) / 2.0)   # a origem da cela é a porta
	add_child(c)
	var k := 0
	for cena in ocupantes_cenas:
		var n := Npc.new()
		n.nome = cena[0]
		n.papel = cena[1]
		n.falas = PackedStringArray([cena[2]])
		n.cena = load(cena[3])
		n.rotina = [{"esperar": 8.0, "anim": "Idle"}, {"esperar": 5.0, "anim": "Crouch_Idle"}]
		n.altura_em = altura_em
		n.position = Vector3(pos.x - 0.8 + k * 1.6, _y(pos), pos.y - 0.3)
		add_child(n)
		npcs.append(n)
		c.ocupantes.append(n)
		k += 1


func _prisao_e_jaulas() -> void:
	_edificio("Prisao", Vector2(-48.0, 14.0), PI / 2.0, REF.ESTILO_PEDRA, "Prisão", "deposito")
	_cela("civis", Vector2(-34.0, 0.0), [
		["Cativo da Aldeia", "Civil", "Pegaram a minha aldeia inteira. Ainda ouço as correntes. Não abra a cela ao lado sem olhar: tem gente lá dentro que já esqueceu o próprio nome.", "res://scenes/personagens/cativo.tscn"],
		["Cativa da Aldeia", "Civil", "Meu filho levaram para a mina. Por favor, abra. Prometo não correr: só quero ir atrás dele.", "res://scenes/personagens/cativa.tscn"]])
	_cela("soldados", Vector2(-34.0, -14.0), [
		["Soldado Rebelde", "Soldado preso", "Lutei contra o Império até me renderem. Kaelor não luta pelo Solon: luta porque acredita que ordem é melhor que liberdade. É isso que o torna perigoso. Tire-nos daqui.", "res://scenes/personagens/soldado_rebelde.tscn"],
		["Soldado Ferido", "Soldado preso", "Estou ferido, mas ainda seguro uma espada. Tire-nos daqui e eu sigo você até onde der.", "res://scenes/personagens/soldado_ferido.tscn"]])
	_guarda(Vector2(-27.0, -7.0), true, "Carcereiro")
	_edificio("JaulasDosDragoes", Vector2(48.0, 14.0), -PI / 2.0, REF.ESTILO_MADEIRA, "Jaulas dos Dragões", "deposito")
	_cela("dragao", Vector2(36.0, -7.0), [])
	_npc("Cuidadora dos Dragões", "Cuidadora", "res://scenes/personagens/cativa.tscn", Vector2(28.0, -1.0),
		PackedStringArray(["Não bata nas jaulas. Eles já não sabem diferenciar uma ameaça de uma tentativa de ajuda.", "Eu era tratadora de cavalos. Me deram um uniforme e uma ordem: manter vivo o que eles chamam de matéria-prima. Eu mantenho vivo e peço perdão todos os dias."]),
		[{"esperar": 8.0, "anim": "Idle", "olhar": Vector2(36.0, -7.0)}, {"esperar": 5.0, "anim": "Crouch_Idle", "olhar": Vector2(36.0, -7.0)}])
	_npc("Soldado Rendido", "Soldado", "res://scenes/personagens/soldado_rebelde.tscn", Vector2(-20.0, 30.0),
		PackedStringArray(["Larguei a lança quando vi o que eles fazem com os dragões. Não sou herói. Só não aguentei mais.", "Se vai ao pátio central, cuidado: o Kaelor sempre chama reforço quando a luta aperta."]),
		[{"esperar": 8.0, "anim": "Idle", "olhar": Vector2(0.0, 30.0)}, {"esperar": 6.0, "anim": "Crouch_Idle", "olhar": Vector2(0.0, 30.0)}])
	Cartaz.colocar(self, Vector3(14.0, _y(Vector2(14.0, 118.0)), 118.0), PI, "Ordem a Kaelor", [
		"AO GENERAL KAELOR, COMANDANTE DE FERROGRIS: o Imperador Solon exige o envio de dragões à Cratera de Ignis até o fim do inverno. Nenhuma jaula deve ficar vazia.",
		"Os que resistirem à captura serão corrigidos. A obediência de um dragão salvará mil vidas humanas.",
		"Assinado: Solon. À margem, em letra miúda do próprio Kaelor: \"Cumpri a ordem. Não pedi que me agradassem.\""])
	_guarda(Vector2(27.0, -7.0), true, "Domador Imperial")
	_placa_em_poste(Vector2(-24.0, 12.0), "Prisão")
	_placa_em_poste(Vector2(24.0, 12.0), "Jaulas dos Dragões")
	_bandeira(Vector2(-24.0, -20.0))
	_bandeira(Vector2(24.0, -20.0))


# ---------------------------------------------------------------- pátio central e sala de comando

func _patio_central() -> void:
	var c := CENTRO
	for k in 8:   # braseiros em anel
		var a := TAU * k / 8.0
		_fogueira(c + Vector2(cos(a), sin(a)) * 24.0, 0.8, 11.0)
	for k in 3:   # bonecos de treino dos soldados
		var b := BonecoDeTreino.new()
		b.position = Vector3(c.x - 14.0 + k * 14.0, _y(c + Vector2(0, 16)), c.y + 16.0)
		add_child(b)
	for p in [Vector2(-14, -22), Vector2(14, -22)]:
		_bandeira(c + p)
	_placa_em_poste(c + Vector2(6.0, 28.0), "Pátio Central")


func _sala_de_comando() -> void:
	_edificio("SalaDeComando", Vector2(0.0, -70.0), PI, REF.ESTILO_PEDRA, "Sala de Comando", "moradia")
	_guarda(Vector2(-10.0, -56.0), true, "Oficial de Comando")
	_guarda(Vector2(10.0, -56.0))
	_placa_em_poste(Vector2(8.0, -52.0), "Sala de Comando")
	_placa_em_poste(Vector2(-8.0, -92.0), "Portão dos Fundos")
	for p in [Vector2(-18, -88), Vector2(18, -88)]:
		_fogueira(p, 0.8, 10.0)


# ---------------------------------------------------------------- Kaelor

func _spawn_kaelor() -> void:
	if chefe != null:
		return
	chefe = (load("res://scenes/inimigos/kaelor.tscn") as PackedScene).instantiate() as Inimigo
	chefe.especie = "kaelor"
	var p := CENTRO + Vector2(0, -16)
	chefe.position = Vector3(p.x, _y(p) + 0.1, p.y)
	add_child(chefe)
	chefe.vida_mudou.connect(_ao_vida_do_chefe)
	chefe.morreu.connect(func(_i: Inimigo) -> void:
		portao_fundos.abrir()
		chefe_morreu.emit("kaelor"))
	GerenciadorMissoes.instancia.aviso.emit("O General Kaelor desce da sala de comando!", 4.0)


func _ao_vida_do_chefe(atual: int, maximo: int) -> void:
	chefe_vida.emit(chefe.nome, atual, maximo)
	var f := float(atual) / maximo
	if _fase == 0 and f <= 0.66:
		_fase = 1
		GerenciadorMissoes.instancia.aviso.emit("Kaelor assobia: os cães de guerra são soltos!", 3.5)
		for dx in [-10.0, 10.0]:
			var p := CENTRO + Vector2(dx, 22.0)
			_inimigo("res://scenes/inimigos/cao_de_guerra.tscn", Vector3(p.x, _y(p) + 0.3, p.y), "Cão de Guerra", "")
	elif _fase == 1 and f <= 0.33:
		_fase = 2
		GerenciadorMissoes.instancia.aviso.emit("Kaelor chama a guarda! Reforços entram no pátio.", 3.5)
		for dx in [-10.0, 10.0]:
			var p := CENTRO + Vector2(dx, 22.0)
			_inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(p.x, _y(p) + 0.2, p.y), "Guarda de Ferrogris", "")


func _process(_delta: float) -> void:
	if chefe == null or chefe.estado == Inimigo.Estado.MORTO or engajado:
		return
	var js := get_tree().get_nodes_in_group("jogador")
	if js.size() > 0 and (js[0] as Node3D).global_position.distance_to(chefe.global_position) < 30.0:
		engajado = true
		chefe_vida.emit(chefe.nome, chefe.vida, chefe.vida_max)


func _ao_missao_concluida(id: String) -> void:
	if id == "C3-M3":
		_spawn_kaelor()


## Muralhas internas separam o pátio externo, o pátio da prisão e a sala de comando; barris, caixotes e arsenais
## enchem os cantos (nenhuma área vazia).
func _divisorias_e_entulho() -> void:
	for z in [42.0, -46.0]:
		_muralha(Vector2(-LADO, z), Vector2(-11.0, z), 5.0, Color(0.3, 0.3, 0.33))
		_muralha(Vector2(11.0, z), Vector2(LADO, z), 5.0, Color(0.3, 0.3, 0.33))
		for lado in [-1.0, 1.0]:
			_torre_de_vigia(Vector2(lado * 13.0, z), 7.0)
		_bandeira(Vector2(-6.0, z + 3.0))
		_bandeira(Vector2(6.0, z + 3.0))
	var itens := ["Barrel", "Bag", "Chest_Wood", "WeaponStand", "Barrel", "Bag"]
	var pontos: Array[Vector2] = [Vector2(-62, 88), Vector2(62, 88), Vector2(-62, 50), Vector2(62, 48), Vector2(-62, 30), Vector2(62, 30), Vector2(-62, -30), Vector2(62, -30), Vector2(-62, -56), Vector2(62, -56), Vector2(-40, -90), Vector2(40, -90), Vector2(-24, 100), Vector2(24, 100), Vector2(-58, 8), Vector2(58, 8)]
	var k := 0
	for p in pontos:
		for j in 3:
			var q := p + Vector2(j * 1.3, (j % 2) * 1.1)
			ConstrutorCasa._movel(self, _solidos, itens[(k + j) % itens.size()], q.x, q.y, 25.0 * (k + j), _y(q))
		k += 1
