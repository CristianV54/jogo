extends SceneTree
# Fotos dos rios.  godot --path . --resolution 1280x720 --script res://tools/capturar_agua.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, de: Vector3, para: Vector3) -> void:
	var m: Mundo = jogo.mundo
	jogo.jogador.global_position = Vector3(para.x + 4.0, m.terreno.altura_em(para.x, para.z) + 3.0, para.z)
	jogo.jogador.velocity = Vector3.ZERO
	cam.global_position = de
	cam.look_at(para)
	await create_timer(3.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/agua_%s.png" % nome)
	print("CAPTURA ", nome)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.far = 3000.0
	cam.fov = 65
	root.add_child(cam)
	cam.current = true
	var m: Mundo = jogo.mundo
	var h := func(x: float, z: float) -> float: return m.terreno.altura_em(x, z)
	await _foto("cinzento_baixo", Vector3(-296, h.call(-296, 70) + 3.0, 70), Vector3(-300, h.call(-300, 95) - 0.3, 95))
	await _foto("cinzento_alto", Vector3(-250, h.call(-250, 40) + 30.0, 60), Vector3(-300, h.call(-300, 95), 100))
	await _foto("ponte", Vector3(-110, h.call(-110, 130) + 5.0, 130), Vector3(-100, h.call(-100, 150), 150))
	quit(0)
