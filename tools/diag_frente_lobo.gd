extends SceneTree
## Mede, sem olho, para onde o lobo olha: direção cabeça-menos-rabo no mundo contra a frente do corpo (-Z) usada pelo ataque e pelo movimento.
func _init() -> void:
	var l := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	root.add_child(l)
	_r.call_deferred(l)
func _r(l: Inimigo) -> void:
	await process_frame
	await process_frame
	var sk: Skeleton3D = l.find_children("*", "Skeleton3D", true, false)[0]
	var ext_pos := {}
	for i in sk.get_bone_count():
		var nm := sk.get_bone_name(i)
		if nm.ends_with("_end") and not nm.begins_with("IK"):
			var g := sk.to_global(sk.get_bone_global_pose(i).origin)
			print("PONTA ", nm, " mundo=", g.snapped(Vector3(0.01, 0.01, 0.01)))
	# a cabeça é a ponta mais alta do eixo longo (o lobo tem cabeça e orelhas acima do rabo): imprime tudo e o corpo para eu comparar
	var cab: Vector3 = sk.to_global(sk.get_bone_global_pose(3).origin)
	var rabo: Vector3 = sk.to_global(sk.get_bone_global_pose(7).origin)
	var d := cab - rabo
	d.y = 0.0
	var fr := -l.global_transform.basis.z
	print("PRODUTO_ESCALAR cabeça-rabo x frente do corpo = ", snapped(d.normalized().dot(fr), 0.01), "  (1 = olha para onde anda; -1 = de costas)")
	var ab := AABB()
	var primeiro := true
	for mi in l.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		ab = bb if primeiro else ab.merge(bb)
		primeiro = false
	print("TAMANHO_DO_LOBO no jogo (m): comprimento z=", snapped(ab.size.z, 0.01), " largura x=", snapped(ab.size.x, 0.01), " altura=", snapped(ab.size.y, 0.01), "  (Torin tem ~1,8 m)")
	print("FRENTE_DO_CORPO=", -l.global_transform.basis.z)
	quit(0)
