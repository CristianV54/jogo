extends SceneTree
# Centro do punho fechado: centroide dos vértices da luva ligados à mão direita e aos dedos, no espaço de hand_r.
#   godot --headless --path . --script res://tools/medir_punho.gd -- res://scenes/personagens/torin.tscn Male_Ranger_Arms
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var h: Humanoide = load(args[0]).instantiate()
	h.arma_cena = null
	root.add_child(h)
	_rodar.call_deferred(h, args[1])
func _rodar(h: Humanoide, nome_malha: String) -> void:
	await process_frame
	var sk: Skeleton3D = h.modelo.find_child("Skeleton3D", true, false)
	var mi: MeshInstance3D = h.modelo.find_child(nome_malha, true, false)
	var osso_mao := sk.find_bone("hand_r")
	var bind_mao := Transform3D.IDENTITY   # matriz de bind do osso hand_r: leva o espaço da malha para o espaço do osso
	for b in mi.skin.get_bind_count():
		if mi.skin.get_bind_name(b) == "hand_r":
			bind_mao = mi.skin.get_bind_pose(b)
	var rep := sk.get_bone_global_rest(osso_mao)
	print("COMPARA rest_hand_r_origem=", rep.origin.snapped(Vector3(0.001, 0.001, 0.001)), " inverso_do_bind_origem=", bind_mao.affine_inverse().origin.snapped(Vector3(0.001, 0.001, 0.001)))
	var dedos := []
	for i in sk.get_bone_count():
		var n := sk.get_bone_name(i)
		if n == "hand_r" or ((n.begins_with("index_") or n.begins_with("middle_") or n.begins_with("ring_") or n.begins_with("pinky_") or n.begins_with("thumb_")) and n.ends_with("_r")):
			dedos.append(i)
	var soma := Vector3.ZERO
	var n_v := 0
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bs: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var ws: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var por_v := bs.size() / vs.size()
		print("DEBUG superficie ", s, " vertices ", vs.size(), " bones ", bs.size(), " por_v ", por_v, " bind_count ", mi.skin.get_bind_count() if mi.skin else -1)
		for v in vs.size():
			var peso := 0.0
			for k in por_v:
				var bi: int = sk.find_bone(mi.skin.get_bind_name(bs[v * por_v + k]))
				if bi in dedos:
					peso += ws[v * por_v + k]
			if peso >= 0.5:
				var p := bind_mao * (mi.transform * vs[v])
				soma += p
				mn = mn.min(p)
				mx = mx.max(p)
				n_v += 1
	var c := soma / maxf(1.0, n_v)
	print("PUNHO vertices=", n_v, " centro(hand_r)=(%.3f, %.3f, %.3f)" % [c.x, c.y, c.z], " caixa_min=", mn.snapped(Vector3(0.001, 0.001, 0.001)), " caixa_max=", mx.snapped(Vector3(0.001, 0.001, 0.001)))
	quit(0)
