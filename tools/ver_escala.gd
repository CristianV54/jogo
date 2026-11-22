extends SceneTree
# Torin ao lado dos dragões, na escala real do jogo: Fagulha, Filhote de Asa e Ignis-Maw.
func _init() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, -30, 0)
	luz.shadow_enabled = true
	root.add_child(luz)
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(200, 200)
	chao.mesh = plano
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.4, 0.5, 0.35)
	chao.material_override = mt
	root.add_child(chao)
	# (cena, escala extra, x)
	var itens := [["res://scenes/personagens/torin.tscn", 1.0, -6.0, "Torin 1,84 m"], ["res://scenes/criaturas/filhote_de_asa_visual.tscn", 0.6, -2.5, "Filhote de Asa"],
		["res://scenes/criaturas/fagulha.tscn", 1.0, 6.0, "Fagulha"], ["res://scenes/criaturas/ignis_maw_visual.tscn", 8.0, 34.0, "Ignis-Maw"]]
	for it in itens:
		var n: Node3D = load(it[0]).instantiate()
		n.position = Vector3(it[2], 0, 0)
		n.scale = Vector3.ONE * it[1]
		root.add_child(n)
		if n is Fagulha:
			n.alvo = null
	_rodar.call_deferred()
var _orbita: Camera3D
var _t := 0.0


func _process(delta: float) -> bool:
	if _orbita:
		_t += delta * 0.12
		var centro := Vector3(14, 4, 0)
		_orbita.global_position = centro + Vector3(sin(_t) * 60.0, 12.0, cos(_t) * 60.0)
		_orbita.look_at(centro)
	return false


func _rodar() -> void:
	if "--ficar" in OS.get_cmdline_user_args():
		_orbita = Camera3D.new()
		_orbita.fov = 50
		root.add_child(_orbita)
		_orbita.current = true
		return
	for n in root.get_children():
		if n is Node3D and not (n is MeshInstance3D) and not (n is DirectionalLight3D):
			var mn := Vector3(1e9, 1e9, 1e9)
			var mx := Vector3(-1e9, -1e9, -1e9)
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				var a: AABB = mi.global_transform * mi.get_aabb()
				mn = mn.min(a.position)
				mx = mx.max(a.position + a.size)
			print("MEDIDA ", n.name, " | altura ", snapped(mx.y - mn.y, 0.1), " | envergadura/largura ", snapped(mx.x - mn.x, 0.1), " | comprimento ", snapped(mx.z - mn.z, 0.1))
	var cam := Camera3D.new()
	cam.fov = 45
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(4, 5, 30)
	cam.look_at(Vector3(4, 3, 0))
	for i in 30:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/escala.png")
	cam.global_position = Vector3(30, 12, 70)
	cam.look_at(Vector3(30, 6, 0))
	for i in 6:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/escala_cima.png")
	print("ESCALA_OK")
	quit(0)
