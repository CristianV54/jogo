class_name Povoador
extends RefCounted
## Espalha pinheiros, pedras e arbustos sobre um Terreno: MultiMesh para o visual e cilindros para os troncos próximos.

static func multimesh(pai: Node3D, malha: Mesh, transformacoes: Array[Transform3D], nome_no: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha
	mm.instance_count = transformacoes.size()
	for i in transformacoes.size():
		mm.set_instance_transform(i, transformacoes[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome_no
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	pai.add_child(inst)


static func livre(t: Terreno, x: float, z: float, folga_caminho: float, inclinacao_min: float) -> bool:
	if Vector2(x, z).length() < t.clareira_raio * 1.02:
		return false
	if t.distancia_caminho(x, z) < folga_caminho:
		return false
	return t.normal_em(x, z).y >= inclinacao_min


static func pinheiros(pai: Node3D, t: Terreno, rng: RandomNumberGenerator, tamanho: float, tentativas: int, colisoes_max := 400) -> int:
	var troncos := StaticBody3D.new()
	troncos.name = "TroncosColisao"
	pai.add_child(troncos)
	var lista: Array[Transform3D] = []
	var colisoes := 0
	for k in tentativas:
		var x := rng.randf_range(-tamanho / 2.0 * 0.97, tamanho / 2.0 * 0.97)
		var z := rng.randf_range(-tamanho / 2.0 * 0.97, tamanho / 2.0 * 0.97)
		if not livre(t, x, z, 4.5, 0.74):
			continue
		var d := Vector2(x, z).length()
		if rng.randf() > 0.25 + 0.75 * smoothstep(t.clareira_raio, t.clareira_raio * 1.5, d):
			continue
		var s := rng.randf_range(0.8, 1.6)
		var base := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.2), s))
		var h := t.altura_em(x, z)
		lista.append(Transform3D(base, Vector3(x, h - 0.15, z)))
		if d < 120.0 and colisoes < colisoes_max:
			colisoes += 1
			var cs := CollisionShape3D.new()
			var cil := CylinderShape3D.new()
			cil.radius = 0.45 * s
			cil.height = 4.0
			cs.shape = cil
			cs.position = Vector3(x, h + 2.0, z)
			troncos.add_child(cs)
	multimesh(pai, FabricaNatureza.pinheiro(), lista, "Pinheiros")
	return lista.size()


static func pedras(pai: Node3D, t: Terreno, rng: RandomNumberGenerator, tamanho: float, quantidade: int, esc_min: float, esc_max: float, com_colisao := false) -> void:
	for v in 3:
		var lista: Array[Transform3D] = []
		var corpo: StaticBody3D = null
		if com_colisao:
			corpo = StaticBody3D.new()
			pai.add_child(corpo)
		for k in quantidade:
			var x := rng.randf_range(-tamanho / 2.0 * 0.95, tamanho / 2.0 * 0.95)
			var z := rng.randf_range(-tamanho / 2.0 * 0.95, tamanho / 2.0 * 0.95)
			if not livre(t, x, z, 3.0, 0.0):
				continue
			var s := rng.randf_range(esc_min, esc_max)
			var base := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.7, 1.3), s))
			var h := t.altura_em(x, z)
			lista.append(Transform3D(base, Vector3(x, h - 0.1, z)))
			if corpo and s > 1.6:
				var cs := CollisionShape3D.new()
				var cil := CylinderShape3D.new()
				cil.radius = s * 0.8
				cil.height = s * 1.2
				cs.shape = cil
				cs.position = Vector3(x, h + s * 0.5, z)
				corpo.add_child(cs)
		multimesh(pai, FabricaNatureza.pedra(1.0 + v * 7.3), lista, "Pedras%d" % v)
