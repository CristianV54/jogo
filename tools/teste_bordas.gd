extends SceneTree
## A beirada de cada região não pode ser um degrau: o Torin entra andando em cada uma das 8 regiões pelos 4 lados (meio do lado e a
## 1/4 e 3/4 dele), saindo de 18 m fora, por 9 s. Falha se ele parar na linha da borda (foi a trava de x=-160 na entrada do Refúgio).
## Parar antes ou depois da borda não conta: aí é árvore, rio, serra ou muro.   godot --headless --path . --script res://tools/teste_bordas.gd
var jogo: Jogo
var jog: Jogador
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_r.call_deferred()
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(2.0).timeout
	Engine.time_scale = 3.0   # só encurta a espera: a física continua em passos de 1/60 s
	# entrar em cada região pelos 4 lados, andando 9 s (36 m) de 18 m fora para dentro, no meio do lado e a 1/4 e 3/4 dele
	var total := 0
	var presos := 0
	for id in MundoDados.REGIOES:
		var c := MundoDados.centro(id)
		var m: float = MundoDados.REGIOES[id]["meia"]
		for lado in [[Vector2(-1, 0), "oeste"], [Vector2(1, 0), "leste"], [Vector2(0, -1), "norte"], [Vector2(0, 1), "sul"]]:
			var n: Vector2 = lado[0]
			var t := Vector2(-n.y, n.x)
			for f in [-0.5, 0.0, 0.5]:
				var ini: Vector2 = c + n * (m + 18.0) + t * m * f
				if not MundoDados.LIMITES.grow(-30.0).has_point(ini) or Costa.distancia(ini.x, ini.y) < 30.0:
					continue
				jog.global_position = Vector3(ini.x, jogo.mundo.chao_em(ini.x, ini.y) + 0.6, ini.y)
				jog.velocity = Vector3.ZERO
				jogo.mundo.atualizar_atividade()
				await create_timer(1.2).timeout
				jogo.camera.yaw = atan2(n.x, n.y)   # andar para -n (para dentro)
				jog.rotation.y = jogo.camera.yaw
				jog.entrada_forcada = Vector2(0, -1)
				await create_timer(9.0).timeout
				jog.entrada_forcada = Vector2.ZERO
				var p := Vector2(jog.global_position.x, jog.global_position.z)
				var avancou: float = (ini - p).dot(n)
				var na_borda: bool = absf(avancou - 18.0) < 1.2
				total += 1
				if na_borda:
					presos += 1
				print("  ", id, " ", lado[1], " f=", f, " avancou=", snapped(avancou, 0.1), " m", "  PRESO NA BORDA" if na_borda else "")
	print("ENTRADAS ", total, " | PRESAS NA BORDA ", presos)
	print("RESULTADO ", "TUDO PASSOU" if presos == 0 and total > 0 else "HA %d FALHAS" % presos)
	quit(0)
