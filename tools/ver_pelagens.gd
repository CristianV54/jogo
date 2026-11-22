extends SceneTree
# 6 indivíduos de cada espécie, para conferir a variação de cor e a textura de pelo.
#   godot --path . --resolution 1700x900 --script res://tools/ver_pelagens.gd
const ESPECIES := ["vaca", "cavalo", "ovelha", "porco", "cao", "lobo", "javali"]


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
	plano.size = Vector2(80, 80)
	chao.mesh = plano
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.4, 0.5, 0.35)
	chao.material_override = mt
	root.add_child(chao)
	seed(5)
	var z := -9.0
	for esp in ESPECIES:
		for k in 6:
			var a := AnimalVila.new()
			a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [esp, esp])
			a.especie = esp
			a.raio_vagar = 0.01
			a.position = Vector3(-7.5 + k * 3.0, 0, z)
			a.rotation.y = PI / 2
			root.add_child(a)
		z += 2.6
	_rodar.call_deferred()


func _rodar() -> void:
	var cam := Camera3D.new()
	cam.fov = 45
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 22, 14)
	cam.look_at(Vector3(0, 0, 1))
	for i in 25:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/pelagens.png")
	cam.global_position = Vector3(-4.5, 3.0, -2.5)
	cam.look_at(Vector3(-4.5, 0.6, -9.0))
	for i in 6:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/pelagens_perto.png")
	print("PELAGENS_OK")
	quit(0)
