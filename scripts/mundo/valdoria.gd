extends AreaAberta
## Valdoria (Capítulo V): a cidade do Império de Drakkar, dourada e opressiva. De sul a norte: fila de carroças e Portão
## Principal -> Rua dos Artesãos -> Praça Central (fonte seca) com o Distrito do Comerciante a leste, o bairro
## residencial (16 casas e becos) a oeste, Quartel da Guarda, Armazém de Suprimentos e Capela Abandonada ->
## Escadaria monumental até o Castelo Imperial. Quatro mercadores (Miro, Lena, Darrik e Suri) fazem trocas de materiais.

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const PRACA := Vector2(0.0, 0.0)
const MERCADO := Vector2(48.0, 19.0)
const PORTAO_Z := 110.0
const NORTE_Z := -85.0
const LADO := 80.0
const TOPO_Y := 7.0
const COR_DRAKKAR := Color(0.65, 0.1, 0.08)

var elite: Array[Inimigo] = []
var barracas: Array[Vector2] = []
var casas: Array[Node3D] = []
var mercadores: Array[Npc] = []
var trocas: Array[Gatilho] = []


func _ready() -> void:
	nome_area = "Valdoria"
	tam = 300.0
	_rng.seed = 89
	_ambiente()
	_montar_terreno(53, 0.0, [], PackedVector2Array([Vector2(0, 150), Vector2(0, -85)]), Color(0.42, 0.38, 0.32), Color(0.34, 0.3, 0.26), 260.0)
	_muralhas()
	_fila_de_carrocas()
	_rua_dos_artesaos()
	_praca()
	_mercado()
	_bairro()
	_predios_publicos()
	_escadaria()
	_gente()
	_guardas()
	_novo_spawn("Entrada", Vector3(0, altura_em(0, 138), 138), Vector3(0, 0, 100))
	_novo_spawn("Principal", Vector3(0, altura_em(0, 138), 138), Vector3(0, 0, 100))
	_novo_spawn("DoCastelo", Vector3(0, TOPO_Y + 0.6, -122.0), Vector3(0, TOPO_Y, 0))
	_portal(Vector3(0, altura_em(0, 146), 146), "cratera_ignis", "DeValdoria", 16.0)
	_portal(Vector3(0, TOPO_Y, -130.0), "castelo_imperial", "Entrada", 14.0)


func _ambiente() -> void:
	_ambiente_padrao()
	var we := get_node("Ambiente") as WorldEnvironment
	var e := we.environment
	var ceu := e.sky.sky_material as ProceduralSkyMaterial
	ceu.sky_top_color = Color(0.5, 0.45, 0.4)
	ceu.sky_horizon_color = Color(0.88, 0.68, 0.42)
	ceu.ground_horizon_color = Color(0.7, 0.55, 0.36)
	e.fog_light_color = Color(0.82, 0.66, 0.46)
	e.fog_density = 0.0025
	e.ambient_light_energy = 0.6
	var sol := get_node("Sol") as DirectionalLight3D
	sol.light_color = Color(1.0, 0.85, 0.62)
	sol.light_energy = 0.75


# ---------------------------------------------------------------- muralhas, portão, carroças

func _muralhas() -> void:
	_muralha(Vector2(-LADO, PORTAO_Z), Vector2(-11.0, PORTAO_Z), 9.0, Color(0.5, 0.45, 0.38))
	_muralha(Vector2(11.0, PORTAO_Z), Vector2(LADO, PORTAO_Z), 9.0, Color(0.5, 0.45, 0.38))
	_muralha(Vector2(-LADO, PORTAO_Z), Vector2(-LADO, NORTE_Z), 9.0, Color(0.5, 0.45, 0.38))
	_muralha(Vector2(LADO, PORTAO_Z), Vector2(LADO, NORTE_Z), 9.0, Color(0.5, 0.45, 0.38))
	_muralha(Vector2(-LADO, NORTE_Z), Vector2(-16.0, NORTE_Z), 9.0, Color(0.5, 0.45, 0.38))
	_muralha(Vector2(16.0, NORTE_Z), Vector2(LADO, NORTE_Z), 9.0, Color(0.5, 0.45, 0.38))
	for t in [Vector2(-13.0, PORTAO_Z), Vector2(13.0, PORTAO_Z), Vector2(-LADO, PORTAO_Z), Vector2(LADO, PORTAO_Z), Vector2(-LADO, NORTE_Z), Vector2(LADO, NORTE_Z)]:
		_torre_de_vigia(t, 11.0)
	var portao := Portao.new()   # o Portão Principal fica aberto (a cidade está tomada), com as folhas recolhidas
	portao.position = Vector3(0, altura_em(0, PORTAO_Z), PORTAO_Z)
	portao.largura = 22.0
	add_child(portao)
	portao.abrir()
	for x in range(-72, 73, 16):   # bandeiras de Drakkar ao longo das muralhas
		_bandeira(Vector2(float(x), PORTAO_Z - 3.0), COR_DRAKKAR)
	for z in range(-70, 100, 24):
		_bandeira(Vector2(-LADO + 3.0, float(z)), COR_DRAKKAR)
		_bandeira(Vector2(LADO - 3.0, float(z)), COR_DRAKKAR)
	_placa_em_poste(Vector2(12.0, PORTAO_Z + 8.0), "Portão Principal de Valdoria")
	for p in [Vector2(-60, 100), Vector2(60, 100), Vector2(-60, -76), Vector2(60, -76)]:
		_rocha(p, 1.6, true, 11.0 + p.x)


