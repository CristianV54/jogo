extends SceneTree
# Fotos do mundo contínuo: povoados, fazendas, estrada com ponte, mata do corredor, divisa entre regiões, vista aérea e o mapa.
#   godot --path . --resolution 1280x720 --script res://tools/capturar_mundo.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, espera := 1.5) -> void:
	await create_timer(espera).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/mundo_%s.png" % nome)
	print("CAPTURA ", nome, " fps=", Engine.get_frames_per_second())


func _ir(p: Vector3, yaw: float) -> void:
	jogo.jogador.global_position = p
	jogo.jogador.velocity = Vector3.ZERO
	jogo.camera.yaw = yaw


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	jogo.clima.congelado = true
	jogo.clima.definir_hora(10.5)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var c: Vector2 = m.povoados["campina"]["centro"]
	_ir(Vector3(c.x, 30.0, c.y + 30.0), 0.0)
	await _foto("fazenda_campina", 2.5)
	c = m.povoados["campos_altos"]["centro"]
	_ir(Vector3(c.x, 30.0, c.y + 35.0), 0.0)
	await _foto("vila_campos_altos", 2.5)
	c = m.povoados["posto_imperial"]["centro"]
	_ir(Vector3(c.x, 40.0, c.y + 30.0), 0.0)
	await _foto("posto_imperial", 2.5)
	var par := m.ponto_na_estrada("bosque", 110.0)
	var p: Vector2 = par[0]
	_ir(Vector3(p.x, 30.0, p.y + 6.0), 0.0)
	await _foto("trilha_do_bosque", 2.5)
	_ir(Vector3(130.0, 30.0, 4.0), -PI / 2.0)
	await _foto("divisa_refugio_leste", 2.5)
	cam = Camera3D.new()
	cam.far = 6000.0
	cam.fov = 60
	root.add_child(cam)
	cam.current = true
	for v in [["aerea_sul", Vector3(150, 700, 600), Vector3(300, 0, -500)], ["aerea_norte", Vector3(900, 900, -400), Vector3(584, 0, -1500)]]:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await _foto(v[0], 3.0)
	cam.current = false
	cam.queue_free()
	_ir(Vector3(0.0, 2.0, 14.0), 0.0)
	await create_timer(1.0).timeout
	jogo._alternar_mapa()
	await _foto("mapa", 0.6)
	quit(0)
