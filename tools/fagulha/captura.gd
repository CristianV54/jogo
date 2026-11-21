extends SceneTree
# Uso: godot --path . --script res://captura.gd -- NomeDaAnimacao arquivo.png segundos
# Toca a animação explicitamente (com loop) e fotografa o que o Godot desenha.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var anim_nome: String = args[0]
	var saida: String = args[1]
	var espera: float = float(args[2])
	var arquivo: String = args[3] if args.size() > 3 else "res://dragao_teste.glb"
	var escala: float = float(args[4]) if args.size() > 4 else 0.035

	var raiz: Node3D = load(arquivo).instantiate()
	raiz.scale = Vector3.ONE * escala   # 1 unidade do Blender = `escala` metros
	root.add_child(raiz)
	for no in raiz.find_children("*", "MeshInstance3D", true, false):
		for i in no.mesh.get_surface_count():
			var mt: Material = no.mesh.surface_get_material(i)
			if mt is BaseMaterial3D:
				print("MATERIAL ", mt.resource_name, " cor_do_vertice_como_albedo ", mt.vertex_color_use_as_albedo,
					" rugosidade ", snapped(mt.roughness, 0.01))

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.75, 0.75, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(luz)
	var cam := Camera3D.new()
	cam.fov = 32
	root.add_child(cam)

	var ap: AnimationPlayer = raiz.find_child("AnimationPlayer", true, false)
	ap.play(anim_nome)   # o loop já vem do nome "-loop" na importação
	print("TOCANDO ", anim_nome, " posicao inicial ", ap.current_animation_position)
	await create_timer(espera).timeout
	print("POSICAO_APOS_ESPERA ", snapped(ap.current_animation_position, 0.01), " tocando ", ap.is_playing())

	# tamanho REAL do bicho animado: caixa que envolve todos os ossos, em metros do mundo
	var sk: Skeleton3D = raiz.find_child("Skeleton3D", true, false)
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	for b in sk.get_bone_count():
		var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(b).origin
		mn = mn.min(p)
		mx = mx.max(p)
	var centro := (mn + mx) / 2.0
	var tam := mx - mn
	print("ESCALA_SKELETON ", sk.global_transform.basis.get_scale(), " | CAIXA_DOS_OSSOS m ", tam, " centro ", centro)
	var malha: MeshInstance3D = raiz.find_child("Dragon_Mesh", true, false)
	var gab: AABB = malha.global_transform * malha.get_aabb()
	print("MALHA_GLOBAL escala ", malha.global_transform.basis.get_scale(), " aabb_mundo tam ", gab.size, " centro ", gab.get_center(),
		" | pai ", malha.get_parent().name)
	var dist: float = max(gab.size.length() * 1.5, 1.0)
	cam.look_at_from_position(gab.get_center() + Vector3(0.8, 0.45, 1.0).normalized() * dist, gab.get_center())
	await process_frame   # a câmera só vale no quadro seguinte
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(saida)
	print("SALVO ", saida, " ", img.get_size())
	quit(0)
