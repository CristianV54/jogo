class_name PecasDaMuralha
extends PecasDeConstrucao
## AS PEÇAS DA MURALHA de Valdoria: lanço, torre de vigia, escada de acesso e portão. Quem as usa (a muralha do reino, a
## bancada de construção) só diz ONDE fica cada peça; como ela é feita está aqui. Critério de pronto: docs/construcoes/muralha.md.
##
## O LANÇO tem, de baixo para cima: soco de pedra escura mais grosso que a parede (talude em dois degraus), a parede, a
## cornija saliente apoiada em cachorros de pedra, o caminho de ronda (dá para andar em cima), ameias do lado de fora e um
## parapeito baixo do lado de dentro. A cada 20 m há um contraforte.
## A TORRE é redonda, mais alta que a muralha, com base alargada, cinta, seteiras, portas para o caminho de ronda, ameias e
## estandarte. O PORTÃO é uma casa de portão funda com passagem em arco de verdade, grade levadiça erguida, folhas de
## madeira abertas, duas torres maiores, estandartes com faixa e braseiros.
## Tudo é desenhado em MultiMesh (centenas de pedras, poucas chamadas de desenho). Chame `fechar()` no fim.

const ALTURA := 11.0          # do chão ao piso do caminho de ronda
const ESPESSURA := 4.6
const VAO := 9.0              # largura livre da passagem do portão
const ALTURA_DO_ARCO := 8.0   # do chão ao fecho do arco
const MEIA_CASA_DO_PORTAO := 7.5   # metade da largura da casa do portão (vão + os dois pés-direitos de 3 m)
const RAIO_TORRE := 5.5
const RAIO_TORRE_DO_PORTAO := 7.0
const COR_PAREDE := Color(0.52, 0.48, 0.42)
const COR_SOCO := Color(0.4, 0.37, 0.33)
const COR_COROA := Color(0.6, 0.56, 0.49)
const AZUL_DO_REI := Color(0.14, 0.2, 0.5)

var _metros := 0.0
var pedra_clara := 0.0   # 0 = pedra parda da muralha da cidade; 1 = pedra branca da cidadela


# ---------------------------------------------------------------- peças

