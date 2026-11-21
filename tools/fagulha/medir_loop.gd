extends SceneTree
# Sem gambiarra: carrega o glb como o jogo carregaria e confere nomes, loop, cor do vértice, escala
# e se cada animação fecha o ciclo (pose do último quadro vs. primeiro, em graus).

func _init() -> void:
	var raiz: Node3D = load("res://assets/models/criaturas/fagulha/fagulha.glb").instantiate()
	root.add_child(raiz)
	print("ESCALA_RAIZ ", raiz.scale)
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var mt: Material = mi.mesh.surface_get_material(i)
			if mt is BaseMaterial3D:
				print("MATERIAL ", mt.resource_name, " cor_do_vertice_como_albedo ", mt.vertex_color_use_as_albedo)
		var gab: AABB = mi.global_transform * mi.get_aabb()
		print("TAMANHO_M (pose aberta) ", gab.size)
	var ap: AnimationPlayer = raiz.find_child("AnimationPlayer", true, false)
	for nome in ap.get_animation_list():
		var an: Animation = ap.get_animation(nome)
		var maior := 0.0
		var acima5 := 0
		var rot := 0
		var salto_pos := 0.0
		for t in an.get_track_count():
			if an.track_get_type(t) == Animation.TYPE_POSITION_3D and an.track_get_key_count(t) > 1:
				var p0: Vector3 = an.track_get_key_value(t, 0)
				var p1: Vector3 = an.track_get_key_value(t, an.track_get_key_count(t) - 1)
				salto_pos = max(salto_pos, p0.distance_to(p1))
			if an.track_get_type(t) == Animation.TYPE_ROTATION_3D and an.track_get_key_count(t) > 1:
				rot += 1
				var a: Quaternion = an.track_get_key_value(t, 0)
				var b: Quaternion = an.track_get_key_value(t, an.track_get_key_count(t) - 1)
				var graus := rad_to_deg(a.angle_to(b))
				maior = max(maior, graus)
				if graus > 5.0:
					acima5 += 1
		print("ANIM ", nome, " duracao_s ", snapped(an.length, 0.01), " loop_mode ", an.loop_mode,
			" | ciclo: trilhas_de_rotacao ", rot, " maior_salto_graus ", snapped(maior, 0.1), " trilhas_acima_de_5_graus ", acima5,
			" | maior_salto_de_posicao_m ", snapped(salto_pos, 0.001))
	quit(0)
