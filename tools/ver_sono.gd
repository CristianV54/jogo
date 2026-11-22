extends SceneTree
# Fotos de NPCs dormindo, por dentro da casa.  godot --path . --resolution 1280x720 --script res://tools/ver_sono.gd
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
	jogo.clima.definir_hora(21.0)
	jogo.clima.forcar_tempo(Clima.Tempo.CHUVA if Clima.Tempo.has("CHUVA") else Clima.Tempo.LIMPO)
	Engine.time_scale = 6.0
	await create_timer(14.0).timeout
	Engine.time_scale = 1.0
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	var i := 0
	for n in get_nodes_in_group("npcs"):
		var npc := n as Npc
		if npc == null or not npc._deitado or i >= 3:
			continue
		var p := npc.global_position
		jogo.jogador.global_position = p + Vector3(0, 3, 0)
		cam.global_position = p + Vector3(1.6, 2.4, 1.6)
		cam.look_at(p)
		await create_timer(1.2).timeout
		RenderingServer.force_draw()
		root.get_viewport().get_texture().get_image().save_png("tools/capturas/sono_%d.png" % i)
		print("CAPTURA sono ", npc.nome)
		i += 1
	quit(0)
