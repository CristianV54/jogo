extends SceneTree
## Simulação de física e combate, medindo onde os corpos ficam de verdade (não é foto):
##  1) o cavalo montado, empurrado contra uma parede/pedra por 5 s, não entra nela;
##  2) um lobo que persegue o Torin até a porta de uma casa não entra na casa;
##  3) um lobo atrás do Torin não o fere; à frente, fere; com parede no meio, não fere.
##   godot --headless --path . --script res://tools/teste_simulacao.gd
var jogo: Jogo
var falhas := 0
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _m(nome: String, ok: bool, det := "") -> void:
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + det + "]") if det != "" else "")
	if not ok:
		falhas += 1
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	var m: Mundo = jogo.mundo
	var jog: Jogador = jogo.jogador
	# ---- 1) cavalo contra a parede de uma casa
	var casa: Node3D = get_nodes_in_group("casas").filter(func(c): return c.name == "Cabana2" or c.name == "CasaDoVane")[0]
	var cavalo: AnimalVila = null
	for a in get_nodes_in_group("animais"):
		if a is AnimalVila and (a as AnimalVila).montavel:
			cavalo = a
			break
	_m("há um cavalo montável", cavalo != null)
	if cavalo:
		var frente_casa := casa.to_global(Vector3(0.0, 0.0, float(casa.get_meta("linhas")) + 7.0))   # no pátio, em frente à fachada
		jog.global_position = frente_casa + Vector3(0, 1.0, 0)
		cavalo.global_position = frente_casa + Vector3(1.2, 0, 0)
		jog.montar(cavalo.montaria)
		await create_timer(1.6).timeout
		var alvo_parede := casa.to_global(Vector3(-float(casa.get_meta("colunas")) * 0.9, 0.0, 0.0))   # a parede lateral
		var dir := (alvo_parede - jog.global_position)
		dir.y = 0.0
		dir = dir.normalized()
		jog.entrada_forcada = Vector2(0, -1)
		jog.correndo_forcado = true
		jog.camera.yaw = atan2(-dir.x, -dir.z) + PI   # a câmera dita a direção do movimento
		jog.camera.yaw = atan2(dir.x, dir.z) + PI
		var min_dist := 1e9
		var dentro := false
		var inicio := jog.global_position
		for i in 60:
			await create_timer(0.1).timeout
			var local := casa.to_local(jog.global_position)
			min_dist = minf(min_dist, maxf(absf(local.x) - float(casa.get_meta("colunas")), absf(local.z) - float(casa.get_meta("linhas"))))
			var meia_x := float(casa.get_meta("colunas"))
			var meia_z := float(casa.get_meta("linhas"))
			if absf(local.x) < meia_x - 0.3 and absf(local.z) < meia_z - 0.3:
				dentro = true
		jog.entrada_forcada = Vector2.ZERO
		jog.correndo_forcado = false
		var andou := inicio.distance_to(jog.global_position)
		_m("o cavalo andou de verdade rumo à casa (mais de 3 m)", andou > 3.0, "%.1f m" % andou)
		_m("cavalo montado empurrado contra a casa não entra nela", not dentro and min_dist >= 1.0, "dentro=%s, menor distância do centro do cavalo à parede %.2f m (o corpo tem ~1,2 m de meio comprimento; sem a caixa dava 0,4 m)" % [str(dentro), min_dist])
		jog.desmontar()
		await create_timer(1.0).timeout
	# ---- 2) e 3) lobo
	var lobo := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	m.add_child(lobo)
	var porta := casa.to_global(Vector3(float(casa.get_meta("x_porta")), 0.0, float(casa.get_meta("linhas")) + 0.2))
	jog.global_position = casa.to_global(Vector3(float(casa.get_meta("x_porta")), 0.3, 0.0))   # o Torin dentro da casa, atrás da porta
	lobo.global_position = porta + (porta - casa.global_position).normalized() * 4.0
	lobo.estado = Inimigo.Estado.PERSEGUINDO
	lobo.alcance_visao = 60.0
	var entrou := false
	for i in 60:
		await create_timer(0.1).timeout
		var lc := casa.to_local(lobo.global_position)
		if absf(lc.x) < float(casa.get_meta("colunas")) - 0.4 and absf(lc.z) < float(casa.get_meta("linhas")) - 0.4:
			entrou = true
	_m("lobo que persegue até a porta não entra na casa", not entrou, "posição local %s" % str(casa.to_local(lobo.global_position)))
	# ataque de costas / à frente / com parede
	lobo.queue_free()
	await create_timer(0.2).timeout
	var campo := Vector3(-60, 0, 60)
	jog.global_position = Vector3(campo.x, m.chao_em(campo.x, campo.z) + 0.5, campo.z)
	var l2 := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	m.add_child(l2)
	l2.global_position = jog.global_position + Vector3(0, 0, 1.0)
	l2.set_physics_process(false)
	l2.alvo = jog
	jog.vida = 100
	l2.rotation.y = 0.0   # frente do lobo = -Z; o Torin está em -Z... posições abaixo
	l2.global_position = jog.global_position + Vector3(0, 0, 1.0)   # lobo a +Z do Torin, olhando para -Z (para o Torin)
	_m("lobo de frente para o alvo acerta", l2._acerta_o_alvo())
	l2.rotation.y = PI   # agora olha para +Z, de costas para o Torin
	_m("lobo de costas para o alvo não acerta", not l2._acerta_o_alvo())
	l2.rotation.y = 0.0
	var parede := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(4, 3, 0.3)
	cs.shape = bx
	parede.add_child(cs)
	m.add_child(parede)
	parede.global_position = jog.global_position + Vector3(0, 1.0, 0.5)
	await physics_frame
	await physics_frame
	_m("parede entre o lobo e o alvo bloqueia o golpe", not l2._acerta_o_alvo())
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
