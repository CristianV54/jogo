class_name MuralhaDoReino
extends Node3D
## A muralha de Valdoria: grossa, de contorno irregular (MundoDados.ponto_da_muralha), com torres redondas de vigia e um
## PORTÃO (duas torres maiores, casa do portão por cima da passagem e estandartes azuis) em todo ponto onde uma estrada
## cruza o contorno. As pedras são desenhadas em MultiMesh (lances em caixas, torres em cilindros); a colisão é um corpo
## só, com uma forma por peça.

const ALTURA := 13.0
const ESPESSURA := 4.6
const VAO_DO_PORTAO := 7.0      # metros livres de cada lado do eixo da estrada
const COR_PEDRA := Color(0.52, 0.48, 0.42)
const AZUL_DO_REI := Color(0.14, 0.2, 0.5)
const PASSOS := 360

var mundo: Mundo
var portoes: Array[Vector2] = []   # onde ficou cada portão (para o mapa e para os testes)
var _corpo: StaticBody3D
var _lances: Array[Transform3D] = []
var _torres: Array[Transform3D] = []


func montar() -> void:
	name = "MuralhaDoReino"
	_corpo = StaticBody3D.new()
	_corpo.name = "Solidos"
	add_child(_corpo)
	for id in mundo.estradas:   # portões: onde cada estrada cruza a muralha
		var pts: PackedVector2Array = mundo.estradas[id]
		for i in pts.size() - 1:
			if MundoDados.ate_a_muralha(pts[i].x, pts[i].y) * MundoDados.ate_a_muralha(pts[i + 1].x, pts[i + 1].y) <= 0.0:
				var g := pts[i].lerp(pts[i + 1], 0.5)
				var novo := true
				for outro in portoes:
					if outro.distance_to(g) < 40.0:
						novo = false
				if novo:
					portoes.append(g)
	for k in PASSOS:
		var p0 := MundoDados.ponto_da_muralha(TAU * k / PASSOS)
		var p1 := MundoDados.ponto_da_muralha(TAU * (k + 1) / PASSOS)
		var meio := (p0 + p1) / 2.0
		var no_portao := false
		for g in portoes:
			if meio.distance_to(g) < VAO_DO_PORTAO:
				no_portao = true
		if no_portao:
			continue
		var y := minf(mundo.terreno.altura_em(p0.x, p0.y), mundo.terreno.altura_em(p1.x, p1.y)) - 1.5
		var giro := atan2((p1 - p0).x, (p1 - p0).y)
		_bloco(Vector3(meio.x, y + ALTURA / 2.0, meio.y), Vector3(ESPESSURA, ALTURA, p0.distance_to(p1) + 0.4), giro, true)
		if k % 2 == 0:   # ameias
			_bloco(Vector3(meio.x, y + ALTURA + 0.6, meio.y), Vector3(ESPESSURA + 0.2, 1.2, 2.4), giro, false)
	for k in 32:     # torres de vigia
		var p := MundoDados.ponto_da_muralha(TAU * (k + 0.5) / 32.0)
		var livre := true
		for g in portoes:
			if p.distance_to(g) < 28.0:
				livre = false
		if livre:
			_torre(p, ALTURA + 6.0, 11.0)
	for g in portoes:   # portão: duas torres maiores, a casa do portão por cima da passagem e estandartes
		var fora := g.normalized()
		var lado := Vector2(-fora.y, fora.x)
		var y := mundo.terreno.altura_em(g.x, g.y)
		for s in [-1.0, 1.0]:
			_torre(g + lado * s * (VAO_DO_PORTAO + 7.0), ALTURA + 11.0, 14.0)
			var b: Vector2 = g + lado * s * (VAO_DO_PORTAO + 7.0) + fora * 7.6
			_bandeira(Vector3(b.x, y + 9.0, b.y), atan2(fora.x, fora.y))
		_bloco(Vector3(g.x, y + ALTURA + 2.0, g.y), Vector3(ESPESSURA + 5.0, 8.0, VAO_DO_PORTAO * 2.0 + 1.0), atan2(lado.x, lado.y), false)
	_multimesh("Lances", _lances, BoxMesh.new())
	var cilindro := CylinderMesh.new()   # raio 0,5 e altura 1: a escala de cada torre dá o tamanho
	cilindro.height = 1.0
	cilindro.radial_segments = 14
	_multimesh("Torres", _torres, cilindro)
	print("MuralhaDoReino: ", _lances.size(), " blocos, ", _torres.size() / 2, " torres, ", portoes.size(), " portões")


## Torre redonda: o fuste, um coroamento mais largo no topo (o caminho de ronda) e as ameias em volta.
func _torre(p: Vector2, altura: float, lado: float) -> void:
	var y := mundo.terreno.altura_em(p.x, p.y) - 1.5
	_torres.append(Transform3D(Basis.from_scale(Vector3(lado, altura, lado)), Vector3(p.x, y + altura / 2.0, p.y)))
	_torres.append(Transform3D(Basis.from_scale(Vector3(lado + 1.8, 1.6, lado + 1.8)), Vector3(p.x, y + altura + 0.8, p.y)))
	for k in 8:
		var a := TAU * k / 8.0
		_bloco(Vector3(p.x + cos(a) * (lado / 2.0 + 0.4), y + altura + 2.3, p.y + sin(a) * (lado / 2.0 + 0.4)), Vector3(1.5, 1.5, 1.2), -a + PI / 2.0, false)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = lado / 2.0
	cil.height = altura
	cs.shape = cil
	cs.position = Vector3(p.x, y + altura / 2.0, p.y)
	_corpo.add_child(cs)


func _bloco(pos: Vector3, tam: Vector3, giro: float, colidir: bool) -> void:
	_lances.append(Transform3D(Basis(Vector3.UP, giro).scaled_local(tam), pos))
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
	m.albedo_color = AZUL_DO_REI
	m.roughness = 0.9
	malha.material = m
	pano.mesh = malha
	pano.position = pos
	pano.rotation.y = giro
	add_child(pano)


func _multimesh(nome: String, lista: Array[Transform3D], malha: PrimitiveMesh) -> void:
	malha.material = Pedra.material(COR_PEDRA)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	add_child(inst)
