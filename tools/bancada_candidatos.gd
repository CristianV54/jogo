extends SceneTree
## BANCADA DE CANDIDATOS: fotografa modelos baixados para avaliação ANTES de entrarem no jogo. Lê os .glb de
## tools/capturas/candidatos/ (pasta fora do git) e faz uma folha por modelo: frente, lado, costas e 3/4, e depois até 6
## animações em 4 quadros cada (vista de lado). Saída em tools/capturas/candidatos/folhas/<nome>.jpg.
##   godot --path . --resolution 1280x720 --script res://tools/bancada_candidatos.gd -- [filtro]
const PASTA := "res://tools/capturas/candidatos"
const LARG := 320
const ALT := 240

var vp: SubViewport
var raiz: Node3D
var cam: Camera3D
var rotulo: Label


func _init() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(LARG, ALT)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	raiz = Node3D.new()
	vp.add_child(raiz)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.72, 0.8, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_energy = 0.8
	raiz.add_child(sol)
	var enchimento := DirectionalLight3D.new()
	enchimento.rotation_degrees = Vector3(-30, 145, 0)
	enchimento.light_energy = 0.45
	raiz.add_child(enchimento)
	cam = Camera3D.new()
	cam.fov = 35.0
	raiz.add_child(cam)
	rotulo = Label.new()
	rotulo.position = Vector2(4, 2)
	rotulo.add_theme_font_size_override("font_size", 12)
	rotulo.add_theme_color_override("font_color", Color.BLACK)
	rotulo.add_theme_color_override("font_outline_color", Color.WHITE)
	rotulo.add_theme_constant_override("outline_size", 4)
	vp.add_child(rotulo)
	_rodar.call_deferred()


func _caixa(no: Node3D) -> AABB:
	var ab := AABB()
	var primeiro := true
	var esq := no.find_child("Skeleton3D", true, false) as Skeleton3D
	if esq != null:
		for i in esq.get_bone_count():
			var q: Vector3 = esq.to_global(esq.get_bone_global_pose(i).origin)
			ab = AABB(q, Vector3.ZERO) if primeiro else ab.expand(q)
			primeiro = false
		return ab.grow(maxf(ab.size.length() * 0.12, 0.02))
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		ab = bb if primeiro else ab.merge(bb)
		primeiro = false
	return ab


func _foto(texto: String) -> Image:
	rotulo.text = texto
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var im := vp.get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	return im


func _rodar() -> void:
	var filtro := OS.get_cmdline_user_args()[0].to_lower() if OS.get_cmdline_user_args().size() > 0 else ""
	DirAccess.make_dir_recursive_absolute(PASTA + "/folhas")
	for f in DirAccess.get_files_at(PASTA):
		if not f.ends_with(".glb") or (filtro != "" and not f.to_lower().contains(filtro)):
			continue
		var nome := f.get_basename()
		var no := (load(PASTA + "/" + f) as PackedScene).instantiate() as Node3D
		raiz.add_child(no)
		await create_timer(0.2).timeout
		var ap := no.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var ab := _caixa(no)
		var centro := ab.get_center()
		var raio := maxf(ab.size.length() * 0.5, 0.05)
		var imagens: Array = []
		for v in [["frente +Z", Vector3(0, 0, 1)], ["lado", Vector3(1, 0, 0)], ["costas", Vector3(0, 0, -1)], ["3/4", Vector3(1, 0, 1).normalized()]]:
			cam.position = centro + (v[1] as Vector3) * raio * 2.8 + Vector3(0, raio * 0.3, 0)
			cam.look_at(centro, Vector3.UP)
			imagens.append(await _foto("%s  [%s]  %.2f x %.2f x %.2f" % [nome, v[0], ab.size.x, ab.size.y, ab.size.z]))
		var anims: PackedStringArray = ap.get_animation_list() if ap else PackedStringArray()
		var feitas := 0
		for a in anims:
			if a == "RESET" or ap.get_animation(a).length < 0.15 or feitas >= 6:
				continue
			feitas += 1
			ap.play(a)
			cam.position = centro + Vector3(1, 0, 0) * raio * 2.8 + Vector3(0, raio * 0.3, 0)
			cam.look_at(centro, Vector3.UP)
			var dur := ap.get_animation(a).length
			for k in 4:
				ap.seek(dur * k / 4.0, true)
				imagens.append(await _foto("%s  %s  %d/4  (%.1f s)" % [nome, String(a).right(22), k + 1, dur]))
		var nl := int(ceil(imagens.size() / 4.0))
		var folha := Image.create(LARG * 4, ALT * nl, false, Image.FORMAT_RGB8)
		for i in imagens.size():
			folha.blit_rect(imagens[i], Rect2i(0, 0, LARG, ALT), Vector2i((i % 4) * LARG, (i / 4) * ALT))
		folha.save_jpg("%s/folhas/%s.jpg" % [PASTA, nome], 0.88)
		print("CANDIDATO ", nome, " animações=", anims.size(), " fotografadas=", feitas)
		no.queue_free()
		await process_frame
	quit(0)
