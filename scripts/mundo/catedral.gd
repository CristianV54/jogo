class_name Catedral
extends PecasDeConstrucao
## A CATEDRAL DE VALDORIA, gótica: nave alta com naves laterais mais baixas, contrafortes com pináculo e arcobotante em
## cada tramo, vitrais ogivais de vidro colorido em chumbo, fachada de duas torres com agulha, portal em ogiva com
## arquivoltas, rosácea, torre do cruzeiro e abside. Não se entra (a porta é fechada).
## Tudo é dito no espaço da própria catedral: `l` ao longo da nave (a fachada fica em l = -24,5 e olha para -l), `w` de
## lado, `y` para cima. `montar(origem, eixo)` põe no mundo. Critério de pronto: docs/construcoes/catedral.md.

const PAREDE := Color(0.78, 0.76, 0.7)
const CLARA := Color(0.88, 0.86, 0.8)
const ESCURA := Color(0.6, 0.58, 0.54)
const ARDOSIA := Color(0.26, 0.3, 0.44)
const CHUMBO := Color(0.12, 0.12, 0.14)
const OURO := Color(0.9, 0.75, 0.3)
const VIDROS := [Color(0.85, 0.2, 0.18), Color(0.2, 0.4, 0.9), Color(0.95, 0.75, 0.2), Color(0.25, 0.7, 0.4), Color(0.65, 0.3, 0.8)]
const LATERAL := Basis.IDENTITY                # parede que corre ao longo de l; a normal é ±w
const FACHADA := Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0))   # parede que corre ao longo de w; a normal é ±l

var topo := 0.0       # altura da ponta mais alta (para os testes)
var vitrais := 0
var _o := Vector3.ZERO
var _b := Basis.IDENTITY
var _giro := 0.0


func _eh_pedra(cor: Color) -> bool:
	return cor.is_equal_approx(PAREDE) or cor.is_equal_approx(CLARA) or cor.is_equal_approx(ESCURA)


func montar(origem: Vector3, eixo: Vector2) -> void:
	name = "Catedral"
	_o = origem
	_giro = atan2(-eixo.y, eixo.x)
	_b = Basis(Vector3.UP, _giro)
	_corpo_da_igreja()
	_tramos()
	_fachada()
	_cruzeiro_e_abside()
	fechar()


## Uma peça no espaço da catedral. `local` = (l, y, w); `tam` = (ao longo de l, altura, ao longo de w).
func _em(local: Vector3, tam: Vector3, cor: Color, colidir := false, luz := false, rot := Basis.IDENTITY, malha := "caixa") -> void:
	var pos := _o + _b * local
	_peca(malha, cor, Transform3D((_b * rot).scaled_local(tam), pos), luz)
	if colidir:
		_solido(pos, tam, _giro)


## Uma peça encostada numa parede: `centro` é um ponto da face, `r` diz para que lado a parede corre, `s` o lado de fora.
## `uyn` = (ao longo da parede, para cima, para fora da parede); `tam` na mesma ordem.
func _na_parede(centro: Vector3, r: Basis, s: float, uyn: Vector3, tam: Vector3, cor: Color, luz := false, malha := "caixa") -> void:
	_em(centro + r * Vector3(uyn.x, uyn.y, uyn.z * s), tam, cor, false, luz, r, malha)


func _piramide(local: Vector3, lado: float, altura: float, cor: Color) -> void:
	_em(local + Vector3(0, altura / 2.0, 0), Vector3(lado * 1.414, altura, lado * 1.414), cor, false, false, Basis(Vector3.UP, PI / 4.0), "piramide")
	topo = maxf(topo, local.y + altura)


