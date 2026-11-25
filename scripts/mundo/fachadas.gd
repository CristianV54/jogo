class_name Fachadas
extends RefCounted
## Pinturas das casas do casario de Valdoria, desenhadas por código (uma vez) e aplicadas em cada face da casa:
##   "enxaimel": reboco claro com vigas de madeira escura (na horizontal, na vertical e em cruz), três andares de janelas
##               com caixilho e uma porta no térreo;
##   "pedra":    parede de pedra miúda com as mesmas janelas e porta, verga e peitoril de pedra clara;
##   "telhado":  fiadas de telha.
## A cor de cada casa (tom do reboco, tom do telhado) vem da cor da instância no MultiMesh e multiplica a pintura.

static var _guardados: Dictionary = {}


static func material(qual: String) -> StandardMaterial3D:
	if _guardados.has(qual):
		return _guardados[qual]
	var m := StandardMaterial3D.new()
	m.roughness = 0.95
	m.vertex_color_use_as_albedo = true
	m.uv1_triplanar = true   # no espaço da própria casa (a caixa vai de -0,5 a 0,5): a pintura inteira cabe em cada face
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if qual == "telhado":
		m.albedo_texture = _telhas()
		m.uv1_scale = Vector3(4.0, 5.0, 4.0)
	else:
		m.albedo_texture = _fachada(qual == "pedra")
		m.uv1_offset = Vector3(0.5, 0.5, 0.5)
	_guardados[qual] = m
	return m


static func _fachada(de_pedra: bool) -> ImageTexture:
	var lado := 256
	var im := Image.create(lado, lado, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51 if de_pedra else 50
	var grao := FastNoiseLite.new()
	grao.seed = 9
	grao.frequency = 0.06
	var viga := Color(0.3, 0.2, 0.13)
	for y in lado:
		for x in lado:
			var v := 0.93 + grao.get_noise_2d(x, y) * 0.05
			if de_pedra:   # pedra miúda: fiadas de 12 pontos, pedras de 20, juntas escuras
				var fiada := y / 12
				var xx := x + (10 if fiada % 2 == 1 else 0)
				var junta := y % 12 < 2 or xx % 20 < 2
				v = (0.5 if junta else 0.72 + 0.1 * sin(float(fiada * 7 + xx / 20) * 12.9898)) + grao.get_noise_2d(x, y) * 0.05
			im.set_pixel(x, y, Color(v, v * 0.98, v * 0.93))
	if not de_pedra:   # vigas do enxaimel
		for k in 4:
			var y0 := mini(k * 85, lado - 5)
			_retangulo(im, 0, y0, lado, 5, viga)
			var x0 := mini(k * 85, lado - 5)
			_retangulo(im, x0, 0, 5, lado, viga)
		for painel in [[0, 0, 1], [2, 0, -1], [0, 1, -1], [2, 1, 1]]:   # travessas em diagonal nos painéis dos cantos
			for t in 80:
				var px: int = int(painel[0]) * 85 + 4 + t
				var py: int = int(painel[1]) * 85 + 4 + (t if int(painel[2]) > 0 else 79 - t)
				_retangulo(im, px, py, 3, 4, viga)
	for andar in 3:   # janelas (e, no térreo, a porta no meio)
		for coluna in 3:
			var cx := 42 + coluna * 85
			var cy := 44 + andar * 85
			if andar == 2 and coluna == 1:
				_retangulo(im, cx - 17, 188, 34, 64, viga)
				_retangulo(im, cx - 14, 191, 28, 61, Color(0.42, 0.28, 0.16))
				_retangulo(im, cx + 7, 222, 3, 3, Color(0.75, 0.65, 0.3))
				continue
			_retangulo(im, cx - 16, cy - 21, 32, 42, Color(0.8, 0.78, 0.72) if de_pedra else viga)
			_retangulo(im, cx - 13, cy - 18, 26, 36, Color(0.17, 0.2, 0.27))
			_retangulo(im, cx - 1, cy - 18, 2, 36, viga)
			_retangulo(im, cx - 13, cy - 1, 26, 2, viga)
			_retangulo(im, cx - 18, cy + 21, 36, 3, Color(0.8, 0.78, 0.72) if de_pedra else viga)   # peitoril
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)


static func _telhas() -> ImageTexture:
	var lado := 64
	var im := Image.create(lado, lado, false, Image.FORMAT_RGB8)
	for y in lado:
		for x in lado:
			var fiada := y / 8
			var xx := x + (4 if fiada % 2 == 1 else 0)
			var sombra := 0.72 if y % 8 == 0 else (0.86 if xx % 8 == 0 else 1.0 - 0.1 * float(y % 8) / 8.0)
			im.set_pixel(x, y, Color(sombra, sombra, sombra))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)


static func _retangulo(im: Image, x: int, y: int, l: int, a: int, cor: Color) -> void:
	im.fill_rect(Rect2i(x, y, l, a).intersection(Rect2i(0, 0, im.get_width(), im.get_height())), cor)
