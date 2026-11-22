extends SceneTree
# Auditoria: toda malha "grande" (>= 0,7 m de base e >= 0,5 m de altura, abaixo de 2,6 m) de cada área precisa ter colisão
# (camadas 1, 4 ou 8) no seu centro. Lista as que não têm. Ignora personagens/criaturas (conferidos no teste de sólidos).
#   godot --path . --resolution 800x450 --script res://tools/auditar_colisao.gd
const AREAS := ["refugio_do_pinhal", "bosque_velado", "fronteira_ferrogris", "cratera_ignis", "valdoria"]
const IGNORAR := ["Npc", "Inimigo", "AnimalVila", "Fagulha", "Jogador", "Criatura", "Humanoide"]


func _init() -> void:
	_rodar.call_deferred()


func _dono_ignorado(no: Node) -> bool:
	var p := no
	while p:
		if p.get_script() and p.get_script().get_global_name() in IGNORAR:
			return true
		p = p.get_parent()
	return false


func _rodar() -> void:
	var total_sem := 0
	for id in AREAS:
		var area: Node3D = load("res://scenes/areas/%s.tscn" % id).instantiate()
		root.add_child(area)
		for i in 3:
			await physics_frame
		var espaco := area.get_world_3d().direct_space_state
		var sem := {}
		var grandes := 0
		for mi in area.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null or _dono_ignorado(m) or m.get_parent() is MultiMeshInstance3D:
				continue
			var a: AABB = m.global_transform * m.get_aabb()
			if a.size.y < 0.5 or a.size.x < 0.7 and a.size.z < 0.7 or a.position.y > 1.6 or a.size.x > 60.0 or a.size.z > 60.0:
				continue   # pequeno, fino, alto demais (telhado) ou o próprio terreno
			grandes += 1
			var c := a.get_center()
			var q := PhysicsPointQueryParameters3D.new()
			q.position = c
			q.collision_mask = 1 | 4 | 8
			if espaco.intersect_point(q, 1).is_empty():
				# tenta também um pouco para os lados (peças em L ou com furo no centro)
				var achou := false
				for d in [Vector3(0.3, 0, 0), Vector3(-0.3, 0, 0), Vector3(0, 0, 0.3), Vector3(0, 0, -0.3)]:
					q.position = c + d
					if not espaco.intersect_point(q, 1).is_empty():
						achou = true
						break
				if not achou:
					var chave := "%s (%s)" % [m.get_parent().name if m.get_parent() else "?", m.name]
					sem[chave] = sem.get(chave, 0) + 1
		print("AREA ", id, " | malhas grandes: ", grandes, " | sem colisão: ", sem.size())
		for k in sem:
			print("   SEM_COLISAO ", k, " x", sem[k])
		total_sem += sem.size()
		area.queue_free()
		await process_frame
	print("AUDITORIA_TOTAL_SEM_COLISAO ", total_sem)
	quit(0)
