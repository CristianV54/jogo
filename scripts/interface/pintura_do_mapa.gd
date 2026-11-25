class_name PinturaDoMapa
extends RefCounted
## Pinta a imagem do mapa do mundo (tecla M) no estilo de mapa antigo desenhado à mão: papel envelhecido, cada bioma com um
## tom leve de aquarela, a mata desenhada árvore por árvore (pinheiro no pinhal e no bosque, copa redonda nos campos, tronco
## seco nas terras frias e queimadas), serras de traço nas terras de pedra e o mar em azul desbotado.
## É pintada uma vez, quando o mundo é construído. Rios, estradas, costa e nomes são traçados por cima pelo MapaDoMundo
## (em vetor, para ficarem nítidos com qualquer zoom).

const AMPLIA := 6          # cada célula da grade vira 6 x 6 pontos de imagem
const PAPEL := Color(0.87, 0.8, 0.63)
const TINTA := Color(0.22, 0.15, 0.09)


## `mata` = quantas árvores há em cada célula de `celula` metros (grade gw x gh sobre MundoDados.LIMITES).
static func pintar(mata: PackedFloat32Array, gw: int, gh: int, celula: float) -> ImageTexture:
	var lim := MundoDados.LIMITES
	var grao := FastNoiseLite.new()
	grao.seed = 77
	grao.frequency = 0.004
	grao.fractal_octaves = 3
	var base := Image.create(gw, gh, false, Image.FORMAT_RGBA8)
	for gz in gh:
		for gx in gw:
			var wx := lim.position.x + gx * celula
			var wz := lim.position.y + gz * celula
			var costa := Costa.distancia(wx, wz)
			var mancha := grao.get_noise_2d(wx, wz) * 0.05   # o papel não é liso
			var cor: Color
			if costa < 0.0:   # mar: azul desbotado, mais claro junto à praia
				cor = Color(0.68, 0.76, 0.72).lerp(Color(0.5, 0.62, 0.64), smoothstep(0.0, -260.0, costa))
			else:
				var chao := Biomas.cor_do_chao(wx, wz, 0.5)
				var aquarela := Color(chao.r * 1.7 + 0.12, chao.g * 1.55 + 0.12, chao.b * 1.5 + 0.08)
				cor = PAPEL.lerp(aquarela, 0.45)
				cor = cor.lerp(Color(0.93, 0.87, 0.7), smoothstep(40.0, 5.0, costa))   # areia clara na beira
			base.set_pixel(gx, gz, Color(cor.r + mancha, cor.g + mancha, cor.b + mancha * 0.8))
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
