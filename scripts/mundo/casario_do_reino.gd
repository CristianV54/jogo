class_name CasarioDoReino
extends Node3D
## O CASARIO DE VALDORIA, com a planta do Reino de Aethelgard que o Cristian tinha feito em blocos: ruas em faixas de leste
## a oeste, quarteirões de larguras diferentes separados por travessas desencontradas, e em cada quarteirão duas
## fileiras de casas (uma de frente para a rua de cima, outra para a de baixo) com um quintal estreito no meio.
## Não há casa em cima da avenida, da praça, da rua em anel do penhasco, das praças reservadas (quartel, estábulos,
## catedral) nem colada na muralha (ali corre uma viela).
## Cada casa tem o térreo (de pedra ou rebocado, com a porta), os andares de cima em enxaimel avançando um palmo sobre a
## rua, vigas marcando cada andar, telhado de duas águas virado para um lado ou para o outro e chaminé. Perto do centro
## as casas têm 3 e 4 andares; junto da muralha, 1 e 2.
## São desenhadas em MultiMesh por pedaço da cidade (poucas chamadas de desenho; o motor esconde o que está fora da tela).
## A colisão é uma caixa por casa. Não se entra nelas: as casas em que se entra são as das praças (ver Povoado).

const PISO := 2.75
const PEDACO := 160.0
const TONS_DE_REBOCO := [Color(1.0, 0.98, 0.92), Color(0.98, 0.9, 0.76), Color(0.9, 0.86, 0.8), Color(1.0, 0.86, 0.7), Color(0.86, 0.9, 0.84), Color(0.94, 0.8, 0.72)]
const TONS_DE_TELHADO := [Color(0.86, 0.36, 0.24), Color(0.74, 0.3, 0.2), Color(0.9, 0.48, 0.28), Color(0.6, 0.26, 0.2), Color(0.42, 0.44, 0.56), Color(0.5, 0.36, 0.3)]

var mundo: Mundo
var lotes: Array = []   # um por casa: {"p": Vector2, "larg": float, "prof": float, "giro": float, "alt": float}
var quarteiroes := 0
var _reservas: Array[Rect2] = []
var _pecas := {}        # "pedaço|malha|material" -> [transformações, cores]
var _solidos: StaticBody3D
var _rng := RandomNumberGenerator.new()


func montar() -> void:
	name = "CasarioDoReino"
	_rng.seed = 7
	_solidos = StaticBody3D.new()
	_solidos.name = "Solidos"
	add_child(_solidos)
	_reservar()
	var e := MundoDados.MURALHA_EIXOS
	var z0 := -e.y - 30.0
	while z0 < e.y + 30.0:
		var frente_n := _rng.randf_range(8.4, 10.6)
		var frente_s := _rng.randf_range(8.4, 10.6)
		var z1 := z0 + frente_n + frente_s + _rng.randf_range(2.0, 5.0)   # as duas fileiras e o quintal no meio
		var x0 := -e.x - 30.0 + _rng.randf_range(0.0, 20.0)
		while x0 < e.x + 30.0:
			var x1 := x0 + _rng.randf_range(38.0, 66.0)
			var usado := false
			for fileira in [[z0, frente_n], [z1 - frente_s, frente_s]]:
				var x := x0
				while x < x1 - 6.0:
					var larg := _rng.randf_range(7.4, 11.6)
					if x1 - x - larg < 6.4:
						larg = x1 - x
					var recuo := _rng.randf_range(0.0, 1.0)
					var de_cima: bool = fileira[0] == z0
					var hz0: float = float(fileira[0]) + (recuo if de_cima else 0.0)
					var hz1: float = float(fileira[0]) + float(fileira[1]) - (0.0 if de_cima else recuo)
					if larg <= 15.0 and _livre(x + 0.2, hz0, x + larg - 0.2, hz1):
						var cx := x + larg / 2.0
						var cz := (hz0 + hz1) / 2.0
						var d_centro := Vector2(cx, cz - 40.0).length()
						var opcoes: Array = [2, 3, 3, 3, 4] if d_centro < 150.0 else ([2, 2, 3, 3] if d_centro < 215.0 else [1, 2, 2, 2, 3])
						_casa(Vector2(cx, cz), larg - 0.5, hz1 - hz0, int(opcoes[_rng.randi() % opcoes.size()]))
						usado = true
					x += larg
			if usado:
				quarteiroes += 1
			x0 = x1 + _rng.randf_range(4.8, 7.2)   # travessa
		z0 = z1 + _rng.randf_range(5.4, 7.4)       # rua
	for chave in _pecas:
		_multimesh(String(chave))
	print("CasarioDoReino: ", lotes.size(), " casas em ", quarteiroes, " quarteirões")


