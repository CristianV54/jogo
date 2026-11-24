extends SceneTree
## BANCADA DE MOVIMENTO: fotografa cada animação de cada ser em 6 quadros ao longo do ciclo (vista de lado, mundo plano) e mede
## se a animação mexe de verdade (amplitude dos ossos), o passo dos pés e a velocidade que a animação pede contra a do jogo.
## Uma folha JPEG por ser em tools/capturas/movimento/<nome>.jpg e a tabela em tools/capturas/movimento/MEDIDAS.md.
##   godot --path . --resolution 1280x720 --script res://tools/bancada_movimento.gd -- [filtro]
const SAIDA := "res://tools/capturas/movimento"
const LARG := 280
const ALT := 210
const QUADROS := 6

var filtro := ""
var vp: SubViewport
var raiz: Node3D
var cam: Camera3D
var rotulo: Label
var itens: Array = []   # {nome, f: Callable, frente: Vector3}
var linhas_md: PackedStringArray = []


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		filtro = a[0].to_lower()
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
	raiz.add_child(sol)
	var enchimento := DirectionalLight3D.new()
	enchimento.rotation_degrees = Vector3(-30, 145, 0)
	enchimento.light_energy = 0.45
	raiz.add_child(enchimento)
	var chao := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(120, 120)
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
	rotulo.position = Vector2(4, 2)
	rotulo.add_theme_font_size_override("font_size", 12)
	rotulo.add_theme_color_override("font_color", Color.BLACK)
	rotulo.add_theme_color_override("font_outline_color", Color.WHITE)
	rotulo.add_theme_constant_override("outline_size", 4)
	vp.add_child(rotulo)


func _add(nome: String, f: Callable, frente: Vector3) -> void:
	if filtro != "":
		var ok_f := false
		for pedaco in filtro.split(","):
			if nome.to_lower().contains(pedaco):
				ok_f = true
		if not ok_f:
			return
	itens.append({"nome": nome, "f": f, "frente": frente})


func _listar() -> void:
	var animais := {
		"vaca": ["vaca", 1.0, "vaca", ""], "ovelha": ["ovelha", 1.0, "ovelha", ""], "cavalo": ["cavalo", 1.0, "cavalo", ""],
		"porco": ["porco", 1.0, "porco", ""], "cao": ["cao", 1.0, "cao", ""], "galinha": ["galinha", 1.0, "galinha", ""],
		"cervo": ["cavalo", 0.62, "cervo", "chifres"], "coelho": ["cao", 0.5, "coelho", "orelhas_longas"],
	}
	for k in animais:
		var d: Array = animais[k]
		_add(k, func() -> Node3D:
			var a := AnimalVila.new()
			a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [d[0], d[0]])
			a.escala = d[1]
			a.especie = d[2]
			a.acessorio = d[3]
			a.altura_em = func(_x, _z): return 0.0
			return a, Vector3(0, 0, 1))
	for f in DirAccess.get_files_at("res://scenes/inimigos"):
		if f.ends_with(".tscn"):
			var caminho := "res://scenes/inimigos/" + f
			_add(f.get_basename(), func() -> Node3D: return (load(caminho) as PackedScene).instantiate() as Node3D, Vector3(0, 0, -1))
	_add("fagulha", func() -> Node3D: return (load("res://scenes/criaturas/fagulha.tscn") as PackedScene).instantiate() as Node3D, Vector3(0, 0, 1))
	_add("torin", func() -> Node3D: return (load("res://scenes/personagens/torin.tscn") as PackedScene).instantiate() as Node3D, Vector3(0, 0, 1))


