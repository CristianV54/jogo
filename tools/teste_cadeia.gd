extends SceneTree
# Cadeia de missões do jogo inteiro: começa no zero, cumpre os objetivos de cada missão pelos eventos reais e confere que
# a PRÓXIMA começa sozinha, até a C5-M4. Tempo acelerado (os 6 s entre missões passam rápido).
#   godot --headless --path . --script res://tools/teste_cadeia.gd
var jogo: Jogo
var m: GerenciadorMissoes


func _init() -> void:
	Jogo.historia = true   # este teste é da campanha antiga, que no jogo está desligada
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.2).timeout
	await create_timer(1.0).timeout
	m = jogo.missoes
	jogo.clima.congelado = true   # o tempo não muda no meio do teste
	jogo.clima.tempo_automatico = false
	Engine.time_scale = 8.0
	var ordem := DadosMissoes.MISSOES.keys()
	var falhas := 0
	for k in ordem.size():
		var id: String = ordem[k]
		var t := 0.0
		while not m.ativas.has(id) and t < 8.0:   # a cadeia espera 6 s de jogo
			await create_timer(0.1).timeout
			t += 0.1
		var ok_inicio := m.ativas == [id]
		print("  ", "PASSOU " if ok_inicio else "FALHOU ", id, " começou sozinha", "" if ok_inicio else "  [ativas=" + str(m.ativas) + "]")
		if not ok_inicio:
			falhas += 1
			m.iniciar(id)   # segue a cadeia para ver o resto
		for obj in DadosMissoes.MISSOES[id]["objetivos"]:
			var alvo: Variant = obj["alvo"]
			var a: String = alvo[0] if alvo is Array else alvo
			var tipo: String = obj["tipo"]
			if tipo == "entregar":
				m.jogador.coletar(obj["item"], int(obj["qtd"]))
				for q in int(obj["qtd"]):
					m.tentar_entrega(a)
			else:
				GerenciadorMissoes.evento(tipo, a, int(obj["qtd"]))
		await create_timer(0.05).timeout
		var ok_fim := m.concluidas.has(id)
		print("  ", "PASSOU " if ok_fim else "FALHOU ", id, " concluída pelos objetivos")
		if not ok_fim:
			falhas += 1
	Engine.time_scale = 1.0
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