## Lanço de muralha entre dois pontos do chão (x, altura do chão, z). `fora` aponta para o lado de fora da cidade.
func lanco(p0: Vector3, p1: Vector3, fora: Vector2) -> void:
	var meio := (p0 + p1) / 2.0
	var comp := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	var tang := Vector2(p1.x - p0.x, p1.z - p0.z).normalized()
	var giro := atan2(tang.x, tang.y)   # o eixo Z da caixa corre ao longo do lanço
	var y := minf(p0.y, p1.y) - 1.5     # a base entra 1,5 m no chão: em ladeira não aparece vão
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var t3 := Vector3(tang.x, 0.0, tang.y)
	var c := comp + 0.35
	_caixa(Vector3(meio.x, y + (ALTURA + 1.5) / 2.0, meio.z), Vector3(ESPESSURA, ALTURA + 1.5, c), giro, COR_PAREDE, true)
	_caixa(Vector3(meio.x, y + 2.6, meio.z), Vector3(ESPESSURA + 1.2, 5.2, c), giro, COR_SOCO, true)          # soco: primeiro degrau do talude
	_caixa(Vector3(meio.x, y + 4.2, meio.z), Vector3(ESPESSURA + 0.6, 8.4, c), giro, COR_SOCO.lerp(COR_PAREDE, 0.5), false)   # segundo degrau
	var topo := y + ALTURA + 1.5
	_caixa(meio * Vector3(1, 0, 1) + Vector3(0, topo - 0.55, 0) + f3 * (ESPESSURA / 2.0 + 0.3), Vector3(0.9, 0.9, c), giro, COR_COROA, false)   # cornija
	for k in 3:   # cachorros de pedra que seguram a cornija
		var q := meio + t3 * ((k - 1) * comp / 3.0)
		_caixa(Vector3(q.x, topo - 1.35, q.z) + f3 * (ESPESSURA / 2.0 + 0.2), Vector3(0.6, 0.7, 0.55), giro, COR_SOCO, false)
	# ameias do lado de fora: parapeito corrido e merlões; por dentro, parapeito baixo
	_caixa(meio * Vector3(1, 0, 1) + Vector3(0, topo + 0.5, 0) + f3 * (ESPESSURA / 2.0 + 0.35), Vector3(0.6, 1.0, c), giro, COR_COROA, false)
	for k in 2:
		var q := meio + t3 * ((k - 0.5) * comp / 2.0)
		_caixa(Vector3(q.x, topo + 1.55, q.z) + f3 * (ESPESSURA / 2.0 + 0.35), Vector3(0.62, 1.1, comp * 0.29), giro, COR_COROA, false)
	_caixa(meio * Vector3(1, 0, 1) + Vector3(0, topo + 0.4, 0) - f3 * (ESPESSURA / 2.0 - 0.2), Vector3(0.4, 0.8, c), giro, COR_COROA, false)
	_solido(meio * Vector3(1, 0, 1) + Vector3(0, topo + 1.0, 0) + f3 * (ESPESSURA / 2.0 + 0.35), Vector3(0.6, 2.0, c), giro)   # ninguém cai para fora
	_metros += comp
	if fmod(_metros, 20.0) < comp:   # contraforte a cada 20 m, do lado de fora
		_caixa(Vector3(meio.x, y + ALTURA * 0.42, meio.z) + f3 * (ESPESSURA / 2.0 + 1.0), Vector3(1.8, ALTURA * 0.84, 2.4), giro, COR_SOCO.lerp(COR_PAREDE, 0.5), true)
		_caixa(Vector3(meio.x, y + ALTURA * 0.84 + 0.4, meio.z) + f3 * (ESPESSURA / 2.0 + 0.7), Vector3(1.2, 0.8, 2.4), giro, COR_COROA, false)


## Torre de vigia redonda no ponto `p` (chão). `tang` é a direção da muralha ali (para as portas do caminho de ronda).
func torre(p: Vector3, tang: Vector2, raio := RAIO_TORRE, sobra := 7.0, estandarte := true) -> void:
	var y := p.y - 1.5
	var alt := ALTURA + 1.5 + sobra   # até o piso da torre
	_cilindro(Vector3(p.x, y + alt / 2.0, p.z), raio, alt, COR_PAREDE)
	_cilindro(Vector3(p.x, y + 2.2, p.z), raio + 0.9, 4.4, COR_SOCO)                       # base alargada
	_cilindro(Vector3(p.x, y + 5.4, p.z), raio + 0.45, 2.0, COR_SOCO.lerp(COR_PAREDE, 0.5))
	_cilindro(Vector3(p.x, y + ALTURA + 1.5, p.z), raio + 0.3, 0.6, COR_COROA)             # cinta na altura do caminho de ronda
	_cilindro(Vector3(p.x, y + alt - 0.5, p.z), raio + 0.8, 1.0, COR_COROA)                # cornija sob as ameias
	var topo := y + alt
	for k in 16:   # parapeito em roda e, por cima, um merlão sim, um não
		var a := TAU * (k + 0.5) / 16.0
		var q := Vector3(p.x + cos(a) * (raio + 0.45), 0.0, p.z + sin(a) * (raio + 0.45))
		var larg := TAU * (raio + 0.45) / 16.0 + 0.08
		_caixa(q + Vector3(0, topo + 0.5, 0), Vector3(larg, 1.0, 0.6), -a + PI / 2.0, COR_COROA, false)
		if k % 2 == 0:
			_caixa(q + Vector3(0, topo + 1.55, 0), Vector3(larg, 1.1, 0.62), -a + PI / 2.0, COR_COROA, false)
	for nivel in [5.5, ALTURA + 1.5 + sobra * 0.5]:   # seteiras em dois andares
		for k in 6:
			var a: float = TAU * (k + 0.25) / 6.0 + float(nivel)
			_caixa(Vector3(p.x + cos(a) * (raio + 0.02), y + float(nivel), p.z + sin(a) * (raio + 0.02)), Vector3(0.45, 2.0, 0.3), -a + PI / 2.0, Color(0.08, 0.08, 0.1), false)
	for s in [-1.0, 1.0]:   # portas de madeira para o caminho de ronda, dos dois lados
		var d: Vector3 = Vector3(tang.x, 0.0, tang.y) * s
		_caixa(Vector3(p.x, y + ALTURA + 1.5 + 1.25, p.z) + d * (raio + 0.03), Vector3(1.5, 2.5, 0.2), atan2(d.x, d.z), Color(0.3, 0.2, 0.12), false)
	if estandarte:
		_caixa(Vector3(p.x, topo + 3.5, p.z), Vector3(0.2, 7.0, 0.2), 0.0, Color(0.2, 0.15, 0.1), false)
		_caixa(Vector3(p.x + 1.7, topo + 5.9, p.z), Vector3(3.2, 2.0, 0.08), 0.0, AZUL_DO_REI, false)
		_caixa(Vector3(p.x + 1.7, topo + 5.9, p.z), Vector3(3.24, 0.36, 0.1), 0.0, Color(0.92, 0.9, 0.82), false)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = alt
	cs.shape = forma
	cs.position = Vector3(p.x, y + alt / 2.0, p.z)
	_corpo.add_child(cs)


