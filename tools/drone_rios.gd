extends SceneTree
## Fotos de todos os rios do mundo pelo Drone: 3 pontos por rio (começo, meio, fim), cada um de cima e de perto.
## Folhas em tools/capturas/rios_<etapa>_<n>.png.   godot --path . --resolution 1280x720 --script res://tools/drone_rios.gd -- <etapa>
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
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	var m: Mundo = jogo.mundo
	drone = jogo.get_node("Admin").drone
	drone.ligar(jogo, jogo.jogador.global_position)
	var cenas: Array = []
	for r in m.terreno.rios:
		var pts: PackedVector2Array = r["pontos"]
		for t in [0.1, 0.5, 0.9]:
			var i := clampi(int(t * (pts.size() - 1)), 0, pts.size() - 2)
			var p: Vector2 = pts[i]
			var dir := (pts[i + 1] - pts[i]).normalized()
			cenas.append([String(r.get("nome", "rio")), p, dir])
	var n := 0
	var folha_imgs: Array[Image] = []
	for c in cenas:
		var p: Vector2 = c[1]
		var dir: Vector2 = c[2]
		var h: float = m.chao_em(p.x, p.y)
		jogo.jogador.global_position = Vector3(p.x, h + 1.0, p.y)
		jogo.mundo.atualizar_atividade()
		for v in [["alto", Vector3(p.x - dir.x * 40.0, h + 35.0, p.y - dir.y * 40.0), Vector3(p.x + dir.x * 20.0, h, p.y + dir.y * 20.0)],
				["baixo", Vector3(p.x - dir.y * 9.0, h + 3.2, p.y + dir.x * 9.0), Vector3(p.x + dir.y * 0.0, h - 0.3, p.y)]]:
			drone.olhar(v[1], v[2])
			await create_timer(1.6).timeout
			RenderingServer.force_draw()
			var im := root.get_viewport().get_texture().get_image()
			im.resize(426, 240)
			folha_imgs.append(im)
		if folha_imgs.size() >= 6:
			_salvar(folha_imgs, n)
			folha_imgs = []
			n += 1
	if folha_imgs.size() > 0:
		_salvar(folha_imgs, n)
	print("FOTOS_RIOS ", n + 1, " folhas")
	quit(0)


func _salvar(imgs: Array[Image], n: int) -> void:
	var folha := Image.create(1278, 480, false, Image.FORMAT_RGB8)
	for k in imgs.size():
		(imgs[k] as Image).convert(Image.FORMAT_RGB8)   # o formato da captura muda com o renderizador (RGBA no OpenGL)
		folha.blit_rect(imgs[k], Rect2i(0, 0, 426, 240), Vector2i((k % 3) * 426, (k / 3) * 240))
	folha.save_png("res://tools/capturas/rios_%s_%d.png" % [etapa, n])