func _carroca(pos: Vector2, giro: float, cor: Color) -> void:
	var y := _y(pos)
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	VilaRefugio._caixa(Vector3(pos.x, y + 0.9, pos.y), Vector3(2.2, 0.8, 3.6), VilaRefugio._mat(cor), true, giro)
	var f := Vector2(sin(giro), cos(giro))
	var r := Vector2(cos(giro), -sin(giro))
	for lado in [-1.0, 1.0]:
		for fr in [-1.0, 1.0]:
			var q: Vector2 = pos + r * lado * 1.2 + f * fr * 1.1
			var roda := VilaRefugio._cilindro(Vector3(q.x, y + 0.5, q.y), 0.5, 0.18, madeira, false, 10)
			roda.rotation = Vector3(0.0, giro, PI / 2.0)
	var carga := pos + f * 0.4
	VilaRefugio._caixa(Vector3(carga.x, y + 1.6, carga.y), Vector3(1.4, 0.9, 1.6), VilaRefugio._mat(Color(0.45, 0.35, 0.2)), false, giro)


func _fila_de_carrocas() -> void:
	for k in 6:   # fila de carroças esperando para entrar, na pista da esquerda
		_carroca(Vector2(-9.0, PORTAO_Z + 12.0 + k * 9.0), PI + sin(k) * 0.05, [Color(0.4, 0.28, 0.16), Color(0.32, 0.22, 0.14), Color(0.44, 0.3, 0.18)][k % 3])
	_placa_em_poste(Vector2(-14.0, PORTAO_Z + 6.0), "Inspeção imperial: fila aqui")


# ---------------------------------------------------------------- rua dos artesãos

func _rua_dos_artesaos() -> void:
	_edificio("Ferraria", Vector2(-18.0, 88.0), PI / 2.0, REF.ESTILO_PEDRA, "Ferraria", "forja")
	_edificio("Carpintaria", Vector2(-18.0, 66.0), PI / 2.0, REF.ESTILO_MADEIRA, "Carpintaria", "deposito")
	_edificio("Curtume", Vector2(18.0, 88.0), -PI / 2.0, REF.ESTILO_MADEIRA, "Curtume", "deposito")
	_edificio("AtelieDeTecidos", Vector2(18.0, 66.0), -PI / 2.0, REF.ESTILO_PEDRA, "Ateliê de Tecidos", "moradia")
	_placa_em_poste(Vector2(4.0, 98.0), "Rua dos Artesãos")
	for p in [Vector2(-28.0, 90.0), Vector2(28.0, 90.0), Vector2(-28.0, 62.0), Vector2(28.0, 62.0)]:
		ConstrutorCasa._movel(self, _solidos, "Barrel", p.x, p.y, 0.0, _y(p))
		ConstrutorCasa._movel(self, _solidos, "Bag", p.x + 1.2, p.y, 30.0, _y(p))
	for z in [100.0, 76.0, 54.0]:   # lampiões de rua
		_fogueira(Vector2(-6.0, z), 0.4, 8.0)
		_fogueira(Vector2(6.0, z), 0.4, 8.0)


# ---------------------------------------------------------------- praça central

