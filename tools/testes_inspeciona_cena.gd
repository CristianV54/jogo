extends SceneTree
# Imprime a árvore (até 4 níveis) e um caminho de trilha de animação de cada cena passada como argumento.
func _arv(n: Node, nivel: int, max_nivel: int) -> void:
	if nivel > max_nivel: return
	print("  ".repeat(nivel), n.name, " [", n.get_class(), "]", (" ossos=" + str(n.get_bone_count())) if n is Skeleton3D else "")
	for c in n.get_children(): _arv(c, nivel + 1, max_nivel)
func _init() -> void:
	for caminho in OS.get_cmdline_user_args():
		print("=== ", caminho)
		var cena: Node = load(caminho).instantiate()
		root.add_child(cena)
		_arv(cena, 0, 3)
		var ap: AnimationPlayer = cena.find_child("AnimationPlayer", true, false)
		if ap:
			var lista := ap.get_animation_list()
			print("ANIMACOES ", lista.size(), " exemplo trilha: ", ap.get_animation(lista[1]).track_get_path(0), " | root_node ", ap.root_node)
	quit(0)
