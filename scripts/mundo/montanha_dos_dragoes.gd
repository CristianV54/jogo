class_name MontanhaDosDragoes
extends Node3D
## O que há na Montanha dos Dragões (o chão é do terreno, ver MundoDados.montanha): o NINHO no platô do topo (roda de
## pedras, ossos, ovos e brasa), dragões selvagens voando em volta do pico e pousados nas pedras, o dragão DOMÁVEL no
## ninho, marcos de pedra ao longo da trilha e a placa no pé dela.

var mundo: Mundo
var dragoes: Array[DragaoSelvagem] = []
var domavel: DragaoSelvagem
var _kit: PecasDeConstrucao


func montar() -> void:
	name = "MontanhaDosDragoes"
	_kit = PecasDoNinho.new()
	_kit.name = "Pecas"
	add_child(_kit)
	var c := MundoDados.MONTANHA_CENTRO
	var topo := mundo.terreno.altura_em(c.x, c.y)
	var ninho := Vector3(c.x, topo, c.y)
	(_kit as PecasDoNinho).ninho(ninho)
	var n := 16
	for i in n + 1:   # marcos de pedra na beira de fora da trilha, e um arco de ossos no começo e no fim
		var t := float(i) / n
		var p := MundoDados.ponto_da_trilha(t)
		var fora := (p - c).normalized()
		var q := p + fora * 6.5
		(_kit as PecasDoNinho).marco(Vector3(q.x, mundo.terreno.altura_em(q.x, q.y), q.y), i)
	for t in [0.01, 0.985]:
		var p := MundoDados.ponto_da_trilha(t)
		var p2 := MundoDados.ponto_da_trilha(t + 0.004)
		(_kit as PecasDoNinho).arco_de_ossos(Vector3(p.x, mundo.terreno.altura_em(p.x, p.y), p.y), (p2 - p).normalized())
	_kit.fechar()
	# dragões: cinco voando em roda do pico em alturas e raios diferentes, três pousados na borda do platô, e o domável
	var cores := [Color(0.9, 0.35, 0.3), Color(0.35, 0.55, 0.9), Color(0.4, 0.8, 0.45), Color(0.95, 0.8, 0.35), Color(0.6, 0.4, 0.85), Color(0.3, 0.3, 0.35), Color(0.9, 0.55, 0.25), Color(0.5, 0.85, 0.85)]
	for k in 5:
		var d := DragaoSelvagem.new()
		d.voando = true
		d.cor = cores[k]
		d.tamanho = [1.6, 2.2, 1.3, 2.8, 1.8][k]
		d.centro = ninho + Vector3(0, [30.0, 55.0, -40.0, 85.0, -90.0][k], 0)
		d.raio = [90.0, 150.0, 220.0, 120.0, 330.0][k]
		d.velocidade = [16.0, 13.0, 18.0, 11.0, 15.0][k] * (1.0 if k % 2 == 0 else -1.0)
		d.fase = k * 1.3
		_por(d, d.centro + Vector3(d.raio, 0, 0))
	for k in 3:
		var a := TAU * (k + 0.2) / 3.0
		var q := c + Vector2(cos(a), sin(a)) * (MundoDados.MONTANHA_TOPO - 9.0)
		var d := DragaoSelvagem.new()
		d.cor = cores[5 + k]
		d.tamanho = [1.5, 2.0, 1.2][k]
		_por(d, Vector3(q.x, mundo.terreno.altura_em(q.x, q.y), q.y))
		d.rotation.y = atan2(c.x - q.x, c.y - q.y)   # olhando para o meio do ninho
	domavel = DragaoSelvagem.new()
	domavel.domavel = true
	domavel.cor = Color(0.62, 0.64, 0.7)   # cinza: é dele que vem o nome
	domavel.tamanho = 1.25
	_por(domavel, ninho + Vector3(9.0, 0.0, 4.0))
	domavel.rotation.y = -2.0
	print("MontanhaDosDragoes: topo a ", snappedf(topo, 0.1), " m, ", dragoes.size(), " dragões (1 domável)")


func _por(d: DragaoSelvagem, onde: Vector3) -> void:
	add_child(d)
	d.global_position = onde
	dragoes.append(d)
