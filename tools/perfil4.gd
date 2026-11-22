extends SceneTree
var jogo: Jogo
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()
func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(2.0).timeout
	var cont := {}
	var luzes := {}
	var parts := {}
	for n in jogo.find_children("*", "", true, false):
		var topo := ""
		var p := n
		while p and p.get_parent() and p.get_parent() != jogo.mundo and p.get_parent() != jogo:
			p = p.get_parent()
		topo = String(p.name)
		if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
			cont[topo] = int(cont.get(topo, 0)) + 1
		if n is Light3D and (n as Light3D).is_visible_in_tree():
			luzes[topo] = int(luzes.get(topo, 0)) + 1
		if (n is CPUParticles3D) and (n as CPUParticles3D).emitting and (n as CPUParticles3D).is_visible_in_tree():
			parts[topo] = int(parts.get(topo, 0)) + 1
	print("PERF meshes visiveis por regiao: ", cont)
	print("PERF luzes visiveis: ", luzes)
	print("PERF particulas emitindo: ", parts)
	quit(0)
