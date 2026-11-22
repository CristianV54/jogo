extends SceneTree
# À noite os NPCs vão dormir na cama (deitados, dentro da casa) e de manhã voltam; o Torin dorme e amanhece.
#   godot --headless --path . --script res://tools/teste_sono.gd
var jogo: Jogo
var falhas := 0


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _marcar(nome: String, ok: bool, det := "") -> void:
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + det + "]") if det != "" else "")
	if not ok:
		falhas += 1


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var clima: Clima = jogo.clima
	clima.congelado = true
	clima.definir_hora(10.0)
	clima.forcar_tempo(Clima.Tempo.LIMPO)
	await create_timer(1.0).timeout
	var civis: Array[Npc] = []
	for n in get_nodes_in_group("npcs"):
		var npc := n as Npc
		if npc and npc.pernoita and npc.rotina.size() > 0 and not npc.segue_jogador and npc.get_parent() == jogo.mundo.regioes["refugio_do_pinhal"]:
			civis.append(npc)
	_marcar("há NPCs com rotina no Refúgio", civis.size() >= 3, str(civis.size()))
	clima.definir_hora(21.0)
	Engine.time_scale = 6.0
	for i in 200:
		await create_timer(0.1).timeout
		if civis.all(func(n: Npc) -> bool: return n._deitado):
			break
	Engine.time_scale = 1.0
	var deitados := civis.filter(func(n: Npc) -> bool: return n._deitado)
	for n in civis:
		if not n._deitado:
			print("    [não deitou] ", n.nome, " papel=", n.papel, " casa=", n.casa, " cama=", n._cama, " recolhido=", n._recolhido, " pos=", n.position)
	_marcar("à noite os NPCs deitam na cama", deitados.size() == civis.size(), "%d de %d" % [deitados.size(), civis.size()])
	var fora := 0
	for n in deitados:
		var casa: Node3D = n._casa_no
		var local := casa.to_local(n.global_position)
		var meia_x := float(casa.get_meta("colunas"))
		var meia_z := float(casa.get_meta("linhas"))
		if absf(local.x) > meia_x or absf(local.z) > meia_z or local.y < 0.2 or local.y > 1.2:
			fora += 1
			print("    [fora da cama] ", n.nome, " local=", local)
	_marcar("deitados dentro da casa, na altura da cama", fora == 0, "%d fora" % fora)
	var camas := {}
	var repetida := false
	for n in deitados:
		if camas.has(n._cama):
			repetida = true
		camas[n._cama] = true
	_marcar("cada um na sua cama", not repetida)
	# o Torin dorme
	var cama: Cama = null
	for c in get_nodes_in_group("interagiveis"):
		if c is Cama:
			cama = c
			break
	jogo.jogador.global_position = cama.global_position + Vector3(0, 0.5, 0)
	clima.definir_hora(22.0)
	jogo.jogador.vida = 40
	cama.acionar()
	await create_timer(3.8).timeout
	_marcar("depois de dormir é de manhã", clima.hora >= 6.0 and clima.hora < 8.0, "hora %.1f" % clima.hora)
	_marcar("vida cheia ao acordar", jogo.jogador.vida == jogo.jogador.vida_max, str(jogo.jogador.vida))
	Engine.time_scale = 6.0
	for i in 120:
		await create_timer(0.1).timeout
		if civis.all(func(n: Npc) -> bool: return not n._deitado):
			break
	Engine.time_scale = 1.0
	var ainda := civis.filter(func(n: Npc) -> bool: return n._deitado).size()
	_marcar("de manhã todos acordam", ainda == 0, "%d ainda deitados" % ainda)
	# povoados e cidades: ao chegar de noite a gente já está deitada
	clima.definir_hora(23.0)
	jogo.mundo.set_process(false)
	for alvo in [["campos_altos", "vila"], ["campina", "fazenda"], ["posto_imperial", "estalagem"], ["beira_rio", "vila"]]:
		var c: Vector2 = jogo.mundo.povoados[alvo[0]]["centro"]
		jogo.jogador.global_position = Vector3(c.x, jogo.mundo.terreno.altura_em(c.x, c.y) + 1.0, c.y + 30.0)
		jogo.mundo.atualizar_atividade()
		await create_timer(1.5).timeout
		var perto := 0
		var acordados := 0
		for n in get_nodes_in_group("npcs"):
			var npc := n as Npc
			if npc and npc.pernoita and npc.rotina.size() > 0 and Vector2(npc.global_position.x, npc.global_position.z).distance_to(c) < 90.0:
				perto += 1
				if not npc._deitado:
					acordados += 1
					print("    [de pé à noite] ", npc.nome, " ", npc.global_position)
		_marcar("%s: de noite todos deitados ao chegar" % alvo[0], perto > 0 and acordados == 0, "%d de %d de pé" % [acordados, perto])
	jogo.jogador.global_position = Vector3(584, 10, -1880 + 40)
	jogo.mundo.atualizar_atividade()
	await create_timer(1.5).timeout
	var cid := 0
	var cid_de_pe := 0
	for n in get_nodes_in_group("npcs"):
		var npc := n as Npc
		if npc and npc.pernoita and not npc.segue_jogador and Vector2(npc.global_position.x, npc.global_position.z).distance_to(Vector2(584, -1880)) < 150.0:
			cid += 1
			if not npc._deitado:
				cid_de_pe += 1
				print("    [de pé à noite, Valdoria] ", npc.nome, " ", npc.papel)
	_marcar("Valdoria: de noite quem pernoita está deitado", cid > 0 and cid_de_pe == 0, "%d de %d de pé" % [cid_de_pe, cid])
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
