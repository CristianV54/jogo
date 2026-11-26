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
var janelas_acesas := 0
var forjas := 0
var ruas: Array[float] = []   # z do meio de cada rua (as faixas vazias entre um par de fileiras e o seguinte)
var floreiras := 0
var arvores_de_quintal := 0
var _copas: Array[Transform3D] = []
var _reservas: Array[Rect2] = []
var _pecas := {}        # "pedaço|malha|material" -> [transformações, cores]
var _solidos: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _rua: PecasDaRua            # calçadas, lampiões e o resto do que fica entre a rua e a fachada
var _rng_rua := RandomNumberGenerator.new()   # sorteio à parte: enfeitar a rua não muda onde ficam as casas
var lampioes_de_parede := 0
var placas := 0


func montar() -> void:
	name = "CasarioDoReino"
	_rng.seed = 7
	_solidos = StaticBody3D.new()
	_solidos.name = "Solidos"
	add_child(_solidos)
	_reservar()
	_rua = PecasDaRua.new()
	_rua.name = "Rua"
	add_child(_rua)
	_rng_rua.seed = 23
	var e := MundoDados.MURALHA_EIXOS
	var z0 := -e.y - 30.0
	while z0 < e.y + 30.0:
		var frente_n := _rng.randf_range(8.4, 10.6)
		var frente_s := _rng.randf_range(8.4, 10.6)
		var z1 := z0 + frente_n + frente_s + _rng.randf_range(2.0, 5.0)   # as duas fileiras e o quintal no meio
		var x0 := -e.x - 30.0 + _rng.randf_range(0.0, 20.0)
		var sarjetas: Array = []
		while x0 < e.x + 30.0:
			var x1 := x0 + _rng.randf_range(38.0, 66.0)
			var usado := false
			var frentes_do_sul: Array = []   # [x do meio, largura] das casas que dão para a rua de baixo (para a sarjeta)
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
						_casa(Vector2(cx, cz), larg - 0.5, hz1 - hz0, int(opcoes[_rng.randi() % opcoes.size()]), -1.0 if de_cima else 1.0)
						_frente(cx, hz0 if de_cima else hz1, larg, -1.0 if de_cima else 1.0, recuo)
						if not de_cima:
							frentes_do_sul.append([cx, larg])
						usado = true
					x += larg
			if usado:
				quarteiroes += 1
				var zq := z0 + frente_n + (z1 - frente_s - z0 - frente_n) / 2.0   # árvores no quintal do meio do quarteirão: copas verdes entre os telhados
				var xq := x0 + _rng.randf_range(4.0, 9.0)
				while xq < x1 - 4.0:
					if _rng.randf() < 0.55 and _livre(xq - 1.0, zq - 1.0, xq + 1.0, zq + 1.0):
						var esc := _rng.randf_range(0.55, 0.8)
						_copas.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled_local(Vector3(esc, esc * 1.25, esc)), Vector3(xq, mundo.terreno.altura_em(xq, zq), zq)))
						arvores_de_quintal += 1
					xq += _rng.randf_range(9.0, 16.0)
			sarjetas.append([frentes_do_sul, z1])
			x0 = x1 + _rng.randf_range(4.8, 7.2)   # travessa
		var largura_da_rua := _rng.randf_range(5.4, 7.4)
		for par in sarjetas:   # a sarjeta corre no meio da rua de baixo, diante de cada casa
			for f in par[0]:
				var zs: float = float(par[1]) + largura_da_rua / 2.0
				var xa: float = float(f[0]) - float(f[1]) / 2.0
				var xb: float = float(f[0]) + float(f[1]) / 2.0
				if _livre(xa, zs - 0.5, xb, zs + 0.5):
					_rua.sarjeta(Vector3(xa, mundo.terreno.altura_em(xa, zs), zs), Vector3(xb, mundo.terreno.altura_em(xb, zs), zs))
		ruas.append(z1 + largura_da_rua / 2.0)
		z0 = z1 + largura_da_rua
	_rua.fechar()
	for chave in _pecas:
		_multimesh(String(chave))
	var mmq := MultiMesh.new()
	mmq.transform_format = MultiMesh.TRANSFORM_3D
	mmq.mesh = FabricaNatureza.folhosa()
	mmq.instance_count = _copas.size()
	for i in _copas.size():
		mmq.set_instance_transform(i, _copas[i])
	var quintais := MultiMeshInstance3D.new()
	quintais.name = "ArvoresDeQuintal"
	quintais.multimesh = mmq
	quintais.material_override = FabricaNatureza.material()
	add_child(quintais)
	print("CasarioDoReino: ", lampioes_de_parede, " lampiões de parede, ", placas, " placas de loja")
	print("CasarioDoReino: ", floreiras, " floreiras, ", arvores_de_quintal, " árvores de quintal")
	print("CasarioDoReino: ", lotes.size(), " casas em ", quarteiroes, " quarteirões, ", janelas_acesas, " janelas acesas, ", forjas, " forjas")