## Animações a fotografar: [[nome, papel], ...] e a lista de papéis sem animação.
func _animacoes(no: Node3D, ap: AnimationPlayer) -> Array:
	var lista: Array = []
	var faltam: PackedStringArray = []
	if no is Inimigo:
		var ini := no as Inimigo
		for par in [["parado", ini.anim_parado], ["andar", ini.anim_andar], ["correr", ini.anim_correr], ["atacar", ini.anim_atacar], ["dano", ini.anim_dano], ["morte", ini.anim_morte]]:
			if String(par[1]) != "" and ap.has_animation(par[1]):
				lista.append([par[1], par[0]])
			else:
				faltam.append("%s (%s)" % [par[0], par[1] if String(par[1]) != "" else "vazio"])
	elif no is Humanoide:
		for n in ["Idle", "Jog_Fwd", "Sprint", "Sword_Attack", "Roll", "Jump", "Hit_Chest", "Death01"]:
			if ap.has_animation(n):
				lista.append([n, ""])
			else:
				faltam.append(n)
	else:
		for n in ap.get_animation_list():
			if n != "RESET" and lista.size() < 8:
				lista.append([n, ""])
		for n in ["Idle", "Walk", "Run", "Death"]:
			if not ap.has_animation(n):
				faltam.append(n)
	return [lista, faltam]


func _ossos(esq: Skeleton3D) -> PackedVector3Array:
	var p := PackedVector3Array()
	for i in esq.get_bone_count():
		p.append(esq.to_global(esq.get_bone_global_pose(i).origin))
	return p


