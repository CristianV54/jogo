extends SceneTree
# Anda pela estrada dos campos a 8 m/s e mede os picos de quadro (hitches), que é o que o jogador sente como "trava".
var jogo: Jogo
var deltas: Array[float] = []
var medindo := false


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _process(delta: float) -> bool:
	if medindo:
		deltas.append(delta * 1000.0)
	return false


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(2.0).timeout
	var flags := OS.get_cmdline_user_args()
	if "semtroncos" in flags:
		var n := 0
		for cs in jogo.mundo.find_children("*", "CollisionShape3D", true, false):
			var sh := (cs as CollisionShape3D).shape as CylinderShape3D
			if sh != null and absf(sh.height - 4.0) < 0.01:
				(cs as CollisionShape3D).disabled = true
				n += 1
		print("PERF troncos desligados: ", n)
	if "semaudio" in flags:
		jogo.clima._chuva_som.stop()
		jogo.clima._trovao_som.stop()
	if "semgente" in flags:
		for no in get_nodes_in_group("npcs") + get_nodes_in_group("inimigos") + get_nodes_in_group("atingiveis"):
			if no is Npc or no is Inimigo or no is AnimalVila:
				no.process_mode = Node.PROCESS_MODE_DISABLED
	if "semcamera" in flags:
		jogo.camera.set_process(false)
	if "semjogador" in flags:
		jogo.jogador.set_process(false)
	if "semfagulha" in flags:
		jogo.fagulha.set_process(false)
	if "semhud" in flags:
		jogo.hud.set_process(false)
	if "semanimais" in flags:
		for a in get_nodes_in_group("atingiveis"):
			if a is AnimalVila:
				a.set_process(false)
	if "semclima" in flags:
		jogo.clima.set_process(false)
	if "semjogo" in flags:
		jogo.set_process(false)
	if "semnpc" in flags:
		for n in get_nodes_in_group("npcs"):
			n.set_process(false)
			n.set_physics_process(false)
	if "sembarreira" in flags:
		for b in jogo.mundo.barreiras.values():
			b.set_process(false)
	var pts: PackedVector2Array = jogo.mundo.estradas["campos"]
	var p := pts[0]
	jogo.jogador.global_position = Vector3(p.x, 2.0, p.y)
	await create_timer(1.0).timeout
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_W
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventKey.new()
	ev2.physical_keycode = KEY_SHIFT
	ev2.pressed = true
	Input.parse_input_event(ev2)
	medindo = true
	var i := 0
	var t := 0.0
	var dt := 0.016
	while t < 25.0 and i < pts.size() - 1:
		var alvo := pts[i + 1]
		var atual := Vector2(jogo.jogador.global_position.x, jogo.jogador.global_position.z)
		var passo := alvo - atual
		if passo.length() < 3.0:
			i += 1
		else:
			jogo.camera.yaw = atan2(-passo.x, -passo.y) + PI
		await process_frame
		if int(t * 2.0) != int((t - dt) * 2.0):
			print("PERF t=%.1f proc=%.1fms fis=%.1fms pares=%d ativos=%d ilhas=%d" % [t, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS), Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS), Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT)])
		dt = clampf(deltas[deltas.size() - 1] / 1000.0, 0.001, 0.1)
		t += dt
	print("PERF andou ate ", jogo.jogador.global_position)
	medindo = false
	deltas.sort()
	var n := deltas.size()
	print("PERF quadros=", n, " p50=%.1fms p95=%.1fms p99=%.1fms max=%.1fms" % [deltas[n / 2], deltas[int(n * 0.95)], deltas[int(n * 0.99)], deltas[n - 1]], " acima de 33ms: ", deltas.filter(func(x): return x > 33.0).size())
	quit(0)
