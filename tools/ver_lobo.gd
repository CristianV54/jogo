extends SceneTree
# Fotografa o lobo em cada animação.  godot --path . --resolution 900x600 --script res://tools/ver_lobo.gd
func _init() -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, -30, 0)
	root.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.7, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.75)
	env.environment = e
	root.add_child(env)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	chao.mesh = pm
	root.add_child(chao)
	var l: Node3D = load("res://scenes/criaturas/lobo_visual.tscn").instantiate()
	root.add_child(l)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	_rodar.call_deferred(l, cam)


func _rodar(l: Criatura, cam: Camera3D) -> void:
	print("ANIMS ", l.animacoes.get_animation_list())
	for nome in ["Idle", "Walk", "Run", "Jump", "Death"]:
		if not l.tem(nome):
			print("FALTA ", nome)
			continue
		l.animacoes.play(nome)
		var tempos := [0.15, 0.5] if nome != "Idle" else [0.3]
		if nome == "Death":
			tempos = [0.2, 0.9]
		for t in tempos:
			l.animacoes.seek(t, true)
			await create_timer(0.25).timeout
			for v in [["lado", Vector3(2.8, 0.8, 0.0)], ["tres_quartos", Vector3(2.0, 1.2, -2.0)], ["frente", Vector3(0, 0.9, -2.8)]]:
				cam.global_position = v[1]
				cam.look_at(Vector3(0, 0.45, 0))
				await create_timer(0.1).timeout
				RenderingServer.force_draw()
				root.get_viewport().get_texture().get_image().save_png("tools/capturas/lobo_%s_%d_%s.png" % [nome, int(t * 100), v[0]])
	quit(0)
