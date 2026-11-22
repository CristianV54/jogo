extends SceneTree
# Cartazes, estátua e NPCs novos.  godot --path . --resolution 1280x720 --script res://tools/capturar_cartazes.gd
var jogo: Jogo
var cam: Camera3D
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _ver(nome: String, no: Node3D, dist := 5.0, alt := 2.2) -> void:
	var p := no.global_position
	var f := Vector3(sin(no.global_rotation.y), 0, cos(no.global_rotation.y))
	jogo.jogador.global_position = p + f * (dist + 3.0) + Vector3(0, 1.5, 0)
	jogo.mundo.atualizar_atividade()
	cam.global_position = p + f * dist + Vector3(0, alt, 0)
	cam.look_at(p + Vector3(0, 1.2, 0))
	await create_timer(2.5).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/cartaz_%s.png" % nome)
	print("CAPTURA ", nome)
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	cam = Camera3D.new()
	cam.fov = 60
	root.add_child(cam)
	cam.current = true
	var cartazes := get_nodes_in_group("interagiveis").filter(func(n): return n is Cartaz)
	print("CARTAZES ", cartazes.size())
	var i := 0
	for c in cartazes:
		if i < 3 or str(c.titulo).contains("Estátua"):
			await _ver("%d" % i, c)
		i += 1
	quit(0)
