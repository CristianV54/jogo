extends SceneTree
## BANCADA: mundo plano e vazio que fotografa cada item do jogo sozinho (frente, lado e costas; parado e andando quando tem animação),
## com o Torin ao lado como régua nos itens grandes. Cada item vira UM JPEG em ~/Desktop/ajustes/<categoria>/<item>/<momento>.jpg.
##   godot --path . --resolution 1280x720 --script res://tools/bancada.gd -- antes [filtro]
##   godot --path . --resolution 1280x720 --script res://tools/bancada.gd -- depois [filtro]
## `filtro` é um pedaço do nome (ex.: lobo) para refazer só alguns itens. Sem filtro faz todos.
const SAIDA := "/Users/faresrames/Desktop/ajustes"
const LARG := 560
const ALT := 420

var momento := "antes"
var filtro := ""
var vp: SubViewport
var raiz: Node3D
var cam: Camera3D
var rotulo: Label
var torin_ref: Node3D
var feitos := 0
var itens: Array = []     # {cat, nome, f: Callable, frente: Vector3, ref: bool}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		momento = a[0]
	if a.size() > 1:
		filtro = a[1].to_lower()
	_montar_palco()
	_listar()
	_rodar.call_deferred()


func _montar_palco() -> void:
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
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_energy = 0.8
	sol.shadow_enabled = true
	raiz.add_child(sol)
	var enchimento := DirectionalLight3D.new()   # luz fraca do lado oposto, sem sombra: as costas dos itens não saem pretas
	enchimento.rotation_degrees = Vector3(-30, 145, 0)
	enchimento.light_energy = 0.45
	raiz.add_child(enchimento)
	var chao := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(80, 80)
	chao.mesh = pl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.62, 0.34)
	mat.roughness = 1.0
	chao.material_override = mat
	raiz.add_child(chao)
	cam = Camera3D.new()
	cam.fov = 35.0
	raiz.add_child(cam)
	rotulo = Label.new()
	rotulo.position = Vector2(8, 4)
	rotulo.add_theme_font_size_override("font_size", 15)
	rotulo.add_theme_color_override("font_color", Color.BLACK)
	rotulo.add_theme_color_override("font_outline_color", Color.WHITE)
	rotulo.add_theme_constant_override("outline_size", 4)
	vp.add_child(rotulo)


func _add(cat: String, nome: String, f: Callable, frente := Vector3(0, 0, 1), ref := true) -> void:
	if filtro != "":
		var ok_f := false
		for pedaco in filtro.split(","):
			if nome.to_lower().contains(pedaco) or cat.to_lower().contains(pedaco):
				ok_f = true
		if not ok_f:
			return
	itens.append({"cat": cat, "nome": nome, "f": f, "frente": frente, "ref": ref})


func _glb(caminho: String) -> Callable:
	return func() -> Node3D:
		return (load(caminho) as PackedScene).instantiate() as Node3D


