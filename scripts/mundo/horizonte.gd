class_name Horizonte
extends RefCounted
## Fecha o mundo de cada área com o que existe além da borda: chão até o fim da vista e duas fileiras de montanhas
## (cones de poucas faces, com neve nos picos se pedir). Não tem colisão: fica fora das paredes invisíveis do mapa.


static func montar(pai: Node3D, tam: float, cor_chao: Color, cor_monte: Color, altura: float, neve := false, semente := 1, y_chao := -0.2) -> void:
	if Mundo.ativo:
		return   # no mundo contínuo as montanhas são do mundo inteiro (ver Mundo._horizonte)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var chao := MeshInstance3D.new()
	chao.name = "ChaoDistante"
	var plano := BoxMesh.new()
	plano.size = Vector3(3000.0, 0.2, 3000.0)
	plano.material = _mat(cor_chao)
	chao.mesh = plano
	chao.position.y = y_chao   # tem que ficar ABAIXO do terreno e da água (rios descem até -2 m)
	chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(chao)
	var serra := Node3D.new()
	serra.name = "Montanhas"
	pai.add_child(serra)
	for camada in 2:
		var raio := tam / 2.0 + 150.0 + camada * 130.0
		var n := 30 + camada * 8
		for k in n:
			var a := TAU * k / n + rng.randf_range(-0.08, 0.08)
			var r := raio + rng.randf_range(-20.0, 30.0)
			var h := altura * rng.randf_range(0.6, 1.4) * (1.0 + camada * 0.45)
			var larg := rng.randf_range(28.0, 55.0)
			var cone := CylinderMesh.new()
			cone.top_radius = rng.randf_range(0.0, 6.0)
			cone.bottom_radius = larg
			cone.height = h
			cone.radial_segments = rng.randi_range(5, 7)
			cone.rings = 1
			var tom := rng.randf_range(0.82, 1.15)
			cone.material = _mat(Color(cor_monte.r * tom, cor_monte.g * tom, cor_monte.b * tom))
			var mi := MeshInstance3D.new()
			mi.mesh = cone
			mi.position = Vector3(cos(a) * r, h / 2.0 - 2.0, sin(a) * r)
			mi.rotation.y = rng.randf() * TAU
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			serra.add_child(mi)
			if neve and h > altura * 0.8:
				var topo := CylinderMesh.new()
				topo.top_radius = 0.0
				topo.bottom_radius = larg * 0.33
				topo.height = h * 0.3
				topo.radial_segments = cone.radial_segments
				topo.rings = 1
				topo.material = _mat(Color(0.72, 0.75, 0.8))
				var pico := MeshInstance3D.new()
				pico.mesh = topo
				pico.position = mi.position + Vector3(0.0, h * 0.36, 0.0)
				pico.rotation.y = mi.rotation.y
				pico.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				serra.add_child(pico)


static func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	return m
