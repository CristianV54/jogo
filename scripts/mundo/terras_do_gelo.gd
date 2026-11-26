class_name TerrasDoGelo
extends Node3D
## O que há nas Terras do Gelo (o chão e a neve são do terreno e do bioma "gelo"): o LAGO CONGELADO (uma placa de gelo
## em que se anda, com rachaduras e pontas de gelo na beira), cristais de gelo espalhados, um dragão de espinhos azul
## pousado na margem e um dragão branco voando em roda do lago, e veios de ferro na rocha.

var mundo: Mundo
var dragoes: Array[DragaoSelvagem] = []


func montar() -> void:
	name = "TerrasDoGelo"
	var c := MundoDados.LAGO_CONGELADO
	var y := mundo.terreno.altura_em(c.x, c.y)
	var kit := PecasDoGelo.new()
	kit.name = "Pecas"
	add_child(kit)
	kit.lago(Vector3(c.x, y, c.y), MundoDados.LAGO_RAIO)
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	for k in 46:   # cristais: em roda do lago e pela neve em volta
		var a := rng.randf() * TAU
		var r := MundoDados.LAGO_RAIO + rng.randf_range(2.0, 150.0) if k % 3 != 0 else MundoDados.LAGO_RAIO + rng.randf_range(-3.0, 4.0)
		var q := c + Vector2(cos(a), sin(a)) * r
		if Biomas.em(q.x, q.y) == "gelo" and mundo.terreno.distancia_caminho(q.x, q.y) > 8.0:
			kit.cristal(Vector3(q.x, mundo.terreno.altura_em(q.x, q.y), q.y), rng.randf_range(0.8, 2.6), rng.randi())
	kit.fechar()
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		var q := c + Vector2(cos(a), sin(a)) * (MundoDados.LAGO_RAIO + 16.0)
		var veio := VeioDeFerro.new()
		veio.position = Vector3(q.x, mundo.terreno.altura_em(q.x, q.y), q.y)
		add_child(veio)
	var pousado := DragaoSelvagem.new()
	pousado.modelo = "espinhos"
	pousado.nome = "Dragão do gelo"
	pousado.tamanho = 1.3
	var qd := c + Vector2(MundoDados.LAGO_RAIO + 9.0, 6.0)
	_por(pousado, Vector3(qd.x, mundo.terreno.altura_em(qd.x, qd.y), qd.y))
	pousado.rotation.y = atan2(c.x - qd.x, c.y - qd.y)
	var branco := DragaoSelvagem.new()
	branco.voando = true
	branco.cor = Color(1.25, 1.35, 1.5)   # o modelo da Fagulha clareado: branco-azulado
	branco.tamanho = 2.0
	branco.centro = Vector3(c.x, y + 45.0, c.y)
	branco.raio = 110.0
	branco.velocidade = 14.0
	_por(branco, branco.centro + Vector3(branco.raio, 0, 0))
	print("TerrasDoGelo: lago de ", MundoDados.LAGO_RAIO * 2.0, " m, ", dragoes.size(), " dragões")


func _por(d: DragaoSelvagem, onde: Vector3) -> void:
	add_child(d)
	d.global_position = onde
	dragoes.append(d)