func _listar() -> void:
	# --- animais de vila e caça (montados como a fauna do mundo monta) ---
	var animais := {
		"vaca": ["vaca", 1.0, "vaca", "", false], "ovelha": ["ovelha", 1.0, "ovelha", "", false], "cavalo": ["cavalo", 1.0, "cavalo", "", true],
		"porco": ["porco", 1.0, "porco", "", false], "cao": ["cao", 1.0, "cao", "", false], "galinha": ["galinha", 1.0, "galinha", "", false],
		"cervo": ["cavalo", 0.62, "cervo", "chifres", true], "coelho": ["coelho", 1.0, "coelho", "", true],
	}
	for k in animais:
		var d: Array = animais[k]
		_add("animais", k, func() -> Node3D:
			var a := AnimalVila.new()
			a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [d[0], d[0]])
			a.escala = d[1]
			a.especie = d[2]
			a.acessorio = d[3]
			a.altura_em = func(_x, _z): return 0.0
			return a, Vector3(0, 0, 1))
	# --- inimigos e chefes (as cenas do jogo) ---
	for f in DirAccess.get_files_at("res://scenes/inimigos"):
		if f.ends_with(".tscn"):
			var cam_c := "res://scenes/inimigos/" + f
			_add("inimigos", f.get_basename(), func() -> Node3D: return (load(cam_c) as PackedScene).instantiate() as Node3D, Vector3(0, 0, -1))
	_add("criaturas", "fagulha", _glb("res://scenes/criaturas/fagulha.tscn"), Vector3(0, 0, 1))
	# --- gente (as cenas do jogo) ---
	for f in DirAccess.get_files_at("res://scenes/personagens"):
		if f.ends_with(".tscn"):
			var cam_p := "res://scenes/personagens/" + f
			_add("personagens", f.get_basename(), func() -> Node3D: return (load(cam_p) as PackedScene).instantiate() as Node3D, Vector3(0, 0, 1))
	# --- itens que caem no chão e armas ---
	for d in DirAccess.get_directories_at("res://assets/models/itens"):
		_add("drops", d, _glb("res://assets/models/itens/%s/%s.glb" % [d, d]), Vector3(0, 0, 1), false)
	for f in DirAccess.get_files_at("res://assets/models/armas"):
		if f.ends_with(".glb"):
			_add("armas", f.get_basename(), _glb("res://assets/models/armas/" + f), Vector3(0, 0, 1), false)
	# --- natureza feita em código ---
	var nat := {"pinheiro": FabricaNatureza.pinheiro, "folhosa": FabricaNatureza.folhosa, "arvore_morta": FabricaNatureza.morta,
		"pedra": FabricaNatureza.pedra, "arbusto": FabricaNatureza.arbusto, "toras": FabricaNatureza.toras, "cogumelo": FabricaNatureza.cogumelo}
	for k in nat:
		var fn: Callable = nat[k]
		_add("natureza", k, func() -> Node3D:
			var m := MeshInstance3D.new()
			m.mesh = fn.call()
			m.material_override = FabricaNatureza.material()
			return m, Vector3(0, 0, 1), k in ["pinheiro", "folhosa", "arvore_morta"])
	# --- móveis e peças de casa (Fantasy Props e Village) ---
	for f in DirAccess.get_files_at("res://assets/models/cenario/moveis"):
		if f.ends_with(".gltf"):
			_add("moveis", f.get_basename(), _glb("res://assets/models/cenario/moveis/" + f), Vector3(0, 0, 1), true)
	for f in DirAccess.get_files_at("res://assets/models/cenario/vila_mv"):
		if f.ends_with(".gltf"):
			_add("pecas_de_casa", f.get_basename(), _glb("res://assets/models/cenario/vila_mv/" + f), Vector3(0, 0, 1), false)


func _caixa(no: Node3D) -> AABB:
	var ab := AABB()
	var primeiro := true
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.visible:
			continue
		var bb: AABB = m.global_transform * m.get_aabb()
		ab = bb if primeiro else ab.merge(bb)
		primeiro = false
	var esq := no.find_child("Skeleton3D", true, false) as Skeleton3D
	if esq != null:   # a caixa da malha em repouso infla o tamanho nos modelos com esqueleto: aí vale só a posição dos ossos
		primeiro = true
		for i in esq.get_bone_count():
			if esq.get_bone_name(i).begins_with("IK"):
				continue
			var q: Vector3 = esq.to_global(esq.get_bone_global_pose(i).origin)
			ab = AABB(q, Vector3.ZERO) if primeiro else ab.expand(q)
			primeiro = false
		ab = ab.grow(maxf(ab.size.length() * 0.06, 0.03))
	return ab if not primeiro else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)


func _anims(no: Node) -> Array:
	var ap := no.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return []
	var saida := []
	for n in ["Idle", "Idle_Loop", "Walk", "WalkSlow", "Walk_Loop", "Run", "Jog_Fwd_Loop"]:
		if ap.has_animation(n) and saida.size() < 3:
			saida.append([ap, n])
	return saida


## Close da cabeça: [centro, comprimento, direção do focinho] pelo esqueleto (osso Head ou Bone.003 e a ponta). Vazio se não tiver.
func _cabeca(no: Node3D) -> Array:
	var esq := no.find_child("Skeleton3D", true, false) as Skeleton3D
	if esq == null:
		return []
	for par in [["Head", "Head_end"], ["Bone.003", "Bone.003_end"], ["head", "Bone"]]:
		var a := esq.find_bone(par[0])
		var b := esq.find_bone(par[1])
		if a >= 0 and b >= 0:
			var pa: Vector3 = esq.to_global(esq.get_bone_global_pose(a).origin)
			var pb: Vector3 = esq.to_global(esq.get_bone_global_pose(b).origin)
			var f := pb - pa
			f.y = 0.0
			return [(pa + pb) * 0.5, pa.distance_to(pb), f.normalized()]
	return []


