extends SceneTree
# Refúgio à noite com chuva: gente dormindo, torre, capim.  godot --path . --resolution 1280x720 --script res://tools/capturar_noite.gd
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
	jogo.clima.definir_hora(21.5)
	jogo.clima.forcar_tempo(Clima.Tempo.TEMPESTADE)
	Engine.time_scale = 6.0
	await create_timer(14.0).timeout
	Engine.time_scale = 1.0
	var cam := Camera3D.new()
	cam.fov = 60
	root.add_child(cam)
	cam.current = true
	var m: Mundo = jogo.mundo
	for v in [["torre", Vector3(34, 0, 14), Vector3(34, 5, 4)], ["vila", Vector3(0, 0, 26), Vector3(0, 2, -10)]]:
		var p: Vector3 = v[1]
		var y: float = m.terreno.altura_em(p.x, p.z)
		jogo.jogador.global_position = Vector3(p.x, y + 1.0, p.z + 2.0)
		cam.global_position = Vector3(p.x, y + 2.2, p.z)
		cam.look_at(v[2])
		await create_timer(2.5).timeout
		RenderingServer.force_draw()
		root.get_viewport().get_texture().get_image().save_png("tools/capturas/noite_%s.png" % v[0])
		print("CAPTURA ", v[0])
	var fora := 0
	for n in get_nodes_in_group("npcs"):
		var npc := n as Npc
		if npc and npc.pernoita and npc.visible and not npc._deitado and npc.rotina.size() > 0:
			fora += 1
			print("FORA ", npc.nome, npc.global_position)
	print("NPCS fora da cama: ", fora)
	quit(0)
