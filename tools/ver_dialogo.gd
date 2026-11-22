extends SceneTree
# Abre falas longas e fotografa a caixa de diálogo.  godot --path . --resolution 1280x720 --script res://tools/ver_dialogo.gd
var jogo: Jogo
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	var c: Cartaz = null
	for n in get_nodes_in_group("interagiveis"):
		if n is Cartaz:
			c = n
			break
	jogo.jogador.global_position = c.global_position + Vector3(0, 0.5, 3.0)
	c.acionar()
	await create_timer(4.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/dialogo_cartaz.png")
	jogo.interagir()
	jogo.interagir()
	await create_timer(0.5).timeout
	jogo.cena_dialogo([["Vane", "Você viu o que um dragão pode fazer. Com três deles ao nosso lado, Ferrogris cairia em uma noite."], ["Vane", "Liberdade é uma palavra bonita para quem nunca precisou vencer uma guerra. Eu enterrei vinte dos nossos, Torin. Vinte. Cada um deles confiou em mim."]])
	await create_timer(5.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/dialogo_vane.png")
	print("CAPTURA dialogos")
	quit(0)
