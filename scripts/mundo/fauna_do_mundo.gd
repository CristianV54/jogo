class_name FaunaDoMundo
extends Node3D
## Bichos coerentes com cada região e cada trecho de estrada do mundo contínuo:
##   campos e fazendas: vacas, ovelhas, porcos, cavalos e galinhas (domésticos, ficam perto de casa);
##   matas e pomares: cervos e coelhos (fogem de quem chega perto) e, nas matas fundas, lobos, javalis e urso (atacam);
##   terras queimadas e a cratera: só corvos e os cães de guerra e guardas do Império;
##   cidade: cães vadios e cavalos nos estábulos.
## Tudo em coordenadas do mundo, sob o chão do mundo.

var mundo: Mundo
var contagem := {}   # espécie -> quantidade criada (para conferir)
var _rng := RandomNumberGenerator.new()


func povoar() -> void:
	name = "FaunaDoMundo"
	_rng.seed = 909
	# regiões que não tinham fauna própria
	_em_regiao("pomar_alto", [["cervo", 5], ["coelho", 6], ["ovelha", 7]], 90.0)
	_em_regiao("acampamento_ruptura", [["cervo", 3], ["coelho", 4], ["lobo", 2]], 80.0)
	_em_regiao("cratera_ignis", [["corvo", 6]], 100.0)
	_em_regiao("valdoria", [["cao", 4]], 55.0)
	_em_regiao("fronteira_ferrogris", [["corvo", 3]], 100.0)
	# estradas: o que vive em cada trecho
	_na_estrada("pomar", [["cervo", 4], ["coelho", 6], ["ovelha", 4]])
	_na_estrada("bosque", [["lobo", 3], ["javali", 2], ["cervo", 3], ["coelho", 4]])
	_na_estrada("campos", [["cervo", 3], ["coelho", 5], ["vaca", 4], ["cavalo", 2], ["lobo", 1]])
	_na_estrada("ruptura", [["lobo", 3], ["javali", 2], ["corvo", 4]])
	_na_estrada("ferrogris", [["corvo", 8], ["cao_guerra", 2], ["guarda", 3]])
	_na_estrada("imperial", [["cavalo", 3], ["vaca", 3], ["cao", 2], ["guarda", 3]])
	# o mundo aberto: cada zona tem a sua fauna (lobos, javalis e ursos só longe das casas)
	_na_zona(Rect2(-760, -380, 1090, 740), [["cervo", 22], ["coelho", 30], ["lobo", 6], ["javali", 3]])          # bacia do Refúgio
	_na_zona(Rect2(-760, -2650, 1090, 2265), [["cervo", 28], ["coelho", 25], ["lobo", 20], ["javali", 10], ["urso", 6]])   # terras do Bosque
	_na_zona(Rect2(330, -940, 550, 1300), [["cervo", 10], ["coelho", 10], ["lobo", 8]])                          # leste, rumo à Ruptura
	_na_zona(Rect2(330, -1700, 550, 760), [["corvo", 24], ["cao_guerra", 6], ["guarda", 10]])                    # terras queimadas
	_na_zona(Rect2(330, -2650, 550, 950), [["cavalo", 4], ["vaca", 4], ["cao", 4], ["guarda", 6]])               # terras do Império


## Espalha bichos num retângulo do mundo, fora das regiões, da água e (os hostis) das casas.
func _na_zona(zona: Rect2, lista: Array) -> void:
	var hostis := ["lobo", "javali", "urso", "cao_guerra", "guarda"]
	for item in lista:
		var feitos := 0
		var tentativas := 0
		while feitos < int(item[1]) and tentativas < 60:
			tentativas += 1
			var p := Vector2(_rng.randf_range(zona.position.x, zona.end.x), _rng.randf_range(zona.position.y, zona.end.y))
			if mundo._em_alguma_area(p) or mundo.terreno.na_agua(p.x, p.y, 3.0):
				continue
			var longe := true
			for pid in mundo.povoados:
				if p.distance_to(mundo.povoados[pid]["centro"]) < float(mundo.povoados[pid]["raio"]) * 1.3:
					longe = false
			if item[0] in hostis and not longe:
				continue
			if item[0] in ["lobo", "javali", "urso"] and MundoDados.retangulo("refugio_do_pinhal", 90.0).has_point(p):
				continue   # perto do Refúgio é seguro
			_criar(item[0], p)
			feitos += 1


func _em_regiao(id: String, lista: Array, raio: float) -> void:
	var c := MundoDados.centro(id)
	for item in lista:
		for k in int(item[1]):
			var p := c + Vector2(_rng.randf_range(-raio, raio), _rng.randf_range(-raio, raio))
			var t = mundo.regioes[id].get("terreno")
			if t is Terreno and (t as Terreno).na_agua(p.x - c.x, p.y - c.y, 7.0):
				continue   # nem dentro do rio nem na parede do leito
			_criar(item[0], p)


