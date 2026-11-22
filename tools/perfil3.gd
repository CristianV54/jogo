extends SceneTree
var jogo: Jogo
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()
func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var flags := OS.get_cmdline_user_args()
	if "pixels" in flags:
		root.scaling_3d_scale = 0.25
	if "semfloresta" in flags:
		for n in jogo.mundo.find_children("*", "MultiMeshInstance3D", true, false):
			n.visible = false
	if "semterreno" in flags:
		for n in jogo.mundo.find_children("Superficie", "MeshInstance3D", true, false):
			n.visible = false
	if "semrefugio" in flags:
		jogo.mundo.regioes["refugio_do_pinhal"].process_mode = Node.PROCESS_MODE_DISABLED
		jogo.mundo.regioes["refugio_do_pinhal"].visible = false
	if "semmundo" in flags:
		for c in jogo.mundo.get_children():
			if not (c is AreaBase):
				c.process_mode = Node.PROCESS_MODE_DISABLED
				if c is Node3D:
					c.visible = false
	if "semfisica" in flags:
		for c in jogo.mundo.find_children("*", "CharacterBody3D", true, false):
			c.set_physics_process(false)
	if "semanim" in flags:
		for ap in jogo.find_children("*", "AnimationPlayer", true, false):
			ap.active = false
	var ativos := 0
	var esq := 0
	for ap in jogo.find_children("*", "AnimationPlayer", true, false):
		if ap.active and ap.is_inside_tree():
			ativos += 1
	for mi in jogo.find_children("*", "MeshInstance3D", true, false):
		if mi.skeleton != NodePath() and mi.is_visible_in_tree():
			esq += 1
	print("PERF animation players ativos=", ativos, " malhas com esqueleto visiveis=", esq)
	if "far300" in flags:
		jogo.camera.get_node("Braco/Lente").far = 300.0
	if "far200" in flags:
		jogo.camera.get_node("Braco/Lente").far = 200.0
	if "semclima" in flags:
		jogo.clima.set_process(false)
	if "semaudio" in flags:
		jogo.clima._chuva_som.queue_free()
		jogo.clima._trovao_som.queue_free()
	if "semsombra" in flags:
		jogo.clima.get_node("Sol").shadow_enabled = false
	if "semceu" in flags:
		jogo.clima._env.background_mode = Environment.BG_COLOR
	for par in [["spawn", Vector3(0, 2, 14), 0.0], ["campos300", Vector3(300, 12, 12), -PI / 2.0]]:
		jogo.jogador.global_position = par[1]
		jogo.camera.yaw = par[2]
		await create_timer(2.5).timeout
		print("PERF ", par[0], " fps=", Engine.get_frames_per_second(), " proc=%.1fms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0), " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	quit(0)
