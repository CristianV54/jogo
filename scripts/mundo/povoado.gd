class_name Povoado
extends Node3D
## Povoado ou fazenda no caminho entre duas regiões (coordenadas do MUNDO). Cada tipo monta o que uma comunidade assim teria:
##   "fazenda": casa, celeiro, duas plantações vivas, poço, curral com animais e fazendeiros que trabalham os campos;
##   "vila": casas, taverna, ferraria, poço, plantações, curral, taverneiro, ferreiro, fazendeiros e uma criança;
##   "cabana": cabana de lenhador, pilha de lenha, cepo e o lenhador cortando;
##   "posto": acampamento rebelde com tendas, fogueira e soldados do Vane;
##   "posto_imperial": estalagem da estrada imperial, carroças, mercador e guardas imperiais;
##   "bairro": bairro do reino (dentro da muralha): uma rua com casas dos dois lados, poço, bancos e moradores;
##   "quartel": quartel da guarda com campo de treino (bonecos, alvos, soldados treinando, capitão);
##   "estabulo": estábulos do reino, com cavalos que dá para montar, feno, bebedouro e cavalariço;
##   "catedral": a Catedral de Valdoria (nave, torre do sino, adro e sacristão);
##   "guarita": sentinelas de um portão da muralha, com braseiro;
##   "mercado": praça de mercado do reino: barracas em volta de uma fogueira, carroças, caixotes e mercadores.

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")

var mundo: Mundo
var dados: Dictionary
var centro := Vector2.ZERO
var dir := Vector2.RIGHT      # sentido da estrada
var para_longe := Vector2.UP  # da estrada para dentro do povoado
var npcs: Array[Npc] = []
var animais: Array[AnimalVila] = []
var bonecos: Array[BonecoDeTreino] = []
var _solidos: StaticBody3D
var balcoes: Array[Gatilho] = []
var bigornas: Array[Gatilho] = []
var _pecas: PecasDaRua   # peças do kit da rua usadas no largo deste povoado (criado só se o tipo usar)
var _rng := RandomNumberGenerator.new()


func montar() -> void:
	name = String(dados["id"])
	centro = dados["centro"]
	dir = dados["dir"]
	para_longe = Vector2(-dir.y, dir.x) * float(dados["lado"])
	_rng.seed = hash(String(dados["id"]))
	_solidos = StaticBody3D.new()
	_solidos.name = "Solidos"
	add_child(_solidos)
	VilaRefugio.preparar(self, mundo.terreno.altura_em, _solidos)   # as ajudantes de cerca, caixa e poço usam este estado
	match String(dados["tipo"]):
		"fazenda":
			_fazenda()
		"vila":
			_vila()
		"cabana":
			_cabana()
		"pescador":
			_pescador()
		"posto":
			_posto()
		"bairro":
			_bairro()
		"mercado":
			_mercado()
		"quartel":
			_quartel()
		"estabulo":
			_estabulo()
		"guarita":
			_guarita()
		"catedral":
			_catedral()
		"lavoura":
			_lavoura()
		_:
			_posto_imperial()
	if String(dados["id"]) in ["pedras_altas", "mineiros", "posto_de_caca"] or (centro.distance_to(MundoDados.MONTANHA_CENTRO) < 1100.0 and String(dados["tipo"]) in ["vila", "posto", "cabana"]):
		for k in 3:   # povoados da serra: veios de ferro na beira
			_veio(_p(-26.0 + k * 9.0, float(dados["raio"]) * 0.55 + k * 2.0))
	if _pecas != null:
		_pecas.fechar()
	if String(dados["tipo"]) != "guarita":   # a guarita não tem placa: fica em cima da estrada
		_placa(_p(-6.0, -float(dados["raio"]) * 0.45), String(dados["nome"]))


# ---------------------------------------------------------------- ajudantes

## O kit de peças da rua deste povoado (lampião, carroça, barraca...), criado na primeira vez que alguém pede.
func _kit() -> PecasDaRua:
	if _pecas == null:
		_pecas = PecasDaRua.new()
		_pecas.name = "Pecas"
		add_child(_pecas)
	return _pecas


## Balcão de mercador: E abre a janela de comprar, vender e pechinchar com a lista `oferta`.
func _balcao(p: Vector2, nome_m: String, oferta: Array) -> void:
	var g := Gatilho.new()
	g.texto = "Negociar com %s" % nome_m
	g.raio = 2.2
	g.uma_vez = false
	g.position = _chao(p)
	add_child(g)
	g.ao_usar = func(este: Gatilho) -> void:
		este.usado = false
		var jogo := get_tree().get_first_node_in_group("jogo")
		if jogo:
			jogo.abrir_oficio("loja", oferta, nome_m)
	balcoes.append(g)


## Bigorna de ferreiro: E abre a forja (as receitas de Itens.RECEITAS).
func _bigorna(p: Vector2) -> void:
	_movel("Anvil", p)
	var g := Gatilho.new()
	g.texto = "Forjar na bigorna"
	g.raio = 2.0
	g.uma_vez = false
	g.position = _chao(p)
	add_child(g)
	g.ao_usar = func(este: Gatilho) -> void:
		este.usado = false
		var jogo := get_tree().get_first_node_in_group("jogo")
		if jogo:
			jogo.abrir_oficio("forja", [], "Forja")
	bigornas.append(g)


func _veio(p: Vector2) -> void:
	var v := VeioDeFerro.new()
	v.position = _chao(p)
	add_child(v)


func _chao(p: Vector2) -> Vector3:
	return Vector3(p.x, _y(p), p.y)


## Terreiro: o chão pisado do largo do povoado (terra batida com pedras), uma mancha de borda irregular colada no terreno.
func _terreiro(p: Vector2, raio: float, cor := Color(0.62, 0.52, 0.4)) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aneis := 5
	var gomos := 28
	var ponto := func(i: int, k: int) -> Vector3:
		var a := TAU * k / gomos
		var r := raio * i / aneis * (1.0 + (0.1 * sin(a * 3.0 + raio) + 0.07 * sin(a * 7.0)) * float(i) / aneis)
		var q := p + Vector2(cos(a), sin(a)) * r
		return Vector3(q.x, _y(q) + 0.05, q.y)
	for i in aneis:
		for k in gomos:
			for canto in [[i, k], [i + 1, k + 1], [i + 1, k], [i, k], [i, k + 1], [i + 1, k + 1]]:
				st.set_normal(Vector3.UP)
				st.add_vertex(ponto.call(int(canto[0]), int(canto[1])))
	var mi := MeshInstance3D.new()
	mi.name = "Terreiro"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_texture = Pedra.calcamento()
	m.albedo_color = cor
	m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.22, 0.22, 0.22)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Ponto do mundo: `u` ao longo da estrada, `v` para dentro do povoado (a partir do centro).
func _p(u: float, v: float) -> Vector2:
	return centro + dir * u + para_longe * v


