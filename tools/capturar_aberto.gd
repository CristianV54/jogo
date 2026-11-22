extends SceneTree
# Fotos do mundo aberto: poço, menino Nilo, espada nas costas correndo, povoados livres, crista com vão e barreira, mata.
#   godot --path . --resolution 1280x720 --script res://tools/capturar_aberto.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, de: Vector3, para: Vector3, espera := 2.0, jog := Vector3.INF) -> void:
	jogo.jogador.global_position = jog if jog != Vector3.INF else Vector3(para.x, para.y + 2.0, para.z)
	jogo.jogador.velocity = Vector3.ZERO
	cam.global_position = de
	cam.look_at(para)
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/aberto_%s.png" % nome)
	print("CAPTURA ", nome, " fps=", Engine.get_frames_per_second())


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	jogo.clima.congelado = true
	jogo.clima.definir_hora(10.5)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.far = 3000.0
	cam.fov = 60
	root.add_child(cam)
	cam.current = true
	var h := func(x: float, z: float) -> float: return m.terreno.altura_em(x, z)
	await _foto("poco", Vector3(-6.5, h.call(-9.0, 5.0) + 2.4, 7.5), Vector3(-9.0, h.call(-9.0, 5.0) + 0.5, 5.0), 2.0, Vector3(-20.0, 2.0, 12.0))
	await _foto("poco_de_cima", Vector3(-9.0, h.call(-9.0, 5.0) + 3.2, 6.6), Vector3(-9.0, h.call(-9.0, 5.0), 5.0), 1.0, Vector3(-20.0, 2.0, 12.0))
	var nilo: Node3D = null
	for n in get_nodes_in_group("npcs"):
		if str(n.get("nome")) == "Nilo":
			nilo = n
	if nilo:
		var p := nilo.global_position
		await _foto("nilo", p + Vector3(0.6, 1.3, 4.2), p + Vector3(0.6, 0.9, 0), 2.0, p + Vector3(1.3, 0.5, 0.2))
	else:
		print("NILO nao achado")
	var tor: Humanoide = jogo.jogador.find_children("*", "Humanoide", true, false)[0] if not jogo.jogador.find_children("*", "Humanoide", true, false).is_empty() else null
	if tor:
		tor.tocar("Jog_Fwd", 0.0)
		var q := jogo.jogador.global_position
		await _foto("espada", q + Vector3(0.0, 1.8, 3.2), q + Vector3(0, 1.1, 0), 0.8)
	for v in [["beira_rio", 60.0, 40.0], ["pedras_altas", 60.0, 40.0], ["rio_claro", 50.0, 35.0], ["pescador", 40.0, 30.0], ["posto_de_caca", 40.0, 30.0]]:
		var c: Vector2 = m.povoados[v[0]]["centro"]
		await _foto(v[0], Vector3(c.x + 10.0, h.call(c.x, c.y) + v[2], c.y + v[1]), Vector3(c.x, h.call(c.x, c.y), c.y), 3.0)
	await _foto("barreira_bosque", Vector3(0.5, h.call(0.5, -330.0) + 14.0, -330.0), Vector3(0.5, h.call(0.5, -385.0) + 4.0, -385.0), 3.0)
	await _foto("crista_lado", Vector3(-250.0, h.call(-250.0, -320.0) + 30.0, -320.0), Vector3(-250.0, h.call(-250.0, -385.0) + 6.0, -385.0), 3.0)
	await _foto("mata_da_estrada", Vector3(-150.0, h.call(-150.0, 20.0) + 5.0, 30.0), Vector3(-300.0, h.call(-300.0, -20.0) + 3.0, -20.0), 3.0)
	await _foto("mata_fechada", Vector3(-480.0, h.call(-480.0, -100.0) + 14.0, -100.0), Vector3(-560.0, h.call(-560.0, -300.0) + 2.0, -300.0), 3.0)
	quit(0)
