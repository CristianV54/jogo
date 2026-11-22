extends SceneTree
# Cervo, urso, coelho e corvo lado a lado, de perfil e de três quartos.
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
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(40, 40)
	chao.mesh = plano
	root.add_child(chao)
	var lista := [["cavalo", "cervo", "chifres", 0.62, -4.5], ["cao", "urso", "orelhas_redondas", 2.3, -1.8], ["cao", "coelho", "orelhas_longas", 0.5, 0.6]]
	for it in lista:
		var a := AnimalVila.new()
		a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [it[0], it[0]])
		a.especie = it[1]
		a.acessorio = it[2]
		a.escala = it[3]
		a.raio_vagar = 0.01
		a.position = Vector3(it[4], 0, 0)
		a.rotation.y = 0.9
		root.add_child(a)
	var c := Corvo.new()
	c.position = Vector3(2.4, 0.0, 0.0)
	c.rotation.y = 0.9
	root.add_child(c)
	_rodar.call_deferred()


func _rodar() -> void:
	var cam := Camera3D.new()
	cam.fov = 40
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(-1.0, 1.6, 7.0)
	cam.look_at(Vector3(-1.0, 0.7, 0))
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/bosque_animais.png")
	quit(0)
