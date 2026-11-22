class_name VariacaoDeCores
extends RefCounted
## Cada animal sai com uma pelagem diferente: troca, por material, a cor do pacote por uma escolhida ao acaso numa paleta
## da espécie, e põe uma textura de pelo (ruído) por cima. Os materiais são copiados: os outros animais não mudam.

# {espécie: {nome do material no .glb: [cores possíveis]}}
const PALETAS := {
	"vaca": {
		"White": [Color(0.93, 0.93, 0.92), Color(0.93, 0.85, 0.68), Color(0.78, 0.78, 0.8), Color(0.86, 0.62, 0.42)],
		"Black": [Color(0.12, 0.12, 0.13), Color(0.4, 0.22, 0.12), Color(0.32, 0.3, 0.3), Color(0.62, 0.32, 0.15), Color(0.5, 0.12, 0.08)],
	},
	"ovelha": {
		"White": [Color(0.93, 0.92, 0.88), Color(0.9, 0.8, 0.62), Color(0.62, 0.62, 0.64), Color(0.38, 0.27, 0.19), Color(0.16, 0.16, 0.17)],
		"Black": [Color(0.1, 0.1, 0.11), Color(0.3, 0.2, 0.13), Color(0.4, 0.4, 0.42)],
	},
	"porco": {
		"Material.003": [Color(0.92, 0.66, 0.66), Color(0.9, 0.78, 0.7), Color(0.65, 0.4, 0.3), Color(0.35, 0.25, 0.22), Color(0.82, 0.55, 0.5)],
	},
	"cavalo": {
		"Material.003": [Color(0.45, 0.25, 0.15), Color(0.66, 0.34, 0.14), Color(0.1, 0.1, 0.11), Color(0.55, 0.55, 0.58), Color(0.86, 0.83, 0.76), Color(0.72, 0.52, 0.3)],
		"Material.006": [Color(0.08, 0.07, 0.07), Color(0.25, 0.15, 0.08), Color(0.88, 0.84, 0.76)],
	},
	"cao": {
		"Beige": [Color(0.92, 0.82, 0.62), Color(0.12, 0.12, 0.13), Color(0.5, 0.3, 0.16), Color(0.93, 0.93, 0.92), Color(0.55, 0.55, 0.58)],
		"Brown": [Color(0.12, 0.09, 0.08), Color(0.3, 0.18, 0.1)],
	},
	"lobo": {
		"Beige": [Color(0.5, 0.5, 0.53), Color(0.36, 0.36, 0.39), Color(0.66, 0.63, 0.58), Color(0.28, 0.27, 0.27)],
		"Brown": [Color(0.12, 0.12, 0.14), Color(0.2, 0.2, 0.22)],
	},
	"javali": {
		"Material.003": [Color(0.3, 0.2, 0.15), Color(0.2, 0.15, 0.12), Color(0.42, 0.28, 0.18), Color(0.12, 0.1, 0.1)],
	},
}

static var _pelo: ImageTexture


static func aplicar(raiz: Node3D, especie: String) -> void:
	var paleta: Dictionary = PALETAS.get(especie, {})
	if paleta.is_empty():
		return
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var malha := mi as MeshInstance3D
		for i in malha.mesh.get_surface_count():
			var base := malha.mesh.surface_get_material(i) as StandardMaterial3D
			if base == null:
				continue
			var m := base.duplicate() as StandardMaterial3D
			var opcoes: Array = paleta.get(base.resource_name, [])
			if opcoes.is_empty():
				malha.set_surface_override_material(i, m)
				continue
			m.albedo_color = opcoes[randi() % opcoes.size()]
			m.albedo_texture = _textura_de_pelo()
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.5
			malha.set_surface_override_material(i, m)


## Ruído em tons de cinza claro, que escurece a cor aos pontos: dá a aparência de pelo.
static func _textura_de_pelo() -> ImageTexture:
	if _pelo == null:
		var ruido := FastNoiseLite.new()
		ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		ruido.frequency = 0.18
		ruido.seed = 7
		var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
		for y in 128:
			for x in 128:
				var v := 0.68 + 0.32 * (ruido.get_noise_2d(x, y) * 0.5 + 0.5)
				img.set_pixel(x, y, Color(v, v, v))
		_pelo = ImageTexture.create_from_image(img)
	return _pelo