## Espalha os bichos ao longo do trecho (dentro do corredor, longe do começo e do fim, que são das regiões).
func _na_estrada(id: String, lista: Array) -> void:
	var comp := mundo.comprimento_da_estrada(id)
	for item in lista:
		for k in int(item[1]):
			var s := _rng.randf_range(comp * 0.12, comp * 0.88)
			var par := mundo.ponto_na_estrada(id, s)
			var dir: Vector2 = par[1]
			var esq := Vector2(-dir.y, dir.x)
			var meia := 40.0
			var p: Vector2 = par[0] + esq * _rng.randf_range(-meia * 0.75, meia * 0.75)
			if mundo.terreno.na_agua(p.x, p.y, 3.0):
				continue
			_criar(item[0], p)


## Perto de uma serra de rocha ou da borda do mundo bicho nenhum nasce (ficaria dentro da pedra).
func _perto_de_barreira(p: Vector2) -> bool:
	var lim := MundoDados.LIMITES
	if not lim.grow(-12.0).has_point(p) or Costa.distancia(p.x, p.y) < 20.0:
		return true
	for c in MundoDados.CRISTAS:
		var a: Vector2 = c["de"]
		var b: Vector2 = c["para"]
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		if p.distance_to(a + (b - a) * t) < 16.0:
			return true
	return false


func _criar(especie: String, p: Vector2) -> void:
	if _perto_de_barreira(p):
		return
	contagem[especie] = int(contagem.get(especie, 0)) + 1
	var y := mundo.terreno.altura_em(p.x, p.y)
	match especie:
		"cervo":
			_caca("cavalo", p, 0.62, "Cervo", "cervo", "chifres", 30, 1.4, {"carne": [2, 3], "couro": [1, 1]})
		"coelho":
			_caca("cao", p, 0.5, "Coelho", "coelho", "orelhas_longas", 6, 1.8, {"carne": [1, 1]})
		"ovelha":
			_domestico("ovelha", p, "Ovelha", "ovelha", 1.0, {"carne": [1, 2], "la": [1, 2]})
		"vaca":
			_domestico("vaca", p, "Vaca", "vaca", 1.0, {"carne": [2, 3], "couro": [1, 1]})
		"cavalo":
			_domestico("cavalo", p, "Cavalo", "cavalo", 1.0, {"carne": [2, 3], "couro": [1, 1]})
		"cao":
			_domestico("cao", p, "Cão vadio", "cao", 1.0, {})
		"corvo":
			var c := Corvo.new()
			c.position = Vector3(p.x, y + 0.2, p.y)
			add_child(c)
		"lobo":
			_inimigo("res://scenes/inimigos/lobo.tscn", p, y)
		"javali":
			_inimigo("res://scenes/inimigos/javali.tscn", p, y)
		"urso":
			_inimigo("res://scenes/inimigos/urso.tscn", p, y)
		"cao_guerra":
			_inimigo("res://scenes/inimigos/cao_de_guerra.tscn", p, y, "cao_guerra")
		"guarda":
			_inimigo("res://scenes/inimigos/guarda_imperial.tscn", p, y, "guarda_patrulha")


func _caca(modelo: String, p: Vector2, esc: float, nome_a: String, especie: String, acess: String, vida: int, vel: float, drops: Dictionary) -> void:
	var a := AnimalVila.new()
	a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [modelo, modelo])
	a.nome = nome_a
	a.especie = especie
	a.acessorio = acess
	a.escala = esc
	a.fugitivo = true
	a.raio_vagar = 6.0
	a.velocidade = vel
	a.vida_max = vida
	a.raio_colisao = 0.5
	a.drops = drops
	a.altura_em = mundo.terreno.altura_em
	a.position = Vector3(p.x, mundo.terreno.altura_em(p.x, p.y), p.y)
	add_child(a)


func _domestico(modelo: String, p: Vector2, nome_a: String, especie: String, esc: float, drops: Dictionary) -> void:
	var a := AnimalVila.new()
	a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [modelo, modelo])
	a.nome = nome_a
	a.especie = especie
	a.escala = esc
	a.raio_vagar = 4.0
	a.vida_max = 30
	a.drops = drops
	a.altura_em = mundo.terreno.altura_em
	a.position = Vector3(p.x, mundo.terreno.altura_em(p.x, p.y), p.y)
	add_child(a)


func _inimigo(caminho: String, p: Vector2, y: float, especie := "") -> void:
	var ini := (load(caminho) as PackedScene).instantiate() as Inimigo
	if especie != "":
		ini.especie = especie
	ini.position = Vector3(p.x, y + 0.3, p.y)
	add_child(ini)
