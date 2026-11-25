class_name Pedra
extends RefCounted
## Material de PEDRA para muralhas e torres: em vez de cor chapada, blocos de cantaria pintados (fiadas de pedra com juntas
## escuras e cada pedra num tom um pouco diferente). A imagem é desenhada uma vez por código e aplicada "pelo mundo"
## (triplanar): não estica nem deforma em parede comprida, e serve para qualquer caixa de qualquer tamanho.

static var _imagem: ImageTexture
static var _guardados: Dictionary = {}   # cor -> material


static func material(cor: Color) -> StandardMaterial3D:
	var chave := cor.to_html()
	if _guardados.has(chave):
		return _guardados[chave]
	if _imagem == null:
		_imagem = _desenhar()
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.albedo_texture = _imagem
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.22, 0.22, 0.22)   # a imagem (4 pedras por 8 fiadas) cobre ~4,5 m de parede
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_guardados[chave] = m
	return m


## Parede de cantaria: 8 fiadas, pedras de largura irregular, fiadas desencontradas, junta escura e leve mancha.
static func _desenhar() -> ImageTexture:
	var lado := 256
	var im := Image.create(lado, lado, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var grao := FastNoiseLite.new()
	grao.seed = 3
	grao.frequency = 0.05
	var fiada := lado / 8
	for f in 8:
		var x := 0
		var desloca := rng.randi_range(0, 30)
		while x < lado:
			var larg := rng.randi_range(44, 78)
			var tom := rng.randf_range(0.78, 1.0)
			for px in range(x, mini(x + larg, lado)):
				for py in range(f * fiada, (f + 1) * fiada):
					var junta := px - x < 2 or py - f * fiada < 2
					var v := (0.52 if junta else tom) + grao.get_noise_2d(px, py) * 0.06
					im.set_pixel((px + desloca) % lado, py, Color(v, v, v * 0.98))
			x += larg
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)
