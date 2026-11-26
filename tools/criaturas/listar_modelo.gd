extends SceneTree
## Lista o que há dentro de modelos 3D importados: tamanho, malhas, ossos e animações. Serve para avaliar um modelo
## novo antes de usá-lo.   godot --headless --path . --script res://tools/criaturas/listar_modelo.gd -- res://a.glb res://b.fbx


func _init() -> void:
	for caminho in OS.get_cmdline_user_args():
		var cena := load(caminho) as PackedScene
		if cena == null:
			print("NÃO CARREGOU ", caminho)
			continue
		var no := cena.instantiate() as Node3D
		root.add_child(no)
		var caixa := AABB()
		var verts := 0
		var malhas := 0
		for mi in no.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			malhas += 1
			caixa = caixa.merge(m.global_transform * m.get_aabb()) if malhas > 1 else m.global_transform * m.get_aabb()
			for s in m.mesh.get_surface_count():
				verts += (m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var ossos := 0
		for sk in no.find_children("*", "Skeleton3D", true, false):
			ossos += (sk as Skeleton3D).get_bone_count()
		var anims: Array = []
		for ap in no.find_children("*", "AnimationPlayer", true, false):
			for a in (ap as AnimationPlayer).get_animation_list():
				anims.append("%s(%.1fs)" % [a, (ap as AnimationPlayer).get_animation(a).length])
		print("MODELO ", caminho.get_file(), ": ", malhas, " malhas, ", verts, " vértices, ", ossos, " ossos, tamanho ", caixa.size.snapped(Vector3.ONE * 0.01), ", de ", caixa.position.snapped(Vector3.ONE * 0.01), "; animações ", anims)
		no.queue_free()
	quit(0)