func _praca() -> void:
	var pedra := VilaRefugio._mat(Color(0.48, 0.44, 0.38))
	var y := _y(PRACA)
	VilaRefugio._cilindro(Vector3(0, y + 0.4, 0), 5.0, 0.8, pedra, true, 18)
	VilaRefugio._cilindro(Vector3(0, y + 0.2, 0), 4.2, 0.45, VilaRefugio._mat(Color(0.28, 0.25, 0.22)), false, 18)   # bacia seca
	VilaRefugio._cilindro(Vector3(0, y + 1.8, 0), 0.7, 2.6, pedra, true, 10)
	VilaRefugio._cilindro(Vector3(0, y + 3.4, 0), 1.4, 0.4, pedra, false, 10)
	var rotulo := Label3D.new()
	rotulo.text = "Praça Central: a fonte secou"
	rotulo.font_size = 44
	rotulo.pixel_size = 0.0055
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.position = Vector3(0, y + 4.6, 0)
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(rotulo)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var b := PRACA + Vector2(cos(a), sin(a)) * 8.5
		ConstrutorCasa._movel(self, _solidos, "Bench", b.x, b.y, rad_to_deg(-a) + 90.0, _y(b))
	for k in 4:
		var a := TAU * k / 4.0
		_bandeira(PRACA + Vector2(cos(a), sin(a)) * 14.0, COR_DRAKKAR)
	_fogueira(PRACA + Vector2(11.0, 11.0), 0.5, 9.0)
	_fogueira(PRACA + Vector2(-11.0, 11.0), 0.5, 9.0)


# ---------------------------------------------------------------- distrito do comerciante

## Barraca de mercado de frente para `giro` (0 = olha para o sul). Devolve o ponto do freguês, em frente à bancada.
func _barraca(pos: Vector2, giro: float, titulo: String, cor: Color) -> Vector2:
	var y := _y(pos)
	var f := Vector2(sin(giro), cos(giro))
	var r := Vector2(cos(giro), -sin(giro))
	var madeira := VilaRefugio._mat(Color(0.32, 0.22, 0.12))
	var balcao := pos + f * 0.9
	VilaRefugio._caixa(Vector3(balcao.x, y + 0.5, balcao.y), Vector3(3.4, 1.0, 0.9), madeira, true, giro)
	for lado in [-1.0, 1.0]:   # postes e toldo
		for fr in [-1.0, 1.0]:
			var q: Vector2 = pos + r * lado * 1.7 + f * fr * 1.2
			VilaRefugio._caixa(Vector3(q.x, y + 1.35, q.y), Vector3(0.14, 2.7, 0.14), madeira)
	VilaRefugio._caixa(Vector3(pos.x, y + 2.75, pos.y), Vector3(4.0, 0.12, 3.2), VilaRefugio._mat(cor), false, giro)
	for k in 5:   # estoque visível sobre a bancada e atrás dela
		var q := balcao + r * (-1.3 + k * 0.65)
		VilaRefugio._caixa(Vector3(q.x, y + 1.2, q.y), Vector3(0.45, 0.4, 0.45), VilaRefugio._mat(Color(_rng.randf_range(0.3, 0.8), _rng.randf_range(0.3, 0.6), _rng.randf_range(0.1, 0.4))), false, k * 0.5)
	var estoque := pos - f * 1.0
	ConstrutorCasa._movel(self, _solidos, "Barrel", estoque.x + r.x * 1.2, estoque.y + r.y * 1.2, 0.0, y)
	ConstrutorCasa._movel(self, _solidos, "Chest_Wood", estoque.x - r.x * 1.2, estoque.y - r.y * 1.2, rad_to_deg(giro), y)   # caixa de moedas
	var rotulo := Label3D.new()
	rotulo.text = titulo
	rotulo.font_size = 42
	rotulo.pixel_size = 0.005
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.98, 0.9, 0.65)
	rotulo.position = Vector3(pos.x + f.x * 1.7, y + 3.2, pos.y + f.y * 1.7)
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(rotulo)
	barracas.append(pos)
	return pos + f * 2.2


