extends SceneTree
# Perfil de desempenho em janela: anda pelo mundo e imprime fps, tempo de física/processo e chamadas de desenho.
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _amostra(rotulo: String) -> void:
	await create_timer(2.0).timeout
	print("PERF ", rotulo, " fps=", Engine.get_frames_per_second(), " processo=%.1fms fisica=%.1fms" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0],
		" draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objetos=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.clima.congelado = true
	await _amostra("refugio parado")
	var sol := jogo.clima.get_node("Sol") as DirectionalLight3D
	sol.shadow_enabled = false
	await _amostra("sem sombra do sol")
	sol.shadow_enabled = true
	var mm := jogo.mundo.get_node("FlorestaDoMundo") as MultiMeshInstance3D
	mm.visible = false
	await _amostra("sem floresta do mundo")
	mm.visible = true
	jogo.clima.forcar_tempo(Clima.Tempo.TEMPESTADE)
	await _amostra("tempestade (chuva)")
	jogo.clima.forcar_tempo(Clima.Tempo.LIMPO)
	jogo.jogador.global_position = Vector3(300, 12, 12)
	await _amostra("estrada dos campos")
	quit(0)
