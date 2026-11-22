extends SceneTree
# Foto do Torin correndo no jogo, de trás e de lado.  godot --path . --resolution 1280x720 --script res://tools/ver_correndo_jogo.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var tor: Humanoide = jogo.jogador.find_children("*", "Humanoide", true, false)[0]
	jogo.jogador.correndo_forcado = true
	jogo.jogador.entrada_forcada = Vector2(0, -1)
	await create_timer(1.2).timeout
	print("ARMA correndo giro=", tor._arma_mao.rotation_degrees, " animacao=", tor.animacoes.current_animation)
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/correndo_jogo.png")
	jogo.jogador.entrada_forcada = Vector2.ZERO
	jogo.jogador.correndo_forcado = false
	await create_timer(0.5).timeout
	print("ARMA parado giro=", tor._arma_mao.rotation_degrees, " visivel=", tor._arma_mao.visible)
	quit(0)
