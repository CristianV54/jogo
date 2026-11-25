extends SceneTree
## BANCADA DE CONSTRUÇÃO: monta UMA peça de construção sozinha, em chão plano, com o Torin ao lado de régua, e fotografa de
## longe, de perto, de cima, por dentro e rente ao chão. Roda em segundos (não carrega o mundo). É onde cada peça fica
## pronta antes de entrar em Valdoria (regra do usuário: uma peça por vez). Critérios em docs/construcoes/<peca>.md.
##   godot --path . --resolution 1280x720 --script res://tools/bancada_construcao.gd -- muralha
## Saída: tools/capturas/construcao/<peca>/NN_nome.jpg e, no terminal, as medidas e os testes de andar.
var cam: Camera3D
var torin: Node3D
var peca := "muralha"
var falhas := 0


func _init() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		peca = OS.get_cmdline_user_args()[0]
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(0.26, 0.48, 0.84)
	ceu.sky_horizon_color = Color(0.7, 0.82, 0.93)
	ceu.ground_horizon_color = Color(0.6, 0.66, 0.6)
	var sky := Sky.new()
	sky.sky_material = ceu
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR   # luz de preenchimento neutra: a sombra não fica azul nem marrom
	env.ambient_light_color = Color(0.8, 0.8, 0.78)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, -38, 0)   # o sol bate na face de fora, de lado (o mesmo ângulo do sol do jogo)
	sol.light_color = Color(1.0, 0.93, 0.8)
	sol.light_energy = 1.1
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 220.0
	root.add_child(sol)
	var chao := StaticBody3D.new()
	chao.name = "Chao"
	var forma := CollisionShape3D.new()
	var plano := BoxShape3D.new()
	plano.size = Vector3(600, 1, 600)
	forma.shape = plano
	forma.position.y = -0.5
	chao.add_child(forma)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	var mg := StandardMaterial3D.new()
	mg.albedo_color = Color(0.3, 0.42, 0.2)
	mg.roughness = 1.0
	pm.material = mg
	mi.mesh = pm
	chao.add_child(mi)
	root.add_child(chao)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.far = 800.0
	root.add_child(cam)
	cam.current = true
	torin = (load("res://scenes/personagens/torin.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(torin)
	_rodar.call_deferred()


func _foto(nome: String, de: Vector3, para: Vector3, regua: Vector3) -> void:
	torin.global_position = regua
	cam.global_position = de
	cam.look_at(para)
	for i in 4:
		await process_frame
	RenderingServer.force_draw()
	var im := root.get_viewport().get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.save_jpg("tools/capturas/construcao/%s/%s.jpg" % [peca, nome], 0.92)
	print("FOTO ", nome)


func _conferir(nome: String, ok: bool, detalhe: String) -> void:
	print("  ", "PASSOU" if ok else "FALHOU", " ", nome, "  [", detalhe, "]")
	if not ok:
		falhas += 1


## Altura do primeiro sólido debaixo do ponto (raio de cima para baixo).
func _chao_em(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 40, 0), p + Vector3(0, -5, 0))
	var r := root.get_world_3d().direct_space_state.intersect_ray(q)
	return float(r["position"].y) if not r.is_empty() else -99.0


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/capturas/construcao/" + peca)
	match peca:
		"muralha":
			await _muralha()
		_:
			print("peça desconhecida: ", peca)
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)