## O que fica entre a rua e a fachada de uma casa: calçada, degrau da porta e, por sorteio, lampião de parede, placa de
## loja, carga, banco e vasos. `zf` é o z da fachada, `s` o lado para onde ela olha (-1 norte, +1 sul).
func _frente(cx: float, zf: float, larg: float, s: float, recuo: float) -> void:
	var fora := Vector2(0, s)
	var y := mundo.terreno.altura_em(cx, zf + s)
	var l := larg - 0.5
	_rua.calcada(Vector3(cx - larg / 2.0, y, zf), Vector3(cx + larg / 2.0, y, zf), fora, 1.3 + recuo)
	_rua.degrau(Vector3(cx, y, zf), fora, l * 0.17)
	if _rng_rua.randf() < 0.36:
		_rua.lampiao_de_parede(Vector3(cx + l * 0.165, y, zf), fora)
		lampioes_de_parede += 1
	if _rng_rua.randf() < 0.2:
		_rua.placa(Vector3(cx - l * 0.165, y, zf), fora, [Color(0.2, 0.4, 0.62), Color(0.7, 0.2, 0.18), Color(0.25, 0.5, 0.3), Color(0.8, 0.62, 0.2)][_rng_rua.randi() % 4])
		placas += 1
	var sorte := _rng_rua.randf()
	if sorte < 0.22:
		_rua.carga(Vector3(cx + l * 0.3, y, zf + s * 0.5), Vector2(1, 0), 1 + _rng_rua.randi() % 3, _rng_rua.randi() % 20)
	elif sorte < 0.32:
		_rua.banco(Vector3(cx + l * 0.32, y, zf), fora)
	if _rng_rua.randf() < 0.4:
		_rua.vaso(Vector3(cx - l * 0.32, y, zf + s * 0.35), [Color(0.85, 0.2, 0.25), Color(0.95, 0.75, 0.2), Color(0.8, 0.4, 0.75), Color(0.95, 0.95, 0.9)][_rng_rua.randi() % 4])


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


const MADEIRA_ESCURA := Color(0.3, 0.2, 0.13)
const TONS_DE_VENEZIANA := [Color(0.24, 0.4, 0.3), Color(0.22, 0.34, 0.5), Color(0.5, 0.2, 0.16), Color(0.42, 0.3, 0.18), Color(0.3, 0.42, 0.44)]


## Janela em relevo na fachada: peitoril, verga e duas venezianas abertas. `c` é o centro do vão, na face da parede.
func _janela(pedaco: String, c: Vector3, larg_vao: float, alt_vao: float, frente: float, veneziana: Color, de_pedra: bool) -> void:
	var moldura: Color = Color(0.8, 0.78, 0.72) if de_pedra else MADEIRA_ESCURA
	_peca(pedaco, "caixa", "liso", c + Vector3(0, -alt_vao / 2.0 - 0.05, frente * 0.09), Vector3(larg_vao + 0.3, 0.1, 0.2), 0.0, moldura)
	_peca(pedaco, "caixa", "liso", c + Vector3(0, alt_vao / 2.0 + 0.05, frente * 0.05), Vector3(larg_vao + 0.2, 0.12, 0.1), 0.0, moldura)
	for lado in [-1.0, 1.0]:
		_peca(pedaco, "caixa", "liso", c + Vector3(lado * (larg_vao / 2.0 + larg_vao * 0.26), 0, frente * 0.04), Vector3(larg_vao * 0.48, alt_vao, 0.06), 0.0, veneziana)
		_peca(pedaco, "caixa", "liso", c + Vector3(lado * (larg_vao / 2.0 + larg_vao * 0.26), 0, frente * 0.075), Vector3(larg_vao * 0.36, 0.06, 0.02), 0.0, veneziana.darkened(0.35))


