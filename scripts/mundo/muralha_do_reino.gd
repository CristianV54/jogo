class_name MuralhaDoReino
extends Node3D
## A muralha grande do reino: um círculo de pedra em volta de Valdoria, do Castelo e dos bairros (MundoDados.REINO).
## Acompanha o relevo em lances curtos, tem uma torre a cada 15 graus e abre um PORTÃO (duas torres altas, arco e
## bandeiras) em todo ponto onde uma estrada cruza o círculo. As pedras são desenhadas em dois MultiMesh (lances e
## torres): centenas de blocos custam duas chamadas de desenho. A colisão é um corpo só, com uma caixa por bloco.

const ALTURA := 11.0
const ESPESSURA := 2.6
const VAO_DO_PORTAO := 8.0      # metros livres de cada lado do eixo da estrada
const COR_PEDRA := Color(0.52, 0.48, 0.42)
const COR_DRAKKAR := Color(0.65, 0.1, 0.08)

var mundo: Mundo
var portoes: Array[Vector2] = []   # onde ficou cada portão (para o mapa e para os testes)
var _corpo: StaticBody3D
var _lances: Array[Transform3D] = []
var _torres: Array[Transform3D] = []


func montar() -> void:
	name = "MuralhaDoReino"
	var c: Vector2 = MundoDados.REINO["centro"]
	var r: float = MundoDados.REINO["raio"]
	_corpo = StaticBody3D.new()
	_corpo.name = "Solidos"
	add_child(_corpo)
	for id in mundo.estradas:   # portões: onde cada estrada cruza o círculo
		var pts: PackedVector2Array = mundo.estradas[id]
		for i in pts.size() - 1:
			if (pts[i].distance_to(c) - r) * (pts[i + 1].distance_to(c) - r) <= 0.0:   # <= : o ponto pode cair exatamente em cima do círculo
				var g := c + (pts[i].lerp(pts[i + 1], 0.5) - c).normalized() * r
				var novo := true
				for outro in portoes:
					if outro.distance_to(g) < 40.0:
						novo = false
				if novo:
					portoes.append(g)
	var passos := int(TAU * r / 5.0)
	for k in passos:
		var a0 := TAU * k / passos
		var a1 := TAU * (k + 1) / passos
		var p0 := c + Vector2.from_angle(a0) * r
		var p1 := c + Vector2.from_angle(a1) * r
		var meio := (p0 + p1) / 2.0
		var no_portao := false
		for g in portoes:
			if meio.distance_to(g) < VAO_DO_PORTAO:
				no_portao = true
		if no_portao:
			continue
		var y := minf(mundo.terreno.altura_em(p0.x, p0.y), mundo.terreno.altura_em(p1.x, p1.y)) - 1.5
		var giro := atan2((p1 - p0).x, (p1 - p0).y)
		_bloco(_lances, Vector3(meio.x, y + ALTURA / 2.0, meio.y), Vector3(ESPESSURA, ALTURA, p0.distance_to(p1) + 0.3), giro, true)
		if k % 2 == 0:   # ameias
			_bloco(_lances, Vector3(meio.x, y + ALTURA + 0.6, meio.y), Vector3(ESPESSURA + 0.2, 1.2, 2.4), giro, false)
	for k in 24:     # torres da muralha
		var p := c + Vector2.from_angle(TAU * (k + 0.5) / 24.0) * r
		var livre := true
		for g in portoes:
			if p.distance_to(g) < 30.0:
				livre = false
		if livre:
			_torre(p, ALTURA + 5.0, 8.0)
	for g in portoes:   # portão: duas torres altas, o arco por cima da estrada e bandeiras de Drakkar
		var fora := (g - c).normalized()
		var lado := Vector2(-fora.y, fora.x)
		var y := mundo.terreno.altura_em(g.x, g.y)
		for s in [-1.0, 1.0]:
			_torre(g + lado * s * (VAO_DO_PORTAO + 4.5), ALTURA + 9.0, 9.0)
			var b: Vector2 = g + lado * s * (VAO_DO_PORTAO + 4.5) + fora * 5.0
			_bandeira(Vector3(b.x, y + 9.0, b.y), atan2(fora.x, fora.y))
		_bloco(_lances, Vector3(g.x, y + ALTURA + 1.0, g.y), Vector3(ESPESSURA + 1.4, 5.0, VAO_DO_PORTAO * 2.0 + 1.0), atan2(lado.x, lado.y), false)
	_multimesh("Lances", _lances)
	_multimesh("Torres", _torres)
	print("MuralhaDoReino: ", _lances.size(), " blocos, ", _torres.size(), " torres, ", portoes.size(), " portões")


func _torre(p: Vector2, altura: float, lado: float) -> void:
	var y := mundo.terreno.altura_em(p.x, p.y) - 1.5
	_bloco(_torres, Vector3(p.x, y + altura / 2.0, p.y), Vector3(lado, altura, lado), 0.0, true)
	for dx in [-1.0, 1.0]:   # merlões nos quatro cantos
		for dz in [-1.0, 1.0]:
			_bloco(_torres, Vector3(p.x + dx * (lado / 2.0 - 0.7), y + altura + 0.8, p.y + dz * (lado / 2.0 - 0.7)), Vector3(1.4, 1.6, 1.4), 0.0, false)


func _bloco(lista: Array[Transform3D], pos: Vector3, tam: Vector3, giro: float, colidir: bool) -> void:
	lista.append(Transform3D(Basis(Vector3.UP, giro).scaled_local(tam), pos))
	if colidir:
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = tam
		cs.shape = caixa
		cs.position = pos
		cs.rotation.y = giro
		_corpo.add_child(cs)


func _bandeira(pos: Vector3, giro: float) -> void:
	var pano := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = Vector3(2.6, 5.0, 0.12)
	var m := StandardMaterial3D.new()
	m.albedo_color = COR_DRAKKAR
	m.roughness = 0.9
	malha.material = m
	pano.mesh = malha
	pano.position = pos
	pano.rotation.y = giro
	add_child(pano)


func _multimesh(nome: String, lista: Array[Transform3D]) -> void:
	var caixa := BoxMesh.new()
	caixa.material = Pedra.material(COR_PEDRA)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = caixa
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	add_child(inst)
