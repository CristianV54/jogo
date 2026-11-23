extends SceneTree
## Fotos de cada região pelo Drone (câmera livre): visão aérea, entrada, centro e borda. Uma folha de contato por região
## em tools/capturas/drone_<etapa>_<regiao>.png.   godot --path . --resolution 1280x720 --script res://tools/drone_fotos.gd -- <etapa> [hora] [tempo]
var jogo: Jogo
var drone: Drone
var etapa := "x"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		etapa = a[0]
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var a := OS.get_cmdline_user_args()
	jogo.clima.congelado = true
	jogo.clima.definir_hora(float(a[1]) if a.size() > 1 else 11.0)
	jogo.clima.forcar_tempo(int(a[2]) if a.size() > 2 else Clima.Tempo.LIMPO)
	var m: Mundo = jogo.mundo
	drone = jogo.get_node("Admin").drone
	drone.ligar(jogo, jogo.jogador.global_position)
	DirAccess.make_dir_recursive_absolute("res://tools/capturas")
	for id in MundoDados.REGIOES:
		var c := MundoDados.centro(id)
		var meia: float = MundoDados.REGIOES[id]["meia"]
		var h: float = m.chao_em(c.x, c.y)
		var pontos := [
			["aerea", Vector3(c.x + 40.0, h + 150.0, c.y + meia * 1.1), Vector3(c.x, h, c.y)],
			["entrada", Vector3(c.x, h + 5.0, c.y + meia * 0.9), Vector3(c.x, h + 3.0, c.y + meia * 0.4)],
			["centro", Vector3(c.x + 28.0, h + 9.0, c.y + 28.0), Vector3(c.x, h + 1.5, c.y)],
			["borda", Vector3(c.x - meia * 0.85, h + 8.0, c.y - meia * 0.2), Vector3(c.x - meia * 0.3, h + 2.0, c.y)]]
		var imgs: Array[Image] = []
		for p in pontos:
			drone.olhar(p[1], p[2])
			jogo.jogador.global_position = Vector3(p[1].x, m.chao_em(p[1].x, p[1].z) + 1.0, p[1].z)   # perto, para as regiões em volta ligarem (no chão do ponto, não no da região)
			m.atualizar_atividade()
			await create_timer(2.2).timeout
			RenderingServer.force_draw()
			imgs.append(root.get_viewport().get_texture().get_image())
		var folha := Image.create(1280, 720, false, Image.FORMAT_RGB8)
		for k in 4:
			var im := imgs[k]
			im.resize(640, 360)
			folha.blit_rect(im, Rect2i(0, 0, 640, 360), Vector2i((k % 2) * 640, (k / 2) * 360))
		folha.save_png("res://tools/capturas/drone_%s_%s.png" % [etapa, id])
		print("FOTO ", id)
	quit(0)
