class_name VilaRefugio
extends RefCounted
## Construções da vila do Refúgio do Pinhal que não são casas: portões com torres, currais, galinheiro, poço, horta,
## canil, bancos e varal da praça. Tudo em geometria simples de madeira e pedra (o kit de cenário não tem esses itens),
## com colisão onde o jogador esbarraria. `construir` devolve as áreas ocupadas ([Vector2 centro, raio]) para o chão vivo
## não plantar grama dentro dos currais.

const RAIO_CERCA := 40.0

static var _h: Callable
static var _area: Node3D
static var _corpo: StaticBody3D


## Prepara o estado estático para outras áreas usarem as ajudantes (cercas, caixas) sem construir a vila.
static func preparar(area: Node3D, altura_em: Callable, corpo: StaticBody3D) -> void:
	_area = area
	_h = altura_em
	_corpo = corpo


static func construir(area: Node3D, altura_em: Callable) -> Array:
	_area = area
	_h = altura_em
	_corpo = StaticBody3D.new()
	_corpo.name = "SolidosDaVila"
	area.add_child(_corpo)
	var ocupado: Array = []
	_portao(Vector3(0.0, 0.0, -1.0), "Trilha do Bosque Velado")
	_portao(Vector3(1.0, 0.0, 0.0), "Refúgio do Pinhal - Estrada de Ferrogris")
	_portao(Vector3(-1.0, 0.0, 0.0), "Trilha do Pomar Alto")
	ocupado.append(_curral(Vector3(0.0, 0.0, 31.0), 16.0, 11.0, "n", ["Cocho", "Feno"]))
	ocupado.append(_curral(Vector3(-15.0, 0.0, -28.0), 8.0, 6.0, "l", ["Cocho"]))
	ocupado.append(_curral(Vector3(-30.0, 0.0, 13.0), 9.0, 8.0, "l", ["Cocho", "Feno"]))
	ocupado.append(_galinheiro(Vector3(12.0, 0.0, 22.0)))
	ocupado.append(_horta(Vector3(15.0, 0.0, -14.0)))
	ocupado.append(_poco(Vector3(-9.0, 0.0, 5.0)))
	ocupado.append(_canil(Vector3(35.5, 0.0, -5.5)))
	_praca()
	return ocupado


# ---------------------------------------------------------------- ajudantes

static func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.95
	return m


