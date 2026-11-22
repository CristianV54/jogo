extends SceneTree
# Marco 4 ponta a ponta, sem janela: C2-M1 a C2-M4 no Bosque Velado e na Mina das Correntes.
#   godot --headless --path . --script res://tools/teste_marco4.gd
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
	return get_nodes_in_group("interagiveis").filter(func(x): return is_instance_of(x, tipo) and jogo.area.is_ancestor_of(x))


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.0)
	m = jogo.missoes
	for id in ["C1-M1", "C1-M2", "C1-M3", "C1-M4"]:   # Capítulo I já concluído (testado no Marco 3)
		m.concluidas.append(id)
	m.ativas.clear()   # a C1-M1 começou sozinha com o jogo: o Capítulo I está concluído
	m.quadro_liberado = true
	jogo.liberar_fagulha()
	await ir_para_area("bosque_velado", "Entrada")
	var a: Node = jogo.area
	marcar("Chegou ao Bosque Velado", jogo.area_nome == "bosque_velado" and a.nome_area == "Bosque Velado")
	marcar("3 NPCs: Elda, Borin e Sava", a.npcs.size() == 3, str(a.npcs.map(func(n): return n.nome)))
	var jaulas := interagiveis(JaulaDeFilhote)
	var raizes := interagiveis(RaizMedicinal)
	var guardas := a.find_children("*", "Inimigo", false, false).filter(func(x): return x.especie == "guarda_mina")
	marcar("3 jaulas, 8 raízes, 7 guardas, 3 âncoras, 3 vagonetes, 4 corvos", jaulas.size() == 3 and raizes.size() == 8 and guardas.size() == 7 and a.obelisco.ancoras.size() == 3 and interagiveis(CarrinhoDeMinerio).size() == 3 and get_nodes_in_group("corvos").filter(func(c): return a.is_ancestor_of(c)).size() == 4,
		"%d/%d/%d/%d/%d/%d" % [jaulas.size(), raizes.size(), guardas.size(), a.obelisco.ancoras.size(), interagiveis(CarrinhoDeMinerio).size(), get_nodes_in_group("corvos").filter(func(c): return a.is_ancestor_of(c)).size()])
	marcar("Fauna: lobos, javalis, urso, cervos e coelhos", a.find_children("*", "Inimigo", false, false).filter(func(x): return x.especie in ["lobo", "javali", "urso"]).size() == 6 and a._fauna.size() == 10, str(a._fauna.size()))

	print("== C2-M1 ==")
	await falar_com("Elda")
	marcar("Elda passa a C2-M1 (Caçada e Rastreamento)", m.ativas == ["C2-M1"])
	jog.global_position = a.to_global(Vector3(a.TOCA.x, a.altura_em(a.TOCA.x, a.TOCA.y) + 1.0, a.TOCA.y + 12.0))
	await esperar(0.5)
	jog.global_position = a.to_global(Vector3(a.TOCA.x, a.altura_em(a.TOCA.x, a.TOCA.y) + 1.0, a.TOCA.y))
	await esperar(0.7)
	marcar("Seguiu as pegadas de lobo até a toca", m.feito("C2-M1", "pegadas") == 1)
	for i in 4:
		await perto(raizes[i].global_position, 0.8)
		jogo.interagir()
		await esperar(0.1)
		while jogo.hud.dialogo_aberto:
			jogo.interagir()
	marcar("4 raízes colhidas", m.feito("C2-M1", "raizes") == 4, str(jog.inventario))
	jog.coletar("couro", 2)
	jog.coletar("presa", 2)
	await esperar(0.2)
	marcar("Couros e presas (misturados) contam: C2-M1 concluída", m.concluidas.has("C2-M1"), str(m.concluidas))

	print("== C2-M2 ==")
	await falar_com("Sava")
	marcar("Sava passa a C2-M2 (Asas nas Gaiolas)", m.ativas == ["C2-M2"])
	var com_chave := guardas.filter(func(x): return x.drops.has("chave"))
	marcar("3 guardas carregam chave", com_chave.size() == 3)
	await perto(jaulas[0].global_position, 2.0)
	jogo.interagir()
	marcar("Jaula sem chave não abre", m.feito("C2-M2", "jaulas") == 0 and jaulas[0].disponivel())
	for g in com_chave:
		(g as Inimigo).receber_dano(9999, jog)
	await esperar(0.4)
	for pk in a.find_children("*", "Pickup", false, false):
		if is_instance_valid(pk):
			jog.global_position = pk.global_position + Vector3(0, 0.3, 0)
			await esperar(0.25)
	marcar("3 chaves tiradas dos guardas", m.feito("C2-M2", "chaves") == 3 and int(jog.inventario.get("chave", 0)) == 3, str(jog.inventario))
	for j in jaulas:
		await perto(j.global_position, 1.6)
		jogo.interagir()
		await esperar(0.2)
		while jogo.hud.dialogo_aberto:
			jogo.interagir()
	marcar("3 jaulas abertas e as chaves gastas", m.feito("C2-M2", "jaulas") == 3 and int(jog.inventario.get("chave", 0)) == 0)
	marcar("C2-M2 concluída", m.concluidas.has("C2-M2"))
	await esperar(6.6)
	marcar("C2-M3 começa sozinha depois", m.ativas == ["C2-M3"], str(m.ativas))

	print("== C2-M3 ==")
	await falar_com("Borin")
	marcar("Borin explica o obelisco", m.feito("C2-M3", "borin") == 1)
	var ob: Obelisco = a.obelisco
	var fog0: float = a._ambiente_env.fog_density
	for an in ob.ancoras:
		await perto(an.global_position, 2.2)
		for golpe in 3:
			an.receber_dano(22, jog)
	await esperar(0.4)
	marcar("3 âncoras destruídas em etapas", m.feito("C2-M3", "ancoras") == 3 and ob.restantes == 0 and ob.ancoras.all(func(x): return x.morto))
	await esperar(6.5)
	marcar("A névoa recuou", a._ambiente_env.fog_density < fog0 * 0.6, "%.4f -> %.4f" % [fog0, a._ambiente_env.fog_density])
	var minerios := a.find_children("*", "Pickup", false, false).filter(func(x): return x.item == "minerio_bruto")
	marcar("Obelisco largou 3 ferros negros brutos", minerios.size() == 1 and minerios[0].quantidade == 3, str(minerios.size()))
	for pk in minerios:
		jog.global_position = pk.global_position + Vector3(0, 0.3, 0)
		await esperar(0.3)
	marcar("Ferro Negro bruto coletado: C2-M3 concluída", m.concluidas.has("C2-M3"), str(jog.inventario))
	marcar("Gorath surge na praça", a.chefe != null)
	await esperar(6.6)
	marcar("C2-M4 começa sozinha", m.ativas == ["C2-M4"], str(m.ativas))

	print("== C2-M4 ==")
	# vagonete como arma: empurra e atropela o Gorath
	var carro: CarrinhoDeMinerio = interagiveis(CarrinhoDeMinerio)[2]
	var vida0: int = a.chefe.vida
	a.chefe.global_position = carro.global_position + Vector3(0, 0, 6.0)
	await perto(carro.global_position + Vector3(0, 0, -1.2), 0.0)
	jogo.interagir()
	await esperar(2.6)
	marcar("Vagonete empurrado atropelou o Gorath (-90)", a.chefe.vida < vida0, "%d -> %d" % [vida0, a.chefe.vida])
	a.chefe.receber_dano(99999, jog)
	await esperar(0.5)
	marcar("Gorath derrotado: sinal de chefe chega ao jogo", jogo.derrotados.has("gorath"))
	marcar("C2-M4 concluída", m.concluidas.has("C2-M4"))
	await ir_para_area("acampamento_ruptura", "Entrada")
	marcar("A estrada leste (Acampamento da Ruptura) abriu depois do Gorath", jogo.area_nome == "acampamento_ruptura")

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