func _troca(pos: Vector2, texto: String, entrada: String, qin: int, saida: String, qout: int) -> void:
	var g := Gatilho.new()
	g.texto = texto
	g.raio = 1.4
	g.uma_vez = false
	g.position = Vector3(pos.x, _y(pos), pos.y)
	add_child(g)
	g.ao_usar = func(este: Gatilho) -> void:
		este.usado = false
		var jog := get_tree().get_first_node_in_group("jogador") as Jogador
		if jog == null or not jog.gastar_item(entrada, qin):
			GerenciadorMissoes.instancia.aviso.emit("Falta material: precisa de %d %s." % [qin, Itens.nome(entrada)], 2.5)
			return
		jog.coletar(saida, qout)
		GerenciadorMissoes.instancia.aviso.emit("Troca feita: %d %s por %d %s." % [qin, Itens.nome(entrada), qout, Itens.nome(saida)], 2.5)
		GerenciadorMissoes.evento("interagir", "suprimento")
	trocas.append(g)


func _mercador(nome_m: String, papel: String, pos_barraca: Vector2, giro: float, falas: PackedStringArray) -> void:
	var f := Vector2(sin(giro), cos(giro))
	var alvo := pos_barraca + f * 6.0
	var n := _npc(nome_m, papel, "res://scenes/personagens/%s.tscn" % ["dorn" if nome_m in ["Darrik", "Miro"] else "mira"], pos_barraca - f * 0.4, falas,
		[{"esperar": 6.0, "anim": "Idle_Talking", "olhar": alvo}, {"esperar": 4.0, "anim": "Idle", "olhar": alvo}, {"fazer": "Interact", "seg": 4.0, "olhar": alvo}])
	mercadores.append(n)


func _mercado() -> void:
	var m := MERCADO
	var zona := ZonaDeEvento.new()
	zona.id = "mercado_valdoria"
	zona.raio = 16.0
	zona.position = Vector3(m.x, _y(m), m.y)
	add_child(zona)
	var posicoes := [Vector2(30.0, 30.0), Vector2(48.0, 30.0), Vector2(66.0, 30.0), Vector2(30.0, 8.0), Vector2(48.0, 8.0), Vector2(66.0, 8.0)]
	var giros := [PI, PI, PI, 0.0, 0.0, 0.0]
	var cores := [Color(0.6, 0.2, 0.15), Color(0.25, 0.4, 0.3), Color(0.5, 0.4, 0.15), Color(0.2, 0.3, 0.5), Color(0.5, 0.25, 0.4), Color(0.4, 0.4, 0.4)]
	var titulos := ["Poções do Miro", "Comida da Lena", "Armas usadas do Darrik", "Chaves e mapas (psiu)", "Tecidos e fitas", "Frutas secas"]
	var frente: Array[Vector2] = []
	for k in 6:
		frente.append(_barraca(posicoes[k], giros[k], titulos[k], cores[k]))
	_mercador("Miro", "Vendedor de poções", posicoes[0], giros[0], PackedStringArray(["Poções para tudo. Dizem que a do castelo anda cara.", "Se traz raízes do Riacho da Névoa, eu troco por caldo forte."]))
	_mercador("Lena", "Comerciante de alimentos", posicoes[1], giros[1], PackedStringArray(["Pão, carne e maçã. Com a guarda de olho, o preço sobe.", "Rumor: o Imperador não sai do salão do trono desde que o obelisco foi aceso."]))
	_mercador("Darrik", "Vendedor de armas usadas", posicoes[2], giros[2], PackedStringArray(["Espadas de soldados que não voltaram. Barato, pouca pergunta.", "O Vane treina todo dia no pátio do duelo. Cuidado com ele."]))
	_mercador("Suri", "Contrabandista de chaves e mapas", posicoes[3], giros[3], PackedStringArray(["Chaves e mapas, só por troca. Fale baixo.", "O castelo tem estábulos reais, sala de armas, galeria de estandartes e prisão subterrânea."]))
	_troca(frente[0] + Vector2(-0.9, 0.0), "Miro: 2 raízes por 1 carne (caldo forte)", "raiz", 2, "carne", 1)
	_troca(frente[0] + Vector2(0.9, 0.0), "Miro: 3 maçãs por 1 raiz (poção da casa)", "maca", 3, "raiz", 1)
	_troca(frente[1] + Vector2(-0.9, 0.0), "Lena: 2 maçãs por 1 carne", "maca", 2, "carne", 1)
	_troca(frente[1] + Vector2(0.9, 0.0), "Lena: 1 couro por 3 carnes", "couro", 1, "carne", 3)
	_troca(frente[2] + Vector2(-0.9, 0.0), "Darrik: 1 presa por 2 maçãs", "presa", 1, "maca", 2)
	_troca(frente[2] + Vector2(0.9, 0.0), "Darrik: 2 lãs por 2 carnes", "la", 2, "carne", 2)
	_troca(frente[3], "Suri: 1 Ferro Negro bruto por 1 chave", "minerio_bruto", 1, "chave", 1)
	_npc("Freguês Apressado", "Comprador", "res://scenes/personagens/soldado_rebelde.tscn", Vector2(40.0, 19.0), PackedStringArray(["Está tudo caro hoje. Sempre está."]),
		[{"ir": Vector2(56.0, 19.0), "vel": 1.3}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(56.0, 30.0)}, {"ir": Vector2(40.0, 19.0), "vel": 1.3}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(40.0, 8.0)}])
	_placa_em_poste(Vector2(22.0, 19.0), "Distrito do Comerciante")


