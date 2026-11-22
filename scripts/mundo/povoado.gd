class_name Povoado
extends Node3D
## Povoado ou fazenda no caminho entre duas regiões (coordenadas do MUNDO). Cada tipo monta o que uma comunidade assim teria:
##   "fazenda": casa, celeiro, duas plantações vivas, poço, curral com animais e fazendeiros que trabalham os campos;
##   "vila": casas, taverna, ferraria, poço, plantações, curral, taverneiro, ferreiro, fazendeiros e uma criança;
##   "cabana": cabana de lenhador, pilha de lenha, cepo e o lenhador cortando;
##   "posto": acampamento rebelde com tendas, fogueira e soldados do Vane;
##   "posto_imperial": estalagem da estrada imperial, carroças, mercador e guardas imperiais.

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")

var mundo: Mundo
var dados: Dictionary
var centro := Vector2.ZERO
var dir := Vector2.RIGHT      # sentido da estrada
var para_longe := Vector2.UP  # da estrada para dentro do povoado
var npcs: Array[Npc] = []
var animais: Array[AnimalVila] = []
var _solidos: StaticBody3D
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
		"posto":
			_posto()
		_:
			_posto_imperial()
	_placa(_p(-6.0, -float(dados["raio"]) * 0.45), String(dados["nome"]))


# ---------------------------------------------------------------- ajudantes

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
		"vila":      # blocos de pedra: cinza com ardósia ou arenito quente com telha
			opcoes = [{"parede": Color(0.82, 0.84, 0.9), "telhado": Color(0.5, 0.5, 0.58)}, {"parede": Color(1.0, 0.88, 0.7), "telhado": Color(1.0, 0.9, 0.85)}, {"parede": Color(0.75, 0.78, 0.76), "telhado": Color(0.62, 0.42, 0.34)}]
		"cabana":
			opcoes = [{"parede": Color(0.42, 0.31, 0.2), "telhado": Color(0.55, 0.45, 0.28)}, {"parede": Color(0.55, 0.52, 0.48), "telhado": Color(0.45, 0.4, 0.3)}]
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
	var y := _y(p)
	VilaRefugio._telhado(Vector3(p.x, y + 1.2, p.y), Vector3(3.6, 2.4, 3.8), VilaRefugio._mat(cor), atan2(para_longe.x, para_longe.y))
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.2, 2.2, 3.4)
	cs.shape = caixa
	cs.position = Vector3(p.x, y + 1.1, p.y)
	_solidos.add_child(cs)


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
	_casa("CasaDaFazenda", _p(0.0, 4.0), 3, 3, REF.ESTILO_MADEIRA)
	_casa("Celeiro", _p(-22.0, 10.0), 4, 4, REF.ESTILO_MADEIRA, "deposito")
	var c1 := _p(0.0, 43.0)   # um campo grande atrás da casa, com o poço e o palheiro no quintal entre os dois
	var c2 := c1
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


func _cabana() -> void:
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
	_casa("Estalagem", _p(0.0, 6.0), 4, 4, REF.ESTILO_PEDRA)
	_casa("Estabulo", _p(-24.0, 8.0), 3, 3, REF.ESTILO_MADEIRA, "deposito")
	for k in 3:   # caravanas paradas
		var q := _p(12.0 + k * 8.0, 20.0)
		VilaRefugio._caixa(Vector3(q.x, _y(q) + 0.9, q.y), Vector3(2.2, 0.8, 3.6), VilaRefugio._mat(Color(0.4, 0.28, 0.16)), true, atan2(dir.x, dir.y))
		VilaRefugio._caixa(Vector3(q.x, _y(q) + 1.6, q.y), Vector3(1.4, 0.9, 1.6), VilaRefugio._mat(Color(0.45, 0.35, 0.2)))
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
