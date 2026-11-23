extends SceneTree
## Fotos do Drone de todos os povoados: uma folha por povoado (aérea, entrada, centro e detalhe) em tools/capturas/povoado_<etapa>_<id>.png.
##   godot --path . --resolution 1280x720 --script res://tools/drone_povoados.gd -- <etapa> [id1,id2,...]
var jogo: Jogo
var etapa := "x"
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		etapa = a[0]
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var a := OS.get_cmdline_user_args()
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var m: Mundo = jogo.mundo
	var drone: Drone = jogo.get_node("Admin").drone
	drone.ligar(jogo, jogo.jogador.global_position)
	var ids: Array = m.povoados.keys()
	if a.size() > 1:
		ids = String(a[1]).split(",")
	for id in ids:
		var c: Vector2 = m.povoados[id]["centro"]
		var dir: Vector2 = m.povoados[id]["dir"]
		var pg: Vector2 = Vector2(-dir.y, dir.x) * float(m.povoados[id]["lado"])
		var h := m.chao_em(c.x, c.y)
		jogo.jogador.global_position = Vector3(c.x, h + 1.0, c.y)
		m.atualizar_atividade()
		var imgs: Array[Image] = []
		var pontos := [
			[Vector3(c.x - dir.x * 22.0 - pg.x * 8.0, h + 75.0, c.y - dir.y * 22.0 - pg.y * 8.0), Vector3(c.x + pg.x * 14.0, h, c.y + pg.y * 14.0)],
			[Vector3(c.x - dir.x * 30.0 - pg.x * 18.0, h + 5.0, c.y - dir.y * 30.0 - pg.y * 18.0), Vector3(c.x + pg.x * 12.0, h + 1.5, c.y + pg.y * 12.0)],
			[Vector3(c.x + dir.x * 14.0 - pg.x * 6.0, h + 6.5, c.y + dir.y * 14.0 - pg.y * 6.0), Vector3(c.x + pg.x * 12.0, h + 1.5, c.y + pg.y * 12.0)],
			[Vector3(c.x + pg.x * 28.0 + dir.x * 8.0, h + 9.0, c.y + pg.y * 28.0 + dir.y * 8.0), Vector3(c.x + pg.x * 8.0, h + 1.0, c.y + pg.y * 8.0)]]
		for p in pontos:
			drone.olhar(p[0], p[1])
			await create_timer(1.8).timeout
			RenderingServer.force_draw()
			var im := root.get_viewport().get_texture().get_image()
			im.resize(640, 360)
			imgs.append(im)
		var folha := Image.create(1280, 720, false, Image.FORMAT_RGB8)
		for k in 4:
			folha.blit_rect(imgs[k], Rect2i(0, 0, 640, 360), Vector2i((k % 2) * 640, (k / 2) * 360))
		folha.save_png("res://tools/capturas/povoado_%s_%s.png" % [etapa, id])
		print("FOTO ", id)
	quit(0)
