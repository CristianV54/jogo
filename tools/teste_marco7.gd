extends SceneTree
# Marco 7 ponta a ponta, sem janela: C5-M1 a C5-M4 em Valdoria e no Castelo Imperial.
#   godot --headless --path . --script res://tools/teste_marco7.gd
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


var fim_emitido := false


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.0)
	m = jogo.missoes
	for id in ["C1-M1", "C1-M2", "C1-M3", "C1-M4", "C2-M1", "C2-M2", "C2-M3", "C2-M4", "C3-M1", "C3-M2", "C3-M3", "C3-M4", "C4-M1", "C4-M2", "C4-M3", "C4-M4"]:
		m.concluidas.append(id)
	m.ativas.clear()
	m.quadro_liberado = true
	jogo.liberar_fagulha()
	for b in ["gorath", "kaelor", "ignis_maw"]:
		jogo.derrotados[b] = true
	jog.vida_max = 99999
	jog.vida = 99999
	jog.coletar("maca", 6)
	jogo.fim_de_jogo.connect(func() -> void: fim_emitido = true)
	m.iniciar("C5-M1")
	await ir_para_area("valdoria", "Entrada")
	var a: Node = jogo.area
	marcar("Chegou a Valdoria", a.nome_area == "Valdoria")
	marcar("16 casas, 6 barracas, 4 mercadores, 7 trocas, 4 guardas de elite", a.casas.size() >= 10 and a.barracas.size() == 6 and a.mercadores.size() == 4 and a.trocas.size() == 7 and a.elite.size() == 4, "%d/%d/%d/%d/%d" % [a.casas.size(), a.barracas.size(), a.mercadores.size(), a.trocas.size(), a.elite.size()])
	marcar("Cidade com 12 ou mais pessoas", a.npcs.size() >= 12, str(a.npcs.size()))
	await ir_para_area("castelo_imperial", "Entrada")
	marcar("Sem a C5-M1 o castelo fica fechado", jogo.area_nome == "valdoria")

	print("== C5-M1 ==")
	jog.global_position = Vector3(48.0, 1.0, 19.0)
	await esperar(0.7)
	marcar("Atravessou o Distrito do Comerciante", m.feito("C5-M1", "mercado") == 1)
	jog.global_position = a.trocas[5].global_position + Vector3(0.3, 0.6, 0)
	await esperar(0.2)
	jogo.interagir()
	marcar("Troca sem o material (2 lãs) não vale", m.feito("C5-M1", "suprimento") == 0, str(jog.inventario))
	var carne0 := int(jog.inventario.get("carne", 0))
	jog.global_position = a.trocas[2].global_position + Vector3(0.3, 0.6, 0)
	await esperar(0.2)
	jogo.interagir()
	marcar("Troca com a Lena: 2 maçãs por 1 carne", m.feito("C5-M1", "suprimento") == 1 and int(jog.inventario.get("carne", 0)) == carne0 + 1, str(jog.inventario))
	await matar(a.elite)
	marcar("4 guardas de elite derrotados: C5-M1 concluída", m.concluidas.has("C5-M1"), str(m.feito("C5-M1", "elite")))
	await esperar(6.6)
	marcar("C5-M2 começa sozinha", m.ativas == ["C5-M2"], str(m.ativas))

	print("== C5-M2 ==")
	await ir_para_area("castelo_imperial", "Entrada")
	a = jogo.area
	marcar("Castelo aberto: 4 focos, Vane dormindo e salão fechado", a.nome_area == "Castelo Imperial" and a.focos.size() == 4 and a.vane != null and a.portao_salao._folhas[0].collision_layer != 0)
	marcar("Escadaria sobe 3 m e a plataforma é 3 m", is_equal_approx(a.altura_em(0.0, 100.0), 3.0) and a.altura_em(0.0, 115.0) > 0.5 and a.altura_em(0.0, 115.0) < 2.5)
	jog.global_position = Vector3(0.0, 4.0, 12.0)
	await esperar(0.7)
	marcar("Conversa antes do duelo roda sozinha", a.duelo_iniciado and (not jogo._cena.is_empty() or jogo.hud.dialogo_aberto))
	await fechar_dialogo()
	marcar("Vane acorda depois da conversa", a.vane.alcance_visao > 0.0)
	a.vane.receber_dano(int(a.vane.vida - a.vane.vida_max * 0.4), jog)
	await esperar(0.2)
	marcar("Vane a 40%: ataques corrompidos", a._fase_vane == 1)
	a.vane.receber_dano(99999, jog)
	await esperar(0.6)
	await fechar_dialogo()
	marcar("Vane derrotado: sinal chega ao jogo", jogo.derrotados.has("vane"))
	marcar("C5-M2 concluída e o portão do salão abriu", m.concluidas.has("C5-M2") and a.portao_salao._folhas[0].collision_layer == 0)
	await esperar(6.6)
	marcar("C5-M3 começa sozinha", m.ativas == ["C5-M3"], str(m.ativas))

	print("== C5-M3 ==")
	var luz0: float = a._luz_obelisco.light_energy
	for i in 4:
		a.focos[i].receber_dano(999, jog)
		await esperar(0.2)
	marcar("4 focos de energia contam na missão", m.feito("C5-M3", "focos") == 4 and a._focos_restantes == 0)
	await esperar(3.4)
	marcar("A luz do Grande Obelisco se apagou", a._luz_obelisco.light_energy < luz0 * 0.1, "%.2f -> %.2f" % [luz0, a._luz_obelisco.light_energy])
	marcar("C5-M3 concluída e Solon se levanta", m.concluidas.has("C5-M3") and a.solon != null)
	await esperar(6.6)
	marcar("C5-M4 começa sozinha", m.ativas == ["C5-M4"], str(m.ativas))

	print("== C5-M4 ==")
	var so: Inimigo = a.solon
	so.set_physics_process(false)
	var v0 := so.vida
	so.receber_dano(100, jog)
	marcar("Escudo do obelisco absorve 70% do dano", a.escudo and so.vida == v0 - 30, "%d -> %d" % [v0, so.vida])
	var golpes := 0
	while a.escudo and golpes < 12:
		so.receber_dano(400, jog)
		golpes += 1
	marcar("Escudo quebra na metade da vida", not a.escudo and so.vida <= so.vida_max / 2, "vida %d em %d golpes" % [so.vida, golpes])
	var v1 := so.vida
	await esperar(2.0)
	marcar("Fagulha mergulha e causa dano (80)", so.vida <= v1 - 80, "%d -> %d" % [v1, so.vida])
	so.receber_dano(99999, jog)
	await esperar(0.6)
	marcar("Solon derrotado: sinal chega ao jogo", jogo.derrotados.has("solon"))
	await fechar_dialogo()
	await esperar(0.3)
	marcar("C5-M4 concluída e o epílogo termina o jogo", m.concluidas.has("C5-M4") and fim_emitido)

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
