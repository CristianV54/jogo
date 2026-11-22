extends SceneTree
# Rede de segurança: jogar o Torin para fora do mundo e ver se ele volta ao chão firme.
#   godot --headless --path . --script res://tools/teste_queda.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(1.5).timeout
	var antes := jogo.jogador.global_position
	jogo.jogador.global_position = Vector3(5000.0, 40.0, 5000.0)   # fora de tudo: cai para sempre
	var voltou := false
	for i in 120:
		await create_timer(0.1).timeout
		if jogo.jogador.global_position.distance_to(antes) < 15.0:
			voltou = true
			break
	print("  ", "PASSOU " if voltou else "FALHOU ", "caiu do mundo e voltou ao último chão firme  [", jogo.jogador.global_position, "]")
	print("RESULTADO ", "TUDO PASSOU" if voltou else "HA 1 FALHAS")
	quit(0)
