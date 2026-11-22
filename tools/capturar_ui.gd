extends SceneTree
# Captura a interface do jogo: mapa do mundo, caixa de diálogo (letra a letra e completa) e marcador "?" sobre o NPC.
#   godot --path . --resolution 1280x720 --script res://tools/capturar_ui.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String) -> void:
	for i in 6:
		await process_frame
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/ui_%s.png" % nome)
	print("CAPTURA ", nome)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.2).timeout
	await create_timer(1.5).timeout
	var brenn: Npc
	for n in jogo.area.npcs:
		if n.nome == "Brenn":
			brenn = n
	jogo.jogador.global_position = brenn.global_position + Vector3(1.6, 0.6, 1.0)
	await create_timer(1.0).timeout
	await _foto("npc_marca")   # C1-M1 pede para falar com a Brenn: "?" sobre a cabeça
	jogo.interagir()
	await create_timer(0.4).timeout
	await _foto("dialogo_revelando")
	await create_timer(2.0).timeout
	await _foto("dialogo_completo")
	jogo.interagir()
	jogo.interagir()
	jogo.interagir()
	await create_timer(0.3).timeout
	jogo._alternar_mapa()
	await create_timer(0.3).timeout
	await _foto("mapa")
	quit(0)