## Escada de pedra encostada na face de DENTRO da muralha: sobe de `pe` (chão), ao longo de `tang`, até o caminho de ronda.
func escada(pe: Vector3, tang: Vector2, fora: Vector2) -> void:
	var corrida := 17.0
	var largura := 2.0
	var t3 := Vector3(tang.x, 0.0, tang.y)
	var dentro := -Vector3(fora.x, 0.0, fora.y)
	var eixo := pe + dentro * (largura / 2.0)
	var y0 := pe.y
	var y1 := pe.y + ALTURA
	var degraus := 44
	var giro := atan2(tang.x, tang.y)
	for i in degraus:   # cada degrau é um bloco maciço do chão até a altura dele, com uma laje mais clara no piso
		var t := (i + 0.5) / degraus
		var q := eixo + t3 * (corrida * t)
		var h := (y1 - y0) * (i + 1.0) / degraus
		_caixa(Vector3(q.x, y0 + (h - 0.1) / 2.0 - 0.75, q.z), Vector3(largura, h - 0.1 + 1.5, corrida / degraus + 0.03), giro, COR_PAREDE, false)
		_caixa(Vector3(q.x, y0 + h - 0.05, q.z), Vector3(largura + 0.06, 0.1, corrida / degraus + 0.05), giro, COR_COROA, false)
	var rampa := CollisionShape3D.new()   # a colisão é uma rampa lisa: o Torin sobe sem tropeçar em degrau
	var forma := BoxShape3D.new()
	forma.size = Vector3(largura, 0.6, Vector2(corrida, y1 - y0).length())
	rampa.shape = forma
	rampa.position = eixo + t3 * (corrida / 2.0) + Vector3(0, (y1 - y0) / 2.0 - 0.26, 0)
	rampa.basis = Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, -atan2(y1 - y0, corrida))
	_corpo.add_child(rampa)
	var patamar := eixo + t3 * (corrida + 1.2)   # patamar no alto, na altura do caminho de ronda
	_caixa(Vector3(patamar.x, y0 + ALTURA / 2.0, patamar.z), Vector3(largura, ALTURA, 2.4), giro, COR_PAREDE, true)
	# guarda-corpo do lado de dentro: uma mureta inclinada que acompanha a subida, e outra reta no patamar
	var inclina := Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, -atan2(y1 - y0, corrida))
	var meio_g := eixo + t3 * (corrida / 2.0) + dentro * (largura / 2.0 - 0.15) + Vector3(0, (y1 - y0) / 2.0 + 0.75, 0)
	_peca("caixa", COR_COROA, Transform3D(inclina.scaled_local(Vector3(0.3, 1.0, Vector2(corrida, y1 - y0).length() + 0.2)), meio_g))
	_caixa(Vector3(patamar.x, y0 + ALTURA + 0.5, patamar.z) + dentro * (largura / 2.0 - 0.15), Vector3(0.3, 1.0, 2.4), giro, COR_COROA, false)