## Vitral ogival: moldura de pedra clara com ponta, peitoril, vidro em oito painéis coloridos, ponta de vidro e chumbo.
func _vitral(centro: Vector3, r: Basis, s: float, larg: float, alt: float, semente: int) -> void:
	_na_parede(centro, r, s, Vector3(0, alt / 2.0, 0.06), Vector3(larg + 0.5, alt + 0.2, 0.3), CLARA)
	_na_parede(centro, r, s, Vector3(0, alt + 0.1 + (larg + 0.5) * 0.4, 0.06), Vector3(larg + 0.5, (larg + 0.5) * 0.8, 0.3), CLARA, false, "prisma")
	_na_parede(centro, r, s, Vector3(0, -0.12, 0.2), Vector3(larg + 0.9, 0.24, 0.5), CLARA)
	for i in 2:
		for j in 4:
			_na_parede(centro, r, s, Vector3((i - 0.5) * larg / 2.0, (j + 0.5) * alt / 4.0, 0.2), Vector3(larg / 2.0 - 0.08, alt / 4.0 - 0.08, 0.08), VIDROS[(semente + i + j * 2) % VIDROS.size()], true)
	_na_parede(centro, r, s, Vector3(0, alt + larg * 0.4, 0.2), Vector3(larg - 0.1, larg * 0.8, 0.08), VIDROS[(semente + 3) % VIDROS.size()], true, "prisma")
	_na_parede(centro, r, s, Vector3(0, alt / 2.0, 0.19), Vector3(larg, alt, 0.06), CHUMBO)
	vitrais += 1


func _corpo_da_igreja() -> void:
	_em(Vector3(2, 10, 0), Vector3(40, 20, 13), PAREDE, true)                      # nave
	_em(Vector3(2, 0.9, 0), Vector3(40.6, 1.8, 13.6), ESCURA)                      # soco
	_em(Vector3(2, 19.7, 0), Vector3(40.6, 0.6, 13.8), CLARA)                      # cornija
	_em(Vector3(2, 24.5, 0), Vector3(14.4, 9.0, 41.0), ARDOSIA, false, false, Basis(Vector3.UP, PI / 2.0), "prisma")
	_em(Vector3(2, 29.1, 0), Vector3(41.2, 0.3, 0.4), CHUMBO)                      # cumeeira
	for s in [-1.0, 1.0]:
		_em(Vector3(2, 5, s * 10.0), Vector3(38, 10, 7), PAREDE, true)             # nave lateral
		_em(Vector3(2, 0.9, s * 10.2), Vector3(38.6, 1.8, 7.4), ESCURA)
		_em(Vector3(2, 9.8, s * 10.2), Vector3(38.6, 0.5, 7.5), CLARA)
		_em(Vector3(2, 11.6, s * 10.1), Vector3(38.4, 0.3, 8.0), ARDOSIA, false, false, Basis(Vector3.RIGHT, s * 0.42))   # telhado de meia-água
		_em(Vector3(22.5, 23.0, 0), Vector3(0.4, 6.0, 0.1), CLARA)


## Em cada tramo: contraforte em dois degraus com pináculo, arcobotante até a nave, vitral baixo e vitral alto.
func _tramos() -> void:
	for s in [-1.0, 1.0]:
		for k in 7:
			var l := -15.0 + k * 5.6
			_em(Vector3(l, 4.0, s * 14.3), Vector3(1.7, 8.0, 2.2), PAREDE, true)
			_em(Vector3(l, 0.9, s * 14.4), Vector3(2.0, 1.8, 2.6), ESCURA)
			_em(Vector3(l, 8.1, s * 14.3), Vector3(1.9, 0.3, 2.4), CLARA)
			_em(Vector3(l, 11.0, s * 14.1), Vector3(1.3, 5.6, 1.6), PAREDE)
			_em(Vector3(l, 13.9, s * 14.1), Vector3(1.5, 0.3, 1.8), CLARA)
			_piramide(Vector3(l, 14.05, s * 14.1), 1.2, 3.2, CLARA)
			_em(Vector3(l, 14.4, s * 10.3), Vector3(0.7, 0.7, 8.4), PAREDE, false, false, Basis(Vector3.RIGHT, s * 0.5))   # arcobotante
			_em(Vector3(l, 14.0, s * 6.62), Vector3(1.1, 12.0, 0.3), CLARA)        # pilastra na parede da nave
			if k < 6:
				_vitral(Vector3(l + 2.8, 2.6, s * 13.5), LATERAL, s, 1.6, 4.2, k)
				_vitral(Vector3(l + 2.8, 12.0, s * 6.5), LATERAL, s, 1.7, 5.2, k + 2)


