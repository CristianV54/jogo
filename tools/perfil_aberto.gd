extends SceneTree
# Desempenho do mundo aberto em janela: fps, tempo de física e desenho em pontos típicos (com a floresta em blocos).
#   godot --path . --resolution 1280x720 --script res://tools/perfil_aberto.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _amostra(rotulo: String) -> void:
	await create_timer(3.0).timeout
	var soma := 0.0
	var minimo := 999.0
	for i in 20:
		await create_timer(0.1).timeout
		var f := Engine.get_frames_per_second()
		soma += f
		minimo = minf(minimo, f)
	print("PERF ", rotulo, " fps_medio=%.0f fps_min=%.0f fisica=%.1fms draws=%d prims=%.1fM" % [soma / 20.0, minimo, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1.0e6])


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	jogo.clima.congelado = true
	jogo.clima.definir_hora(11.0)
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	await _amostra("Refúgio, parado")
	for v in [["estrada do pomar", Vector3(-300, 0, -10)], ["mata a oeste (floresta densa)", Vector3(-560, 0, -300)], ["Aldeia Beira-Rio", Vector3(-200, 0, 270)], ["Fazenda Rio Claro", Vector3(210, 0, 240)], ["Valdoria", Vector3(584, 0, -1880)]]:
		var p: Vector3 = v[1]
		jogo.jogador.global_position = Vector3(p.x, m.terreno.altura_em(p.x, p.z) + 1.5, p.z)
		jogo.jogador.velocity = Vector3.ZERO
		await _amostra(v[0])
	jogo.clima.forcar_tempo(Clima.Tempo.TEMPESTADE)
	await _amostra("Valdoria, tempestade")
	quit(0)
