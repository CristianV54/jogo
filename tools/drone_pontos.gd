extends SceneTree
## Fotos do Drone em pontos escolhidos (coordenadas do relatório da auditoria): de cima, em ângulo e de perto.
##   godot --path . --resolution 1280x720 --script res://tools/drone_pontos.gd -- <nome> "x,z;x,z;..."
var jogo: Jogo
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var a := OS.get_cmdline_user_args()
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.definir_hora(float(a[2]) if a.size() > 2 else 11.0)
	jogo.clima.forcar_tempo(int(a[3]) if a.size() > 3 else Clima.Tempo.LIMPO)
	var m: Mundo = jogo.mundo
	var drone: Drone = jogo.get_node("Admin").drone
	drone.ligar(jogo, jogo.jogador.global_position)
	var imgs: Array[Image] = []
	for par in String(a[1]).split(";"):
		var xz := par.split(",")
		var x := float(xz[0])
		var z := float(xz[1])
		var h := m.chao_em(x, z)
		jogo.jogador.global_position = Vector3(x, h + 1.0, z)
		m.atualizar_atividade()
		for v in [Vector3(0, 55, 55), Vector3(14, 6, 14), Vector3(-5, 2.5, 6)]:
			drone.olhar(Vector3(x, h, z) + v, Vector3(x, h, z))
			await create_timer(1.6).timeout
			RenderingServer.force_draw()
			var im := root.get_viewport().get_texture().get_image()
			im.resize(426, 240)
			imgs.append(im)
	var folha := Image.create(1278, 240 * ((imgs.size() + 2) / 3), false, Image.FORMAT_RGB8)
	for k in imgs.size():
		(imgs[k] as Image).convert(Image.FORMAT_RGB8)   # o formato da captura muda com o renderizador (RGBA no OpenGL)
		folha.blit_rect(imgs[k], Rect2i(0, 0, 426, 240), Vector2i((k % 3) * 426, (k / 3) * 240))
	folha.save_png("res://tools/capturas/pontos_%s.png" % a[0])
	print("FOTOS_PONTOS ", imgs.size())
	quit(0)