func _torre(l: float, w: float, lado: float, altura: float, agulha: float) -> void:
	_em(Vector3(l, altura / 2.0, w), Vector3(lado, altura, lado), PAREDE, true)
	_em(Vector3(l, 1.0, w), Vector3(lado + 0.6, 2.0, lado + 0.6), ESCURA)
	var cinta := 9.0
	while cinta < altura - 2.0:
		_em(Vector3(l, cinta, w), Vector3(lado + 0.4, 0.4, lado + 0.4), CLARA)
		cinta += 8.0
	_em(Vector3(l, altura - 0.3, w), Vector3(lado + 0.8, 0.6, lado + 0.8), CLARA)
	for face in [[LATERAL, 1.0, Vector3(l, 0, w + lado / 2.0)], [LATERAL, -1.0, Vector3(l, 0, w - lado / 2.0)], [FACHADA, 1.0, Vector3(l + lado / 2.0, 0, w)], [FACHADA, -1.0, Vector3(l - lado / 2.0, 0, w)]]:
		var c: Vector3 = face[2]   # sineira: duas aberturas ogivais com venezianas escuras em cada face
		for u in [-1.0, 1.0]:
			_na_parede(c + Vector3(0, altura - 8.0, 0), face[0], float(face[1]), Vector3(u * lado * 0.2, 2.2, 0.05), Vector3(lado * 0.26, 4.4, 0.2), CLARA)
			_na_parede(c + Vector3(0, altura - 8.0, 0), face[0], float(face[1]), Vector3(u * lado * 0.2, 4.4 + lado * 0.1, 0.05), Vector3(lado * 0.26, lado * 0.2, 0.2), CLARA, false, "prisma")
			_na_parede(c + Vector3(0, altura - 8.0, 0), face[0], float(face[1]), Vector3(u * lado * 0.2, 2.2, 0.12), Vector3(lado * 0.17, 4.0, 0.1), CHUMBO)
	for sl in [-1.0, 1.0]:
		for sw in [-1.0, 1.0]:
			_piramide(Vector3(l + sl * (lado / 2.0 - 0.4), altura, w + sw * (lado / 2.0 - 0.4)), 1.1, 3.4, CLARA)
	_piramide(Vector3(l, altura, w), lado - 1.4, agulha, ARDOSIA)
	_em(Vector3(l, altura + agulha + 0.7, w), Vector3(0.14, 1.6, 0.14), OURO)
	_em(Vector3(l, altura + agulha + 1.0, w), Vector3(0.14, 0.14, 0.8), OURO)
	topo = maxf(topo, altura + agulha + 1.5)


