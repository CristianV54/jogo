extends SceneTree
# Marco 5 ponta a ponta, sem janela: C3-M1 a C3-M4 no Acampamento da Ruptura e na Fortaleza de Ferrogris.
#   godot --headless --path . --script res://tools/teste_marco5.gd
var jogo: Jogo
var jog: Jogador
var m: GerenciadorMissoes
var checks := {}


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_rodar.call_deferred()


func esperar(s: float) -> void:
	await create_timer(s).timeout


func marcar(nome: String, ok: bool, detalhe := "") -> void:
	checks[nome] = ok
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + detalhe + "]") if detalhe != "" else "")


func ir_para_area(nome: String, spawn: String) -> void:
	jogo.ir_para(nome, spawn)
	var t := 0
	while (jogo.area_nome != nome or jogo._trocando) and t < 300:
		await esperar(0.1)
		t += 1
	await esperar(0.8)


func perto(pos: Vector3, dist := 1.0) -> void:
	jog.global_position = pos + Vector3(dist, 0.6, 0)
	jog.velocity = Vector3.ZERO
	await esperar(0.15)


func falar_com(nome: String) -> void:
	for n in jogo.area.npcs:
		if n.nome == nome:
			await perto(n.global_position, 1.3)
			break
	jogo.interagir()
	var g := 0
	while jogo.hud.dialogo_aberto and g < 10:
		jogo.interagir()
		g += 1


func interagiveis(tipo: Variant) -> Array:
	return get_nodes_in_group("interagiveis").filter(func(x): return is_instance_of(x, tipo))


func matar(lista: Array) -> void:
	for x in lista:
		if is_instance_valid(x):
			(x as Inimigo).receber_dano(99999, jog)
	await esperar(0.4)


func pegar_pickups(area: Node, item := "") -> void:
	for pk in area.find_children("*", "Pickup", false, false):
		if is_instance_valid(pk) and (item == "" or pk.item == item):
			jog.global_position = pk.global_position + Vector3(0, 0.3, 0)
			await esperar(0.25)