func _velocidades(no: Node3D) -> Dictionary:
	if no is Inimigo:
		return {"andar": (no as Inimigo).velocidade, "correr": (no as Inimigo).velocidade}
	if no is AnimalVila:
		return {"andar": (no as AnimalVila).velocidade, "correr": (no as AnimalVila).velocidade * 4.0}
	if no is Fagulha:
		return {}
	return {"andar": 4.0, "correr": 7.0}


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute(SAIDA)
	linhas_md.append("# Medidas de movimento (tools/bancada_movimento.gd)\n")
	linhas_md.append("Amplitude = quanto o osso que mais mexe se desloca no ciclo (m). Passo = vai e vem do pé que mais anda, no eixo da frente (m).")
	linhas_md.append("Velocidade pedida = 2 x passo / duração (o pé fica no chão metade do ciclo). Se a do jogo for muito diferente, o pé desliza.\n")
	linhas_md.append("| Ser | Animação | Duração (s) | Loop | Amplitude (m) | Passo (m) | Vel. pedida (m/s) | Vel. no jogo (m/s) | Observação |")
	linhas_md.append("|---|---|---|---|---|---|---|---|---|")
	for it in itens:
		var no: Node3D = (it["f"] as Callable).call()
		raiz.add_child(no)
		no.set_physics_process(false)
		await create_timer(0.2).timeout
		var ap := no.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap == null:
			ap = no.find_child("Animacoes", true, false) as AnimationPlayer
		var esq := no.find_child("Skeleton3D", true, false) as Skeleton3D
		if ap == null or esq == null:
			linhas_md.append("| %s | (sem AnimationPlayer ou sem esqueleto) | | | | | | | SEM ANIMAÇÃO |" % it["nome"])
			print("MOV ", it["nome"], " sem animação")
			no.queue_free()
			await process_frame
			continue
		var par := _animacoes(no, ap)
		var anims: Array = par[0]
		var faltam: PackedStringArray = par[1]
		var frente: Vector3 = it["frente"]
		var lado := Vector3.UP.cross(frente).normalized()
		var vels := _velocidades(no)
		# enquadramento: caixa dos ossos somando todas as animações
		var caixa := AABB()
		var primeiro := true
		for an in anims:
			ap.play(an[0])
			var dur0 := ap.get_animation(an[0]).length
			for k in 4:
				ap.seek(dur0 * k / 4.0, true)
				for q in _ossos(esq):
					caixa = AABB(q, Vector3.ZERO) if primeiro else caixa.expand(q)
					primeiro = false
		caixa = caixa.grow(maxf(caixa.size.length() * 0.08, 0.05))
		var centro := caixa.get_center()
		var raio := maxf(caixa.size.length() * 0.5, 0.2)
		cam.position = centro + lado * raio * 2.7 + Vector3(0, raio * 0.25, 0)
		cam.look_at(centro, Vector3.UP)
		var imagens: Array = []
		for an in anims:
			var anim := ap.get_animation(an[0])
			var dur := anim.length
			ap.play(an[0])
			# medidas: 16 amostras
			var mins: PackedVector3Array = []
			var maxs: PackedVector3Array = []
			for k in 16:
				ap.seek(dur * k / 16.0, true)
				var ps := _ossos(esq)
				if k == 0:
					mins = ps.duplicate()
					maxs = ps.duplicate()
				else:
					for i in ps.size():
						mins[i] = mins[i].min(ps[i])
						maxs[i] = maxs[i].max(ps[i])
			var amplitude := 0.0
			var passo := 0.0
			var altura := caixa.size.y
			for i in mins.size():
				amplitude = maxf(amplitude, (maxs[i] - mins[i]).length())
				if mins[i].y < caixa.position.y + altura * 0.22:   # osso que chega perto do chão: pé
					passo = maxf(passo, absf((maxs[i] - mins[i]).dot(frente)))
			var papel := String(an[1])
			var eh_andar: bool = papel == "andar" or String(an[0]) in ["Walk", "WalkSlow", "Jog_Fwd"]
			var eh_correr: bool = papel == "correr" or String(an[0]) in ["Run", "Sprint"]
			var ritmo := (no as Inimigo).ritmo_correr if (no is Inimigo and eh_correr) else 1.0   # o jogo toca a corrida acelerada
			var pedida := 2.0 * passo * ritmo / dur if (eh_andar or eh_correr) else 0.0
			var do_jogo := float(vels.get("andar" if eh_andar else "correr", 0.0)) if (eh_andar or eh_correr) else 0.0
			var obs: PackedStringArray = []
			if amplitude < altura * 0.02:
				obs.append("PARADA: quase não mexe")
			if (eh_andar or eh_correr) and do_jogo > 0.0 and pedida > 0.0:
				var razao := do_jogo / pedida
				if razao > 1.4:
					obs.append("pé desliza: jogo %.1fx mais rápido que o passo" % razao)
				elif razao < 0.7:
					obs.append("pé patina: jogo %.1fx mais lento que o passo" % (1.0 / razao))
			linhas_md.append("| %s | %s%s | %.2f | %s | %.2f | %.2f | %s | %s | %s |" % [it["nome"], an[0], (" (" + papel + ")") if papel != "" else "", dur,
				"sim" if anim.loop_mode != Animation.LOOP_NONE else "não", amplitude, passo,
				("%.1f" % pedida) if pedida > 0.0 else "", ("%.1f" % do_jogo) if do_jogo > 0.0 else "", "; ".join(obs)])
			for k in QUADROS:
				var t := dur * k / float(QUADROS)
				ap.seek(t, true)
				rotulo.text = "%s  %s  %d/%d  t=%.2fs" % [it["nome"], an[0], k + 1, QUADROS, t]
				await process_frame
				await process_frame
				RenderingServer.force_draw()
				var im := vp.get_texture().get_image()
				im.convert(Image.FORMAT_RGB8)
				imagens.append(im)
		if not faltam.is_empty():
			linhas_md.append("| %s | FALTAM: %s | | | | | | | sem animação para isso |" % [it["nome"], ", ".join(faltam)])
		if not imagens.is_empty():
			var nl := int(ceil(imagens.size() / float(QUADROS)))
			var folha := Image.create(LARG * QUADROS, ALT * nl, false, Image.FORMAT_RGB8)
			for i in imagens.size():
				folha.blit_rect(imagens[i], Rect2i(0, 0, LARG, ALT), Vector2i((i % QUADROS) * LARG, (i / QUADROS) * ALT))
			folha.save_jpg("%s/%s.jpg" % [SAIDA, it["nome"]], 0.88)
		print("MOV ", it["nome"], " ", anims.size(), " animações")
		no.queue_free()
		await process_frame
	var arq := FileAccess.open(SAIDA + "/MEDIDAS.md", FileAccess.WRITE)
	arq.store_string("\n".join(linhas_md) + "\n")
	arq.close()
	print("BANCADA_MOVIMENTO fim")
	quit(0)