## Fachada: duas torres, pano central com empena, portal em ogiva com três arquivoltas, portas, escadaria e rosácea.
func _fachada() -> void:
	for s in [-1.0, 1.0]:
		_torre(-21.0, s * 8.0, 7.0, 34.0, 14.0)
		_vitral(Vector3(-24.5, 12.0, s * 8.0), FACHADA, -1.0, 1.6, 5.0, 1)
		_vitral(Vector3(-24.5, 3.0, s * 8.0), FACHADA, -1.0, 1.4, 3.6, 4)
	_em(Vector3(-19.0, 10, 0), Vector3(3.0, 20, 9.0), PAREDE, true)
	_em(Vector3(-20.3, 22.3, 0), Vector3(9.4, 4.8, 0.5), PAREDE, false, false, FACHADA, "prisma")    # empena
	_em(Vector3(-20.3, 25.3, 0), Vector3(0.14, 1.5, 0.14), OURO)
	_em(Vector3(-20.3, 25.6, 0), Vector3(0.14, 0.14, 0.8), OURO)
	var face := Vector3(-20.5, 0, 0)
	for k in 3:   # arquivoltas: três molduras em ogiva, cada uma menor e mais funda
		var larg := 6.4 - k * 0.9
		var alt := 5.6 - k * 0.35
		var cor: Color = [CLARA, PAREDE, CLARA][k]
		for u in [-1.0, 1.0]:
			_na_parede(face, FACHADA, -1.0, Vector3(u * (larg / 2.0 - 0.22), alt / 2.0, 0.5 - k * 0.14), Vector3(0.45, alt, 0.3), cor)
		_na_parede(face, FACHADA, -1.0, Vector3(0, alt + larg * 0.32, 0.5 - k * 0.14), Vector3(larg, larg * 0.64, 0.3), cor, false, "prisma")
	_na_parede(face, FACHADA, -1.0, Vector3(0, 4.9 + 1.2, 0.12), Vector3(3.5, 2.3, 0.1), ESCURA, false, "prisma")   # tímpano
	for u in [-1.0, 1.0]:   # duas folhas de porta com ferragens
		_na_parede(face, FACHADA, -1.0, Vector3(u * 0.9, 2.45, 0.1), Vector3(1.75, 4.9, 0.14), Color(0.34, 0.22, 0.13))
		for yb in [1.0, 2.5, 4.0]:
			_na_parede(face, FACHADA, -1.0, Vector3(u * 0.9, yb, 0.18), Vector3(1.6, 0.14, 0.04), CHUMBO)
		_na_parede(face, FACHADA, -1.0, Vector3(u * 0.25, 2.3, 0.2), Vector3(0.12, 0.3, 0.06), OURO)
	_na_parede(face, FACHADA, -1.0, Vector3(0, 2.45, 0.19), Vector3(0.12, 4.9, 0.06), CHUMBO)
	for k in 3:   # escadaria
		_em(Vector3(-21.6 - k * 0.55, 0.36 - k * 0.14, 0), Vector3(1.4, 0.2, 9.0 + k * 1.0), CLARA)
	_solido(_o + _b * Vector3(-22.0, 0.05, 0), Vector3(2.4, 0.3, 10.0), _giro)
	var cr := Vector3(-20.5, 13.6, 0)   # rosácea: aro de pedra, doze pétalas de vidro, miolo dourado
	var deitar := Basis(Vector3.BACK, PI / 2.0)
	_em(cr, Vector3(6.0, 0.5, 6.0), CLARA, false, false, deitar, "cilindro")
	_em(cr + Vector3(-0.1, 0, 0), Vector3(5.2, 0.5, 5.2), CHUMBO, false, false, deitar, "cilindro")
	for k in 12:
		var a := TAU * k / 12.0
		_em(cr + Vector3(-0.38, sin(a) * 1.7, cos(a) * 1.7), Vector3(0.06, 1.5, 0.72), VIDROS[k % VIDROS.size()], false, true, Basis(Vector3.RIGHT, PI / 2.0 - a))
		_em(cr + Vector3(-0.4, sin(a + TAU / 24.0) * 1.3, cos(a + TAU / 24.0) * 1.3), Vector3(0.1, 2.5, 0.1), CLARA, false, false, Basis(Vector3.RIGHT, PI / 2.0 - a - TAU / 24.0))
	_em(cr + Vector3(-0.42, 0, 0), Vector3(1.1, 0.12, 1.1), OURO, false, true, deitar, "cilindro")
	vitrais += 1


func _cruzeiro_e_abside() -> void:
	_torre(8.0, 0.0, 9.0, 44.0, 19.0)
	for s in [-1.0, 1.0]:   # braços do transepto, com um vitral grande em cada ponta
		_em(Vector3(8.0, 9.0, s * 11.5), Vector3(9.0, 18.0, 10.0), PAREDE, true)
		_em(Vector3(8.0, 0.9, s * 11.7), Vector3(9.5, 1.8, 10.2), ESCURA)
		_em(Vector3(8.0, 20.0, s * 11.5), Vector3(9.6, 4.0, 10.4), ARDOSIA, false, false, Basis.IDENTITY, "prisma")
		_vitral(Vector3(8.0, 4.0, s * 16.5), LATERAL, s, 2.6, 8.0, 2)
	_em(Vector3(25.0, 8.0, 0), Vector3(7.0, 16.0, 10.0), PAREDE, true)             # abside
	_em(Vector3(25.0, 0.9, 0), Vector3(7.5, 1.8, 10.5), ESCURA)
	_em(Vector3(25.0, 15.8, 0), Vector3(7.5, 0.5, 10.5), CLARA)
	_piramide(Vector3(25.0, 16.0, 0), 7.6, 6.0, ARDOSIA)
	for w in [-3.0, 0.0, 3.0]:
		_vitral(Vector3(28.5, 4.0, w), FACHADA, 1.0, 1.5, 6.0, int(w) + 4)
	for s in [-1.0, 1.0]:
		_vitral(Vector3(25.0, 4.0, s * 5.0), LATERAL, s, 1.5, 6.0, 1)
