extends SceneTree
# Lobo no mundo, ao lado do Torin (para ver o tamanho).  godot --path . --resolution 1280x720 --script res://tools/capturar_lobo_jogo.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var m: Mundo = jogo.mundo
	var p := Vector2(-250, 40)
	var y: float = m.terreno.altura_em(p.x, p.y)
	jogo.jogador.global_position = Vector3(p.x, y + 1.0, p.y)
	jogo.jogador.velocity = Vector3.ZERO
	var lobo := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	m.add_child(lobo)
	lobo.global_position = Vector3(p.x + 3.0, y + 0.3, p.y - 1.0)
	lobo.set_physics_process(false)
	var cam := Camera3D.new()
	cam.fov = 60
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(p.x - 1.5, y + 1.6, p.y + 5.5)
	cam.look_at(Vector3(p.x + 1.5, y + 0.7, p.y - 0.5))
	await create_timer(2.5).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/lobo_no_jogo.png")
	print("CAPTURA lobo_no_jogo")
	quit(0)