func _foto(centro: Vector3, raio: float, dir: Vector3) -> Image:
	var d := maxf(raio * 2.6, 0.6)
	cam.position = centro + dir.normalized() * d + Vector3(0, raio * 0.35, 0)
	cam.look_at(centro, Vector3.UP)
	await process_frame        # o rótulo (texto 2D) só atualiza no quadro seguinte
	await process_frame
	RenderingServer.force_draw()   # desenha agora, sem esperar a GPU: foto sempre igual ao que está posicionado
	return vp.get_texture().get_image()


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute(SAIDA)
	var ini := Time.get_ticks_msec()
	for it in itens:
		if filtro == "" and momento == "antes" and FileAccess.file_exists("%s/%s/%s/%s.jpg" % [SAIDA, it["cat"], it["nome"], momento]):
			feitos += 1
			continue   # já feito (retomada)
		var no: Node3D = (it["f"] as Callable).call()
		raiz.add_child(no)
		for c in [no]:
			if c is Node:
				c.set_physics_process(false)
		await create_timer(0.15).timeout
		var ab := _caixa(no)
		var maior := maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
		var com_ref: bool = it["ref"] and ab.size.y > 0.6
		if com_ref:
			torin_ref = (load("res://assets/models/personagens/torin/torin.glb") as PackedScene).instantiate() as Node3D
			raiz.add_child(torin_ref)
			torin_ref.position = Vector3(maior * 0.5 + 0.9, 0, 0.0)
			var apt := torin_ref.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if apt:
				for n in ["Idle_Loop", "Idle"]:
					if apt.has_animation(n):
						apt.play(n)
						break
		var cena_ab := ab
		if com_ref:
			cena_ab = ab.merge(AABB(Vector3(torin_ref.position.x - 0.4, 0, -0.4), Vector3(0.8, 1.8, 0.8)))
		var centro := cena_ab.get_center()
		var raio := maxf(cena_ab.size.length() * 0.5, 0.15)
		var frente: Vector3 = it["frente"]
		var lado := Vector3.UP.cross(frente).normalized()
		var vistas := [["frente", frente], ["lado", lado], ["costas", -frente]]
		var estados: Array = _anims(no)
		if estados.is_empty():
			estados = [null]
		var linhas: Array = []
		for est in estados:
			var rotulo_est := "parado"
			if est != null:
				(est[0] as AnimationPlayer).play(est[1])
				(est[0] as AnimationPlayer).seek(0.35, true)
				rotulo_est = String(est[1])
			await process_frame
			for v in vistas:
				rotulo.text = "%s / %s   [%s %s]   %.2f x %.2f x %.2f m (c x l x a)" % [it["cat"], it["nome"], v[0], rotulo_est, ab.size.z, ab.size.x, ab.size.y]
				linhas.append(await _foto(centro, raio, v[1]))
		var n_cab := 0
		var cab := _cabeca(no)
		if not cab.is_empty():
			var fh: Vector3 = cab[2]
			var lat := Vector3.UP.cross(fh).normalized()
			var vistas_cab := [["cabeça 3/4 esq", (fh + lat).normalized()], ["cabeça frente", fh], ["cabeça 3/4 dir", (fh - lat).normalized()]]
			n_cab = 3
			for v in vistas_cab:
				rotulo.text = "%s / %s   [%s]" % [it["cat"], it["nome"], v[0]]
				linhas.append(await _foto(cab[0], maxf(float(cab[1]) * 0.9, 0.05), v[1]))
		var colunas := 3
		var nl := int(ceil(linhas.size() / float(colunas)))
		var folha := Image.create(LARG * colunas, ALT * nl, false, Image.FORMAT_RGB8)
		for i in linhas.size():
			var im: Image = linhas[i]
			im.convert(Image.FORMAT_RGB8)
			folha.blit_rect(im, Rect2i(0, 0, LARG, ALT), Vector2i((i % colunas) * LARG, (i / colunas) * ALT))
		var pasta := "%s/%s/%s" % [SAIDA, it["cat"], it["nome"]]
		DirAccess.make_dir_recursive_absolute(pasta)
		folha.save_jpg("%s/%s.jpg" % [pasta, momento], 0.9)
		if n_cab > 0:   # só a linha da cabeça, para conferir os olhos de relance
			var fc := Image.create(LARG * 3, ALT, false, Image.FORMAT_RGB8)
			for i in 3:
				var im2: Image = linhas[linhas.size() - 3 + i]
				im2.convert(Image.FORMAT_RGB8)
				fc.blit_rect(im2, Rect2i(0, 0, LARG, ALT), Vector2i(i * LARG, 0))
			fc.save_jpg("%s/cabeca_%s.jpg" % [pasta, momento], 0.9)
		feitos += 1
		print("FOTO ", it["cat"], "/", it["nome"], " ", momento, " (", feitos, "/", itens.size(), ")")
		no.queue_free()
		if com_ref:
			torin_ref.queue_free()
		await process_frame
	print("BANCADA fim: ", feitos, " itens em ", (Time.get_ticks_msec() - ini) / 1000, " s")
	quit(0)