## Portão: `g` é o meio da passagem (chão), `fora` aponta para fora da cidade.
func portao(g: Vector3, fora: Vector2) -> void:
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var lado := Vector3(-fora.y, 0.0, fora.x)
	var giro := atan2(lado.x, lado.z)   # eixo Z das caixas ao longo da muralha; X para fora
	var y := g.y - 1.0
	var fundo := 9.0                    # a casa do portão é mais funda que a muralha
	var alto := ALTURA + 5.0
	for s in [-1.0, 1.0]:   # pés-direitos da passagem
		_caixa(g * Vector3(1, 0, 1) + Vector3(0, y + alto / 2.0, 0) + lado * s * (VAO / 2.0 + 1.5), Vector3(fundo, alto, 3.0), giro, COR_PAREDE, true)
		_caixa(g * Vector3(1, 0, 1) + Vector3(0, y + 1.7, 0) + lado * s * (VAO / 2.0 + 1.5), Vector3(fundo + 0.8, 3.4, 3.6), giro, COR_SOCO, false)
	var y_arco := g.y + ALTURA_DO_ARCO
	_caixa(g * Vector3(1, 0, 1) + Vector3(0, (y_arco + y + alto) / 2.0, 0), Vector3(fundo, y + alto - y_arco, VAO), giro, COR_PAREDE, true)   # o pano por cima do arco
	_arco(g, f3, lado, fundo)
	for sentido in [-1.0, 1.0]:   # aduelas claras em volta do arco, pedra de fecho e ombreiras, por fora e por dentro
		var face: Vector3 = g * Vector3(1, 0, 1) + f3 * sentido * (fundo / 2.0 + 0.08)
		for k in 15:
			var ang := PI * (k + 0.5) / 15.0
			var radial := lado * cos(ang) + Vector3.UP * sin(ang)
			var tangente := -lado * sin(ang) + Vector3.UP * cos(ang)
			var fecho := k == 7
			var alt_pedra := 1.5 if fecho else (1.05 if k % 2 == 0 else 0.85)
			var base := Basis(tangente * (PI * 5.0 / 15.0 - 0.06), radial * alt_pedra, f3 * (0.5 if fecho else 0.36))
			_peca("caixa", COR_COROA, Transform3D(base, face + Vector3(0, g.y + 3.5, 0) + radial * (VAO / 2.0 + alt_pedra / 2.0)))
		for s in [-1.0, 1.0]:
			for fiada in 5:
				var larg_o := 1.05 if fiada % 2 == 0 else 0.8
				_caixa(face + lado * s * (VAO / 2.0 + larg_o / 2.0) + Vector3(0, g.y + 0.35 + fiada * 0.7, 0), Vector3(0.36, 0.66, larg_o), giro, COR_COROA, false)
	for k in 9:   # cachorros de pedra sob a cornija da frente
		_caixa(g * Vector3(1, 0, 1) + lado * ((k - 4.0) * 1.7) + Vector3(0, y + alto - 1.3, 0) + f3 * (fundo / 2.0 + 0.25), Vector3(0.6, 0.6, 0.5), giro, COR_SOCO.lerp(COR_COROA, 0.5), false)
	_caixa(g * Vector3(1, 0, 1) + Vector3(0, y + alto - 0.5, 0) + f3 * (fundo / 2.0 + 0.3), Vector3(0.9, 1.0, VAO + 6.0), giro, COR_COROA, false)   # cornija da frente
	for k in 7:   # ameias da casa do portão, na frente e atrás
		var q := g * Vector3(1, 0, 1) + lado * ((k - 3.0) * 2.3)
		for sentido in [-1.0, 1.0]:
			_caixa(q + Vector3(0, y + alto + 0.5, 0) + f3 * sentido * (fundo / 2.0 + 0.1), Vector3(0.6, 1.0, 2.3), giro, COR_COROA, false)
			if k % 2 == 0:
				_caixa(q + Vector3(0, y + alto + 1.55, 0) + f3 * sentido * (fundo / 2.0 + 0.1), Vector3(0.62, 1.1, 1.3), giro, COR_COROA, false)
	# grade levadiça erguida: só as pontas aparecem no alto do arco
	var ferro := Color(0.13, 0.13, 0.14)
	var zg := f3 * (fundo / 2.0 - 1.6)
	for k in 13:
		var x := (k - 6.0) * 0.7
		var teto := g.y + 3.5 + sqrt(maxf(0.0, pow(VAO / 2.0, 2.0) - x * x))   # onde o arco está, ali
		var ponta := g.y + ALTURA_DO_ARCO - 2.3
		if teto > ponta + 0.3:
			_caixa(g * Vector3(1, 0, 1) + lado * x + zg + Vector3(0, (teto + ponta) / 2.0, 0), Vector3(0.14, teto - ponta, 0.14), giro, ferro, false)
	_caixa(g * Vector3(1, 0, 1) + zg + Vector3(0, g.y + ALTURA_DO_ARCO - 1.5, 0), Vector3(0.14, 0.14, 5.4), giro, ferro, false)
	for s in [-1.0, 1.0]:   # folhas de madeira abertas para dentro, encostadas nos pés-direitos, com ferragens
		var folha: Vector3 = g * Vector3(1, 0, 1) + lado * s * (VAO / 2.0 - 0.16) - f3 * (fundo / 2.0 - 2.4)
		_caixa(folha + Vector3(0, g.y + 3.3, 0), Vector3(4.4, 6.6, 0.3), giro, Color(0.33, 0.22, 0.13), false)
		for yb in [1.2, 3.3, 5.4]:
			_caixa(folha + Vector3(0, g.y + yb, 0) - lado * s * 0.05, Vector3(4.4, 0.22, 0.34), giro, ferro, false)
	for s in [-1.0, 1.0]:   # torres do portão, estandartes com faixa e braseiros
		var pt: Vector3 = g + lado * s * (MEIA_CASA_DO_PORTAO + RAIO_TORRE_DO_PORTAO - 0.8) + f3 * 1.5
		torre(pt, Vector2(lado.x, lado.z), RAIO_TORRE_DO_PORTAO, 11.0)
		var pano: Vector3 = pt + f3 * (RAIO_TORRE_DO_PORTAO + 0.12)
		_caixa(pano + Vector3(0, 11.0, 0), Vector3(0.1, 8.0, 3.0), giro, AZUL_DO_REI, false)
		_caixa(pano + f3 * 0.02 + Vector3(0, 11.0, 0), Vector3(0.1, 8.0, 0.5), giro, Color(0.92, 0.9, 0.82), false)
		_caixa(pano + f3 * 0.02 + Vector3(0, 13.4, 0), Vector3(0.1, 1.1, 1.1), giro + PI / 4.0, Color(0.85, 0.72, 0.3), false)
		var bra: Vector3 = g + lado * s * (VAO / 2.0 + 1.5) - f3 * (fundo / 2.0 + 1.6)
		# braseiro: pedestal de pedra, três pés de ferro, bacia e a chama em línguas (laranja por fora, amarela por dentro)
		_cilindro(bra + Vector3(0, 0.3, 0), 0.55, 0.6, COR_SOCO)
		for k in 3:
			var ab := TAU * k / 3.0
			_peca("caixa", ferro, Transform3D((Basis(Vector3.UP, -ab) * Basis(Vector3.BACK, 0.25)).scaled_local(Vector3(0.07, 0.9, 0.07)), bra + Vector3(cos(ab) * 0.3, 1.0, sin(ab) * 0.3)))
		_cilindro(bra + Vector3(0, 1.5, 0), 0.55, 0.22, ferro)
		_cilindro(bra + Vector3(0, 1.6, 0), 0.47, 0.08, Color(0.25, 0.1, 0.05))
		for k in 4:
			var af := TAU * k / 4.0 + 0.4
			_peca("piramide", Color(1.0, 0.5, 0.12), Transform3D(Basis(Vector3.UP, af).scaled_local(Vector3(0.34, 0.75 + 0.2 * (k % 2), 0.34)), bra + Vector3(cos(af) * 0.17, 2.0 + 0.1 * (k % 2), sin(af) * 0.17)), true)
		_peca("piramide", Color(1.0, 0.85, 0.35), Transform3D(Basis.from_scale(Vector3(0.3, 1.1, 0.3)), bra + Vector3(0, 2.15, 0)), true)


