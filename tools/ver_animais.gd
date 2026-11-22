extends SceneTree
# Põe os animais lado a lado, toca uma animação em cada um, mede altura/comprimento e fotografa.
#   godot --path . --resolution 1600x700 --script res://tools/ver_animais.gd -- Walk
const ANIMAIS := ["vaca", "cavalo", "ovelha", "porco", "cao", "lobo", "javali"]
var _modelos := {}


func _init() -> void:
	var anim := "Idle"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		anim = args[0]
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.82)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, -30, 0)
	luz.shadow_enabled = true
	root.add_child(luz)
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(60, 60)
	chao.mesh = plano
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.4, 0.5, 0.35)
	chao.material_override = mt
	root.add_child(chao)
	var x := -10.0
	for nome in ANIMAIS:
		var caminho: String = "res://assets/models/criaturas/%s/%s.glb" % [nome, nome]
		if not ResourceLoader.exists(caminho):
			continue
		var n: Node3D = load(caminho).instantiate()
		n.position = Vector3(x, 0, 0)
		n.rotation_degrees.y = 90.0   # de perfil, andando para +X
		n.name = nome
		root.add_child(n)
		_modelos[nome] = n
		x += 3.4
	_rodar.call_deferred(anim)


func _rodar(anim: String) -> void:
	await process_frame
	for nome in _modelos:
		var n: Node3D = _modelos[nome]
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		var lista := ap.get_animation_list() if ap else PackedStringArray()
		var loops := []
		for a in lista:
			loops.append(a + ("(loop)" if ap.get_animation(a).loop_mode != Animation.LOOP_NONE else ""))
		if ap and ap.has_animation(anim):
			ap.play(anim)
			ap.seek(0.4, true)
		var mn := Vector3(1e9, 1e9, 1e9)
		var mx := Vector3(-1e9, -1e9, -1e9)
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = mi.global_transform * mi.get_aabb()
			mn = mn.min(a.position)
			mx = mx.max(a.position + a.size)
		print("ANIMAL ", nome, " | altura ", snapped(mx.y - mn.y, 0.01), " | largura ", snapped(mx.x - mn.x, 0.01), " | comprimento ", snapped(mx.z - mn.z, 0.01), " | pe_y ", snapped(mn.y, 0.01), " | anims ", loops)
	var cam := Camera3D.new()
	cam.fov = 40
	root.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 2.2, 15)
	cam.look_at(Vector3(0, 0.9, 0))
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/animais_%s.png" % anim)
	print("ANIMAIS_OK")
	quit(0)
