extends SceneTree
# Fotografa o Torin correndo e parado (espada sempre na mão), de costas, de lado e de frente.
#   godot --path . --script res://tools/ver_espada.gd -- gx gy gz   (giro extra da corrida, em graus)
func _init() -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, -30, 0)
	root.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.6, 0.65, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment = e
	root.add_child(env)
	var t: Node3D = load("res://scenes/personagens/torin.tscn").instantiate()
	root.add_child(t)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	_rodar.call_deferred(t, cam)


func _rodar(t: Humanoide, cam: Camera3D) -> void:
	var g := OS.get_cmdline_user_args()
	if g.size() >= 3:
		t.corrida_giro = Vector3(float(g[0]), float(g[1]), float(g[2]))
	var tag := "_".join(g) if g.size() >= 3 else "atual"
	for par in [["parado", "Idle"], ["correndo", "Jog_Fwd"]]:
		t.tocar(par[1], 0.0)
		await create_timer(0.7).timeout
		for v in [["costas", Vector3(0, 1.3, -3.0)], ["lado", Vector3(3.0, 1.3, 0)], ["frente", Vector3(0, 1.3, 3.0)]]:
			cam.global_position = v[1]
			cam.look_at(Vector3(0, 1.1, 0))
			await create_timer(0.35).timeout
			RenderingServer.force_draw()
			root.get_viewport().get_texture().get_image().save_png("tools/capturas/espada_%s_%s_%s.png" % [tag, par[0], v[0]])
	quit(0)
