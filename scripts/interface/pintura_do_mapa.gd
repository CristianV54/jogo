class_name PinturaDoMapa
extends RefCounted
## Pinta a imagem do mapa do mundo (tecla M) como mapa de JOGO: cores vivas do chão de cada bioma, RELEVO sombreado (o
## penhasco de Valdoria e a Montanha dos Dragões saltam), mar em três fundos com espuma na praia, mata como mancha
## escura com a árvore desenhada por cima (pinheiro no pinhal e no bosque, copa redonda nos campos, tronco
## seco nas terras frias e queimadas), serras de traço nas terras de pedra e o mar em azul desbotado.
## É pintada uma vez, quando o mundo é construído. Rios, estradas, costa e nomes são traçados por cima pelo MapaDoMundo
## (em vetor, para ficarem nítidos com qualquer zoom).

const AMPLIA := 6          # cada célula da grade vira 6 x 6 pontos de imagem
const PAPEL := Color(0.87, 0.8, 0.63)
const TINTA := Color(0.22, 0.15, 0.09)


## `mata` = quantas árvores há em cada célula de `celula` metros (grade gw x gh sobre MundoDados.LIMITES).
## `altura` devolve a altura do chão em (x, z): com ela o mapa ganha RELEVO (sombra de morro, como nos mapas de jogo).
static func pintar(mata: PackedFloat32Array, gw: int, gh: int, celula: float, altura: Callable) -> ImageTexture:
	var lim := MundoDados.LIMITES
	var grao := FastNoiseLite.new()
	grao.seed = 77
	grao.frequency = 0.004
	grao.fractal_octaves = 3
	var alturas := PackedFloat32Array()
	alturas.resize(gw * gh)
	for gz in gh:
		for gx in gw:
			alturas[gz * gw + gx] = float(altura.call(lim.position.x + gx * celula, lim.position.y + gz * celula))
	var base := Image.create(gw, gh, false, Image.FORMAT_RGBA8)
	var sol := Vector3(-0.55, 0.62, -0.56).normalized()   # luz de noroeste, a convenção dos mapas de relevo
	for gz in gh:
		for gx in gw:
			var wx := lim.position.x + gx * celula
			var wz := lim.position.y + gz * celula
			var costa := Costa.distancia(wx, wz)
			var mancha := grao.get_noise_2d(wx, wz) * 0.04
			var cor: Color
			if costa < 0.0:   # mar: turquesa no raso, azul fundo e escuro mar adentro
				cor = Color(0.36, 0.66, 0.68).lerp(Color(0.13, 0.33, 0.47), smoothstep(0.0, -140.0, costa))
				cor = cor.lerp(Color(0.07, 0.18, 0.3), smoothstep(-140.0, -900.0, costa))
				cor = cor.lerp(Color(0.85, 0.93, 0.9), smoothstep(-14.0, 0.0, costa) * 0.7)   # espuma na beira
				mancha *= 0.5
			else:
				var chao := Biomas.cor_do_chao(wx, wz, 0.5)
				cor = Color(chao.r * 1.45 + 0.1, chao.g * 1.4 + 0.1, chao.b * 1.3 + 0.06)   # a cor do chão do jogo, mais viva e clara
				var n := mata[gz * gw + gx]
				cor = cor.lerp(Color(0.16, 0.3, 0.17), clampf(n / 5.0, 0.0, 0.55))            # mata fechada lê-se como mancha escura
				var h := alturas[gz * gw + gx]
				cor = cor.lerp(Color(0.52, 0.47, 0.42), smoothstep(14.0, 60.0, h))             # rocha nos altos
				cor = cor.lerp(Color(0.86, 0.84, 0.82), smoothstep(150.0, 240.0, h))           # cinza clara no pico
				var hx := alturas[gz * gw + mini(gx + 1, gw - 1)] - alturas[gz * gw + maxi(gx - 1, 0)]
				var hz := alturas[mini(gz + 1, gh - 1) * gw + gx] - alturas[maxi(gz - 1, 0) * gw + gx]
				var normal := Vector3(-hx, 2.0 * celula * 0.35, -hz).normalized()                # relevo exagerado para ler de longe
				var luz := clampf(normal.dot(sol) / sol.y, 0.45, 1.5)
				cor = Color(cor.r * luz, cor.g * luz, cor.b * luz)
				cor = cor.lerp(Color(0.93, 0.87, 0.68), smoothstep(34.0, 4.0, costa))            # praia
			base.set_pixel(gx, gz, Color(clampf(cor.r + mancha, 0.0, 1.0), clampf(cor.g + mancha, 0.0, 1.0), clampf(cor.b + mancha, 0.0, 1.0)))
	base.resize(gw * AMPLIA, gh * AMPLIA, Image.INTERPOLATE_CUBIC)
	var selos := {"pinheiro": _pinheiro(), "copa": _copa(), "seca": _seca(), "serra": _serra()}
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for gz in gh:   # de cima para baixo: a árvore de baixo cobre o pé da de cima, como em desenho
		for gx in gw:
			var wx := lim.position.x + gx * celula
			var wz := lim.position.y + gz * celula
			var n := mata[gz * gw + gx]
			if Costa.distancia(wx, wz) < 20.0:
				continue
			var bioma := Biomas.em(wx, wz)
			if n > 0.0:
				var selo: Image = selos["pinheiro"] if bioma == "pinhal" or bioma == "bosque" else (selos["seca"] if bioma == "ferrogris" or bioma == "cratera" else selos["copa"])
				for k in clampi(int(ceil(n / 2.0)), 1, 3):
					var q := Vector2i(gx * AMPLIA + rng.randi_range(-2, AMPLIA - 2), gz * AMPLIA + rng.randi_range(-3, AMPLIA - 3))
					base.blend_rect(selo, Rect2i(Vector2i.ZERO, selo.get_size()), q - selo.get_size() / 2)
			elif (bioma == "ferrogris" or bioma == "cratera") and gx % 3 == 0 and gz % 3 == 0 and grao.get_noise_2d(wx * 3.0, wz * 3.0) > 0.05:
				var s: Image = selos["serra"]
				base.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(gx * AMPLIA, gz * AMPLIA) - s.get_size() / 2)
	base.generate_mipmaps()   # de longe as árvores viram mancha suave, sem cintilar
	return ImageTexture.create_from_image(base)


