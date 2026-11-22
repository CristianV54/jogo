class_name Terreno
extends Node3D
## Terreno procedural pintado por vértice (grama, mata, terra, pedra).
## Plano e limpo numa clareira central (0, 0), com colinas fora dela e caminhos de terra.

@export var tamanho := 320.0
@export var passo := 2.0
@export var semente := 7
@export var amplitude := 16.0
@export var frequencia := 0.011
@export var clareira_raio := 45.0
@export var cor_grama := Color(0.34, 0.5, 0.21)
@export var cor_mata := Color(0.2, 0.34, 0.16)
@export var cor_terra := Color(0.47, 0.36, 0.23)
@export var cor_pedra := Color(0.5, 0.48, 0.45)

## Cada caminho é um PackedVector2Array de pontos (x, z).
var caminhos: Array = []
var corpo: StaticBody3D
var _ruido := FastNoiseLite.new()
var _ruido_fino := FastNoiseLite.new()


func gerar() -> void:
	_ruido.seed = semente
	_ruido.frequency = frequencia
	_ruido.fractal_octaves = 4
	_ruido_fino.seed = semente + 1
	_ruido_fino.frequency = frequencia * 7.0

	var malha := _malha()
	var mi := MeshInstance3D.new()
	mi.name = "Superficie"
	mi.mesh = malha
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)

	corpo = StaticBody3D.new()
	corpo.name = "Colisao"
	var cs := CollisionShape3D.new()
	cs.shape = malha.create_trimesh_shape()
	corpo.add_child(cs)
	add_child(corpo)


func altura_em(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var m := smoothstep(clareira_raio, clareira_raio * 1.9, d)
	var n := _ruido.get_noise_2d(x, z) * 0.5 + 0.5
	return (n * amplitude + _ruido_fino.get_noise_2d(x, z) * 1.3) * m


func normal_em(x: float, z: float) -> Vector3:
	var e := passo
	var dx := altura_em(x + e, z) - altura_em(x - e, z)
	var dz := altura_em(x, z + e) - altura_em(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


func distancia_caminho(x: float, z: float) -> float:
	var melhor := 1e9
	var p := Vector2(x, z)
	for c in caminhos:
		for i in range(c.size() - 1):
			var a: Vector2 = c[i]
			var b: Vector2 = c[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			melhor = minf(melhor, p.distance_to(a + ab * t))
	return melhor


func cor_em(x: float, z: float) -> Color:
	var d := Vector2(x, z).length()
	var n := normal_em(x, z)
	var c := cor_grama.lerp(cor_mata, smoothstep(clareira_raio * 1.05, clareira_raio * 2.2, d))
	c = c * (0.92 + 0.16 * (_ruido_fino.get_noise_2d(x * 3.1, z * 3.1) * 0.5 + 0.5))
	var inclinacao := 1.0 - n.y
	c = c.lerp(cor_pedra, smoothstep(0.22, 0.45, inclinacao))
	c = c.lerp(cor_terra, 1.0 - smoothstep(1.4, 3.2, distancia_caminho(x, z)))
	c = c.lerp(cor_terra, 0.55 * (1.0 - smoothstep(5.0, 15.0, d)))   # chão pisado em volta da fogueira
	return c


func _malha() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(tamanho / passo)
	var meia := tamanho / 2.0
	for i in n:
		for j in n:
			var x0 := -meia + i * passo
			var z0 := -meia + j * passo
			var x1 := x0 + passo
			var z1 := z0 + passo
			var p00 := Vector3(x0, altura_em(x0, z0), z0)
			var p10 := Vector3(x1, altura_em(x1, z0), z0)
			var p01 := Vector3(x0, altura_em(x0, z1), z1)
			var p11 := Vector3(x1, altura_em(x1, z1), z1)
			for tri in [[p00, p10, p01], [p10, p11, p01]]:   # sentido horário visto de cima (a face que o Godot desenha)
				for v in tri:
					st.set_color(cor_em(v.x, v.z).srgb_to_linear())   # cor de vértice é linear no Godot
					st.set_normal(normal_em(v.x, v.z))
					st.add_vertex(v)
	return st.commit()
