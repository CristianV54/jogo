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
	marcar("6 regiões, 30 estradas, 118 povoados, nenhuma barreira (mundo aberto)", m.regioes.size() == 6 and m.estradas.size() == 30 and m.povoados.size() == 118 and m.barreiras.size() == 0, "%d regiões, %d estradas, %d povoados" % [m.regioes.size(), m.estradas.size(), m.povoados.size()])
	var sem_gente: Array[String] = []
	for id in m.povoados:
		var pv: Povoado = m.povoados[id]["no"]
		if pv.npcs.is_empty() and m.povoados[id]["tipo"] != "posto_imperial":
			sem_gente.append(String(id))
	marcar("Valdoria tem muralha com 3 portões (sul, oeste e leste)", m.muralha.portoes.size() == 3, str(m.muralha.portoes))
	marcar("História desligada: nenhuma missão ativa e a Fagulha já acompanha o Torin", not Jogo.historia and jogo.missoes.ativas.is_empty() and jogo.fagulha_livre, str(jogo.missoes.ativas))
	marcar("Penhasco no centro: 64 m no topo e chão plano na praça", absf(m.chao_em(0.0, 0.0) - MundoDados.PENHASCO_ALTURA) < 0.5 and absf(m.chao_em(0.0, 150.0)) < 0.5, "%.1f m no topo, %.1f m na praça" % [m.chao_em(0.0, 0.0), m.chao_em(0.0, 150.0)])
	# a rampa: do pé (leste) até o portão da cidadela (oeste), andando pelo meio dela, sem degrau maior que 0,7 m a cada 2 m
	var eixos := MundoDados.PENHASCO_EIXOS
	var meio_da_rampa := (MundoDados.RAMPA_R0 + MundoDados.RAMPA_R1) / 2.0
	var pior_degrau := 0.0
	var altura_antes := -1.0
	var t := MundoDados.RAMPA_TS - 0.03   # começa já em cima da rampa, no pé dela
	while t > MundoDados.RAMPA_TE - 0.1:
		var hr := m.chao_em(-cos(t) * eixos.x * meio_da_rampa, sin(t) * eixos.y * meio_da_rampa)
		if altura_antes >= 0.0:
			pior_degrau = maxf(pior_degrau, absf(hr - altura_antes))
		altura_antes = hr
		t -= 2.0 / (eixos.x * meio_da_rampa)
	marcar("Dá para subir a rampa do penhasco a pé até o portão da cidadela", pior_degrau < 0.7 and altura_antes > MundoDados.PENHASCO_ALTURA - 1.0, "maior degrau %.2f m; chega a %.1f m" % [pior_degrau, altura_antes])
	marcar("Cidadela no alto: 20 torres ou mais, a mais alta 130 m ou mais acima da cidade, 7 prédios ou mais", m.cidadela.torres >= 20 and m.cidadela.topo_mais_alto >= 130.0 and m.cidadela.predios >= 7, "%d torres, topo a %.0f m, %d prédios" % [m.cidadela.torres, m.cidadela.topo_mais_alto, m.cidadela.predios])
	var rei := false
	for n in get_nodes_in_group("npcs"):
		if (n as Npc).nome == "Rei Aldren":
			rei = true
	marcar("O rei está no Salão do Trono (NPC Rei Aldren)", rei, "")
	var bravos: Array = []
	for e in get_nodes_in_group("inimigos"):
		var e3 := e as Node3D
		if MundoDados.ate_a_muralha(e3.global_position.x, e3.global_position.z) < 0.0:
			bravos.append(String(e3.name))
	marcar("Dentro da muralha não há inimigo (nem guarda hostil, nem lobo)", bravos.is_empty(), str(bravos.slice(0, 8)))
	var casario := m.get_node("CasarioDoReino") as CasarioDoReino
	marcar("Casario apertado dentro da muralha (500 casas ou mais, como no reino de blocos, em 80 quarteirões ou mais)", casario.lotes.size() >= 500 and casario.quarteiroes >= 80, "%d casas, %d quarteirões" % [casario.lotes.size(), casario.quarteiroes])
	marcar("Casas com vida: 300 janelas acesas ou mais e 20 forjas ou mais", casario.janelas_acesas >= 300 and casario.forjas >= 20, "%d janelas acesas, %d forjas" % [casario.janelas_acesas, casario.forjas])
	var vida := m.get_node("VidaDasRuas") as VidaDasRuas
	marcar("Ruas com vida: 25 pessoas circulando ou mais, lampiões, jardins e rocha no penhasco", vida.npcs.size() >= 25 and vida.lampioes >= 12 and vida.arvores >= 100 and vida.rochas >= 200, "%d pessoas, %d lampiões, %d árvores, %d rochas" % [vida.npcs.size(), vida.lampioes, vida.arvores, vida.rochas])
	var quartel := m.povoados["quartel_da_guarda"]["no"] as Povoado
	marcar("Quartel: 6 bonecos de treino e 4 soldados que são gente (não inimigos)", quartel.bonecos.size() == 6 and quartel.npcs.size() == 4, "%d bonecos, %d soldados" % [quartel.bonecos.size(), quartel.npcs.size()])
	var estabulo := m.povoados["estabulos_do_reino"]["no"] as Povoado
	var montaveis := 0
	for a in estabulo.animais:
		if a.montaria != null:
			montaveis += 1
	marcar("Estábulos do Reino: 4 cavalos que dá para montar", montaveis == 4, str(montaveis))
	var mercado := m.povoados["mercado_central"]["no"] as Povoado
	jogo.jogador.coletar("couro", 1)
	var carne_antes := int(jogo.jogador.inventario.get("carne", 0))
	(mercado.trocas[1] as Gatilho).ao_usar.call(mercado.trocas[1])
	marcar("Mercado: trocar 1 couro rende 3 carnes", int(jogo.jogador.inventario.get("carne", 0)) == carne_antes + 3 and int(jogo.jogador.inventario.get("couro", 0)) == 0, str(jogo.jogador.inventario))
	var sentinelas := 0
	for g in ["guarita_sul", "guarita_oeste", "guarita_leste"]:
		sentinelas += (m.povoados[g]["no"] as Povoado).npcs.size()
	marcar("Sentinelas nos 3 portões (2 em cada)", sentinelas == 6, str(sentinelas))
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