## Áreas onde não entra casa: a avenida do sul, as avenidas do oeste e do leste, a praça e as praças dos prédios públicos.
func _reservar() -> void:
	var a := MundoDados.ANEL_EIXOS
	var xo := a.x * sqrt(maxf(0.0, 1.0 - pow(MundoDados.PORTAO_OESTE_Z / a.y, 2.0)))
	var xl := a.x * sqrt(maxf(0.0, 1.0 - pow(MundoDados.PORTAO_LESTE_Z / a.y, 2.0)))
	_reservas.append(Rect2(-8.5, a.y - 9.0, 17.0, 300.0))
	_reservas.append(Rect2(-400.0, MundoDados.PORTAO_OESTE_Z - 7.5, 400.0 - xo + 6.0, 15.0))
	_reservas.append(Rect2(xl - 6.0, MundoDados.PORTAO_LESTE_Z - 7.5, 400.0, 15.0))
	_reservas.append(MundoDados.PRACA.grow(2.5))
	for pid in mundo.povoados:
		var pv: Dictionary = mundo.povoados[pid]
		var c: Vector2 = pv["centro"]
		if MundoDados.ate_a_muralha(c.x, c.y) > 0.0 or String(pv["tipo"]) == "mercado":
			continue
		if String(pv["tipo"]) == "guarita":
			_reservas.append(Rect2(c - Vector2(14, 14), Vector2(28, 28)))
			continue
		var dir: Vector2 = pv["dir"]
		var longe := Vector2(-dir.y, dir.x) * float(pv["lado"])
		var r := Rect2(c, Vector2.ZERO)   # o prédio público ocupa de -6 a 58 m para dentro e 42 m para cada lado
		for canto in [dir * -42.0 + longe * -6.0, dir * 42.0 + longe * -6.0, dir * -42.0 + longe * 58.0, dir * 42.0 + longe * 58.0]:
			r = r.expand(c + canto)
		_reservas.append(r)


func _livre(x0: float, z0: float, x1: float, z1: float) -> bool:
	var a := MundoDados.ANEL_EIXOS
	for p in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1), Vector2((x0 + x1) / 2.0, (z0 + z1) / 2.0)]:
		if MundoDados.ate_a_muralha(p.x, p.y) > -11.0:
			return false   # junto da muralha corre uma viela
		if Vector2(p.x / a.x, p.y / a.y).length() < 1.06:
			return false   # o penhasco e a rua em anel
		if mundo.terreno.distancia_caminho(p.x, p.y) < 3.0:
			return false
	var lote := Rect2(x0, z0, x1 - x0, z1 - z0)
	for r in _reservas:
		if r.intersects(lote):
			return false
	return true


