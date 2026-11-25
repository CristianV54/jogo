class_name PecasDaRua
extends PecasDeConstrucao
## AS PEÇAS DA RUA de Valdoria: o que fica entre o calçamento e a fachada das casas. Calçada de lajes com meio-fio,
## sarjeta no meio da rua, degrau de porta, lampião (de parede e de poste), placa de loja pendurada, barris e caixotes,
## banco e vasos de flor. Quem usa (o casario, a vida das ruas, a bancada) só diz ONDE; como é feito está aqui.
## Critério de pronto: docs/construcoes/rua.md. Chame `fechar()` no fim.

const LAJE := Color(0.42, 0.4, 0.37)
const MEIO_FIO := Color(0.52, 0.5, 0.46)
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


## Peça solta de um conjunto girado: `local` e `tam` no espaço do conjunto (Z = frente), `inclina` gira em torno do X dele.
func _no_conjunto(p: Vector3, giro: float, local: Vector3, tam: Vector3, cor: Color, inclina := 0.0, malha := "caixa") -> void:
	var b := Basis(Vector3.UP, giro)
	_peca(malha, cor, Transform3D((b * Basis(Vector3.RIGHT, inclina)).scaled_local(tam), p + b * local))


## Barraca de feira: quatro esteios, toldo listrado inclinado com sanefa, balcão com saia de pano e caixas de mercadoria.
## `frente` aponta para o freguês. `mercadoria` são as cores do que está à venda (frutas, panos, queijos...).
func barraca(p: Vector3, frente: Vector2, cor: Color, mercadoria: Array) -> void:
	var giro := atan2(frente.x, frente.y)
	var creme := Color(0.93, 0.9, 0.82)
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 1.6, 1.25, 1.2), Vector3(0.12, 2.5, 0.12), MADEIRA.darkened(0.2))
		_no_conjunto(p, giro, Vector3(sx * 1.6, 1.0, -1.2), Vector3(0.12, 2.0, 0.12), MADEIRA.darkened(0.2))
		_no_conjunto(p, giro, Vector3(sx * 1.6, 2.22, 0.0), Vector3(0.08, 0.08, 2.5), MADEIRA.darkened(0.2), -0.2)
	_no_conjunto(p, giro, Vector3(0, 2.45, 1.2), Vector3(3.3, 0.08, 0.08), MADEIRA.darkened(0.2))
	for k in 7:   # toldo em sete faixas, uma na cor da barraca, outra creme
		var x := (k - 3.0) * 0.5
		var c := cor if k % 2 == 0 else creme
		_no_conjunto(p, giro, Vector3(x, 2.33, 0.05), Vector3(0.5, 0.05, 3.0), c, -0.2)
		_no_conjunto(p, giro, Vector3(x, 2.47 - (0.06 if k % 2 == 0 else 0.0), 1.54), Vector3(0.5, 0.34 + (0.12 if k % 2 == 0 else 0.0), 0.04), c)   # sanefa recortada
	_no_conjunto(p, giro, Vector3(0, 1.05, -1.22), Vector3(3.2, 1.9, 0.05), cor.darkened(0.25))   # pano do fundo
	_no_conjunto(p, giro, Vector3(0, 0.95, 0.85), Vector3(3.1, 0.1, 0.95), MADEIRA)                # balcão
	_no_conjunto(p, giro, Vector3(0, 0.46, 1.3), Vector3(3.1, 0.9, 0.04), cor)                     # saia de pano
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 1.45, 0.45, 0.5), Vector3(0.1, 0.9, 0.1), MADEIRA.darkened(0.2))
	for k in 3:   # caixas rasas inclinadas para o freguês, cheias de mercadoria
		var x := (k - 1.0) * 0.98
		var m: Color = mercadoria[k % mercadoria.size()]
		_no_conjunto(p, giro, Vector3(x, 1.12, 0.85), Vector3(0.86, 0.16, 0.74), MADEIRA.lightened(0.15), 0.18)
		for i in 3:
			for j in 3:
				_no_conjunto(p, giro, Vector3(x + (i - 1) * 0.24, 1.25 + 0.05 * (j - 1), 0.85 + (j - 1) * 0.2), Vector3(0.2, 0.16, 0.18), m.lightened(0.12 * ((i + j) % 2)), 0.18)
	_solido(p + Basis(Vector3.UP, giro) * Vector3(0, 0.6, 0.85), Vector3(3.2, 1.2, 1.0), giro)
	_solido(p + Basis(Vector3.UP, giro) * Vector3(0, 1.0, -1.22), Vector3(3.2, 2.0, 0.2), giro)