func _y(p: Vector2) -> float:
	return mundo.terreno.altura_em(p.x, p.y)


## Cor das casas deste povoado: cada tipo (e cada povoado do mesmo tipo) tem a sua, para não ser tudo igual.
func _paleta() -> Dictionary:
	var opcoes: Array
	match String(dados["tipo"]):
		"fazenda":   # palha e taipa, madeira escura ou caiada com telha
			opcoes = [{"parede": Color(0.66, 0.5, 0.34), "telhado": Color(0.86, 0.7, 0.34)}, {"parede": Color(0.5, 0.37, 0.25), "telhado": Color(0.62, 0.5, 0.3)}, {"parede": Color(1.0, 0.96, 0.86), "telhado": Color(0.95, 0.75, 0.55)}]
		"bairro":    # bairros do reino: reboco claro com telha, cada bairro com o seu tom
			opcoes = [{"parede": Color(1.0, 0.9, 0.75), "telhado": Color(0.85, 0.5, 0.38)}, {"parede": Color(0.9, 0.86, 0.8), "telhado": Color(0.55, 0.5, 0.58)}, {"parede": Color(0.95, 0.8, 0.62), "telhado": Color(0.6, 0.38, 0.32)}, {"parede": Color(0.82, 0.84, 0.9), "telhado": Color(0.45, 0.5, 0.62)}]
		"vila":      # blocos de pedra: cinza com ardósia ou arenito quente com telha
			opcoes = [{"parede": Color(0.82, 0.84, 0.9), "telhado": Color(0.5, 0.5, 0.58)}, {"parede": Color(1.0, 0.88, 0.7), "telhado": Color(1.0, 0.9, 0.85)}, {"parede": Color(0.75, 0.78, 0.76), "telhado": Color(0.62, 0.42, 0.34)}]
		"cabana":
			opcoes = [{"parede": Color(0.42, 0.31, 0.2), "telhado": Color(0.55, 0.45, 0.28)}, {"parede": Color(0.55, 0.52, 0.48), "telhado": Color(0.45, 0.4, 0.3)}]
		"pescador":
			opcoes = [{"parede": Color(0.5, 0.45, 0.36), "telhado": Color(0.42, 0.34, 0.26)}]
		"posto_imperial":
			opcoes = [{"parede": Color(0.55, 0.55, 0.62), "telhado": Color(0.3, 0.3, 0.38)}]
		_:
			opcoes = [{"parede": Color(0.5, 0.42, 0.34), "telhado": Color(0.45, 0.4, 0.34)}]
	return opcoes[hash(String(dados["id"])) % opcoes.size()]


func _casa(nome_c: String, p: Vector2, colunas: int, linhas: int, estilo: Dictionary, interior := "moradia") -> Node3D:
	var casa := ConstrutorCasa.montar(colunas, linhas, estilo, true, interior, _paleta())
	casa.name = nome_c
	casa.position = Vector3(p.x, _y(p), p.y)
	casa.rotation.y = atan2(-para_longe.x, -para_longe.y)   # a porta (+Z local) olha para a estrada
	add_child(casa)
	return casa


## Lado da cerca (n, s, o, l) que olha para a estrada: é por onde se entra e se sai.
func _lado_da_estrada() -> String:
	if absf(para_longe.x) > absf(para_longe.y):
		return "o" if para_longe.x > 0.0 else "l"
	return "n" if para_longe.y > 0.0 else "s"


## Campo de cultivo: o bloco de talhões, a cerca e o espantalho são um conjunto só, alinhado com o povoado (o portão olha
## para o quintal, do lado da estrada).
func _plantacao(p: Vector2, larg: float, prof: float) -> void:
	var pl := Plantacao.new()
	pl.largura = larg
	pl.profundidade = prof
	pl.position = Vector3(p.x, _y(p), p.y)
	pl.rotation.y = atan2(para_longe.x, para_longe.y)   # +Z do campo aponta para dentro do povoado; o portão fica em -Z
	add_child(pl)


## Palheiro: fardos redondos e um monte de feno, junto ao celeiro ou ao curral (nunca dentro do campo).
func _feno(p: Vector2) -> void:
	var feno := VilaRefugio._mat(Color(0.66, 0.5, 0.2))
	var y := _y(p)
	for k in 3:
		var fardo := VilaRefugio._cilindro(Vector3(p.x + (k % 2) * 1.2, y + 0.55 + (0.95 if k == 2 else 0.0), p.y + (k % 2) * 0.3 + (0.3 if k == 2 else 0.0)), 0.55, 1.0, feno, false, 12)
		fardo.rotation_degrees.x = 90.0
		fardo.rotation.y = atan2(dir.x, dir.y)
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()   # monte de feno cônico
	cm.top_radius = 0.1
	cm.bottom_radius = 1.4
	cm.height = 2.2
	cm.material = feno
	cone.mesh = cm
	cone.position = Vector3(p.x + 3.6, y + 1.1, p.y)
	add_child(cone)
	var cs := CollisionShape3D.new()
	var f := BoxShape3D.new()
	f.size = Vector3(5.2, 1.8, 2.4)
	cs.shape = f
	cs.position = Vector3(p.x + 1.8, y + 0.9, p.y)
	_solidos.add_child(cs)


## Bebedouro de tronco, dentro do curral ou ao lado do celeiro.
func _bebedouro(p: Vector2) -> void:
	var y := _y(p)
	var g := atan2(dir.x, dir.y)
	VilaRefugio._caixa(Vector3(p.x, y + 0.25, p.y), Vector3(1.8, 0.5, 0.7), VilaRefugio._mat(Color(0.3, 0.2, 0.11)), true, g)
	var agua := MeshInstance3D.new()
	var a := BoxMesh.new()
	a.size = Vector3(1.5, 0.04, 0.45)
	var m := VilaRefugio._mat(Color(0.12, 0.3, 0.5, 0.85))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	a.material = m
	agua.mesh = a
	agua.position = Vector3(p.x, y + 0.48, p.y)
	agua.rotation.y = g
	add_child(agua)


func _placa(p: Vector2, texto: String) -> void:
	var y := _y(p)
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	VilaRefugio._caixa(Vector3(p.x, y + 1.3, p.y), Vector3(0.18, 2.6, 0.18), madeira, true)
	VilaRefugio._caixa(Vector3(p.x, y + 2.2, p.y), Vector3(2.8, 0.5, 0.08), madeira, false, atan2(dir.x, dir.y))
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.font_size = 44
	rotulo.pixel_size = 0.0048
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	rotulo.position = Vector3(p.x, y + 2.2, p.y)
	add_child(rotulo)