static func _tela(l: int, a: int) -> Image:
	var im := Image.create(l, a, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


## Pinheiro: triângulo verde-escuro com contorno de tinta e um lado mais claro.
static func _pinheiro() -> Image:
	var im := _tela(9, 12)
	for y in 10:
		var meia := int(round(y * 0.42))
		for x in range(4 - meia, 5 + meia):
			var borda := x == 4 - meia or x == 4 + meia or y == 9
			im.set_pixel(x, y, Color(0.16, 0.2, 0.11) if borda else (Color(0.33, 0.44, 0.24) if x < 4 else Color(0.25, 0.35, 0.19)))
	im.set_pixel(4, 10, TINTA)
	im.set_pixel(4, 11, TINTA)
	return im


## Árvore de copa redonda (campos e reino).
static func _copa() -> Image:
	var im := _tela(9, 11)
	for y in 8:
		for x in 9:
			var d := Vector2(x - 4.0, y - 3.5).length()
			if d <= 4.0:
				im.set_pixel(x, y, Color(0.2, 0.24, 0.12) if d > 3.1 else (Color(0.47, 0.56, 0.28) if x + y < 7 else Color(0.37, 0.47, 0.23)))
	for y in range(8, 11):
		im.set_pixel(4, y, TINTA)
	return im


## Árvore seca (terras frias e queimadas): tronco e galhos.
static func _seca() -> Image:
	var im := _tela(7, 10)
	var cor := Color(0.3, 0.24, 0.2)
	for y in range(2, 10):
		im.set_pixel(3, y, cor)
	for p in [Vector2i(2, 4), Vector2i(1, 3), Vector2i(0, 2), Vector2i(4, 3), Vector2i(5, 2), Vector2i(6, 1), Vector2i(3, 1), Vector2i(2, 0), Vector2i(4, 6), Vector2i(5, 5)]:
		im.set_pixel(p.x, p.y, cor)
	return im


## Serra: dois picos de traço, com o lado da sombra hachurado.
static func _serra() -> Image:
	var im := _tela(17, 11)
	for pico in [[5, 9, 1], [11, 7, 3]]:
		var cx: int = pico[0]
		var alt: int = pico[1]
		var topo: int = pico[2]
		for k in alt:
			im.set_pixel(cx - k * 5 / alt - (1 if k == alt - 1 else 0), topo + k, TINTA)
			im.set_pixel(mini(cx + k * 5 / alt, 16), topo + k, TINTA)
			if k % 2 == 1:   # sombra do lado direito
				for x in range(cx + 1, mini(cx + k * 5 / alt, 16)):
					im.set_pixel(x, topo + k, Color(TINTA.r, TINTA.g, TINTA.b, 0.35))
	return im
