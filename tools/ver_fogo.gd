extends SceneTree
# Fogo isolado, com e sem fumaça, sobre fundo escuro e fundo claro.
func _init() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.1, 0.14) if OS.get_cmdline_user_args().size() > 0 else Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.3, 0.3, 0.32)
	env.environment = e
	root.add_child(env)
	for k in 2:
		var f := Fogo.new()
		f.com_fumaca = k == 1
		f.position = Vector3(-2.0 + k * 4.0, 0, 0)
		root.add_child(f)
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(30, 30)
	chao.mesh = plano
	root.add_child(chao)
	_rodar.call_deferred()


func _rodar() -> void:
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 2.0, 7.5)
	cam.look_at(Vector3(0, 1.3, 0))
	for i in 50:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/fogo_isolado%s.png" % ("_noite" if OS.get_cmdline_user_args().size() > 0 else ""))
	quit(0)