## O arco da passagem: os dois cantos de pedra entre a imposta (3,5 m) e o fecho (8 m), cortados em meio círculo.
func _arco(g: Vector3, f3: Vector3, lado: Vector3, fundo: float) -> void:
	var r := VAO / 2.0
	var y_imposta := g.y + ALTURA_DO_ARCO - r
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 12
	for s in [-1.0, 1.0]:
		var canto := Vector2(float(s) * r, r)   # (x ao longo da muralha, altura acima da imposta) = canto de cima
		for i in n:
			var a0 := PI / 2.0 * i / n
			var a1 := PI / 2.0 * (i + 1) / n
			var p0 := Vector2(float(s) * r * cos(a0), r * sin(a0))
			var p1 := Vector2(float(s) * r * cos(a1), r * sin(a1))
			for face in [-1.0, 1.0]:   # frente e fundo
				var z: Vector3 = f3 * float(face) * fundo / 2.0
				var tri: Array = [canto, p0, p1] if float(face) * float(s) > 0.0 else [canto, p1, p0]
				for v in tri:
					st.add_vertex(g * Vector3(1, 0, 1) + lado * (v as Vector2).x + Vector3(0, y_imposta + (v as Vector2).y, 0) + z)
			var q: Array = [[p0, -1.0], [p1, -1.0], [p1, 1.0], [p0, -1.0], [p1, 1.0], [p0, 1.0]]   # o intradorso (a barriga do arco)
			if float(s) < 0.0:
				q.reverse()
			for v in q:
				st.add_vertex(g * Vector3(1, 0, 1) + lado * (v[0] as Vector2).x + Vector3(0, y_imposta + (v[0] as Vector2).y, 0) + f3 * float(v[1]) * fundo / 2.0)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Arco"
	mi.mesh = st.commit()
	var pedra_do_arco := Pedra.material(COR_PAREDE).duplicate() as StandardMaterial3D
	pedra_do_arco.cull_mode = BaseMaterial3D.CULL_DISABLED   # o arco se vê por baixo e pelos dois lados
	mi.material_override = pedra_do_arco
	add_child(mi)


# ---------------------------------------------------------------- acabamento

## Monta os MultiMesh. Chamar uma vez, depois de pôr todas as peças.
func _eh_pedra(cor: Color) -> bool:
	return cor.is_equal_approx(COR_PAREDE) or cor.is_equal_approx(COR_SOCO) or cor.is_equal_approx(COR_COROA) or cor.is_equal_approx(COR_SOCO.lerp(COR_PAREDE, 0.5))


func _cor_final(cor: Color) -> Color:
	return cor.lerp(Color(0.95, 0.93, 0.89), pedra_clara * 0.8) if _eh_pedra(cor) else cor