## Carroça de carga parada: estrado com taipais de tábua, quatro rodas raiadas, varal e sacos em cima. `frente` é para onde aponta o varal.
func carroca(p: Vector3, frente: Vector2) -> void:
	var giro := atan2(frente.x, frente.y)
	var escura := MADEIRA.darkened(0.3)
	_no_conjunto(p, giro, Vector3(0, 0.85, 0), Vector3(1.7, 0.12, 3.4), MADEIRA)
	for sx in [-1.0, 1.0]:   # taipais: duas tábuas com vão e montantes
		for h in [1.05, 1.38]:
			_no_conjunto(p, giro, Vector3(sx * 0.85, float(h), 0), Vector3(0.06, 0.24, 3.4), MADEIRA.lightened(0.1))
		for k in 4:
			_no_conjunto(p, giro, Vector3(sx * 0.9, 1.2, (k - 1.5) * 1.05), Vector3(0.07, 0.75, 0.09), escura)
		for sz in [-1.0, 1.0]:   # roda: aro, cubo e raios em cruz
			var centro := Vector3(sx * 1.02, 0.55, sz * 1.05)
			var b := Basis(Vector3.UP, giro)
			_peca("cilindro", escura, Transform3D((b * Basis(Vector3.BACK, PI / 2.0)).scaled_local(Vector3(1.1, 0.1, 1.1)), p + b * centro))
			_peca("cilindro", FERRO, Transform3D((b * Basis(Vector3.BACK, PI / 2.0)).scaled_local(Vector3(0.26, 0.22, 0.26)), p + b * centro))
			for r in 4:
				_peca("caixa", MADEIRA.lightened(0.2), Transform3D((b * Basis(Vector3.RIGHT, r * PI / 4.0)).scaled_local(Vector3(0.12, 0.06, 1.0)), p + b * (centro + Vector3(sx * 0.02, 0, 0))))
	for sz in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(0, 1.2, sz * 1.7), Vector3(1.7, 0.56, 0.06), MADEIRA.lightened(0.1))
		_no_conjunto(p, giro, Vector3(0, 0.55, sz * 1.05), Vector3(1.9, 0.09, 0.09), FERRO)   # eixo
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 0.45, 0.62, 2.9), Vector3(0.08, 0.08, 2.6), escura, 0.2)   # varais apoiados no chão
	for k in 4:   # carga: sacos e um barril
		_no_conjunto(p, giro, Vector3(-0.38 + 0.76 * (k % 2), 1.14 + 0.05 * k, -1.0 + 0.62 * k), Vector3(0.62, 0.44, 0.56), Color(0.72, 0.64, 0.42).darkened(0.08 * (k % 3)), 0.1 * (k % 2))
	_solido(p + Vector3(0, 0.8, 0), Vector3(1.9, 1.6, 3.5), giro)


## Cavalete de armas do quartel: duas travessas em cavalete com lanças em pé, espadas penduradas e dois escudos.
func cavalete_de_armas(p: Vector3, frente: Vector2) -> void:
	var giro := atan2(frente.x, frente.y)
	var aco := Color(0.7, 0.72, 0.75)
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 1.2, 0.8, 0.22), Vector3(0.09, 1.7, 0.09), MADEIRA.darkened(0.2), 0.28)
		_no_conjunto(p, giro, Vector3(sx * 1.2, 0.8, -0.22), Vector3(0.09, 1.7, 0.09), MADEIRA.darkened(0.2), -0.28)
	for h in [0.55, 1.45]:
		_no_conjunto(p, giro, Vector3(0, float(h), 0), Vector3(2.6, 0.09, 0.09), MADEIRA)
	for k in 4:   # lanças
		var x := -0.9 + k * 0.28
		_no_conjunto(p, giro, Vector3(x, 1.25, 0.1), Vector3(0.045, 2.5, 0.045), MADEIRA.lightened(0.15), 0.07)
		_no_conjunto(p, giro, Vector3(x, 2.55, 0.01), Vector3(0.09, 0.3, 0.03), aco, 0.07)
	for k in 3:   # espadas de ponta para baixo
		var x := 0.35 + k * 0.3
		_no_conjunto(p, giro, Vector3(x, 0.95, 0.09), Vector3(0.07, 0.9, 0.02), aco)
		_no_conjunto(p, giro, Vector3(x, 1.42, 0.09), Vector3(0.26, 0.05, 0.05), FERRO)
		_no_conjunto(p, giro, Vector3(x, 1.54, 0.09), Vector3(0.05, 0.2, 0.05), MADEIRA.darkened(0.3))
	for sx in [-1.0, 1.0]:   # escudos redondos encostados nos pés
		var b := Basis(Vector3.UP, giro)
		_peca("cilindro", Color(0.14, 0.2, 0.5), Transform3D((b * Basis(Vector3.RIGHT, PI / 2.0 - 0.3)).scaled_local(Vector3(0.8, 0.07, 0.8)), p + b * Vector3(sx * 0.75, 0.42, 0.42)))
		_peca("cilindro", aco, Transform3D((b * Basis(Vector3.RIGHT, PI / 2.0 - 0.3)).scaled_local(Vector3(0.22, 0.12, 0.22)), p + b * Vector3(sx * 0.75, 0.43, 0.45)))
	_solido(p + Vector3(0, 0.9, 0), Vector3(2.6, 1.8, 0.7), giro)