# ---------------------------------------------------------------- bairro residencial, prédios públicos

func _bairro() -> void:
	var colunas := [[-70.0, PI / 2.0, [60.0, 44.0, 28.0, 12.0, -4.0]], [-56.0, -PI / 2.0, [60.0, 44.0, 28.0, 12.0, -4.0]], [-44.0, PI / 2.0, [50.0, 30.0, 10.0]], [-32.0, -PI / 2.0, [50.0, 30.0, 10.0]]]
	var n := 0
	for col in colunas:
		for z in col[2]:
			var casa := ConstrutorCasa.montar(3, 2, REF.ESTILO_PEDRA if n % 2 == 0 else REF.ESTILO_MADEIRA, true, "moradia")
			casa.name = "Casa%d" % n
			casa.position = Vector3(col[0], altura_em(col[0], z), z)
			casa.rotation.y = col[1]
			add_child(casa)
			casas.append(casa)
			n += 1
	_placa_em_poste(Vector2(-60.0, 70.0), "Bairro dos Moradores")
	for p in [Vector2(-62.0, 52.0), Vector2(-62.0, 20.0), Vector2(-38.0, 40.0), Vector2(-38.0, 20.0), Vector2(-62.0, 4.0)]:   # becos com caixotes e varais
		ConstrutorCasa._movel(self, _solidos, "Barrel", p.x, p.y, 0.0, _y(p))
		ConstrutorCasa._movel(self, _solidos, "Bag", p.x + 1.0, p.y + 1.0, 40.0, _y(p))
	for z in [36.0, 4.0]:
		_muralha(Vector2(-LADO + 1.0, z), Vector2(-71.0, z), 3.0, Color(0.42, 0.38, 0.32))   # muretas que fecham becos sem saída


func _predios_publicos() -> void:
	_edificio("QuartelDaGuarda", Vector2(-52.0, -50.0), PI / 2.0, REF.ESTILO_PEDRA, "Quartel da Guarda", "moradia")
	_edificio("ArmazemDeSuprimentos", Vector2(58.0, -48.0), -PI / 2.0, REF.ESTILO_MADEIRA, "Armazém de Suprimentos", "deposito")
	var capela := ConstrutorCasa.montar(3, 2, REF.ESTILO_PEDRA, true, "vazio")   # capela abandonada: sem telhado novo, com entulho
	capela.name = "CapelaAbandonada"
	capela.position = Vector3(26.0, altura_em(26.0, -52.0), -52.0)
	add_child(capela)
	var rotulo := Label3D.new()
	rotulo.text = "Capela Abandonada"
	rotulo.font_size = 40
	rotulo.pixel_size = 0.0045
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.8, 0.75, 0.65)
	rotulo.position = Vector3(26.0 + capela.get_meta("x_porta"), 3.4, -52.0 + float(capela.get_meta("linhas")) + 0.4)
	add_child(rotulo)
	for k in 5:
		_rocha(Vector2(20.0 + k * 3.2, -44.0), 0.7 + (k % 2) * 0.4, k % 2 == 0, 500.0 + k)
	for p in [Vector2(70.0, -36.0), Vector2(70.0, -50.0), Vector2(46.0, -62.0)]:
		ConstrutorCasa._movel(self, _solidos, "Barrel", p.x, p.y, 0.0, _y(p))
		ConstrutorCasa._movel(self, _solidos, "Chest_Wood", p.x - 1.4, p.y, 20.0, _y(p))
	for p in [Vector2(-70.0, -36.0), Vector2(-66.0, -62.0), Vector2(-38.0, -58.0)]:
		ConstrutorCasa._movel(self, _solidos, "WeaponStand", p.x, p.y, 0.0, _y(p))
	# estábulo da cidade: curral pequeno ao lado do armazém, com cavalo e vaca
	var curral := Vector2(30.0, -28.0)
	_muralha(curral + Vector2(-6, -5), curral + Vector2(6, -5), 1.4, Color(0.3, 0.2, 0.11))
	_muralha(curral + Vector2(-6, -5), curral + Vector2(-6, 5), 1.4, Color(0.3, 0.2, 0.11))
	_muralha(curral + Vector2(6, -5), curral + Vector2(6, 5), 1.4, Color(0.3, 0.2, 0.11))
	for it in [["cavalo", "Cavalo da Cidade", Vector2(-2, 0), 0.28, "cavalo"], ["vaca", "Vaca da Cidade", Vector2(2.5, 1.5), 0.27, "vaca"]]:
		var a := AnimalVila.new()
		a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [it[0], it[0]])
		a.nome = it[1]
		a.especie = it[4]
		a.raio_vagar = 2.0
		a.escala = 1.0
		a.altura_em = altura_em
		a.position = Vector3(curral.x + it[2].x, _y(curral), curral.y + it[2].y)
		add_child(a)