func _npc(nome_n: String, papel: String, cena: String, p: Vector2, falas: PackedStringArray, rotina: Array) -> Npc:
	var n := Npc.new()
	n.nome = nome_n
	n.papel = papel
	n.falas = falas
	n.cena = load("res://scenes/personagens/%s.tscn" % cena)
	for passo in rotina:
		for chave in ["ir", "olhar"]:
			if passo.has(chave) and passo[chave] is Vector2:
				var v: Vector2 = passo[chave]
				passo[chave] = Vector3(v.x, _y(v), v.y)
	n.rotina = rotina
	n.altura_em = mundo.terreno.altura_em
	n.position = Vector3(p.x, _y(p), p.y)
	add_child(n)
	npcs.append(n)
	return n


func _animal(modelo: String, nome_a: String, especie: String, p: Vector2, esc: float, vagar: float, vida: int, drops: Dictionary, fugitivo := false, acess := "") -> void:
	var a := AnimalVila.new()
	a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [modelo, modelo])
	a.nome = nome_a
	a.especie = especie
	a.acessorio = acess
	a.escala = esc
	a.raio_vagar = vagar
	a.vida_max = vida
	a.fugitivo = fugitivo
	a.montavel = modelo == "cavalo"   # todo cavalo de vila, fazenda ou estábulo pode ser montado (E)
	a.drops = drops
	a.altura_em = mundo.terreno.altura_em
	a.position = Vector3(p.x, _y(p), p.y)
	add_child(a)
	animais.append(a)


func _curral(p: Vector2, larg: float, prof: float, bichos: Array) -> void:
	VilaRefugio._cerca_retangular(Vector3(p.x, _y(p), p.y), larg, prof, _lado_da_estrada(), 3.4)
	_bebedouro(p + Vector2(larg / 2.0 - 1.6, prof / 2.0 - 1.1))   # a água fica dentro do curral, junto à cerca do fundo
	for b in bichos:   # [modelo, nome, especie, escala, drops]
		var q := p + Vector2(_rng.randf_range(-larg / 3.5, larg / 3.5), _rng.randf_range(-prof / 3.5, prof / 3.5))   # longe do bebedouro e da cerca
		_animal(b[0], b[1], b[2], q, b[3], 2.0, 30, b[4])


func _fogueira(p: Vector2, escala := 0.9) -> void:
	var f := Fogo.new()
	f.escala = escala
	f.energia_luz = 2.0
	f.alcance_luz = 12.0
	f.position = Vector3(p.x, _y(p) + 0.15, p.y)
	add_child(f)


func _tenda(p: Vector2, cor: Color) -> void:
	_kit().tenda(_chao(p), -para_longe, cor)


func _movel(nome_m: String, p: Vector2, giro := 0.0) -> void:
	ConstrutorCasa._movel(self, _solidos, nome_m, p.x, p.y, giro, _y(p))


func _lavrador(nome_n: String, cena: String, campo: Vector2, falas: PackedStringArray) -> void:
	var a := campo + dir * -6.0
	var b := campo + dir * 6.0
	_npc(nome_n, "Lavrador", cena, a, falas, [
		{"fazer": "Interact", "seg": 9.0, "olhar": campo + para_longe * 3.0}, {"ir": b, "vel": 1.1},
		{"fazer": "Interact", "seg": 9.0, "olhar": campo + para_longe * 3.0}, {"ir": a, "vel": 1.1}])


# ---------------------------------------------------------------- tipos

func _fazenda() -> void:
	_terreiro(_p(0.0, 10.0), 17.0)
	_kit().carroca(_chao(_p(30.0, -1.0)), dir)
	_kit().carga(_chao(_p(13.0, -1.5)), dir, 3, _rng.randi() % 20)
	_kit().lampiao_de_poste(_chao(_p(-9.0, -2.0)), para_longe)
	_casa("CasaDaFazenda", _p(0.0, 4.0), 3, 3, REF.ESTILO_MADEIRA)
	_casa("Celeiro", _p(-22.0, 10.0), 4, 4, REF.ESTILO_MADEIRA, "deposito")
	var c1 := _p(0.0, 43.0)   # um campo grande atrás da casa, com o poço e o palheiro no quintal entre os dois
	var c2 := c1
	_casa("Anexo", _p(17.0, 4.0), 2, 2, REF.ESTILO_MADEIRA)   # quarto dos lavradores
	_plantacao(c1, 32.0, 18.0)
	_feno(_p(-12.0, 16.0))
	VilaRefugio._poco(Vector3(_p(10.0, 8.0).x, 0.0, _p(10.0, 8.0).y))
	_curral(_p(-30.0, 28.0), 14.0, 10.0, [["vaca", "Vaca", "vaca", 1.0, {"carne": [2, 3], "couro": [1, 1]}], ["vaca", "Vaca", "vaca", 1.0, {"carne": [2, 3], "couro": [1, 1]}], ["ovelha", "Ovelha", "ovelha", 1.0, {"carne": [1, 2], "la": [1, 2]}]])
	for k in 4:
		_animal("galinha", "Galinha", "galinha", _p(-9.0 + k * 3.0, -3.0), 1.0, 3.0, 8, {"carne": [1, 1]})
	_lavrador("Hugo", "oren", c1, PackedStringArray(["Planto trigo e milho desde menino. O Império leva metade, e eu agradeço quando levam só metade.", "Chuva boa essa semana. Pena que o céu anda carregado."]))
	_lavrador("Marta", "tessa", c2 + dir * 10.0, PackedStringArray(["As abóboras estão no ponto. Quer uma? Não posso dar de graça, o patrão conta tudo."]))
	_npc("Caio", "Pastor", "nilo", _p(-20.0, 22.0), PackedStringArray(["Cuido das vacas e das ovelhas. O lobo ronda à noite, por isso as recolho cedo."]),
		[{"fazer": "Interact", "seg": 7.0, "olhar": _p(-30.0, 28.0)}, {"ir": _p(-14.0, 24.0), "vel": 1.0}, {"esperar": 5.0, "anim": "Idle", "olhar": _p(-30.0, 28.0)}, {"ir": _p(-20.0, 22.0), "vel": 1.0}])


