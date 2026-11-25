class_name Cidadela
extends Node3D
## A CIDADELA: o alto do rochedo redondo do Castelo. Tem três partes, todas de pedra clara:
##   1. a ESCADARIA de pedra que sobe do sul, da Rua do Castelo até o portão (degraus largos entre dois muros);
##   2. a MURALHA REDONDA da cidadela (182 m de raio), com 14 torres redondas de telhado em ponta e o portão ao sul;
##   3. o CASARIO DE PEDRA do alto: quartéis, celeiros, casas de oficiais e oficinas em anéis entre a muralha redonda
##      e o castelo, para não sobrar terreno vazio lá em cima.
## O castelo propriamente dito (pátios, Salão do Trono, torre de menagem) é a região `castelo_imperial`, no miolo.

const PEDRA_CLARA := Color(0.84, 0.82, 0.78)
const AZUL_DO_REI := Color(0.14, 0.2, 0.5)
const ALTURA_DA_MURALHA := 11.0
const ANEIS_DE_CASAS := [100.0, 113.0, 131.0, 144.0, 162.0]

var mundo: Mundo
var casas := 0
var _corpo: StaticBody3D
var _caixas: Array[Transform3D] = []
var _torres: Array[Transform3D] = []
var _pontas: Array[Transform3D] = []


func montar() -> void:
	name = "Cidadela"
	_corpo = StaticBody3D.new()
	_corpo.name = "Solidos"
	add_child(_corpo)
	_escadaria()
	_muralha_redonda()
	_casario_de_pedra()
	_multimesh("Pedras", BoxMesh.new(), Pedra.material(PEDRA_CLARA), _caixas)
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.radial_segments = 14
	_multimesh("Torres", cil, Pedra.material(PEDRA_CLARA), _torres)
	var cone := CylinderMesh.new()
	cone.height = 1.0
	cone.top_radius = 0.02
	cone.radial_segments = 10
	var ardosia := StandardMaterial3D.new()
	ardosia.albedo_color = Color(0.2, 0.26, 0.5)
	ardosia.roughness = 0.9
	_multimesh("Pontas", cone, ardosia, _pontas)
	print("Cidadela: escadaria, muralha redonda com ", _torres.size() / 2, " torres e ", casas, " prédios de pedra no alto")


func _y(p: Vector2) -> float:
	return mundo.chao_em(p.x, p.y)


func _bloco(pos: Vector3, tam: Vector3, giro := 0.0, colidir := true) -> void:
	_caixas.append(Transform3D(Basis(Vector3.UP, giro).scaled_local(tam), pos))
	if colidir:
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = tam
		cs.shape = caixa
		cs.position = pos
		cs.rotation.y = giro
		_corpo.add_child(cs)


func _torre(p: Vector2, raio: float, altura: float) -> void:
	var y := _y(p) - 2.0
	_torres.append(Transform3D(Basis.from_scale(Vector3(raio * 2.0, altura, raio * 2.0)), Vector3(p.x, y + altura / 2.0, p.y)))
	_torres.append(Transform3D(Basis.from_scale(Vector3(raio * 2.0 + 1.6, 1.4, raio * 2.0 + 1.6)), Vector3(p.x, y + altura + 0.7, p.y)))
	_pontas.append(Transform3D(Basis.from_scale(Vector3(raio * 2.0 + 1.2, raio * 2.6, raio * 2.0 + 1.2)), Vector3(p.x, y + altura + 1.4 + raio * 1.3, p.y)))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = altura
	cs.shape = forma
	cs.position = Vector3(p.x, y + altura / 2.0, p.y)
	_corpo.add_child(cs)


## Escadaria: uma rampa de colisão (para subir sem tropeçar) com os degraus desenhados por cima e um muro de cada lado.
func _escadaria() -> void:
	var z0 := MundoDados.ESCADARIA_Z_BAIXO
	var z1 := MundoDados.ESCADARIA_Z_ALTO
	var y0 := MundoDados.altura_da_escadaria(z0)
	var y1 := MundoDados.altura_da_escadaria(z1)
	var meia := MundoDados.ESCADARIA_MEIA_LARGURA
	var comp := Vector2(z0 - z1, y1 - y0).length()
	var ang := atan2(y1 - y0, z0 - z1)
	var rampa := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(meia * 2.0, 0.8, comp + 2.0)
	rampa.shape = forma
	rampa.position = Vector3(0.0, (y0 + y1) / 2.0 - 0.4, (z0 + z1) / 2.0)
	rampa.rotation.x = ang   # sobe para o norte (-Z)
	_corpo.add_child(rampa)
	var degraus := 48
	for i in degraus:
		var t := (i + 0.5) / degraus
		_bloco(Vector3(0.0, lerpf(y0, y1, t) - 0.35, lerpf(z0, z1, t)), Vector3(meia * 2.0, 0.7, (z0 - z1) / degraus + 0.06), 0.0, false)
	for lado in [-1.0, 1.0]:   # muros laterais, em lances que acompanham a subida, com um pilar a cada 12 m
		for k in 12:
			var t := (k + 0.5) / 12.0
			var z := lerpf(z0, z1, t)
			_bloco(Vector3(lado * (meia + 0.7), lerpf(y0, y1, t) - 1.0, z), Vector3(1.4, 4.6, (z0 - z1) / 12.0 + 0.3))
			if k % 2 == 0:
				_bloco(Vector3(lado * (meia + 0.7), lerpf(y0, y1, t) + 1.9, z), Vector3(2.0, 1.4, 2.0), 0.0, false)
	for lado in [-1.0, 1.0]:   # pé da escadaria: dois pedestais com braseiro
		_bloco(Vector3(lado * (meia + 1.2), y0 + 0.9, z0 + 2.0), Vector3(3.0, 3.6, 3.0))


