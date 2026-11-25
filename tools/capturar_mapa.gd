extends SceneTree
# Fotos do mapa do mundo (tecla M): inteiro, com destino marcado, com zoom, e o facho do destino dentro do jogo.  godot --path . --resolution 1280x720 --script res://tools/capturar_mapa.gd
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
	await _foto("mapa_inteiro")
	jogo.hud.mapa.marcar(Vector2(0, 320))   # destino: portão sul de Valdoria
	await _foto("mapa_com_destino")
	jogo.hud.mapa._aproximar(4.0, root.get_viewport().get_visible_rect().size / 2.0)
	jogo.hud.mapa.centro = Vector2(-150, 700)
	await _foto("mapa_zoom_4x_sul_do_reino")
	jogo._alternar_mapa()
	jogo.jogador.global_position = Vector3(-225, jogo.mundo.chao_em(-225, 1300) + 1.5, 1300)   # fora do Refúgio, na estrada do reino
	jogo.camera.yaw = 0.0
	await _foto("destino_no_jogo", 4.0)
	quit(0)


func _foto(nome: String, espera := 1.0) -> void:
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	var im := root.get_viewport().get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.save_jpg("tools/capturas/ilha/%s.jpg" % nome, 0.92)
	print("CAPTURA ", nome)
