extends SceneTree
## Fotografa o Fagulha nas 3 fases (em campo aberto, na mata e perto de uma casa).  godot --path . --resolution 1280x720 --script res://tools/ver_fagulha_fases.gd
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
	jogo.clima.definir_hora(11.0)
	jogo.liberar_fagulha()
	var f: Fagulha = jogo.fagulha
	var m: Mundo = jogo.mundo
	var drone: Drone = jogo.get_node("Admin").drone
	drone.ligar(jogo, jogo.jogador.global_position)
	var casa := get_nodes_in_group("casas")[0] as Node3D
	var locais := [["aberto", Vector3(-250, 0, 40)], ["mata", Vector3(-420, 0, 140)], ["casa", casa.global_position + Vector3(0, 0, 9)]]
	var imgs: Array[Image] = []
	for loc in locais:
		var p: Vector3 = loc[1]
		var y := m.chao_em(p.x, p.z)
		jogo.jogador.global_position = Vector3(p.x, y + 1.0, p.z)
		m.atualizar_atividade()
		for fase in [1, 2, 3]:
			f.definir_fase(fase)
			f.set_physics_process(false)
			f.modo_voo = false
			f.global_position = Vector3(p.x + 3.0, y, p.z)
			f.rotation.y = -PI / 2.0
			drone.olhar(Vector3(p.x - 3.0, y + 3.0, p.z + 8.0), Vector3(p.x + 1.5, y + 1.0, p.z))
			await create_timer(1.6).timeout
			RenderingServer.force_draw()
			var im := root.get_viewport().get_texture().get_image()
			im.resize(426, 240)
			imgs.append(im)
	var folha := Image.create(1278, 720, false, Image.FORMAT_RGB8)
	for k in imgs.size():
		folha.blit_rect(imgs[k], Rect2i(0, 0, 426, 240), Vector2i((k % 3) * 426, (k / 3) * 240))
	folha.save_png("res://tools/capturas/fagulha_fases.png")
	print("FOTO fagulha")
	quit(0)
