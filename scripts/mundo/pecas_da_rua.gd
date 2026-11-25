class_name PecasDaRua
extends PecasDeConstrucao
## AS PEÇAS DA RUA de Valdoria: o que fica entre o calçamento e a fachada das casas. Calçada de lajes com meio-fio,
## sarjeta no meio da rua, degrau de porta, lampião (de parede e de poste), placa de loja pendurada, barris e caixotes,
## banco e vasos de flor. Quem usa (o casario, a vida das ruas, a bancada) só diz ONDE; como é feito está aqui.
## Critério de pronto: docs/construcoes/rua.md. Chame `fechar()` no fim.

const LAJE := Color(0.5, 0.48, 0.44)
const MEIO_FIO := Color(0.62, 0.6, 0.55)
const SARJETA := Color(0.24, 0.23, 0.22)
const FERRO := Color(0.13, 0.13, 0.14)
const MADEIRA := Color(0.4, 0.28, 0.16)
const LUZ := Color(1.0, 0.8, 0.42)
const ALTURA_DA_CALCADA := 0.1   # baixa de propósito: não tem colisão, o Torin pisa por cima sem tropeçar


func _eh_pedra(cor: Color) -> bool:
	return cor.is_equal_approx(LAJE) or cor.is_equal_approx(MEIO_FIO) or cor.is_equal_approx(SARJETA)


## Calçada de `a` até `b` (pontos no chão, rente à fachada), saindo `largura` metros na direção `fora` (para a rua).
func calcada(a: Vector3, b: Vector3, fora: Vector2, largura: float) -> void:
	var meio := (a + b) / 2.0
	var comp := Vector2(b.x - a.x, b.z - a.z).length()
	var giro := atan2(b.x - a.x, b.z - a.z)
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var y := minf(a.y, b.y)
	_caixa(Vector3(meio.x, y + ALTURA_DA_CALCADA - 0.2, meio.z) + f3 * (largura / 2.0 - 0.1), Vector3(largura - 0.2, 0.4, comp), giro, LAJE, false)
	_caixa(Vector3(meio.x, y + ALTURA_DA_CALCADA - 0.18, meio.z) + f3 * (largura - 0.1), Vector3(0.24, 0.4, comp), giro, MEIO_FIO, false)


## Sarjeta: a valeta de pedra escura no meio da rua, com uma fiada clara de cada lado.
func sarjeta(a: Vector3, b: Vector3) -> void:
	var meio := (a + b) / 2.0
	var comp := Vector2(b.x - a.x, b.z - a.z).length()
	var giro := atan2(b.x - a.x, b.z - a.z)
	var y := minf(a.y, b.y)
	var lado := Vector3(cos(giro), 0.0, -sin(giro))
	_caixa(Vector3(meio.x, y + 0.045, meio.z), Vector3(0.5, 0.06, comp), giro, SARJETA, false)
	for s in [-1.0, 1.0]:
		_caixa(Vector3(meio.x, y + 0.055, meio.z) + lado * s * 0.31, Vector3(0.12, 0.06, comp), giro, LAJE, false)


## Degrau de pedra diante de uma porta (`p` no chão, rente à fachada).
func degrau(p: Vector3, fora: Vector2, largura: float) -> void:
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var giro := atan2(fora.x, fora.y)
	_caixa(p + f3 * 0.3 + Vector3(0, 0.1, 0), Vector3(largura + 0.5, 0.28, 0.6), giro, MEIO_FIO, false)
	_caixa(p + f3 * 0.14 + Vector3(0, 0.22, 0), Vector3(largura + 0.2, 0.3, 0.3), giro, LAJE, false)


