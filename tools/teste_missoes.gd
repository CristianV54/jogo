extends SceneTree
# Fluxo real da missão C1-M1, sem janela: falar com Vane e Brenn, bater 3x no boneco, acender 3 tochas, receber a recompensa.
#   godot --headless --path . --script res://tools/teste_missoes.gd
var jogo: Jogo
var jog: Jogador
var checks := {}
var avisos: Array[String] = []


func _init() -> void:
	Jogo.historia = true   # este teste é da campanha antiga, que no jogo está desligada
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


func perto(pos: Vector3, dist := 1.5) -> void:
	jog.global_position = pos + Vector3(dist, 0.3, 0)
	jog.velocity = Vector3.ZERO
	await esperar(0.2)


func falar_com(nome: String) -> String:
	var n: Npc = null
	for x in jogo.area.npcs:
		if x.nome == nome:
			n = x
	await perto(n.global_position)
	jogo.interagir()
	var primeira := jogo._falas_atuais[0] if jogo._falas_atuais.size() > 0 else ""
	var guarda := 0
	while jogo.hud.dialogo_aberto and guarda < 10:
		jogo.interagir()
		guarda += 1
	return primeira


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.0)
	var m := jogo.missoes
	m.aviso.connect(func(t: String, _s: float) -> void: avisos.append(t))
	marcar("Missão C1-M1 começa ativa", m.ativas == ["C1-M1"] and jogo.hud._rastreador.text.begins_with("Rotina do Exílio"), jogo.hud._rastreador.text.replace("\n", " | "))
	var f1 := await falar_com("Vane")
	marcar("Vane tem fala da missão e o objetivo conta", f1.begins_with("Torin. Antes") and m.feito("C1-M1", "vane") == 1, f1)
	var f2 := await falar_com("Brenn")
	marcar("Brenn tem fala da missão e o objetivo conta", f2.begins_with("Então o Vane") and m.feito("C1-M1", "brenn") == 1)
	var boneco: BonecoDeTreino = jogo.area.get_node("BonecoDeTreino")
	for i in 3:
		jog.global_position = boneco.global_position + Vector3(1.5, 0.3, 0)
		jog.rotation.y = atan2(1.5, 0.0) * 0.0 + PI / 2.0 * 1.0
		var d := boneco.global_position - jog.global_position
		jog.rotation.y = atan2(-d.x, -d.z)
		await esperar(0.2)
		jog.golpear()
		await esperar(1.15)
	marcar("3 golpes no boneco contam", m.feito("C1-M1", "espada") == 3, "%d/3" % m.feito("C1-M1", "espada"))
	marcar("Missão ainda não concluiu sem as tochas", m.ativas.has("C1-M1"))
	for no in get_nodes_in_group("interagiveis").filter(func(x): return x.id == "tocha_treino"):
		await perto(no.global_position, 1.2)
		jogo.interagir()
		await esperar(0.1)
	marcar("3 tochas acesas contam", m.feito("C1-M1", "tochas") == 3, "%d/3" % m.feito("C1-M1", "tochas"))
	marcar("Missão concluída", m.concluidas.has("C1-M1") and m.ativas.is_empty())
	marcar("Recompensa entregue (2 carnes)", int(jog.inventario.get("carne", 0)) == 2, str(jog.inventario))
	marcar("Aviso de conclusão com o encerramento do Vane", avisos.any(func(t): return t.contains("Missão concluída") and t.contains("Vane")))
	marcar("Rastreador esvaziou", jogo.hud._rastreador.text == "")
	var quadro: QuadroDeAvisos = jogo.area.get_node("QuadroDeAvisos")
	await perto(quadro.global_position, 1.3)
	avisos.clear()
	jogo.interagir()
	marcar("Quadro liberado depois da missão", m.quadro_liberado and avisos.size() == 1 and (avisos[0].contains("Nenhum aviso") or avisos[0].contains("Missão:")), str(avisos))   # desde o Marco 3 o quadro já oferece a próxima missão
	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