## Muralha: o portão no meio (a face de fora olha para +Z), 60 m de lanço para um lado com uma torre de vigia e a escada
## de acesso por dentro, e 25 m para o outro.
func _muralha() -> void:
	var kit := PecasDaMuralha.new()
	root.add_child(kit)
	var fora := Vector2(0, 1)
	var tang := Vector2(1, 0)
	var borda := PecasDaMuralha.MEIA_CASA_DO_PORTAO + PecasDaMuralha.RAIO_TORRE_DO_PORTAO * 2.0 - 2.0   # onde a muralha encosta na torre do portão
	kit.portao(Vector3.ZERO, fora)
	var x := -borda - 62.5
	while x < -borda - 0.1:
		kit.lanco(Vector3(x, 0, 0), Vector3(x + 5.0, 0, 0), fora)
		x += 5.0
	x = borda
	while x < borda + 24.9:
		kit.lanco(Vector3(x, 0, 0), Vector3(x + 5.0, 0, 0), fora)
		x += 5.0
	var xt := -borda - 36.0
	kit.torre(Vector3(xt, 0, 0), tang)
	kit.escada(Vector3(xt + 8.0, 0, -PecasDaMuralha.ESPESSURA / 2.0), tang, fora)
	kit.fechar()
	await physics_frame
	await physics_frame
	var h := PecasDaMuralha.ALTURA
	var regua_fora := Vector3(-6.0, 0, 8.0)
	await _foto("01_de_longe", Vector3(-20, 14, 95), Vector3(-20, 8, 0), regua_fora)
	await _foto("02_tres_quartos", Vector3(-70, 22, 60), Vector3(-25, 8, 0), regua_fora)
	await _foto("03_lanco_de_perto", Vector3(-34, 3.0, 17), Vector3(-38, 6.5, 0), Vector3(-36, 0, 5.2))
	await _foto("04_base_rente_ao_chao", Vector3(-30, 0.8, 7.0), Vector3(-36, 1.6, 2.2), Vector3(-34, 0, 4.4))
	await _foto("05_ameias_e_cornija", Vector3(-34, h + 5.0, 9.0), Vector3(-40, h + 1.0, 2.0), Vector3(-39, h, 0.0))
	await _foto("06_torre_de_vigia", Vector3(xt + 14, 9, 30), Vector3(xt, 10, 0), Vector3(xt + 9, 0, 7))
	await _foto("07_portao_por_fora", Vector3(0, 6, 44), Vector3(0, 9, 0), Vector3(-3.0, 0, 9.0))
	await _foto("08_portao_de_perto", Vector3(7, 2.2, 17), Vector3(0, 5.5, 2), Vector3(-2.5, 0, 6.5))
	await _foto("09_debaixo_do_arco", Vector3(1.5, 1.8, 2.5), Vector3(-1.0, 7.0, -2.0), Vector3(-2.2, 0, -1.0))
	await _foto("10_portao_por_dentro", Vector3(-10, 5, -32), Vector3(0, 8, 0), Vector3(2.5, 0, -8.0))
	await _foto("11_escada_por_dentro", Vector3(xt + 34, 7, -22), Vector3(xt + 16, 6, -3), Vector3(xt + 12, h * 0.27, -3.3))
	await _foto("12_caminho_de_ronda", Vector3(xt + 30, h + 3.2, -1.0), Vector3(xt + 6, h + 1.0, 0.0), Vector3(xt + 20, h, 0.0))
	await _foto("13_de_cima", Vector3(-30, 60, 20), Vector3(-30, 0, 0), regua_fora)
	# medidas e testes de andar
	print("MEDIDAS: muralha de ", h, " m até o caminho de ronda (", snappedf(h / 1.8, 0.1), " Torins); vão do portão ", PecasDaMuralha.VAO, " x ", PecasDaMuralha.ALTURA_DO_ARCO, " m")
	_conferir("Caminho de ronda: dá para pisar em cima da muralha", absf(_chao_em(Vector3(-38, 0, 0)) - h) < 0.2, "%.2f m" % _chao_em(Vector3(-38, 0, 0)))
	var pior := 0.0
	var antes := 0.0
	for i in 60:   # subindo a escada pelo meio dela
		var hx := _chao_em(Vector3(xt + 8.0 + 18.0 * i / 59.0, 0, -PecasDaMuralha.ESPESSURA / 2.0 - 1.0))
		pior = maxf(pior, hx - antes)
		antes = hx
	_conferir("Escada: sobe do chão ao caminho de ronda sem degrau que trave", pior < 0.45 and absf(antes - h) < 0.3, "maior degrau %.2f m; chega a %.2f m" % [pior, antes])
	var livre := true
	for px in [-3.5, 0.0, 3.5]:   # debaixo do arco tem de estar livre até 4 m de altura (cavaleiro)
		var q := PhysicsRayQueryParameters3D.create(Vector3(px, 0.3, 12.0), Vector3(px, 0.3, -12.0))
		if not root.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			livre = false
		q = PhysicsRayQueryParameters3D.create(Vector3(px, 3.9, 12.0), Vector3(px, 3.9, -12.0))
		if px == 0.0 and not root.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			livre = false
	_conferir("Portão: passagem livre para carroça e cavaleiro", livre, "raios a 0,3 m e a 3,9 m de altura")
