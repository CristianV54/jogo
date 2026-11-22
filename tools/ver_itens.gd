extends SceneTree
# Os quatro itens de drop lado a lado, no tamanho que aparecem no jogo (escala 1,8).
func _init() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.82)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(luz)
	var x := -0.9
	for nome in ["carne", "couro", "la", "presa"]:
		var n: Node3D = load("res://assets/models/itens/%s/%s.glb" % [nome, nome]).instantiate()
		n.scale = Vector3.ONE * 1.8
		n.position = Vector3(x, 0.1, 0)
		n.rotation_degrees.y = 25.0
		root.add_child(n)
		x += 0.6
	_rodar.call_deferred()


func _rodar() -> void:
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 0.7, 1.9)
	cam.look_at(Vector3(0, 0.15, 0))
	for i in 10:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/itens.png")
	quit(0)
