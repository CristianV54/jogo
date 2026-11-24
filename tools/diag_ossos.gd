extends SceneTree
## Lista, por criatura, os ossos e onde está cada um (no modelo em repouso), para posicionar olhos e conferir tamanhos.
func _init() -> void:
	_r.call_deferred()


func _r() -> void:
	for esp in ["vaca", "ovelha", "porco", "cavalo", "cao", "galinha", "javali", "lobo", "ignis_maw", "filhote_de_asa", "fagulha"]:
		var caminho := "res://assets/models/criaturas/%s/%s.glb" % [esp, esp]
		var n := (load(caminho) as PackedScene).instantiate() as Node3D
		root.add_child(n)
		await process_frame
		var sks := n.find_children("*", "Skeleton3D", true, false)
		print("== ", esp, " esqueletos=", sks.size())
		if sks.is_empty():
			continue
		var sk: Skeleton3D = sks[0]
		var linha := ""
		for i in sk.get_bone_count():
			var nm := sk.get_bone_name(i)
			var l := nm.to_lower()
			if l.contains("ik") or not (l.contains("head") or l.contains("neck") or l.contains("ear") or l.contains("jaw") or l.contains("snout") or l.contains("eye") or l.contains("beak") or l.contains("horn") or l.contains("bone") or l.contains("tail") or l.contains("spine")):
				continue
			var p := sk.to_global(sk.get_bone_global_pose(i).origin)
			linha += "%s(%.2f,%.2f,%.2f) " % [nm, p.x, p.y, p.z]
		print(linha)
		n.queue_free()
	quit(0)