## A lanterna em si: armação de ferro, vidro aceso e chapéu. `p` é o centro do vidro.
func _lanterna(p: Vector3) -> void:
	_caixa(p, Vector3(0.26, 0.36, 0.26), 0.0, LUZ, false, true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_caixa(p + Vector3(sx * 0.14, 0, sz * 0.14), Vector3(0.04, 0.42, 0.04), 0.0, FERRO, false)
	_caixa(p + Vector3(0, -0.21, 0), Vector3(0.34, 0.05, 0.34), 0.0, FERRO, false)
	_peca("prisma", FERRO, Transform3D(Basis.from_scale(Vector3(0.44, 0.2, 0.44)), p + Vector3(0, 0.31, 0)))
	_peca("prisma", FERRO, Transform3D(Basis(Vector3.UP, PI / 2.0).scaled_local(Vector3(0.44, 0.2, 0.44)), p + Vector3(0, 0.31, 0)))
	_caixa(p + Vector3(0, 0.45, 0), Vector3(0.03, 0.12, 0.03), 0.0, FERRO, false)


## Lampião de parede: braço de ferro com escora saindo da fachada e a lanterna pendurada na ponta.
func lampiao_de_parede(p: Vector3, fora: Vector2) -> void:
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var giro := atan2(fora.x, fora.y)
	var y := p.y + 2.55
	_caixa(Vector3(p.x, y, p.z) + f3 * 0.02, Vector3(0.16, 0.5, 0.05), giro, FERRO, false)          # chapa na parede
	_caixa(Vector3(p.x, y + 0.18, p.z) + f3 * 0.45, Vector3(0.05, 0.05, 0.9), giro, FERRO, false)    # braço
	_peca("caixa", FERRO, Transform3D((Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, 0.6)).scaled_local(Vector3(0.04, 0.04, 0.62)), Vector3(p.x, y - 0.02, p.z) + f3 * 0.3))   # escora
	_lanterna(Vector3(p.x, y - 0.33, p.z) + f3 * 0.82)


## Lampião de poste, para avenidas e praças: base de pedra, poste de ferro com anel, braço e lanterna.
func lampiao_de_poste(p: Vector3, para: Vector2) -> void:
	var d3 := Vector3(para.x, 0.0, para.y)
	var giro := atan2(para.x, para.y)
	_caixa(p + Vector3(0, 0.25, 0), Vector3(0.6, 0.5, 0.6), 0.0, MEIO_FIO, true)
	_caixa(p + Vector3(0, 0.55, 0), Vector3(0.42, 0.14, 0.42), 0.0, LAJE, false)
	_cilindro(p + Vector3(0, 2.2, 0), 0.07, 3.4, FERRO)
	_cilindro(p + Vector3(0, 1.0, 0), 0.11, 0.1, FERRO)
	_cilindro(p + Vector3(0, 3.7, 0), 0.11, 0.1, FERRO)
	_caixa(p + Vector3(0, 3.85, 0) + d3 * 0.4, Vector3(0.05, 0.05, 0.9), giro, FERRO, false)
	_peca("caixa", FERRO, Transform3D((Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, 0.7)).scaled_local(Vector3(0.04, 0.04, 0.6)), p + Vector3(0, 3.62, 0) + d3 * 0.24))
	_lanterna(p + Vector3(0, 3.36, 0) + d3 * 0.78)


## Placa de loja pendurada num braço de ferro, atravessada à fachada (lê-se de quem vem pela rua).
func placa(p: Vector3, fora: Vector2, cor: Color) -> void:
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var giro := atan2(fora.x, fora.y)
	var y := p.y + 2.6
	_caixa(Vector3(p.x, y, p.z) + f3 * 0.5, Vector3(0.05, 0.05, 1.0), giro, FERRO, false)
	for d in [0.3, 0.8]:
		_caixa(Vector3(p.x, y - 0.1, p.z) + f3 * float(d), Vector3(0.025, 0.2, 0.025), giro, FERRO, false)
	_caixa(Vector3(p.x, y - 0.48, p.z) + f3 * 0.55, Vector3(0.06, 0.56, 0.78), giro, MADEIRA.darkened(0.25), false)
	_caixa(Vector3(p.x, y - 0.48, p.z) + f3 * 0.55, Vector3(0.08, 0.44, 0.66), giro, cor, false)
	_caixa(Vector3(p.x, y - 0.48, p.z) + f3 * 0.55, Vector3(0.1, 0.2, 0.2), giro + PI / 4.0, Color(0.92, 0.85, 0.6), false)