## Muralha redonda da cidadela, com torres de telhado em ponta e o portão (duas torres maiores e um arco) ao sul.
func _muralha_redonda() -> void:
	var r := MundoDados.RAIO_DA_CIDADELA
	var passos := int(TAU * r / 5.0)
	for k in passos:
		var a0 := TAU * k / passos
		var a1 := TAU * (k + 1) / passos
		var p0 := Vector2.from_angle(a0) * r
		var p1 := Vector2.from_angle(a1) * r
		var meio := (p0 + p1) / 2.0
		if absf(meio.x) < 9.5 and meio.y > 0.0:
			continue   # o vão do portão, no alto da escadaria
		var y := minf(_y(p0), _y(p1)) - 2.0
		var giro := atan2((p1 - p0).x, (p1 - p0).y)
		_bloco(Vector3(meio.x, y + ALTURA_DA_MURALHA / 2.0, meio.y), Vector3(3.2, ALTURA_DA_MURALHA, p0.distance_to(p1) + 0.3), giro)
		if k % 2 == 0:
			_bloco(Vector3(meio.x, y + ALTURA_DA_MURALHA + 0.6, meio.y), Vector3(3.4, 1.2, 2.2), giro, false)
	for k in 14:
		var a := PI / 2.0 + TAU * (k + 0.5) / 14.0
		_torre(Vector2.from_angle(a) * r, 5.0, ALTURA_DA_MURALHA + 9.0)
	for lado in [-1.0, 1.0]:   # portão da cidadela
		_torre(Vector2(lado * 15.5, sqrt(r * r - 15.5 * 15.5)), 6.5, ALTURA_DA_MURALHA + 14.0)
	var yp := _y(Vector2(0.0, r))
	_bloco(Vector3(0.0, yp + ALTURA_DA_MURALHA + 1.5, r), Vector3(20.0, 7.0, 6.0), 0.0, false)   # arco por cima da passagem
	for lado in [-1.0, 1.0]:
		var pano := MeshInstance3D.new()
		var malha := BoxMesh.new()
		malha.size = Vector3(2.6, 6.0, 0.12)
		var m := StandardMaterial3D.new()
		m.albedo_color = AZUL_DO_REI
		malha.material = m
		pano.mesh = malha
		pano.position = Vector3(lado * 15.5, yp + 12.0, r + 7.0)
		add_child(pano)


## Prédios de pedra do alto: sobrados compridos em anéis, virados para o castelo. Nenhum nasce dentro do castelo, na
## passagem do portão para a porta do castelo, nem colado na muralha redonda.
func _casario_de_pedra() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	var corpos: Array = [[], []]
	var telhados: Array = [[], []]
	for raio_v in ANEIS_DE_CASAS:
		var raio: float = raio_v
		var ang := rng.randf() * 0.1
		while ang < TAU - 0.02:
			var larg := rng.randf_range(9.0, 15.0)
			var meio: float = ang + larg / raio / 2.0
			ang += (larg + rng.randf_range(0.4, 1.2)) / raio
			var p: Vector2 = Vector2.from_angle(meio) * raio
			if (absf(p.x) < 92.0 and p.y > -140.0 and p.y < 146.0) or (absf(p.x) < 16.0 and p.y > 0.0):
				continue   # dentro do castelo, ou na avenida que vai do portão da cidadela à porta do castelo
			var prof := rng.randf_range(8.0, 9.6)
			var alt := rng.randf_range(6.5, 11.5)
			var giro := -meio + PI / 2.0
			var y := _y(p) - 0.3
			var base := Basis(Vector3.UP, giro)
			corpos[0].append(Transform3D(base.scaled_local(Vector3(larg, alt, prof)), Vector3(p.x, y + alt / 2.0, p.y)))
			corpos[1].append(Color(0.95, 0.93, 0.9) * rng.randf_range(0.9, 1.0))
			var alt_t := rng.randf_range(3.4, 5.0)
			telhados[0].append(Transform3D((base * Basis(Vector3.UP, PI / 2.0)).scaled_local(Vector3(prof + 1.0, alt_t, larg + 0.5)), Vector3(p.x, y + alt + alt_t / 2.0, p.y)))
			telhados[1].append(Color(0.44, 0.48, 0.66) * rng.randf_range(0.85, 1.0))   # ardósia azulada, a cor dos telhados do rei
			var cs := CollisionShape3D.new()
			var caixa := BoxShape3D.new()
			caixa.size = Vector3(larg, alt + 3.0, prof)
			cs.shape = caixa
			cs.position = Vector3(p.x, y + (alt + 3.0) / 2.0, p.y)
			cs.rotation.y = giro
			_corpo.add_child(cs)
			casas += 1
	_multimesh("PrediosDoAlto", BoxMesh.new(), Fachadas.material("pedra"), corpos[0], corpos[1])
	_multimesh("TelhadosDoAlto", PrismMesh.new(), Fachadas.material("telhado"), telhados[0], telhados[1])


func _multimesh(nome: String, malha: Mesh, mat: Material, lista: Array, cores: Array = []) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not cores.is_empty()
	mm.mesh = malha
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
		if not cores.is_empty():
			mm.set_instance_color(i, cores[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)
