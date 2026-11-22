extends SceneTree
# Uma casa com a porta fechada e depois aberta (um "jogador" fantasma se aproxima).
func _init() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.7, 0.75, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.62)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, -25, 0)
	root.add_child(luz)
	var casa := ConstrutorCasa.montar(3, 4, {"parede": "Wall_Plaster_Straight", "porta": "Wall_Plaster_Door_Flat", "janela": "Wall_Plaster_Window_Wide_Flat", "piso": "Floor_WoodDark", "canto": "Corner_Exterior_Wood"})
	root.add_child(casa)
	var fantasma := Node3D.new()
	fantasma.add_to_group("jogador")
	fantasma.position = Vector3(0, 0, 14)
	root.add_child(fantasma)
	_rodar.call_deferred(fantasma)


func _rodar(fantasma: Node3D) -> void:
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(3.2, 1.8, 10.5)
	cam.look_at(Vector3(0, 1.2, 4.0))
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/porta_a_fechada.png")
	fantasma.position = Vector3(0, 0, 6.0)
	await create_timer(0.22).timeout
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/porta_b_abrindo.png")
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/porta_c_aberta.png")
	quit(0)