# ---------------------------------------------------------------- escadaria

func _escadaria() -> void:
	var pedra := VilaRefugio._mat(Color(0.55, 0.5, 0.42))
	var comp := 24.0
	var ang := atan2(TOPO_Y, comp)
	var rampa := StaticBody3D.new()   # colisão lisa (o jogador sobe como numa rampa); os degraus abaixo são só o desenho
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(20.0, 0.6, sqrt(comp * comp + TOPO_Y * TOPO_Y) + 1.0)
	cs.shape = forma
	rampa.add_child(cs)
	rampa.position = Vector3(0.0, TOPO_Y / 2.0 - 0.3, -100.0)
	rampa.rotation.x = ang
	add_child(rampa)
	for i in 14:
		var t := (i + 0.5) / 14.0
		VilaRefugio._caixa(Vector3(0.0, TOPO_Y * t - 0.18, NORTE_Z - 4.0 - comp * t), Vector3(20.0, 0.5, comp / 14.0 + 0.1), pedra)
	VilaRefugio._caixa(Vector3(0.0, TOPO_Y / 2.0 - 0.3, -126.0 + 3.0), Vector3(30.0, TOPO_Y, 16.0), pedra, true)   # plataforma do alto
	for lado in [-1.0, 1.0]:
		var mur := VilaRefugio._caixa(Vector3(lado * 11.0, TOPO_Y / 2.0 + 1.0, -100.0), Vector3(1.4, TOPO_Y + 3.0, 26.0), pedra, true)
		mur.rotation = Vector3.ZERO
		for k in 4:
			_bandeira(Vector2(lado * 11.0, -90.0 - k * 8.0), COR_DRAKKAR)
	_placa_em_poste(Vector2(14.0, -80.0), "Escadaria do Castelo Imperial")
	for lado in [-1.0, 1.0]:
		_fogueira(Vector2(lado * 8.0, -78.0), 0.8, 12.0)


# ---------------------------------------------------------------- gente e guardas