## Alvo de arco: tripé de madeira e o disco de palha com três anéis pintados, virado para `frente`.
func alvo_de_arco(p: Vector3, frente: Vector2) -> void:
	var giro := atan2(frente.x, frente.y)
	var b := Basis(Vector3.UP, giro)
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 0.45, 0.85, 0.0), Vector3(0.08, 1.9, 0.08), MADEIRA.darkened(0.2), -0.12)
	_no_conjunto(p, giro, Vector3(0, 0.8, -0.55), Vector3(0.08, 1.9, 0.08), MADEIRA.darkened(0.2), 0.5)
	var discos := [[1.5, Color(0.86, 0.74, 0.4)], [1.05, Color(0.2, 0.3, 0.6)], [0.62, Color(0.92, 0.9, 0.84)], [0.26, Color(0.72, 0.15, 0.1)]]
	for k in discos.size():
		_peca("cilindro", discos[k][1], Transform3D((b * Basis(Vector3.RIGHT, PI / 2.0 - 0.12)).scaled_local(Vector3(float(discos[k][0]), 0.22 + k * 0.03, float(discos[k][0]))), p + b * Vector3(0, 1.3, 0.12)))
	_solido(p + Vector3(0, 1.0, 0), Vector3(1.4, 2.0, 0.6), giro)


## Estandarte do rei num mastro alto: base de pedra, mastro, travessa e pano azul com faixa clara e ponta dourada.
func estandarte(p: Vector3, frente: Vector2) -> void:
	var giro := atan2(frente.x, frente.y)
	_caixa(p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7), 0.0, MEIO_FIO, true)
	_cilindro(p + Vector3(0, 3.4, 0), 0.07, 6.2, MADEIRA.darkened(0.3))
	_no_conjunto(p, giro, Vector3(0, 6.2, 0), Vector3(1.5, 0.07, 0.07), MADEIRA.darkened(0.3))
	_no_conjunto(p, giro, Vector3(0, 4.7, 0.02), Vector3(1.3, 2.9, 0.04), Color(0.14, 0.2, 0.5))
	_no_conjunto(p, giro, Vector3(0, 4.7, 0.05), Vector3(0.3, 2.9, 0.03), Color(0.92, 0.9, 0.82))
	_no_conjunto(p, giro, Vector3(0, 3.1, 0.02), Vector3(0.92, 0.92, 0.04), Color(0.14, 0.2, 0.5), 0.0, "caixa")
	_cilindro(p + Vector3(0, 6.6, 0), 0.12, 0.24, Color(0.85, 0.72, 0.3))


