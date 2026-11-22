extends SceneTree
# Fotos do capim em vários biomas.  godot --path . --resolution 1280x720 --script res://tools/capturar_capim.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, p: Vector3, olhar: Vector3) -> void:
	var m: Mundo = jogo.mundo
	var y := m.terreno.altura_em(p.x, p.z)
	jogo.jogador.global_position = Vector3(p.x + 3.0, y + 2.0, p.z + 3.0)
	jogo.jogador.velocity = Vector3.ZERO
	cam.global_position = Vector3(p.x, y + 2.2, p.z)
	cam.look_at(Vector3(olhar.x, y + 0.6, olhar.z))
	await create_timer(3.0).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/capim_%s.png" % nome)
	print("CAPTURA ", nome, " fps=", Engine.get_frames_per_second(), " blocos=", m.capim._blocos.size())


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(10.5)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.far = 3000.0
	cam.fov = 70
	root.add_child(cam)
	cam.current = true
	await _foto("campos_sul", Vector3(-250, 0, 60), Vector3(-330, 0, -20))
	await _foto("refugio_borda", Vector3(0, 0, 110), Vector3(40, 0, 200))
	await _foto("campos_secos", Vector3(300, 0, -520), Vector3(360, 0, -600))
	await _foto("cinzas", Vector3(200, 0, -1000), Vector3(300, 0, -1100))
	await _foto("cratera_vizinha", Vector3(450, 0, -1250), Vector3(500, 0, -1350))
	await _foto("ocre_valdoria", Vector3(450, 0, -1700), Vector3(520, 0, -1780))
	quit(0)
