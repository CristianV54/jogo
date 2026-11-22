extends SceneTree
# Carrega o .glb importado e imprime o que veio: malhas, esqueleto, animações.

func _init() -> void:
	var cena: PackedScene = load("res://dragao_teste.glb")
	if cena == null:
		print("ERRO: nao carregou o glb")
		quit(1)
		return
	var raiz: Node = cena.instantiate()
	root.add_child(raiz)
	print("RAIZ ", raiz.name, " escala ", raiz.scale if raiz is Node3D else "n/a")
	for no in _todos(raiz):
		if no is MeshInstance3D:
			var m: Mesh = no.mesh
			var tris := 0
			var mats := []
			for i in m.get_surface_count():
				var arr := m.surface_get_arrays(i)
				tris += arr[Mesh.ARRAY_INDEX].size() / 3
				var mat := m.surface_get_material(i)
				var tex := ""
				if mat is BaseMaterial3D and mat.albedo_texture:
					tex = " tex=%dx%d" % [mat.albedo_texture.get_width(), mat.albedo_texture.get_height()]
				mats.append((mat.resource_name if mat else "SEM_MATERIAL") + tex)
			print("MALHA ", no.name, " superficies ", m.get_surface_count(), " triangulos ", tris,
				" aabb ", no.get_aabb().size, " skin ", no.skin != null)
			print("  materiais ", mats)
		if no is Skeleton3D:
			print("ESQUELETO ", no.name, " ossos ", no.get_bone_count())
			var raizes := []
			for b in no.get_bone_count():
				if no.get_bone_parent(b) == -1:
					raizes.append(no.get_bone_name(b))
			print("  raizes ", raizes)
		if no is AnimationPlayer:
			print("ANIMATIONPLAYER ", no.name)
			for a in no.get_animation_list():
				var an: Animation = no.get_animation(a)
				print("  anim ", a, " duracao_s ", snapped(an.length, 0.01), " trilhas ", an.get_track_count(), " loop ", an.loop_mode)
	quit(0)

func _todos(n: Node) -> Array:
	var r := [n]
	for c in n.get_children():
		r.append_array(_todos(c))
	return r
