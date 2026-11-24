extends SceneTree
# Mundo contínuo, sem janela: regiões, povoados com gente e animais, fauna coerente, e o horário dos NPCs (vão para casa à noite
# e voltam de dia). A caminhada pelas estradas está em tools/auditoria_continua.gd.
#   godot --headless --path . --script res://tools/teste_mundo.gd
var jogo: Jogo
var checks := {}


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func marcar(nome: String, ok: bool, detalhe := "") -> void:
	checks[nome] = ok
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + detalhe + "]") if detalhe != "" else "")


func _rodar() -> void:
	var t0 := Time.get_ticks_msec()
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	print("  mundo construído em %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	marcar("8 regiões, 11 estradas, 46 povoados, nenhuma barreira (mundo aberto)", m.regioes.size() == 8 and m.estradas.size() == 11 and m.povoados.size() == 46 and m.barreiras.size() == 0, "%d povoados" % m.povoados.size())
	var sem_gente: Array[String] = []
	for id in m.povoados:
		var pv: Povoado = m.povoados[id]["no"]
		if pv.npcs.is_empty() and m.povoados[id]["tipo"] != "posto_imperial":
			sem_gente.append(String(id))
	marcar("Todo povoado tem gente trabalhando", sem_gente.is_empty(), str(sem_gente))
	var fazendeiros := get_nodes_in_group("npcs").filter(func(n): return n.papel == "Lavrador").size()
	marcar("Fazendeiros nos campos (4 ou mais)", fazendeiros >= 4, str(fazendeiros))
	var c: Dictionary = m.fauna.contagem
	marcar("Fauna: cervos, coelhos, lobos, javalis, vacas, ovelhas, cavalos, corvos", c.get("cervo", 0) > 0 and c.get("coelho", 0) > 0 and c.get("lobo", 0) > 0 and c.get("javali", 0) > 0 and c.get("vaca", 0) > 0 and c.get("ovelha", 0) > 0 and c.get("cavalo", 0) > 0 and c.get("corvo", 0) > 0, str(c))
	# coerência: nenhum lobo ou javali dentro de fazenda, nenhuma vaca na mata funda do bosque
	var lobos_em_fazenda := 0
	for no in get_nodes_in_group("inimigos"):
		if no.especie in ["lobo", "javali"]:
			var p := Vector2(no.global_position.x, no.global_position.z)
			for pid in m.povoados:
				if m.povoados[pid]["tipo"] in ["fazenda", "vila"] and p.distance_to(m.povoados[pid]["centro"]) < float(m.povoados[pid]["raio"]):
					lobos_em_fazenda += 1
	marcar("Lobos e javalis não nascem dentro de fazenda ou vila", lobos_em_fazenda == 0, str(lobos_em_fazenda))
	var na_agua := 0
	for no in get_nodes_in_group("atingiveis"):
		var p3: Vector3 = no.global_position
		if m.regiao_em(p3) == "" and m.terreno.na_agua(p3.x, p3.z, 0.0):
			na_agua += 1
	marcar("Ninguém nasceu dentro d'água nos corredores", na_agua == 0, str(na_agua))
	# horário: noite -> vão para casa; dia -> voltam ao trabalho
	var clima: Clima = jogo.clima
	clima.congelado = true
	clima.forcar_tempo(Clima.Tempo.LIMPO)
	var campos: Povoado = m.povoados["campos_altos"]["no"]
	jogo.jogador.global_position = Vector3(campos.centro.x, m.terreno.altura_em(campos.centro.x, campos.centro.y + 40.0) + 1.5, campos.centro.y + 40.0)   # perto, para o povoado ficar ativo
	clima.definir_hora(10.0)
	await create_timer(1.0).timeout
	Engine.time_scale = 6.0
	var antes: Dictionary = {}
	for n in campos.npcs:
		antes[n] = n.position
	clima.definir_hora(21.0)
	await create_timer(16.0).timeout   # ~96 s de jogo
	var em_casa := 0
	var trabalhadores := 0
	for n in campos.npcs:
		if n.pernoita and n.rotina.size() > 0 and not n.segue_jogador:
			trabalhadores += 1
			if n._recolhido:
				em_casa += 1
	marcar("À noite os trabalhadores se recolhem", trabalhadores > 0 and em_casa == trabalhadores, "%d de %d" % [em_casa, trabalhadores])
	var perto_de_casa := 0
	for n in campos.npcs:
		if n._deitado or (n._recolhido and n.casa != Vector3.INF and Vector2(n.position.x - n.casa.x, n.position.z - n.casa.z).length() < 4.0):   # chegou: já deitado na cama ou na porta
			perto_de_casa += 1
	for n in campos.npcs:
		if n._recolhido:
			print("    [debug] ", n.nome, " pos=", n.position, " casa=", n.casa, " dist=", snappedf(Vector2(n.position.x - n.casa.x, n.position.z - n.casa.z).length(), 0.1))
	marcar("Chegam à porta da casa", perto_de_casa >= em_casa - 1 and perto_de_casa > 0, "%d de %d" % [perto_de_casa, em_casa])
	clima.definir_hora(9.0)
	await create_timer(3.5).timeout   # cada NPC confere o relógio a cada 1,5 a 2,5 s
	var voltaram := campos.npcs.filter(func(n): return not n._recolhido).size()
	marcar("De manhã voltam ao trabalho", voltaram == campos.npcs.size(), "%d de %d" % [voltaram, campos.npcs.size()])
	clima.forcar_tempo(Clima.Tempo.TEMPESTADE)
	await create_timer(3.0).timeout
	var abrigados := campos.npcs.filter(func(n): return n._recolhido).size()
	marcar("Na tempestade o povo se abriga", abrigados > 0, "%d" % abrigados)
	Engine.time_scale = 1.0
	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