func _gente() -> void:
	_npc("Hobb", "Ferreiro", "res://scenes/personagens/dorn.tscn", Vector2(-24.0, 90.0), PackedStringArray(["Forjo para a guarda. Não pergunto para quem é a lâmina."]),
		[{"fazer": "Sword_Attack", "seg": 9.0, "olhar": Vector2(-30.0, 90.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 90.0)}])
	_npc("Rurik", "Carpinteiro", "res://scenes/personagens/oren.tscn", Vector2(-24.0, 66.0), PackedStringArray(["Madeira para as barracas do mercado. Metade já está podre."]),
		[{"fazer": "Interact", "seg": 7.0, "olhar": Vector2(-30.0, 66.0)}, {"ir": Vector2(-24.0, 70.0), "vel": 1.2}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 70.0)}, {"ir": Vector2(-24.0, 66.0), "vel": 1.2}])
	_npc("Yara", "Curtidora", "res://scenes/personagens/mira.tscn", Vector2(24.0, 88.0), PackedStringArray(["Couro de tudo que corre. O Império paga pouco e atrasado."]),
		[{"fazer": "Interact", "seg": 6.0, "olhar": Vector2(30.0, 88.0)}, {"esperar": 4.0, "anim": "Idle_Talking", "olhar": Vector2(0.0, 88.0)}])
	_npc("Pim", "Tecelão", "res://scenes/personagens/nilo.tscn", Vector2(24.0, 66.0), PackedStringArray(["Fiando bandeiras de Drakkar o dia inteiro. Eu preferia fiar cobertores."]),
		[{"fazer": "Interact", "seg": 8.0, "olhar": Vector2(30.0, 66.0)}, {"esperar": 3.0, "anim": "Idle", "olhar": Vector2(0.0, 66.0)}])
	_npc("Jessa", "Varredora", "res://scenes/personagens/cativa.tscn", Vector2(6.0, 12.0), PackedStringArray(["Varro a praça todo dia. A fonte seca não ajuda."]),
		[{"fazer": "Interact", "seg": 8.0, "olhar": Vector2(6.0, 20.0)}, {"ir": Vector2(-8.0, 12.0), "vel": 1.0}, {"fazer": "Interact", "seg": 8.0, "olhar": Vector2(-8.0, 20.0)}, {"ir": Vector2(6.0, 12.0), "vel": 1.0}])
	_npc("Bram", "Carregador", "res://scenes/personagens/soldado_ferido.tscn", Vector2(52.0, -40.0), PackedStringArray(["Caixas para o mercado, sempre. As costas não perdoam."]),
		[{"ir": Vector2(48.0, 2.0), "vel": 1.6}, {"esperar": 4.0, "anim": "Interact", "olhar": Vector2(48.0, 8.0)}, {"ir": Vector2(52.0, -40.0), "vel": 1.6}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(58.0, -48.0)}])
	_npc("Ollo", "Tratador de animais", "res://scenes/personagens/orin.tscn", Vector2(36.0, -24.0), PackedStringArray(["O cavalo da cidade come mais que eu. Não me queixo."]),
		[{"fazer": "Interact", "seg": 6.0, "olhar": Vector2(30.0, -28.0)}, {"ir": Vector2(36.0, -30.0), "vel": 1.2}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(30.0, -28.0)}, {"ir": Vector2(36.0, -24.0), "vel": 1.2}])
	_npc("Corretor Ágil", "Discutindo preços", "res://scenes/personagens/soldado_rebelde.tscn", Vector2(-4.0, 30.0), PackedStringArray(["Dobrou o preço do pão! Você vê isso?"]),
		[{"esperar": 6.0, "anim": "Idle_Talking", "olhar": Vector2(4.0, 30.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(4.0, 30.0)}])
	_npc("Comprador Zangado", "Discutindo preços", "res://scenes/personagens/cativo.tscn", Vector2(4.0, 30.0), PackedStringArray(["Pago o que sempre paguei, nem um tostão a mais."]),
		[{"esperar": 5.0, "anim": "Idle_Talking", "olhar": Vector2(-4.0, 30.0)}, {"esperar": 5.0, "anim": "Idle", "olhar": Vector2(-4.0, 30.0)}])
	var tico := _npc("Tico", "Menino curioso", "res://scenes/personagens/nilo.tscn", Vector2(-4.0, 100.0), PackedStringArray(["Você veio no dragão? Posso ver de perto?"]), [])
	tico.segue_jogador = true   # reage ao Fagulha, como as crianças do Refúgio


func _guarda_comum(pos: Vector2) -> void:
	_inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(pos.x, _y(pos) + 0.2, pos.y), "Guarda de Valdoria", "guarda_valdoria")


func _guardas() -> void:
	for p in [Vector2(-8.0, 104.0), Vector2(8.0, 104.0), Vector2(-50.0, -44.0), Vector2(-50.0, -56.0)]:
		_guarda_comum(p)
	for p in [Vector2(-10.0, -30.0), Vector2(10.0, -30.0), Vector2(-8.0, -66.0), Vector2(8.0, -66.0)]:   # guarda de elite diante da escadaria
		var g := (load("res://scenes/inimigos/guarda_imperial.tscn") as PackedScene).instantiate() as Inimigo
		g.nome = "Guarda de Elite"
		g.especie = "guarda_elite"
		g.vida_max = 160
		g.dano = 14
		g.velocidade = 4.0
		g.position = Vector3(p.x, _y(p) + 0.2, p.y)
		add_child(g)
		elite.append(g)