func _barril(p: Vector3) -> void:
	_cilindro(p + Vector3(0, 0.45, 0), 0.3, 0.9, MADEIRA)
	_cilindro(p + Vector3(0, 0.45, 0), 0.34, 0.5, MADEIRA.lightened(0.08))   # a barriga
	for h in [0.14, 0.76]:
		_cilindro(p + Vector3(0, float(h), 0), 0.325, 0.06, FERRO)
	for h in [0.3, 0.6]:
		_cilindro(p + Vector3(0, float(h), 0), 0.35, 0.05, FERRO)
	_cilindro(p + Vector3(0, 0.9, 0), 0.27, 0.03, MADEIRA.darkened(0.2))


func _caixote(p: Vector3, lado: float, giro: float) -> void:
	_caixa(p + Vector3(0, lado / 2.0, 0), Vector3(lado, lado, lado), giro, MADEIRA.lightened(0.15), false)
	for s in [-1.0, 1.0]:   # sarrafos nas arestas e uma travessa em cada face da frente
		_caixa(p + Vector3(0, lado / 2.0 + s * (lado / 2.0 - 0.04), 0), Vector3(lado + 0.04, 0.08, lado + 0.04), giro, MADEIRA.darkened(0.15), false)
	_caixa(p + Vector3(0, lado / 2.0, 0), Vector3(0.09, lado, lado + 0.05), giro, MADEIRA.darkened(0.15), false)
	_caixa(p + Vector3(0, lado / 2.0, 0), Vector3(lado + 0.05, lado, 0.09), giro, MADEIRA.darkened(0.15), false)


## Monte de carga encostado na fachada: barris e caixotes (`quantos` de 1 a 3), com uma colisão só.
func carga(p: Vector3, ao_longo: Vector2, quantos: int, semente: int) -> void:
	var t3 := Vector3(ao_longo.x, 0.0, ao_longo.y)
	for k in quantos:
		var q := p + t3 * (k * 0.74)
		if (semente + k) % 3 == 0:
			_caixote(q, 0.62, 0.2 * ((semente + k) % 5))
			if (semente + k) % 2 == 0:
				_caixote(q + Vector3(0.05, 0.62, 0.0), 0.44, 0.5)
		else:
			_barril(q)
	_solido(p + t3 * ((quantos - 1) * 0.37) + Vector3(0, 0.5, 0), Vector3(0.8, 1.0, 0.8 + (quantos - 1) * 0.74), atan2(ao_longo.x, ao_longo.y))


## Banco de madeira encostado na fachada, com encosto.
func banco(p: Vector3, fora: Vector2) -> void:
	var f3 := Vector3(fora.x, 0.0, fora.y)
	var giro := atan2(fora.x, fora.y)
	var lado := Vector3(fora.y, 0.0, -fora.x)
	_caixa(p + f3 * 0.3 + Vector3(0, 0.45, 0), Vector3(1.6, 0.07, 0.42), giro, MADEIRA, true)
	_caixa(p + f3 * 0.07 + Vector3(0, 0.78, 0), Vector3(1.6, 0.3, 0.06), giro, MADEIRA, false)
	for s in [-1.0, 1.0]:
		_caixa(p + f3 * 0.3 + lado * s * 0.68 + Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.4), giro, MADEIRA.darkened(0.2), false)
		_caixa(p + f3 * 0.07 + lado * s * 0.68 + Vector3(0, 0.5, 0), Vector3(0.07, 0.95, 0.07), giro, MADEIRA.darkened(0.2), false)


## Vaso de barro com planta e flores, no chão junto à parede.
func vaso(p: Vector3, flor: Color) -> void:
	_cilindro(p + Vector3(0, 0.2, 0), 0.2, 0.4, Color(0.62, 0.34, 0.22))
	_cilindro(p + Vector3(0, 0.4, 0), 0.24, 0.07, Color(0.68, 0.38, 0.25))
	_cilindro(p + Vector3(0, 0.6, 0), 0.26, 0.36, Color(0.22, 0.42, 0.18))
	_cilindro(p + Vector3(0, 0.8, 0), 0.17, 0.16, Color(0.28, 0.5, 0.2))
	for k in 5:
		var a := TAU * k / 5.0
		_caixa(p + Vector3(cos(a) * 0.17, 0.82 + 0.05 * (k % 2), sin(a) * 0.17), Vector3(0.1, 0.1, 0.1), a, flor, false)