func _casa(p: Vector2, larg: float, prof: float, pisos: int) -> void:
	var y := mundo.terreno.altura_em(p.x, p.y) - 0.3
	var reboco: Color = TONS_DE_REBOCO[_rng.randi() % TONS_DE_REBOCO.size()]
	var pedaco := "%d_%d" % [floori(p.x / PEDACO), floori(p.y / PEDACO)]
	var de_pedra := _rng.randf() < 0.5
	var cor_terreo: Color = Color(0.95, 0.93, 0.9) * _rng.randf_range(0.82, 1.0) if de_pedra else reboco
	_peca(pedaco, "caixa", "terreo_pedra" if de_pedra else "terreo_reboco", Vector3(p.x, y + (PISO + 0.3) / 2.0, p.y), Vector3(larg, PISO + 0.3, prof), 0.0, cor_terreo)
	var topo := y + PISO + 0.3
	if pisos > 1:   # andares de cima em enxaimel, avançando sobre a rua, com uma viga marcando a divisa
		var alt := (pisos - 1) * PISO
		_peca(pedaco, "caixa", "liso", Vector3(p.x, topo + 0.11, p.y), Vector3(larg + 0.7, 0.22, prof + 0.7), 0.0, Color(0.3, 0.2, 0.13))
		_peca(pedaco, "caixa", "sobrado", Vector3(p.x, topo + 0.22 + alt / 2.0, p.y), Vector3(larg + 0.4, alt, prof + 0.4), 0.0, reboco)
		topo += 0.22 + alt
	_peca(pedaco, "caixa", "liso", Vector3(p.x, topo + 0.11, p.y), Vector3(larg + 0.8, 0.22, prof + 0.8), 0.0, Color(0.3, 0.2, 0.13))
	topo += 0.22
	var cumeeira_em_x := _rng.randf() < 0.6   # a cumeeira corre ao longo da rua ou atravessada (empena para a rua)
	var vao := prof if cumeeira_em_x else larg
	var alt_t := clampf(vao * 0.5, 3.4, 6.2)
	var cor_telhado: Color = TONS_DE_TELHADO[_rng.randi() % TONS_DE_TELHADO.size()] * _rng.randf_range(0.82, 1.0)
	if cumeeira_em_x:   # o prisma tem a cumeeira no eixo Z dele
		_peca(pedaco, "prisma", "telhado", Vector3(p.x, topo + alt_t / 2.0, p.y), Vector3(prof + 1.0, alt_t, larg + 1.0), PI / 2.0, cor_telhado)
	else:
		_peca(pedaco, "prisma", "telhado", Vector3(p.x, topo + alt_t / 2.0, p.y), Vector3(larg + 1.0, alt_t, prof + 1.0), 0.0, cor_telhado)
	_peca(pedaco, "caixa", "liso", Vector3(p.x + _rng.randf_range(-larg / 4.0, larg / 4.0), topo + (alt_t + 1.0) / 2.0, p.y + _rng.randf_range(-prof / 4.0, prof / 4.0)), Vector3(0.9, alt_t + 1.0, 0.9), 0.0, Color(0.34, 0.32, 0.31))   # chaminé
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(larg, topo - y + 3.0, prof)
	cs.shape = caixa
	cs.position = Vector3(p.x, y + caixa.size.y / 2.0, p.y)
	_solidos.add_child(cs)
	lotes.append({"p": p, "larg": larg, "prof": prof, "giro": 0.0, "alt": topo - y})


func _peca(pedaco: String, malha: String, material: String, pos: Vector3, tam: Vector3, giro: float, cor: Color) -> void:
	var chave := "%s|%s|%s" % [pedaco, malha, material]
	if not _pecas.has(chave):
		_pecas[chave] = [[], []]
	_pecas[chave][0].append(Transform3D(Basis(Vector3.UP, giro).scaled_local(tam), pos))
	_pecas[chave][1].append(cor)


func _multimesh(chave: String) -> void:
	var partes := chave.split("|")
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = PrismMesh.new() if partes[1] == "prisma" else BoxMesh.new()
	var lista: Array = _pecas[chave][0]
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
		mm.set_instance_color(i, _pecas[chave][1][i])
	var inst := MultiMeshInstance3D.new()
	inst.name = chave.replace("|", "_")
	inst.multimesh = mm
	inst.material_override = Fachadas.material(partes[2])
	add_child(inst)