## Barco de pesca a remo, em terra: fundo chato, costados, proa em ponta, popa reta, dois bancos e os remos guardados dentro.
func barco(p: Vector3, frente: Vector2) -> void:
	var giro := atan2(frente.x, frente.y)
	var casco := MADEIRA.darkened(0.1)
	var b := Basis(Vector3.UP, giro)
	_no_conjunto(p, giro, Vector3(0, 0.2, -0.1), Vector3(1.28, 0.1, 3.5), casco.darkened(0.15))   # fundo
	_no_conjunto(p, giro, Vector3(0, 0.2, 1.95), Vector3(0.5, 0.1, 0.6), casco.darkened(0.15))    # fundo da proa (estreito: cabe dentro da ponta)
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 0.62, 0.5, -0.1), Vector3(0.08, 0.6, 3.5), casco.lightened(0.1))   # costado
		_no_conjunto(p, giro, Vector3(sx * 0.64, 0.82, -0.1), Vector3(0.14, 0.07, 3.56), MADEIRA.darkened(0.3))   # borda
		_peca("caixa", casco.lightened(0.1), Transform3D((b * Basis(Vector3.UP, -sx * 0.464)).scaled_local(Vector3(0.08, 0.6, 1.4)), p + b * Vector3(sx * 0.31, 0.5, 2.25)))   # a proa fecha em ponta
		_peca("caixa", MADEIRA.darkened(0.3), Transform3D((b * Basis(Vector3.UP, -sx * 0.464)).scaled_local(Vector3(0.14, 0.07, 1.44)), p + b * Vector3(sx * 0.32, 0.82, 2.25)))
		_no_conjunto(p, giro, Vector3(sx * 0.22, 0.7, -0.2), Vector3(0.06, 0.06, 2.6), MADEIRA.lightened(0.2))   # remo deitado nos bancos
		_no_conjunto(p, giro, Vector3(sx * 0.22, 0.7, -1.3), Vector3(0.2, 0.04, 0.55), MADEIRA.lightened(0.2))   # pá do remo
	_no_conjunto(p, giro, Vector3(0, 0.5, 2.92), Vector3(0.12, 0.7, 0.12), MADEIRA.darkened(0.3))   # roda de proa
	_no_conjunto(p, giro, Vector3(0, 0.5, -1.86), Vector3(1.32, 0.6, 0.08), casco.lightened(0.1))   # popa
	for z in [-0.9, 0.6]:
		_no_conjunto(p, giro, Vector3(0, 0.62, float(z)), Vector3(1.2, 0.06, 0.3), MADEIRA.lightened(0.15))
	_solido(p + Vector3(0, 0.45, 0) + b * Vector3(0, 0, 0.5), Vector3(1.5, 0.9, 5.0), giro)


## Varal de secar peixe: dois esteios, duas varas e peixes pendurados pela cauda.
func varal_de_peixe(p: Vector3, frente: Vector2) -> void:
	var giro := atan2(frente.x, frente.y)
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 1.4, 0.95, 0), Vector3(0.1, 1.9, 0.1), MADEIRA.darkened(0.2))
	for h in [1.8, 1.25]:
		_no_conjunto(p, giro, Vector3(0, float(h), 0), Vector3(3.0, 0.06, 0.06), MADEIRA)
		for k in 6:
			var x := -1.1 + k * 0.44
			_no_conjunto(p, giro, Vector3(x, float(h) - 0.24, 0), Vector3(0.13, 0.4, 0.05), Color(0.46, 0.52, 0.58) if k % 2 == 0 else Color(0.58, 0.47, 0.36))
			_no_conjunto(p, giro, Vector3(x, float(h) - 0.05, 0), Vector3(0.16, 0.1, 0.03), Color(0.45, 0.48, 0.52))
	_solido(p + Vector3(0, 0.95, 0), Vector3(3.0, 1.9, 0.3), giro)


## Tenda de acampamento em duas águas: lona, mastros, cumeeira, entrada aberta com as abas presas, estacas e esteira.
func tenda(p: Vector3, frente: Vector2, cor: Color) -> void:
	var giro := atan2(frente.x, frente.y)
	var pau := MADEIRA.darkened(0.25)
	_no_conjunto(p, giro, Vector3(0, 1.1, 0), Vector3(3.2, 2.2, 3.6), cor, 0.0, "prisma")
	_no_conjunto(p, giro, Vector3(0, 0.86, 1.81), Vector3(1.9, 1.7, 0.04), Color(0.08, 0.07, 0.07), 0.0, "prisma")   # a boca escura da entrada
	for sx in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(sx * 1.25, 0.5, 1.84), Vector3(0.5, 0.9, 0.05), cor.lightened(0.12))   # abas da entrada, recolhidas para os lados
		for sz in [-1.0, 1.0]:
			_no_conjunto(p, giro, Vector3(sx * 1.95, 0.12, sz * 1.5), Vector3(0.07, 0.3, 0.07), pau, sz * 0.4)   # estacas
	for sz in [-1.0, 1.0]:
		_no_conjunto(p, giro, Vector3(0, 1.2, sz * 1.84), Vector3(0.09, 2.4, 0.09), pau)
	_no_conjunto(p, giro, Vector3(0, 2.26, 0), Vector3(0.09, 0.09, 4.1), pau)
	_no_conjunto(p, giro, Vector3(0, 0.04, 2.6), Vector3(1.0, 0.06, 1.3), Color(0.45, 0.36, 0.26))   # esteira na porta
	_solido(p + Vector3(0, 1.0, 0), Vector3(3.0, 2.0, 3.4), giro)
