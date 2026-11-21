extends SceneTree
# Só carrega a cena de teste e confere que os nós e as ligações existem. Sai com erro se faltar algo.
func _init() -> void:
	var cena: Node = load("res://scenes/teste/cena_teste.tscn").instantiate()
	root.add_child(cena)
	var falta: Array = []
	for caminho in ["Jogador", "Fagulha", "Fagulha/Modelo", "Camera", "Camera/Braco/Lente", "Chao"]:
		if cena.get_node_or_null(caminho) == null:
			falta.append(caminho)
	var jog: Jogador = cena.get_node("Jogador")
	var fag: Fagulha = cena.get_node("Fagulha")
	var cam: CameraTerceiraPessoa = cena.get_node("Camera")
	print("LIGACOES jogador.camera=", jog.camera, " fagulha.alvo=", fag.alvo, " camera.alvo=", cam.alvo)
	print("ANIMACAO_INICIAL ", fag.animacao_atual, " | NOS_FALTANDO ", falta)
	quit(1 if falta.size() > 0 or jog.camera == null or fag.alvo == null or cam.alvo == null else 0)