func fechar_dialogo() -> void:
	var g := 0
	while (jogo.hud.dialogo_aberto or not jogo._cena.is_empty()) and g < 20:
		jogo.interagir()
		g += 1


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.0)
	m = jogo.missoes
	for id in ["C1-M1", "C1-M2", "C1-M3", "C1-M4", "C2-M1", "C2-M2", "C2-M3", "C2-M4"]:
		m.concluidas.append(id)
	m.ativas.clear()
	m.quadro_liberado = true
	jogo.liberar_fagulha()
	jogo.derrotados["gorath"] = true
	await ir_para_area("fronteira_ferrogris", "Entrada")
	marcar("Sem a C3-M1 a Fortaleza fica fechada", jogo.area_nome == "refugio_do_pinhal")
	m.iniciar("C3-M1")
	var vida_max0 := jog.vida_max
	var golpe0 := jog.dano_golpe

	print("== C3-M1 ==")
	await ir_para_area("acampamento_ruptura", "Entrada")
	var a: Node = jogo.area
	marcar("Chegou ao Acampamento da Ruptura", a.nome_area == "Acampamento da Ruptura")
	var minerio := interagiveis(PilhaDeItem)
	marcar("3 pilhas de Ferro Negro no acampamento", minerio.size() == 3)
	var vane: Npc = a._vane
	await perto(vane.global_position, 4.0)
	await esperar(0.5)
	marcar("Cena do Vane rodou sozinha", not jogo._cena.is_empty() or jogo.hud.dialogo_aberto)
	await fechar_dialogo()
	marcar("Confronto visto (objetivo)", m.feito("C3-M1", "confronto") == 1 and not jog.travado)
	for p in minerio:
		await perto(p.global_position, 0.3)
		jogo.interagir()
		await esperar(0.1)
	marcar("3 Ferro Negro bruto no inventário", int(jog.inventario.get("minerio_bruto", 0)) == 3, str(jog.inventario))
	await ir_para_area("refugio_do_pinhal", "DaFronteira")
	await falar_com("Brenn")
	await fechar_dialogo()
	marcar("Entregou à Brenn: C3-M1 concluída", m.concluidas.has("C3-M1"), str(m.concluidas))
	marcar("Equipamento reforçado (+8 golpe, +20 vida)", jog.dano_golpe == golpe0 + 8 and jog.vida_max == vida_max0 + 20, "%d/%d" % [jog.dano_golpe, jog.vida_max])
	await esperar(6.6)
	marcar("C3-M2 começa sozinha", m.ativas == ["C3-M2"], str(m.ativas))

	print("== C3-M2 ==")
	await ir_para_area("fronteira_ferrogris", "Entrada")
	a = jogo.area
	marcar("Fortaleza aberta com a C3-M1 feita", a.nome_area == "Fortaleza de Ferrogris")
	var todos := a.find_children("*", "Inimigo", false, false)
	var arqueiros := todos.filter(func(x): return x.especie == "arqueiro")
	var guardas := todos.filter(func(x): return x.especie == "guarda_ferrogris")
	var caes := todos.filter(func(x): return x.especie == "cao_guerra")
	marcar("4 arqueiros, 8 guardas, 2 cães", arqueiros.size() == 4 and guardas.size() == 8 and caes.size() == 2, "%d/%d/%d" % [arqueiros.size(), guardas.size(), caes.size()])
	var guardas_chave := guardas.filter(func(x): return x.drops.has("chave"))
	var guardas_comuns := guardas.filter(func(x): return not x.drops.has("chave"))
	marcar("3 guardas carregam chave", guardas_chave.size() == 3)
	jog.global_position = Vector3(0, a.altura_em(0, 100) + 0.6, 100)
	var vida_antes := jog.vida
	await esperar(3.5)
	marcar("Arqueiro atirou no jogador", jog.vida < vida_antes, "%d -> %d" % [vida_antes, jog.vida])
	jog.vida_max = 99999
	jog.vida = 99999
	await matar(guardas_comuns)
	await matar(caes)
	await matar(arqueiros)
	var aco := interagiveis(PilhaDeItem).filter(func(x): return x.item == "aco_imperial")
	marcar("4 pilhas de Aço Imperial no depósito", aco.size() == 4)
	for i in 3:
		await perto(aco[i].global_position, 0.3)
		jogo.interagir()
		await esperar(0.1)
	marcar("C3-M2 concluída (guardas, cães e aço)", m.concluidas.has("C3-M2"), str(m.feito("C3-M2", "guardas")) + "/" + str(m.feito("C3-M2", "caes")) + "/" + str(m.feito("C3-M2", "aco")))
	await esperar(6.6)
	marcar("C3-M3 começa sozinha", m.ativas == ["C3-M3"], str(m.ativas))

	print("== C3-M3 ==")
	var celas := interagiveis(CelaTrancada)
	marcar("3 celas: civis, soldados e dragão", celas.size() == 3 and celas.map(func(c): return c.tipo).has("dragao"))
	jog.global_position = celas[0].global_position + Vector3(0, 0.6, 1.0)
	await esperar(0.15)
	jogo.interagir()
	marcar("Cela sem chave não abre", m.feito("C3-M3", "setores") == 0 and celas[0].disponivel())
	await matar(guardas_chave)
	await pegar_pickups(a, "chave")
	marcar("3 chaves tiradas", m.feito("C3-M3", "chaves") == 3 and int(jog.inventario.get("chave", 0)) == 3, str(jog.inventario))
	for c in celas:
		jog.global_position = c.global_position + Vector3(0, 0.6, 1.0)
		await esperar(0.15)
		jogo.interagir()
		await esperar(0.3)
		await fechar_dialogo()
	marcar("3 setores abertos, chaves gastas", m.feito("C3-M3", "setores") == 3 and int(jog.inventario.get("chave", 0)) == 0)
	marcar("C3-M3 concluída", m.concluidas.has("C3-M3"))
	await esperar(1.0)
	marcar("Kaelor surge no pátio", a.chefe != null and a.chefe.especie == "kaelor")
	await esperar(6.6)
	marcar("C3-M4 começa sozinha", m.ativas == ["C3-M4"], str(m.ativas))

	print("== C3-M4 ==")
	var ch: Inimigo = a.chefe
	var cres0 := a.find_children("*", "Inimigo", false, false).size()
	ch.receber_dano(int(ch.vida - ch.vida_max * 0.6), jog)
	await esperar(0.3)
	var cres1 := a.find_children("*", "Inimigo", false, false).size()
	marcar("Fase 2: cães de guerra entram", cres1 == cres0 + 2 and a._fase == 1, "%d -> %d" % [cres0, cres1])
	ch.receber_dano(int(ch.vida - ch.vida_max * 0.3), jog)
	await esperar(0.3)
	marcar("Fase 3: guardas de reforço", a.find_children("*", "Inimigo", false, false).size() == cres1 + 2 and a._fase == 2)
	marcar("Portão dos fundos ainda fechado", a.portao_fundos._folhas[0].collision_layer != 0)
	ch.receber_dano(99999, jog)
	await esperar(0.5)
	marcar("Kaelor derrotado: sinal chega ao jogo", jogo.derrotados.has("kaelor"))
	marcar("C3-M4 concluída", m.concluidas.has("C3-M4"))
	marcar("Portão dos fundos abriu", a.portao_fundos._folhas[0].collision_layer == 0)
	await ir_para_area("cratera_ignis", "Entrada")
	marcar("O caminho para a Cratera de Ignis abriu", jogo.area_nome == "cratera_ignis")

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
