extends SceneTree
# Fotos do castelo e da cidade.  godot --path . --resolution 1280x720 --script res://tools/capturar_castelo.gd
var jogo: Jogo
var cam: Camera3D


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _foto(nome: String, de: Vector3, para: Vector3, jog: Vector3) -> void:
	jogo.jogador.global_position = jog
	jogo.jogador.velocity = Vector3.ZERO
	cam.global_position = de
	cam.look_at(para)
	await create_timer(3.5).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/castelo_%s.png" % nome)
	print("CAPTURA ", nome)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(17.5)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.far = 4000.0
	cam.fov = 60
	root.add_child(cam)
	cam.current = true
	var c := MundoDados.centro("castelo_imperial")
	await _foto("de_longe", Vector3(c.x + 120, 55, c.y + 300), Vector3(c.x, 8, c.y), Vector3(c.x, 8, c.y + 150))
	await _foto("do_portao", Vector3(c.x - 30, 14, c.y + 175), Vector3(c.x, 10, c.y + 90), Vector3(c.x, 6, c.y + 150))
	await _foto("aereo", Vector3(c.x + 200, 160, c.y + 160), Vector3(c.x, 0, c.y), Vector3(c.x, 6, c.y + 150))
	quit(0)
