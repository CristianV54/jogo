extends SceneTree
# Fotos da ILHA (mapa novo): planta vista de cima, vistas aéreas dos quatro lados, a praia com o raso, o reino e o mapa (tecla M).
# Também prova o tubarão: põe o Torin mar adentro e confere que ele é avisado e morre.
#   godot --path . --resolution 1280x720 --script res://tools/capturar_ilha.gd      (saída em tools/capturas/ilha/)
var jogo: Jogo
var cam: Camera3D
var avisos: Array = []


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, espera := 2.5) -> void:
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	var im := root.get_viewport().get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.save_jpg("tools/capturas/ilha/%s.jpg" % nome, 0.9)
	print("CAPTURA ", nome)


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/capturas/ilha")
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	jogo._alternar_mapa()
	await _foto("mapa_tecla_M", 1.5)
	jogo._alternar_mapa()
	jogo.clima._env.fog_enabled = false   # só para as fotos de longe: a névoa do jogo esconde tudo a 2 km
	cam = Camera3D.new()
	cam.far = 9000.0
	root.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3400.0
	cam.global_position = Vector3(0, 2500, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	await _foto("planta_de_cima", 4.0)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 60.0
	for v in [["aerea_do_sul", Vector3(0, 900, 2300)], ["aerea_do_oeste", Vector3(-2300, 900, 0)], ["aerea_do_norte", Vector3(0, 900, -2300)], ["aerea_do_leste", Vector3(2300, 900, 0)]]:
		cam.global_position = v[1]
		cam.look_at(Vector3(0, 0, 0))
		await _foto(v[0], 3.0)
	cam.global_position = Vector3(0, 260, 620)
	cam.look_at(Vector3(0, 0, -60))
	await _foto("reino_no_centro", 3.0)
	cam.current = false
	cam.queue_free()
	jogo.clima._env.fog_enabled = true
	# praia do sul, perto da foz do Riacho do Pinhal: Torin na areia, olhando o mar
	var z := 1300.0
	while Costa.distancia(-150.0, z) > 6.0:
		z += 2.0
	jogo.jogador.global_position = Vector3(-150.0, jogo.mundo.chao_em(-150.0, z) + 1.0, z)
	jogo.jogador.velocity = Vector3.ZERO
	jogo.camera.yaw = PI   # de costas para a ilha, olhando o mar
	await _foto("praia_do_sul", 3.0)
	# tubarão: Torin posto 45 m mar adentro
	jogo.mundo.tubarao.aviso.connect(func(t: String) -> void: avisos.append(t))
	while Costa.distancia(-150.0, z) > -40.0:
		z += 2.0
	jogo.jogador.global_position = Vector3(-150.0, Costa.NIVEL_MAR, z)
	await create_timer(1.0).timeout
	await _foto("tubarao_chegando", 0.5)
	var t := 0.0
	while not jogo.jogador.morto and t < 20.0:
		await create_timer(0.25).timeout
		t += 0.25
	print("TUBARAO avisos=", avisos, " morreu=", jogo.jogador.morto, " em ", t, " s")
	quit(0)
