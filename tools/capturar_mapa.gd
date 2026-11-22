extends SceneTree
# Foto do mapa do mundo (tecla M).  godot --path . --resolution 1280x720 --script res://tools/capturar_mapa.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(1.0).timeout
	jogo._alternar_mapa()
	await create_timer(1.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/mapa_aberto.png")
	print("CAPTURA mapa")
	quit(0)
