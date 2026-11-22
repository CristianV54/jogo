extends SceneTree
# Fotografa o Torin correndo (espada nas costas) e parado (espada na mão), de costas e de lado.
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
	var giro := OS.get_cmdline_user_args()
	if giro.size() >= 3:
		t._arma_costas.rotation_degrees = Vector3(float(giro[0]), float(giro[1]), float(giro[2]))
	if giro.size() >= 6:
		t._arma_costas.position = Vector3(float(giro[3]), float(giro[4]), float(giro[5]))
	for par in [["parado", "Idle"], ["correndo", "Jog_Fwd"]]:
		t.tocar(par[1], 0.0)
		await create_timer(0.7).timeout
		for v in [["costas", Vector3(0, 1.3, -3.0)], ["lado", Vector3(3.0, 1.3, 0)], ["frente", Vector3(0, 1.3, 3.0)]]:
			cam.global_position = v[1]
			cam.look_at(Vector3(0, 1.1, 0))
			await create_timer(0.35).timeout
			RenderingServer.force_draw()
			root.get_viewport().get_texture().get_image().save_png("tools/capturas/espada_%s_%s.png" % [par[0], v[0]])
	quit(0)
