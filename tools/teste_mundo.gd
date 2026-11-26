extends SceneTree
# Mundo contínuo, sem janela: regiões, povoados com gente e animais, fauna coerente, e o horário dos NPCs (vão para casa à noite
# e voltam de dia).
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
	marcar("6 regiões, 32 estradas, 119 povoados, nenhuma barreira (mundo aberto)", m.regioes.size() == 6 and m.estradas.size() == 32 and m.povoados.size() == 119 and m.barreiras.size() == 0, "%d regiões, %d estradas, %d povoados" % [m.regioes.size(), m.estradas.size(), m.povoados.size()])
	var sem_gente: Array[String] = []
	for id in m.povoados:
		var pv: Povoado = m.povoados[id]["no"]
		if pv.npcs.is_empty() and m.povoados[id]["tipo"] != "posto_imperial":
			sem_gente.append(String(id))
	marcar("Valdoria tem muralha com 3 portões (sul, oeste e leste)", m.muralha.portoes.size() == 3, str(m.muralha.portoes))
	var espaco := m.get_world_3d().direct_space_state
	var fechados: Array[String] = []
	for g in m.muralha.portoes:   # um raio a 2 m do chão atravessa cada portão de fora para dentro sem bater em nada
		var n: Vector2 = g.normalized()
		var yg: float = m.chao_em(g.x, g.y) + 2.0
		var q := PhysicsRayQueryParameters3D.create(Vector3(g.x + n.x * 12.0, yg, g.y + n.y * 12.0), Vector3(g.x - n.x * 12.0, yg, g.y - n.y * 12.0))
		var bate := espaco.intersect_ray(q)
		if not bate.is_empty() and not (bate["collider"] is CharacterBody3D):
			fechados.append("%s em %s" % [bate["collider"].name, g])
	marcar("Muralha do kit novo: 24 torres ou mais, 6 escadas ou mais e os 3 portões com a passagem livre", m.muralha.torres >= 24 and m.muralha.escadas >= 6 and fechados.is_empty(), "%d torres, %d escadas, fechados: %s" % [m.muralha.torres, m.muralha.escadas, fechados])
	# a Montanha dos Dragões: altura, trilha que se sobe a pé, dragões, domar com carne e salvar/carregar
	var mc := MundoDados.MONTANHA_CENTRO
	var pe_m := MundoDados.ponto_da_trilha(0.0)
	var sobe: float = m.chao_em(mc.x, mc.y) - m.chao_em(pe_m.x, pe_m.y)
	var pior_m := 0.0
	var antes_m: float = m.chao_em(pe_m.x, pe_m.y)
	for i in range(1, 1201):   # andando pelo eixo da trilha, a cada ~2 m
		var q := MundoDados.ponto_da_trilha(i / 1200.0)
		var hq: float = m.chao_em(q.x, q.y)
		pior_m = maxf(pior_m, absf(hq - antes_m))
		antes_m = hq
	marcar("Montanha dos Dragões: 200 m ou mais do pé ao ninho e trilha sem degrau maior que 0,9 m", sobe >= 200.0 and pior_m < 0.9, "sobe %.0f m; maior degrau %.2f m" % [sobe, pior_m])
	var cinza: DragaoSelvagem = m.montanha.domavel
	var voando := 0
	for dr in m.montanha.dragoes:
		if dr.voando:
			voando += 1
	var gesto := cinza.get_node("Domar") as DomarDragao
	gesto.acionar()   # sem carne: nada acontece
	var sem_carne := not cinza.domado
	jogo.jogador.coletar("carne", 3)
	gesto.acionar()
	if not jogo._cena.is_empty():
		jogo._cena.clear()
		jogo.hud.fechar_dialogo()
		jogo.jogador.travado = false
	marcar("Dragões: 8 ou mais na montanha (5 voando), e o do ninho só se doma com 3 carnes e vira montaria que voa", m.montanha.dragoes.size() >= 9 and voando == 5 and sem_carne and cinza.domado and cinza.montaria != null and cinza.montaria.voa and int(jogo.jogador.inventario.get("carne", 0)) == 0, "%d dragões, %d voando, domado %s" % [m.montanha.dragoes.size(), voando, cinza.domado])
	var onde_antes: Vector3 = jogo.jogador.global_position
	jogo.jogador.coletar("couro", 2)
	var gravou := SalvarJogo.gravar(jogo, "user://teste_de_salvar.json")
	jogo.jogador.gastar_item("couro", 2)
	jogo.jogador.global_position = onde_antes + Vector3(40, 0, 0)
	var leu := SalvarJogo.carregar(jogo, "user://teste_de_salvar.json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://teste_de_salvar.json"))
	marcar("Salvar e carregar: volta o lugar e o inventário", gravou and leu and jogo.jogador.global_position.distance_to(onde_antes) < 1.5 and int(jogo.jogador.inventario.get("couro", 0)) == 2, "gravou %s, leu %s, a %.1f m" % [gravou, leu, jogo.jogador.global_position.distance_to(onde_antes)])
	jogo.jogador.gastar_item("couro", 2)   # devolve o inventário como estava, para os testes seguintes
	# som: os 18 efeitos e os 4 laços carregados e tocando; domar rugiu; pegar item tocou; passos saem quando o Torin anda
	var sons: Sons = jogo.sons
	var lacos_tocando := 0
	for nome_l in sons._lacos:
		if (sons._lacos[nome_l] as AudioStreamPlayer).playing and ((sons._lacos[nome_l] as AudioStreamPlayer).stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD:
			lacos_tocando += 1
	var passos_antes := 0
	for nome_p in sons.tocados:
		if String(nome_p).begins_with("passo_"):
			passos_antes += int(sons.tocados[nome_p])
	var onde_som: Vector3 = jogo.jogador.global_position
	jogo.jogador.entrada_forcada = Vector2(0, -1)
	await create_timer(2.0).timeout
	jogo.jogador.entrada_forcada = Vector2.ZERO
	jogo.jogador.global_position = onde_som   # volta para onde estava, para os testes seguintes
	jogo.jogador.velocity = Vector3.ZERO
	var passos_depois := 0
	for nome_p in sons.tocados:
		if String(nome_p).begins_with("passo_"):
			passos_depois += int(sons.tocados[nome_p])
	marcar("Som: 19 efeitos, 4 laços tocando (vento, mar, grilos, música), rugido ao domar, som de pegar item e passos ao andar", sons._amostras.size() == 19 and not sons._amostras.values().has(null) and lacos_tocando == 4 and int(sons.tocados.get("rugido", 0)) == 1 and int(sons.tocados.get("coletar", 0)) >= 1 and passos_depois - passos_antes >= 2, "%d efeitos, %d laços, rugido %d, coletar %d, passos em 2 s: %d" % [sons._amostras.size(), lacos_tocando, int(sons.tocados.get("rugido", 0)), int(sons.tocados.get("coletar", 0)), passos_depois - passos_antes])
	var lg := MundoDados.LAGO_CONGELADO
	jogo.jogador.global_position = Vector3(lg.x, m.chao_em(lg.x, lg.y) + 3.0, lg.y)
	jogo.jogador.velocity = Vector3.ZERO
	await create_timer(1.5).timeout
	var no_gelo: float = jogo.jogador.global_position.y - m.chao_em(lg.x, lg.y)
	marcar("Terras do Gelo: bioma de gelo no norte, lago congelado em que se anda (o Torin fica em cima da placa), 2 dragões e a Vila Geada", Biomas.em(lg.x, lg.y) == "gelo" and no_gelo > 0.1 and no_gelo < 1.2 and m.gelo.dragoes.size() == 2 and m.povoados.has("vila_geada") and m.nome_do_lugar(jogo.jogador.global_position) == "Lago Congelado", "bioma %s, Torin %.2f m acima do fundo, lugar %s" % [Biomas.em(lg.x, lg.y), no_gelo, m.nome_do_lugar(jogo.jogador.global_position)])
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
	# sobrevivência e ofícios: fome, comer, equipar arma e armadura, comprar, vender, pechinchar, forjar e minerar
	var j: Jogador = jogo.jogador
	j.fome = 50.0
	j._passar_fome(60.0)
	var caiu := 50.0 - j.fome
	var paes := int(j.inventario.get("pao", 0))
	j.fome = 50.0
	j.usar_item("pao")
	marcar("Fome: cai com o tempo (uns 4 pontos por minuto parado) e o pão mata 30", caiu > 2.0 and caiu < 9.0 and absf(j.fome - 80.0) < 0.5 and int(j.inventario.get("pao", 0)) == paes - 1 and j.animacao_atual == "Interact", "caiu %.1f em 60 s; depois do pão %.0f; animação %s" % [caiu, j.fome, j.animacao_atual])
	j._comendo = 0.0
	j.travado = false
	j.animacao_atual = ""
	j.coletar("espada_longa", 1)
	j.coletar("armadura_de_couro", 1)
	j.usar_item("espada_longa")
	j.usar_item("armadura_de_couro")
	var pecas_vestidas := 0
	for no_a in j.visual.modelo.find_child("Skeleton3D", true, false).get_children():
		if String(no_a.name).begins_with("Armadura"):
			pecas_vestidas += 1
	j.vida = 100
	j._invulneravel = 0.0
	j.receber_dano(10)
	marcar("Equipar: espada longa dá dano 32; armadura de couro veste 3 peças e tira um quinto do dano", j.dano_golpe == 32 and j.equipado["arma"] == "espada_longa" and pecas_vestidas == 3 and j.vida == 92, "dano %d, %d peças, vida %d depois de um golpe de 10" % [j.dano_golpe, pecas_vestidas, j.vida])
	j.vida = 100
	j.vida_mudou.emit(100, 100)
	var mercado := m.povoados["mercado_central"]["no"] as Povoado
	(mercado.balcoes[1] as Gatilho).ao_usar.call(mercado.balcoes[1])   # a mercadora de sal: pão a 4 moedas
	var loja: PainelDeOficio = jogo.hud.oficio
	var aberta := loja.visible and j.travado
	j.inventario["moeda"] = 20
	j.coletar("couro", 1)
	var comprou := loja.comprar("pao")
	var moedas_1 := int(j.inventario["moeda"])
	var vendeu := loja.vender("couro")
	var moedas_2 := int(j.inventario["moeda"])
	var deu := loja.pechinchar(0.1)
	var barato := loja.preco_de_compra("pao")
	jogo.fechar_oficio()
	marcar("Comércio: 4 balcões no mercado; comprar pão custa 4, vender couro rende 4, pechinchar baixa o pão para 4 -> 4 (80%)", mercado.balcoes.size() == 4 and aberta and comprou and moedas_1 == 16 and vendeu and moedas_2 == 20 and deu and barato == 4 and loja.preco_de_compra("espada_longa") == 36 and not loja.visible and not j.travado, "aberta %s; moedas 20 -> %d -> %d; espada longa com desconto %d" % [aberta, moedas_1, moedas_2, loja.preco_de_compra("espada_longa")])
	(mercado.bigornas[0] as Gatilho).ao_usar.call(mercado.bigornas[0])
	j.coletar("minerio_de_ferro", 2)
	var forjou := loja.forjar(0)
	var sem_material := not loja.forjar(3)
	jogo.fechar_oficio()
	var veio: VeioDeFerro = m.montanha.find_children("*", "VeioDeFerro", true, false)[0]
	var minerio_antes := int(j.inventario.get("minerio_de_ferro", 0))
	veio.acionar()   # sem picareta: nada
	var sem_picareta := int(j.inventario.get("minerio_de_ferro", 0)) == minerio_antes
	j.coletar("picareta", 1)
	veio.acionar()
	var tirou := int(j.inventario.get("minerio_de_ferro", 0)) - minerio_antes
	marcar("Forja e mineração: 2 minérios viram 1 lingote; sem material não forja; o veio só dá ferro com picareta e depois descansa", forjou and int(j.inventario.get("lingote_de_ferro", 0)) == 1 and sem_material and sem_picareta and tirou >= 2 and not veio.disponivel(), "forjou %s, lingotes %d, veio deu %d" % [forjou, int(j.inventario.get("lingote_de_ferro", 0)), tirou])
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