func _casa(p: Vector2, larg: float, prof: float, pisos: int, frente: float) -> void:
	var y := mundo.terreno.altura_em(p.x, p.y) - 0.3
	var reboco: Color = TONS_DE_REBOCO[_rng.randi() % TONS_DE_REBOCO.size()]
	var pedaco := "%d_%d" % [floori(p.x / PEDACO), floori(p.y / PEDACO)]
	var de_pedra := _rng.randf() < 0.5
	var cor_terreo: Color = Color(0.95, 0.93, 0.9) * _rng.randf_range(0.82, 1.0) if de_pedra else reboco
	_peca(pedaco, "caixa", "terreo_pedra" if de_pedra else "terreo_reboco", Vector3(p.x, y + (PISO + 0.3) / 2.0, p.y), Vector3(larg, PISO + 0.3, prof), 0.0, cor_terreo)
	var topo := y + PISO + 0.3
	var veneziana: Color = TONS_DE_VENEZIANA[_rng_rua.randi() % TONS_DE_VENEZIANA.size()]
	var zf := p.y + frente * prof / 2.0
	var at := PISO + 0.3
	for lado_j in [-1.0, 1.0]:
		_janela(pedaco, Vector3(p.x + lado_j * 0.32 * larg, y + 0.56 * at, zf), 0.125 * larg, 0.3 * at, frente, veneziana, de_pedra)
		_janela(pedaco, Vector3(p.x + lado_j * 0.32 * larg, y + 0.56 * at, p.y - frente * prof / 2.0), 0.125 * larg, 0.3 * at, -frente, veneziana, de_pedra)   # os fundos também têm janela em relevo
	var porta_l := 0.14 * larg   # a porta: folha de tábuas, ombreiras e verga em relevo, aldrava
	_peca(pedaco, "caixa", "liso", Vector3(p.x, y + 1.1, zf + frente * 0.03), Vector3(porta_l, 2.2, 0.08), 0.0, Color(0.42, 0.28, 0.16) * _rng_rua.randf_range(0.75, 1.1))
	for k in 3:
		_peca(pedaco, "caixa", "liso", Vector3(p.x + (k - 1) * porta_l / 3.0, y + 1.1, zf + frente * 0.075), Vector3(0.025, 2.2, 0.02), 0.0, Color(0.2, 0.13, 0.08))
	for yb in [0.75, 1.75]:
		_peca(pedaco, "caixa", "liso", Vector3(p.x, y + yb, zf + frente * 0.08), Vector3(porta_l, 0.09, 0.03), 0.0, Color(0.14, 0.14, 0.15))
	_peca(pedaco, "caixa", "liso", Vector3(p.x + porta_l * 0.32, y + 1.3, zf + frente * 0.1), Vector3(0.09, 0.09, 0.05), 0.0, Color(0.75, 0.65, 0.3))
	var cor_ombreira: Color = Color(0.8, 0.78, 0.72) if de_pedra else MADEIRA_ESCURA
	for lado_p in [-1.0, 1.0]:
		_peca(pedaco, "caixa", "liso", Vector3(p.x + lado_p * (porta_l / 2.0 + 0.09), y + 1.15, zf + frente * 0.07), Vector3(0.18, 2.3, 0.16), 0.0, cor_ombreira)
	_peca(pedaco, "caixa", "liso", Vector3(p.x, y + 2.3, zf + frente * 0.09), Vector3(porta_l + 0.5, 0.2, 0.2), 0.0, cor_ombreira)
	for s in [-1.0, 1.0]:   # janelas do térreo: uma de cada lado da porta, nas duas fachadas; algumas acesas
		for lado in [-1.0, 1.0]:
			if _rng.randf() < 0.16:
				_peca(pedaco, "caixa", "luz", Vector3(p.x + s * 0.32 * larg, y + 0.56 * (PISO + 0.3), p.y + lado * (prof / 2.0 + 0.03)), Vector3(0.125 * larg, 0.3 * (PISO + 0.3), 0.06), 0.0, Color(1.0, 0.8, 0.42))
				janelas_acesas += 1
	if absf(p.x) < 26.0 and p.y > 120.0 and _rng.randf() < 0.8:   # casas da avenida do sul: loja no térreo, com toldo listrado sobre a porta
		var para_a_avenida := -signf(p.x)
		var cor_toldo: Color = [Color(0.75, 0.2, 0.18), Color(0.2, 0.4, 0.62), Color(0.85, 0.7, 0.3), Color(0.3, 0.55, 0.3)][_rng.randi() % 4]
		for k in 4:
			_peca(pedaco, "caixa", "liso", Vector3(p.x + para_a_avenida * (larg / 2.0 + 0.35 + k * 0.4), y + PISO + 0.1 - k * 0.14, p.y), Vector3(0.42, 0.08, prof * 0.7), 0.0, cor_toldo if k % 2 == 0 else Color(0.95, 0.93, 0.88))
	var forja := pisos == 1 and _rng.randf() < 0.75   # casa térrea de ferreiro: boca de fornalha acesa e chaminé grossa
	if forja:
		_peca(pedaco, "caixa", "luz", Vector3(p.x, y + 1.0, p.y + prof / 2.0 + 0.04), Vector3(1.8, 1.3, 0.08), 0.0, Color(1.0, 0.45, 0.12))
		forjas += 1
	if pisos > 1:   # andares de cima em enxaimel, avançando sobre a rua, com uma viga marcando a divisa
		var alt := (pisos - 1) * PISO
		_peca(pedaco, "caixa", "liso", Vector3(p.x, topo + 0.11, p.y), Vector3(larg + 0.7, 0.22, prof + 0.7), 0.0, Color(0.3, 0.2, 0.13))
		_peca(pedaco, "caixa", "sobrado", Vector3(p.x, topo + 0.22 + alt / 2.0, p.y), Vector3(larg + 0.4, alt, prof + 0.4), 0.0, reboco)
		var nc := int(larg / 1.1)
		for k in nc:   # pontas de viga que seguram o andar saliente
			_peca(pedaco, "caixa", "liso", Vector3(p.x + (k + 0.5 - nc / 2.0) * (larg / nc), topo - 0.12, zf + frente * 0.12), Vector3(0.16, 0.24, 0.5), 0.0, MADEIRA_ESCURA)
		for fiada in 2:   # as seis janelas do sobrado, em relevo na fachada da rua
			for coluna_j in [-0.336, 0.0, 0.332]:
				_janela(pedaco, Vector3(p.x + coluna_j * (larg + 0.4), topo + 0.22 + alt * (0.75 - 0.5 * fiada), p.y + frente * (prof + 0.4) / 2.0), 0.1 * (larg + 0.4), alt * 0.2, frente, veneziana, false)
				_janela(pedaco, Vector3(p.x + coluna_j * (larg + 0.4), topo + 0.22 + alt * (0.75 - 0.5 * fiada), p.y - frente * (prof + 0.4) / 2.0), 0.1 * (larg + 0.4), alt * 0.2, -frente, veneziana, false)
		for andar in pisos - 1:   # janelas dos andares de cima (a pintura do sobrado tem 2 fiadas de 3)
			for coluna in [-0.336, 0.0, 0.332]:
				for lado in [-1.0, 1.0]:
					if (pisos - 1 == 1 or andar < 2) and _rng.randf() < 0.14:
						var fiadas := 2.0
						var yj := topo + 0.22 + alt * (1.0 - (0.25 + 0.5 * float(andar % 2)))
						_peca(pedaco, "caixa", "luz", Vector3(p.x + coluna * (larg + 0.4), yj, p.y + lado * ((prof + 0.4) / 2.0 + 0.03)), Vector3(0.1 * (larg + 0.4), alt / fiadas * 0.42, 0.06), 0.0, Color(1.0, 0.8, 0.42))
						janelas_acesas += 1
					elif (pisos - 1 == 1 or andar < 2) and _rng.randf() < 0.22:   # floreira debaixo da janela: caixote de madeira com flores
						var yf: float = topo + 0.22 + alt * (1.0 - (0.25 + 0.5 * float(andar % 2))) - alt / 2.0 * 0.26
						var zfl: float = p.y + lado * ((prof + 0.4) / 2.0 + 0.18)
						_peca(pedaco, "caixa", "liso", Vector3(p.x + coluna * (larg + 0.4), yf, zfl), Vector3(0.13 * (larg + 0.4), 0.2, 0.3), 0.0, Color(0.36, 0.24, 0.14))
						_peca(pedaco, "caixa", "liso", Vector3(p.x + coluna * (larg + 0.4), yf + 0.2, zfl), Vector3(0.12 * (larg + 0.4), 0.22, 0.26), 0.0, [Color(0.85, 0.2, 0.25), Color(0.95, 0.75, 0.2), Color(0.8, 0.4, 0.75), Color(0.95, 0.95, 0.9)][_rng.randi() % 4])
						floreiras += 1
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
	var cham_x := p.x + _rng.randf_range(-larg / 4.0, larg / 4.0)
	var cham_z := p.y + _rng.randf_range(-prof / 4.0, prof / 4.0)
	var cham_l := 1.5 if forja else 0.9
	var cham_a := alt_t + (3.0 if forja else 1.0)
	_peca(pedaco, "caixa", "liso", Vector3(cham_x, topo + (alt_t + 1.0) / 2.0, cham_z), Vector3(cham_l, cham_a, cham_l), 0.0, Color(0.34, 0.32, 0.31))   # chaminé (a da forja é grossa e alta)
	var cham_topo := topo + (alt_t + 1.0) / 2.0 + cham_a / 2.0
	_peca(pedaco, "caixa", "liso", Vector3(cham_x, cham_topo + 0.06, cham_z), Vector3(cham_l + 0.26, 0.14, cham_l + 0.26), 0.0, Color(0.44, 0.42, 0.4))   # chapéu de pedra
	for sc in [-1.0, 1.0]:
		_peca(pedaco, "caixa", "liso", Vector3(cham_x + sc * cham_l * 0.22, cham_topo + 0.3, cham_z), Vector3(0.26, 0.36, 0.26), 0.0, Color(0.6, 0.32, 0.22))   # potes de barro
	var cumeeira_l := (larg if cumeeira_em_x else prof) + 1.1
	_peca(pedaco, "caixa", "liso", Vector3(p.x, topo + alt_t, p.y), Vector3(cumeeira_l if cumeeira_em_x else 0.3, 0.2, 0.3 if cumeeira_em_x else cumeeira_l), 0.0, cor_telhado.darkened(0.3))   # telhas de cumeeira
	if cumeeira_em_x and _rng_rua.randf() < 0.45:   # água-furtada virada para a rua
		var zd := p.y + frente * ((prof + 1.0) / 4.0 + 0.25)
		var yd := topo + alt_t / 2.0
		_peca(pedaco, "caixa", "liso", Vector3(p.x, yd + 0.25, zd), Vector3(1.3, 1.3, 1.5), 0.0, reboco)
		_peca(pedaco, "caixa", "liso", Vector3(p.x, yd + 0.4, zd + frente * 0.76), Vector3(0.6, 0.7, 0.04), 0.0, Color(0.17, 0.2, 0.27))
		_peca(pedaco, "caixa", "liso", Vector3(p.x, yd + 0.02, zd + frente * 0.78), Vector3(0.9, 0.08, 0.14), 0.0, MADEIRA_ESCURA)
		_peca(pedaco, "prisma", "telhado", Vector3(p.x, yd + 1.25, zd), Vector3(1.7, 0.7, 1.8), 0.0, cor_telhado)
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