func _vila() -> void:
	_terreiro(_p(0.0, 16.0), 24.0)
	for u in [-15.0, 15.0]:
		_kit().lampiao_de_poste(_chao(_p(u, -2.0)), para_longe)
	_kit().lampiao_de_poste(_chao(_p(3.0, 20.0)), -para_longe)
	_kit().carroca(_chao(_p(-36.0, -1.0)), dir)
	_kit().barraca(_chao(_p(36.0, 1.0)), -para_longe, [Color(0.72, 0.2, 0.16), Color(0.25, 0.42, 0.62), Color(0.3, 0.52, 0.3)][_rng.randi() % 3], [Color(0.8, 0.2, 0.15), Color(0.9, 0.7, 0.2), Color(0.4, 0.6, 0.25)])
	_kit().carga(_chao(_p(31.0, 0.0)), dir, 2, _rng.randi() % 20)
	_balcao(_p(36.0, -1.2), "o mercador da vila", ["pao", "maca", "madeira", "picareta", "couro"])
	_bigorna(_p(-10.5, 22.5))
	_kit().estandarte(_chao(_p(-8.0, -3.0)), -para_longe)   # ao lado da porta da taverna, não na frente
	_casa("Taverna", _p(0.0, 6.0), 4, 4, REF.ESTILO_PEDRA, "moradia")
	_casa("Casa1", _p(-24.0, 6.0), 3, 2, REF.ESTILO_PEDRA)
	_casa("Casa2", _p(24.0, 6.0), 3, 2, REF.ESTILO_PEDRA)
	_casa("Ferraria", _p(-14.0, 26.0), 3, 3, REF.ESTILO_PEDRA, "forja")
	_casa("Casa3", _p(14.0, 28.0), 3, 2, REF.ESTILO_PEDRA)
	VilaRefugio._poco(Vector3(_p(0.0, 16.0).x, 0.0, _p(0.0, 16.0).y))
	var c1 := _p(-34.0, 42.0)
	var c2 := _p(30.0, 46.0)
	_plantacao(c1, 22.0, 14.0)
	_plantacao(c2, 22.0, 14.0)
	_feno(_p(14.0, 44.0))
	_curral(_p(0.0, 48.0), 16.0, 10.0, [["porco", "Porco", "porco", 1.0, {"carne": [2, 3]}], ["porco", "Porco", "porco", 1.0, {"carne": [2, 3]}], ["cavalo", "Cavalo", "cavalo", 1.0, {"carne": [2, 3], "couro": [1, 1]}]])
	_movel("Table_Large", _p(-6.0, 14.0))
	_movel("Bench", _p(-6.0, 12.0), 90.0)
	_movel("Barrel", _p(6.0, 14.0))
	_fogueira(_p(-2.0, 18.0), 0.7)
	_lavrador("Tomás", "oren", c1, PackedStringArray(["Esta vila vive do campo e da estrada. Quem passa para o leste costuma voltar assustado."]))
	_lavrador("Ana", "tessa", c2, PackedStringArray(["Colhemos antes da tempestade. O trovão assusta as ovelhas."]))
	_npc("Bento", "Taverneiro", "dorn", _p(0.0, 11.0), PackedStringArray(["Pão, cerveja e boatos de graça. Dizem que o Vane montou acampamento a leste, e que ele mudou."]),
		[{"fazer": "Interact", "seg": 7.0, "olhar": _p(0.0, 14.0)}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": _p(0.0, 18.0)}])
	_npc("Ferreiro Orlo", "Ferreiro", "orin", _p(-14.0, 21.0), PackedStringArray(["Ferradura, enxada, foice. Espada só para quem prova que não é do Império."]),
		[{"fazer": "Sword_Attack", "seg": 9.0, "olhar": _p(-19.0, 21.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": _p(0.0, 16.0)}])
	_npc("Lia", "Moleca", "mira", _p(8.0, 20.0), PackedStringArray(["Meu pai disse que tem um dragão no Refúgio. É verdade?"]), [])
	_npc("Mercador Davi", "Mercador de feira", "soldado_rebelde", _p(10.0, 14.0), PackedStringArray(["Compro peles e lã. Vendo sal e notícias."]),
		[{"esperar": 6.0, "anim": "Idle_Talking", "olhar": _p(0.0, 14.0)}, {"ir": _p(16.0, 14.0), "vel": 1.2}, {"esperar": 5.0, "anim": "Idle", "olhar": _p(0.0, 14.0)}, {"ir": _p(10.0, 14.0), "vel": 1.2}])


## Bairro do reino: uma rua de terra com quatro casas de cada lado, uma de frente para a outra, poço no meio, bancos,
## barris e gente morando. Sem plantação nem curral: é cidade.
func _bairro() -> void:
	var frente := atan2(-para_longe.x, -para_longe.y)   # porta olhando para a rua do anel
	var n := 0
	for u in [-33.0, -11.0, 11.0, 33.0]:
		for fila in [[10.0, frente + PI], [36.0, frente]]:   # a fila de perto olha para dentro, a de longe olha para a rua
			var p := _p(u, float(fila[0]))
			var casa := ConstrutorCasa.montar(3, 2 + n % 2, REF.ESTILO_PEDRA if n % 3 != 0 else REF.ESTILO_MADEIRA, true, "moradia", _paleta())
			casa.name = "Casa%d" % n
			casa.position = Vector3(p.x, _y(p), p.y)
			casa.rotation.y = float(fila[1])
			add_child(casa)
			n += 1
	VilaRefugio._poco(Vector3(_p(0.0, 23.0).x, 0.0, _p(0.0, 23.0).y))
	for u in [-22.0, 22.0]:
		_movel("Bench", _p(u, 23.0), 90.0)
		_movel("Barrel", _p(u + 2.0, 21.0))
		_fogueira(_p(u * 1.9, 23.0), 0.4)   # lampiões nas pontas da rua
	_npc("Moradora do bairro", "Moradora", "tessa", _p(-4.0, 21.0), PackedStringArray(["Dentro da muralha a gente dorme sem medo de lobo. O medo aqui é outro, e usa armadura."]),
		[{"esperar": 6.0, "anim": "Idle_Talking", "olhar": _p(0.0, 23.0)}, {"ir": _p(-20.0, 23.0), "vel": 1.1}, {"esperar": 4.0, "anim": "Idle", "olhar": _p(-22.0, 23.0)}, {"ir": _p(-4.0, 21.0), "vel": 1.1}])
	_npc("Morador do bairro", "Morador", "oren", _p(18.0, 25.0), PackedStringArray(["O castelo vê tudo lá de cima. Fale baixo."]),
		[{"esperar": 7.0, "anim": "Idle", "olhar": _p(22.0, 23.0)}, {"ir": _p(4.0, 25.0), "vel": 1.0}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": _p(0.0, 23.0)}, {"ir": _p(18.0, 25.0), "vel": 1.0}])
	_npc("Criança do bairro", "Criança", "mira", _p(6.0, 19.0), PackedStringArray(["Você veio de fora da muralha? Tem dragão lá?"]), [])


## Praça de mercado: oito barracas coloridas em volta de uma fogueira, carroças de carga, caixotes, barris e mercadores
## chamando freguês. É o que cerca o reino de comércio (dentro da muralha e do lado de fora dos portões).
func _mercado() -> void:
	var cores := [Color(0.72, 0.2, 0.16), Color(0.85, 0.7, 0.3), Color(0.25, 0.42, 0.62), Color(0.3, 0.52, 0.3), Color(0.62, 0.36, 0.6), Color(0.85, 0.82, 0.74)]
	var meio := _p(0.0, 22.0)
	var kit := PecasDaRua.new()   # barracas e carroças do kit da rua (ver tools/bancada_construcao.gd -- feira)
	kit.name = "Feira"
	add_child(kit)
	var mercadorias := [[Color(0.8, 0.2, 0.15), Color(0.9, 0.7, 0.2), Color(0.4, 0.6, 0.25)], [Color(0.85, 0.8, 0.6), Color(0.6, 0.3, 0.5), Color(0.3, 0.4, 0.65)], [Color(0.55, 0.5, 0.48), Color(0.35, 0.33, 0.32), Color(0.7, 0.55, 0.3)], [Color(0.9, 0.82, 0.5), Color(0.75, 0.45, 0.25), Color(0.9, 0.9, 0.85)]]
	for k in 8:
		var a := TAU * k / 8.0
		var q := meio + Vector2(cos(a), sin(a)) * 15.0
		kit.barraca(Vector3(q.x, _y(q), q.y), -Vector2(cos(a), sin(a)), cores[k % cores.size()], mercadorias[k % mercadorias.size()])
		_movel("Barrel" if k % 2 == 0 else "Bag", q + Vector2(cos(a + 0.5), sin(a + 0.5)) * 3.4)
	if String(dados["id"]) != "mercado_central":   # na praça do mercado de Valdoria o meio é da fonte (ver VidaDasRuas)
		_fogueira(meio, 0.8)
		_movel("Table_Large", meio + Vector2(4.0, 0.0))
		_movel("Bench", meio + Vector2(4.0, 2.0), 90.0)
	for k in 2:   # carroças de carga na beira da praça
		var q := _p(-26.0 + k * 52.0, 8.0)
		kit.carroca(Vector3(q.x, _y(q), q.y), dir)
	kit.fechar()
	var lojas := [["o mercador de panos", ["couro", "la", "armadura_de_couro"]], ["a mercadora de sal", ["pao", "peixe_assado", "carne", "raiz"]], ["o mercador de ferragens", ["picareta", "machado", "madeira", "lingote_de_ferro", "espada_longa"]], ["a mercadora de frutas", ["maca", "pao"]]]
	for k in 4:   # comércio de verdade: em quatro barracas compra-se, vende-se e pechincha-se (E no balcão)
		var a := TAU * (k * 2) / 8.0
		_balcao(meio + Vector2(cos(a), sin(a)) * 12.4, String(lojas[k][0]), lojas[k][1])
	_bigorna(meio + Vector2(7.0, 7.0))
	var falas := [["Mercador de panos", "Lã, linho e couro curtido. Pago bem por pele de lobo."], ["Mercadora de sal", "Sal, ervas e peixe seco. Sem sal a carne não dura a viagem."],
		["Mercador de ferragens", "Prego, ferradura e lâmina cega. Afiar é com o ferreiro."], ["Mercadora de frutas", "Maçã do Pomar Alto, colhida ontem. Prove uma."]]
	var modelos := ["soldado_rebelde", "tessa", "orin", "mira"]
	for k in 4:
		var a := TAU * (k * 2) / 8.0
		var q := meio + Vector2(cos(a), sin(a)) * 11.0
		_npc(String(falas[k][0]), "Mercador", modelos[k], q, PackedStringArray([String(falas[k][1])]),
			[{"esperar": 6.0, "anim": "Idle_Talking", "olhar": meio}, {"esperar": 4.0, "anim": "Idle", "olhar": meio + Vector2(cos(a), sin(a)) * 15.0}])


## Soldado da guarda do reino: gente (não ataca o Torin), com o corpo do guarda imperial.
func _soldado(nome_s: String, papel: String, p: Vector2, fala: String, rotina: Array) -> Npc:
	return _npc(nome_s, papel, "guarda_imperial", p, PackedStringArray([fala]), rotina)


## Quartel da guarda: o prédio, o campo de treino com seis bonecos e três alvos de palha, soldados treinando golpe,
## o capitão olhando, braseiros e bandeiras.
func _quartel() -> void:
	_bigorna(_p(-22.0, 34.0))
	_casa("Quartel", _p(0.0, 44.0), 5, 3, REF.ESTILO_PEDRA, "deposito")
	_casa("Arsenal", _p(-30.0, 42.0), 3, 3, REF.ESTILO_PEDRA, "deposito")
	for k in 6:   # bonecos de treino em duas filas
		var q := _p(-15.0 + (k % 3) * 15.0, 8.0 + (k / 3) * 12.0)
		var b := BonecoDeTreino.new()
		b.position = Vector3(q.x, _y(q), q.y)
		add_child(b)
		bonecos.append(b)
	var kit := PecasDaRua.new()   # peças do campo de treino (ver tools/bancada_construcao.gd -- quartel)
	kit.name = "CampoDeTreino"
	add_child(kit)
	for k in 3:   # alvos de arco
		var q := _p(26.0, 6.0 + k * 9.0)
		kit.alvo_de_arco(Vector3(q.x, _y(q), q.y), -dir)
	for k in 4:   # cavaletes de armas diante do quartel e do arsenal
		var q := _p(-36.0 + k * 12.0, 34.0)
		kit.cavalete_de_armas(Vector3(q.x, _y(q), q.y), -para_longe)
	for q2 in [_p(-34.0, 2.0), _p(34.0, 2.0), _p(-34.0, 30.0), _p(34.0, 30.0)]:   # estandartes do rei nos cantos do campo
		kit.estandarte(Vector3(q2.x, _y(q2), q2.y), para_longe)
	kit.carroca(Vector3(_p(-40.0, 16.0).x, _y(_p(-40.0, 16.0)), _p(-40.0, 16.0).y), dir)
	kit.fechar()
	for u in [-24.0, 24.0]:
		_fogueira(_p(u, 28.0), 0.6)
	for k in 3:   # soldados treinando, cada um no seu boneco
		var q := _p(-15.0 + k * 15.0, 5.6)
		_soldado("Soldado da guarda", "Soldado", q, ["Cem golpes antes do almoço. O capitão conta.", "O boneco não reclama. O capitão, sim.", "Dizem que lá fora tem lobo do tamanho de um potro."][k],
			[{"fazer": "Sword_Attack", "seg": 8.0, "olhar": _p(-15.0 + k * 15.0, 8.0)}, {"esperar": 3.0, "anim": "Idle", "olhar": _p(-15.0 + k * 15.0, 8.0)}])
	_soldado("Capitão da guarda", "Capitão", _p(0.0, 30.0), "Aqui se treina até o braço cair. Quer tentar? Os bonecos de trás estão livres.",
		[{"esperar": 6.0, "anim": "Idle", "olhar": _p(0.0, 10.0)}, {"ir": _p(-18.0, 30.0), "vel": 1.1}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": _p(-15.0, 10.0)}, {"ir": _p(18.0, 30.0), "vel": 1.1}, {"esperar": 5.0, "anim": "Idle", "olhar": _p(15.0, 10.0)}, {"ir": _p(0.0, 30.0), "vel": 1.1}])


## Estábulos do reino: o galpão, um curral grande com quatro cavalos (dá para montar), feno, bebedouro e o cavalariço.
func _estabulo() -> void:
	_casa("Estabulo", _p(-22.0, 40.0), 5, 3, REF.ESTILO_MADEIRA, "deposito")
	_casa("CasaDoCavalarico", _p(24.0, 42.0), 3, 2, REF.ESTILO_MADEIRA)
	var cavalo := ["cavalo", "Cavalo do reino", "cavalo", 1.0, {"carne": [2, 3], "couro": [1, 1]}]
	_curral(_p(0.0, 14.0), 30.0, 16.0, [cavalo, cavalo, cavalo, cavalo])
	_feno(_p(-22.0, 26.0))
	_feno(_p(22.0, 28.0))
	_bebedouro(_p(8.0, 14.0))
	var kit := PecasDaRua.new()
	kit.name = "PatioDosEstabulos"
	add_child(kit)
	for q in [_p(-36.0, 30.0), _p(36.0, 30.0)]:
		kit.estandarte(Vector3(q.x, _y(q), q.y), para_longe)
	kit.carroca(Vector3(_p(34.0, 14.0).x, _y(_p(34.0, 14.0)), _p(34.0, 14.0).y), dir)
	kit.carga(Vector3(_p(-30.0, 30.0).x, _y(_p(-30.0, 30.0)), _p(-30.0, 30.0).y), dir, 3, 5)
	kit.fechar()
	_fogueira(_p(30.0, 30.0), 0.5)
	_npc("Cavalariço", "Cavalariço", "dorn", _p(10.0, 32.0), PackedStringArray(["Cavalo do reino é manso. Chegue pelo lado, sem pressa, e monte."]),   # no pátio, longe do feno e da cerca (nascia encostado num sólido)
		[{"fazer": "Interact", "seg": 6.0, "olhar": _p(8.0, 16.0)}, {"ir": _p(-10.0, 32.0), "vel": 1.1}, {"fazer": "Interact", "seg": 6.0, "olhar": _p(-22.0, 26.0)}, {"ir": _p(10.0, 32.0), "vel": 1.1}])


## CATEDRAL GÓTICA (como a do Reino de Aethelgard de blocos): nave alta com telhado de ardósia, naves laterais mais
## baixas com contrafortes, fileiras de vitrais coloridos que brilham, duas torres gêmeas na fachada com a rosácea e o
## portal entre elas, e a torre do cruzeiro com o pináculo mais alto da cidade baixa. Adro com bancos e o sacristão.
func _catedral() -> void:
	var centro := _p(0.0, 30.0)
	var cat := Catedral.new()   # a construção está em scripts/mundo/catedral.gd (conferida em tools/bancada_construcao.gd -- catedral)
	add_child(cat)
	cat.montar(Vector3(centro.x, _y(centro), centro.y), dir)
	for l in [-30.0, -34.0]:
		_movel("Bench", _p(l, 24.0), 0.0)
		_movel("Bench", _p(l, 36.0), 0.0)
	_npc("Sacristão", "Sacristão da catedral", "oren", _p(-29.0, 30.0), PackedStringArray(["O sino toca ao nascer e ao pôr do sol. Dá para ouvir até da feira do portão.", "Os vitrais vieram de longe, de barco. À tarde o chão da nave fica todo colorido."]),
		[{"esperar": 7.0, "anim": "Idle", "olhar": _p(-40.0, 30.0)}, {"ir": _p(-34.0, 26.0), "vel": 1.0}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": _p(-40.0, 30.0)}, {"ir": _p(-29.0, 30.0), "vel": 1.0}])


## Lavoura do reino (fora da muralha): três campos plantados de verdade, com cerca, leiras e espantalho, um palheiro e
## gente lavrando. É de onde a cidade come.
func _lavoura() -> void:
	var campos := [_p(-26.0, 14.0), _p(4.0, 16.0), _p(-10.0, 38.0)]
	for campo in campos:
		_plantacao(campo, 24.0, 16.0)
	_feno(_p(26.0, 36.0))
	_lavrador("Lavrador do reino", "oren", campos[0], PackedStringArray(["Trigo para o pão da cidade. Quando o sino toca, a gente recolhe."]))
	if hash(String(dados["id"])) % 2 == 0:   # metade das lavouras tem moinho de vento
		_moinho(_p(34.0, 16.0))
	_lavrador("Lavradora do reino", "tessa", campos[1], PackedStringArray(["A terra aqui é boa. Ruim é o imposto do celeiro do rei."]))


## Moinho de vento: torre de pedra mais larga embaixo, telhado em cone e quatro pás de madeira que giram.
func _moinho(p: Vector2) -> void:
	var y := _y(p)
	var torre := VilaRefugio._cilindro(Vector3(p.x, y + 5.0, p.y), 3.2, 10.0, Pedra.material(Color(0.8, 0.77, 0.7)), true, 12)
	(torre.mesh as CylinderMesh).top_radius = 2.3
	var telhado := VilaRefugio._cilindro(Vector3(p.x, y + 11.6, p.y), 0.1, 3.2, VilaRefugio._mat(Color(0.5, 0.3, 0.22)), false, 12)
	(telhado.mesh as CylinderMesh).top_radius = 0.05
	(telhado.mesh as CylinderMesh).bottom_radius = 2.9
	var pas := PasDoMoinho.new()
	pas.name = "Pas"
	pas.position = Vector3(p.x - para_longe.x * 2.8, y + 9.4, p.y - para_longe.y * 2.8)   # do lado da cidade
	pas.rotation.y = atan2(-para_longe.x, -para_longe.y)
	add_child(pas)
	var madeira := VilaRefugio._mat(Color(0.42, 0.3, 0.18))
	var pano := VilaRefugio._mat(Color(0.9, 0.86, 0.74))
	for k in 4:
		var braco := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.22, 7.0, 0.16)
		b.material = madeira
		braco.mesh = b
		braco.rotation.z = PI / 2.0 * k
		braco.position = Vector3(0, 3.5, 0).rotated(Vector3.BACK, PI / 2.0 * k)
		pas.add_child(braco)
		var vela := MeshInstance3D.new()
		var v := BoxMesh.new()
		v.size = Vector3(1.5, 4.6, 0.06)
		v.material = pano
		vela.mesh = v
		vela.rotation.z = PI / 2.0 * k
		vela.position = Vector3(0.85, 4.4, 0.05).rotated(Vector3.BACK, PI / 2.0 * k)
		pas.add_child(vela)


## Guarita de portão: duas sentinelas paradas, um braseiro e um banco. Fica do lado de dentro da muralha.
func _guarita() -> void:
	_fogueira(_p(9.0, 3.0), 0.6)      # tudo de um lado e do outro da estrada: o meio fica livre para passar
	_movel("Bench", _p(11.0, 5.0), 90.0)
	_soldado("Sentinela do portão", "Sentinela", _p(-6.0, 0.0), "Portão aberto do nascer ao pôr do sol. Arma na bainha dentro da muralha.", [])
	_soldado("Sentinela do portão", "Sentinela", _p(6.0, 0.0), "Passe. E não mexa com os cavalos do reino sem falar com o cavalariço.", [])


## Pescador: cabana de madeira sobre palafitas, perto da água, com doca, barco, redes e caixas de peixe. A doca sai da
## margem do rio mais perto (procurada na hora, na direção do rio) e avança sobre a água.
func _pescador() -> void:
	_balcao(_p(8.0, 8.5), "o pescador", ["peixe_assado"])
	_terreiro(_p(0.0, 9.0), 9.0)
	_kit().barco(_chao(_p(-9.0, 11.0)), dir)
	_kit().varal_de_peixe(_chao(_p(8.0, 6.0)), para_longe)
	_kit().carga(_chao(_p(-5.0, 1.0)), dir, 2, 3)
	var casa := _casa("Cabana", _p(0.0, 5.0), 2, 2, REF.ESTILO_MADEIRA)
	var madeira := VilaRefugio._mat(Color(0.34, 0.24, 0.14))
	var c0 := Vector2(casa.position.x, casa.position.z)
	for dx in [-2.0, 2.0]:   # palafitas: toras grossas sob os cantos da casa (a casa já tem a base de pedra; as toras aparecem à frente)
		for dz in [-2.0, 2.0]:
			var q := c0 + Vector2(dx, dz).rotated(casa.rotation.y)
			VilaRefugio._cilindro(Vector3(q.x, _y(q) + 0.4, q.y), 0.22, 1.0, madeira, false, 6)
	_fogueira(_p(5.0, 11.0), 0.6)
	_movel("Barrel", _p(-6.0, 8.0))
	var ponto: Variant = _margem_mais_perto()
	if ponto != null:
		_doca(ponto[0], ponto[1])
	_npc("Pescador Edu", "Pescador", "dorn", _p(3.0, 12.0), PackedStringArray(["O rio dá o que come, desde que a gente não tire demais.", "Os soldados vieram pedir tributo de peixe. Eu disse que o peixe é do rio, não do Imperador. Eles não riram."]),
		[{"fazer": "Interact", "seg": 9.0, "olhar": _p(0.0, -8.0)}, {"esperar": 5.0, "anim": "Idle", "olhar": _p(0.0, -8.0)}])
	_animal("cao", "Cão do pescador", "cao", _p(-3.0, 10.0), 0.5, 3.0, 25, {})


## Procura a margem do rio do mundo mais perto do povoado (dentro de 60 m) e devolve [ponto na margem, sentido para a água].
func _margem_mais_perto() -> Variant:
	var melhor := 1e9
	var res: Variant = null
	for r in mundo.terreno.rios:
		var pts: PackedVector2Array = r["pontos"]
		for i in range(pts.size() - 1):
			var ab := pts[i + 1] - pts[i]
			var t := clampf((centro - pts[i]).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var q := pts[i] + ab * t
			var d := centro.distance_to(q)
			if d < melhor and d < 70.0:
				melhor = d
				var para_agua := (q - centro).normalized()
				var borda := q - para_agua * (float(r["largura"]) / 2.0 + 2.6)   # o pé da doca fica na barranca, antes da água
				res = [borda, para_agua]
	return res


## Doca de tábuas sobre a água, com um barco amarrado, uma rede estendida e caixas de peixe.
func _doca(base: Vector2, para_agua: Vector2) -> void:
	var madeira := VilaRefugio._mat(Color(0.36, 0.25, 0.14))
	var escura := VilaRefugio._mat(Color(0.24, 0.16, 0.1))
	var giro := atan2(para_agua.x, para_agua.y)
	var y := mundo.terreno.altura_em(base.x, base.y)
	var comp := 9.0
	var tabuas := Node3D.new()
	tabuas.position = Vector3(base.x, y + 0.45, base.y)
	tabuas.rotation.y = giro
	add_child(tabuas)
	for k in int(comp / 0.55):
		var t := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(2.2, 0.09, 0.5)
		b.material = madeira
		t.mesh = b
		t.position = Vector3(0.0, 0.0, 0.3 + k * 0.55)
		tabuas.add_child(t)
	var piso := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var f := BoxShape3D.new()
	f.size = Vector3(2.2, 0.2, comp)
	cs.shape = f
	cs.position = Vector3(0.0, -0.05, comp / 2.0)
	piso.add_child(cs)
	tabuas.add_child(piso)
	for k in 4:   # estacas de cada lado
		for lado in [-1.0, 1.0]:
			var e := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.12
			c.bottom_radius = 0.14
			c.height = 2.2
			c.radial_segments = 6
			c.material = escura
			e.mesh = c
			e.position = Vector3(lado * 1.05, -0.5, 1.0 + k * 2.5)
			tabuas.add_child(e)
	var casco := MeshInstance3D.new()   # barco amarrado ao lado da doca: casco, proa e um banco
	var cb := BoxMesh.new()
	cb.size = Vector3(1.3, 0.5, 3.4)
	cb.material = VilaRefugio._mat(Color(0.3, 0.2, 0.12))
	casco.mesh = cb
	casco.position = Vector3(2.0, -0.38, 6.5)
	tabuas.add_child(casco)
	var proa := MeshInstance3D.new()
	var pb := PrismMesh.new()
	pb.size = Vector3(1.3, 0.5, 1.0)
	pb.material = cb.material
	proa.mesh = pb
	proa.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	proa.position = Vector3(2.0, -0.38, 8.6)
	tabuas.add_child(proa)
	var banco := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.2, 0.08, 0.35)
	bb.material = madeira
	banco.mesh = bb
	banco.position = Vector3(2.0, -0.08, 6.4)
	tabuas.add_child(banco)
	var rede := MeshInstance3D.new()   # rede estendida num varal na cabeceira da doca
	var rb := BoxMesh.new()
	rb.size = Vector3(2.4, 1.1, 0.03)
	var rm := VilaRefugio._mat(Color(0.55, 0.5, 0.38, 0.55))
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rb.material = rm
	rede.mesh = rb
	rede.position = Vector3(-2.3, 1.2, 1.2)
	tabuas.add_child(rede)
	for lado in [-3.4, -1.2]:
		var m2 := MeshInstance3D.new()
		var mb := CylinderMesh.new()
		mb.top_radius = 0.06
		mb.bottom_radius = 0.08
		mb.height = 1.8
		mb.material = escura
		m2.mesh = mb
		m2.position = Vector3(lado, 0.8, 1.2)
		tabuas.add_child(m2)
	var cx := ConstrutorCasa.peca("Prop_Crate")   # caixas de peixe na cabeceira
	cx.scale = Vector3.ONE * 0.7
	cx.position = Vector3(-0.6, 0.05, 0.9)
	tabuas.add_child(cx)
	var cx2 := ConstrutorCasa.peca("Prop_Crate")
	cx2.scale = Vector3.ONE * 0.7
	cx2.position = Vector3(0.5, 0.05, 1.4)
	cx2.rotation_degrees.y = 25.0
	tabuas.add_child(cx2)


func _cabana() -> void:
	_terreiro(_p(0.0, 10.0), 9.0)
	_kit().carga(_chao(_p(-7.0, 2.0)), dir, 2, _rng.randi() % 20)
	_kit().lampiao_de_poste(_chao(_p(5.0, 0.0)), para_longe)
	_casa("Cabana", _p(0.0, 5.0), 2, 2, REF.ESTILO_MADEIRA)
	var lenha := VilaRefugio._mat(Color(0.32, 0.21, 0.11))
	for k in 4:   # pilha de lenha
		var q := _p(8.0, 4.0 + k * 0.7)
		VilaRefugio._cilindro(Vector3(q.x, _y(q) + 0.4, q.y), 0.35, 2.4, lenha, false, 8).rotation_degrees.z = 90.0
	var cepo := _p(-6.0, 12.0)
	VilaRefugio._cilindro(Vector3(cepo.x, _y(cepo) + 0.4, cepo.y), 0.5, 0.8, lenha, true, 8)
	_fogueira(_p(4.0, 14.0), 0.6)
	_npc("Rolf", "Lenhador", "dorn", _p(-5.0, 13.0), PackedStringArray(["Corto pinho para a Brenn e para o Refúgio. Cuidado na trilha: lobos, e coisa pior perto da mina."]),
		[{"fazer": "Sword_Attack", "seg": 10.0, "olhar": cepo}, {"esperar": 4.0, "anim": "Idle", "olhar": _p(4.0, 14.0)}])
	_animal("cao", "Cão do lenhador", "cao", _p(2.0, 10.0), 0.5, 4.0, 25, {})


func _posto() -> void:
	_terreiro(_p(1.0, 12.0), 15.0)
	_kit().cavalete_de_armas(_chao(_p(-14.0, 12.0)), dir)
	_kit().carga(_chao(_p(15.5, 13.0)), para_longe, 3, _rng.randi() % 20)
	_kit().carroca(_chao(_p(20.0, 3.0)), dir)
	for k in 3:
		_tenda(_p(-8.0 + k * 9.0, 8.0 + (k % 2) * 3.0), [Color(0.42, 0.22, 0.18), Color(0.34, 0.3, 0.2), Color(0.28, 0.26, 0.32)][k])
	_fogueira(_p(0.0, 16.0), 1.0)
	_movel("Barrel", _p(12.0, 10.0))
	_movel("Chest_Wood", _p(13.5, 10.0), 20.0)
	_npc("Rebelde Sentinela", "Sentinela do Vane", "soldado_rebelde", _p(-12.0, 2.0), PackedStringArray(["Parado. Ah, é você, Torin. O Vane espera mais gente, mas ninguém vem."]),
		[{"esperar": 7.0, "anim": "Idle", "olhar": dir * 30.0 + centro}, {"ir": _p(-4.0, 2.0), "vel": 1.2}, {"esperar": 7.0, "anim": "Idle", "olhar": dir * -30.0 + centro}, {"ir": _p(-12.0, 2.0), "vel": 1.2}])
	_npc("Cozinheira Isa", "Cozinheira", "tessa", _p(2.0, 14.0), PackedStringArray(["Sopa de raiz e o que a caça dá. Sirva-se."]),
		[{"fazer": "Interact", "seg": 8.0, "olhar": _p(0.0, 16.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": _p(0.0, 16.0)}])
	_npc("Rebelde Ferido", "Soldado ferido", "soldado_ferido", _p(8.0, 18.0), PackedStringArray(["Escapei de Ferrogris. Lá é pior do que dizem."]), [{"esperar": 8.0, "anim": "Crouch_Idle", "olhar": _p(0.0, 16.0)}, {"esperar": 5.0, "anim": "Idle", "olhar": _p(0.0, 16.0)}])


func _posto_imperial() -> void:
	_balcao(_p(3.0, 10.5), "o estalajadeiro", ["pao", "carne", "peixe_assado"])
	_casa("Estalagem", _p(0.0, 6.0), 4, 4, REF.ESTILO_PEDRA)
	_casa("Estabulo", _p(-24.0, 8.0), 3, 3, REF.ESTILO_MADEIRA, "deposito")
	_terreiro(_p(4.0, 16.0), 22.0)
	for k in 3:   # caravanas paradas
		_kit().carroca(_chao(_p(12.0 + k * 8.0, 20.0)), dir)
	for u in [-12.0, 12.0]:
		_kit().lampiao_de_poste(_chao(_p(u, -2.0)), para_longe)
	_kit().cavalete_de_armas(_chao(_p(10.0, 2.0)), -para_longe)
	_kit().carga(_chao(_p(-8.0, 1.0)), dir, 3, _rng.randi() % 20)
	_curral(_p(-26.0, 26.0), 12.0, 9.0, [["cavalo", "Cavalo de carga", "cavalo", 1.0, {"carne": [2, 3], "couro": [1, 1]}], ["cavalo", "Cavalo de carga", "cavalo", 1.0, {"carne": [2, 3], "couro": [1, 1]}]])
	_fogueira(_p(2.0, 18.0), 0.8)
	_movel("Table_Large", _p(-2.0, 14.0))
	_npc("Estalajadeiro Brum", "Estalajadeiro", "orin", _p(0.0, 11.0), PackedStringArray(["Quarto, comida e conversa. Valdoria fecha a estrada ao primeiro sinal de rebelião."]),
		[{"fazer": "Interact", "seg": 7.0, "olhar": _p(0.0, 14.0)}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": _p(0.0, 18.0)}])
	_npc("Carroceiro Edu", "Carroceiro", "soldado_rebelde", _p(14.0, 16.0), PackedStringArray(["Levo trigo à cidade. Os soldados revistam tudo, até o que não existe."]),
		[{"esperar": 6.0, "anim": "Idle", "olhar": _p(14.0, 20.0)}, {"ir": _p(22.0, 16.0), "vel": 1.2}, {"fazer": "Interact", "seg": 5.0, "olhar": _p(22.0, 20.0)}, {"ir": _p(14.0, 16.0), "vel": 1.2}])
	for p in [_p(-6.0, 0.0), _p(8.0, 0.0)]:   # guardas imperiais do posto: hostis
		var g := (load("res://scenes/inimigos/guarda_imperial.tscn") as PackedScene).instantiate() as Inimigo
		g.nome = "Guarda do Posto"
		g.especie = "guarda_posto"
		g.position = Vector3(p.x, _y(p) + 0.2, p.y)
		add_child(g)