static func _caixa(pos: Vector3, tam: Vector3, mat: Material, colidir := false, giro := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	b.material = mat
	mi.mesh = b
	mi.position = pos
	mi.rotation.y = giro
	_area.add_child(mi)
	if colidir:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tam
		cs.shape = forma
		cs.transform = Transform3D(Basis(Vector3.UP, giro), pos)
		_corpo.add_child(cs)
	return mi


static func _cilindro(pos: Vector3, raio: float, altura: float, mat: Material, colidir := false, lados := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = raio
	c.bottom_radius = raio
	c.height = altura
	c.radial_segments = lados
	c.material = mat
	mi.mesh = c
	mi.position = pos
	_area.add_child(mi)
	if colidir:
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = raio
		forma.height = altura
		cs.shape = forma
		cs.position = pos
		_corpo.add_child(cs)
	return mi


static func _telhado(pos: Vector3, tam: Vector3, mat: Material, giro := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var p := PrismMesh.new()
	p.size = tam
	p.material = mat
	mi.mesh = p
	mi.position = pos
	mi.rotation.y = giro
	_area.add_child(mi)


static func _y(x: float, z: float) -> float:
	return _h.call(x, z)


## Cerca retangular de estacas (peça do kit), com colisão e uma abertura de `abertura` m no meio do lado indicado
## ("n" = z menor, "s" = z maior, "o" = x menor, "l" = x maior).
static func _cerca_retangular(centro: Vector3, larg: float, prof: float, lado_aberto: String, abertura := 2.8) -> void:
	var lados := {
		"n": [Vector3(-larg / 2.0, 0.0, -prof / 2.0), Vector3(1, 0, 0), larg],
		"s": [Vector3(-larg / 2.0, 0.0, prof / 2.0), Vector3(1, 0, 0), larg],
		"o": [Vector3(-larg / 2.0, 0.0, -prof / 2.0), Vector3(0, 0, 1), prof],
		"l": [Vector3(larg / 2.0, 0.0, -prof / 2.0), Vector3(0, 0, 1), prof],
	}
	for nome in lados:
		var ini: Vector3 = lados[nome][0]
		var dir: Vector3 = lados[nome][1]
		var comp: float = lados[nome][2]
		var n := maxi(1, int(round(comp / 2.06)))
		var passo := comp / n
		for i in n:
			var t := (i + 0.5) * passo
			if nome == lado_aberto and absf(t - comp / 2.0) < abertura / 2.0:
				continue
			var pos := centro + ini + dir * t
			pos.y = _y(pos.x, pos.z)
			var peca := ConstrutorCasa.peca("Prop_WoodenFence_Single")
			peca.position = pos
			peca.rotation.y = atan2(-dir.z, dir.x)
			peca.scale.x = passo / 2.06
			_area.add_child(peca)
			var cs := CollisionShape3D.new()
			var forma := BoxShape3D.new()
			forma.size = Vector3(passo, 1.2, 0.3)
			cs.shape = forma
			cs.transform = Transform3D(Basis(Vector3.UP, peca.rotation.y), pos + Vector3(0.0, 0.6, 0.0))
			_corpo.add_child(cs)


# ---------------------------------------------------------------- portões

## Portão na saída da paliçada: duas torres de vigia de madeira ligadas por uma viga com placa, e dois batentes abertos.
## `sentido` aponta para fora da vila (norte = (0,0,-1), leste = (1,0,0)).
static func _portao(sentido: Vector3, placa: String) -> void:
	var lateral := Vector3(-sentido.z, 0.0, sentido.x)   # ao longo da paliçada
	var raiz := sentido * sqrt(RAIO_CERCA * RAIO_CERCA - 9.3 * 9.3)
	var madeira := _mat(Color(0.34, 0.22, 0.12))
	var escura := _mat(Color(0.22, 0.15, 0.09))
	for lado in [-1.0, 1.0]:
		var c: Vector3 = raiz + lateral * 9.3 * lado
		_torre(c, madeira, escura)
		var folha_pos: Vector3 = raiz + lateral * 7.7 * lado - sentido * 1.9
		_caixa(Vector3(folha_pos.x, 1.6, folha_pos.z), Vector3(3.6, 3.2, 0.22) if absf(sentido.x) > 0.5 else Vector3(0.22, 3.2, 3.6), madeira, false, 0.0)
	var viga_pos := raiz + Vector3(0.0, 4.2, 0.0)
	var viga_tam := Vector3(0.4, 0.45, 18.6) if absf(sentido.x) > 0.5 else Vector3(18.6, 0.45, 0.4)
	_caixa(viga_pos, viga_tam, escura)
	var rotulo := Label3D.new()
	rotulo.text = placa
	rotulo.font_size = 64
	rotulo.pixel_size = 0.011
	rotulo.outline_size = 14
	rotulo.modulate = Color(0.95, 0.88, 0.7)
	rotulo.position = raiz + Vector3(0.0, 4.2, 0.0) - sentido * 0.28
	rotulo.rotation.y = -PI / 2.0 * sentido.x
	_area.add_child(rotulo)


static func _torre(centro: Vector3, madeira: Material, escura: Material) -> void:
	for dx in [-1.0, 1.0]:
		for dz in [-1.0, 1.0]:
			_caixa(centro + Vector3(dx * 1.05, 2.3, dz * 1.05), Vector3(0.3, 4.6, 0.3), madeira, true)
	_caixa(centro + Vector3(0.0, 4.65, 0.0), Vector3(2.8, 0.22, 2.8), escura)
	for dx in [-1.0, 1.0]:
		_caixa(centro + Vector3(dx * 1.3, 5.2, 0.0), Vector3(0.1, 0.9, 2.7), madeira)
		_caixa(centro + Vector3(0.0, 5.2, dx * 1.3), Vector3(2.7, 0.9, 0.1), madeira)
	_telhado(centro + Vector3(0.0, 6.35, 0.0), Vector3(3.4, 1.3, 3.4), escura, PI / 4.0)
	for degrau in 8:   # escada encostada
		_caixa(centro + Vector3(1.4, 0.3 + degrau * 0.55, 0.0), Vector3(0.1, 0.07, 0.8), madeira)


# ---------------------------------------------------------------- currais

static func _curral(centro: Vector3, larg: float, prof: float, lado_aberto: String, itens: Array) -> Array:
	_cerca_retangular(centro, larg, prof, lado_aberto)
	var madeira := _mat(Color(0.34, 0.22, 0.12))
	var agua := _mat(Color(0.18, 0.36, 0.55))
	var palha := _mat(Color(0.82, 0.68, 0.32))
	if itens.has("Cocho"):
		var p := centro + Vector3(-larg / 2.0 + 2.2, 0.0, prof / 2.0 - 1.0)
		_caixa(Vector3(p.x, _y(p.x, p.z) + 0.25, p.z), Vector3(2.0, 0.5, 0.6), madeira, true)
		_caixa(Vector3(p.x, _y(p.x, p.z) + 0.42, p.z), Vector3(1.8, 0.04, 0.42), agua)
	if itens.has("Feno"):
		for k in 3:
			var q := centro + Vector3(larg / 2.0 - 1.6 - k * 0.1, 0.0, prof / 2.0 - 1.0 - k * 0.9)
			var fardo := _cilindro(Vector3(q.x, _y(q.x, q.z) + 0.4, q.z), 0.42, 0.9, palha, true, 8)
			fardo.rotation.z = PI / 2.0
	return [Vector2(centro.x, centro.z), maxf(larg, prof) * 0.65]


static func _galinheiro(centro: Vector3) -> Array:
	_cerca_retangular(centro, 6.0, 5.0, "n", 2.4)
	var madeira := _mat(Color(0.4, 0.27, 0.15))
	var escura := _mat(Color(0.2, 0.13, 0.08))
	var cx := centro.x
	var cz := centro.z + 1.4   # casinha no fundo do cercado
	var y := _y(cx, cz)
	_caixa(Vector3(cx, y + 0.8, cz), Vector3(2.4, 1.6, 1.6), madeira, true)
	_telhado(Vector3(cx, y + 2.0, cz), Vector3(2.8, 0.9, 2.0), escura)
	_caixa(Vector3(cx, y + 0.45, cz - 0.82), Vector3(0.55, 0.8, 0.04), _mat(Color(0.06, 0.04, 0.03)))   # portinha
	for i in 3:   # poleiro e comedouro
		_caixa(Vector3(cx - 1.8 + i * 0.1, y + 0.2, centro.z - 1.2), Vector3(0.7, 0.18, 0.3), madeira, false)
	return [Vector2(centro.x, centro.z), 5.0]


# ---------------------------------------------------------------- poço, horta, canil

static func _poco(c: Vector3) -> Array:
	var pedra := ConstrutorCasa._material_do_kit("Floor_UnevenBrick")
	var madeira := _mat(Color(0.34, 0.22, 0.12))
	var y := _y(c.x, c.z)
	var anel := _cilindro(Vector3(c.x, y + 0.45, c.z), 0.85, 0.9, pedra if pedra else _mat(Color(0.5, 0.5, 0.52)), true, 12)
	anel.name = "Poco"
	_cilindro(Vector3(c.x, y + 0.88, c.z), 0.66, 0.04, _mat(Color(0.12, 0.28, 0.42)), false, 12)
	for dx in [-0.78, 0.78]:
		_caixa(Vector3(c.x + dx, y + 1.5, c.z), Vector3(0.14, 3.0, 0.14), madeira, true)
	_caixa(Vector3(c.x, y + 2.6, c.z), Vector3(1.8, 0.14, 0.14), madeira)
	_telhado(Vector3(c.x, y + 3.1, c.z), Vector3(2.3, 0.9, 1.5), _mat(Color(0.25, 0.17, 0.1)), 0.0)
	_cilindro(Vector3(c.x, y + 1.9, c.z), 0.015, 1.4, _mat(Color(0.5, 0.42, 0.3)), false, 4)   # corda
	_cilindro(Vector3(c.x, y + 1.15, c.z), 0.18, 0.28, madeira, false, 8)   # balde
	return [Vector2(c.x, c.z), 2.5]


static func _horta(centro: Vector3) -> Array:
	_cerca_retangular(centro, 17.0, 12.0, "s", 3.2)
	var plantacao := Plantacao.new()
	plantacao.largura = 11.0
	plantacao.profundidade = 8.0
	plantacao.position = Vector3(centro.x, _y(centro.x, centro.z), centro.z)
	_area.add_child(plantacao)
	return [Vector2(centro.x, centro.z), 11.5]


static func _canil(c: Vector3) -> Array:
	var madeira := _mat(Color(0.4, 0.27, 0.15))
	var y := _y(c.x, c.z)
	_caixa(Vector3(c.x, y + 0.45, c.z), Vector3(1.1, 0.9, 1.3), madeira, true)
	_telhado(Vector3(c.x, y + 1.15, c.z), Vector3(1.5, 0.6, 1.5), _mat(Color(0.22, 0.15, 0.09)))
	_caixa(Vector3(c.x - 0.56, y + 0.35, c.z), Vector3(0.04, 0.6, 0.5), _mat(Color(0.06, 0.04, 0.03)))   # entrada
	return [Vector2(c.x, c.z), 3.0]


# ---------------------------------------------------------------- praça

static func _praca() -> void:
	var corpo := _corpo
	for graus in [150.0, 200.0, 330.0]:   # bancos em volta da fogueira, virados para o fogo
		var a := deg_to_rad(graus)
		var p := Vector2(cos(a), sin(a)) * 4.4
		ConstrutorCasa._movel(_area, corpo, "Bench", p.x, p.y, rad_to_deg(atan2(-p.x, -p.y)), _y(p.x, p.y))
	var madeira := _mat(Color(0.34, 0.22, 0.12))
	var cordas := _mat(Color(0.5, 0.42, 0.3))
	var varal := Vector3(14.0, 0.0, 6.0)   # varal de roupas
	for dx in [-2.2, 2.2]:
		_caixa(Vector3(varal.x + dx, _y(varal.x, varal.z) + 1.15, varal.z), Vector3(0.12, 2.3, 0.12), madeira, true)
	_caixa(Vector3(varal.x, _y(varal.x, varal.z) + 2.1, varal.z), Vector3(4.4, 0.025, 0.025), cordas)
	var panos := [Color(0.75, 0.75, 0.7), Color(0.6, 0.25, 0.2), Color(0.35, 0.5, 0.6), Color(0.8, 0.7, 0.4), Color(0.7, 0.7, 0.65)]
	for i in panos.size():
		_caixa(Vector3(varal.x - 1.7 + i * 0.85, _y(varal.x, varal.z) + 1.7, varal.z), Vector3(0.5, 0.8, 0.02), _mat(panos[i]))
