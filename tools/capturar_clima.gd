extends SceneTree
# Fotos do clima no Refúgio: alvorecer, meio-dia, pôr do sol, noite, chuva e tempestade (com relâmpago).
#   godot --path . --resolution 1280x720 --script res://tools/capturar_clima.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, espera := 1.2) -> void:
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/clima_%s.png" % nome)
	print("CAPTURA ", nome)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.2).timeout
	await create_timer(1.0).timeout
	var c := jogo.clima
	c.congelado = true
	jogo.jogador.global_position = Vector3(0.0, 1.0, 22.0)
	jogo.camera.yaw = PI
	c.forcar_tempo(Clima.Tempo.LIMPO)
	for par in [["alvorecer", 6.3], ["meio_dia", 12.0], ["por_do_sol", 17.9], ["noite", 23.0]]:
		c.definir_hora(par[1])
		await _foto(par[0])
	c.definir_hora(14.0)
	c.forcar_tempo(Clima.Tempo.CHUVA)
	await _foto("chuva", 2.5)
	c.forcar_tempo(Clima.Tempo.TEMPESTADE)
	c.relampago = 1.0
	await _foto("tempestade_raio", 0.05)
	c.definir_hora(22.0)
	c.relampago = 0.0
	await _foto("tempestade_noite", 2.0)
	quit(0)
