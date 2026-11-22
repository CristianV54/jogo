extends SceneTree
# Jogada completa automatizada (precisa de janela, para capturar tela):
#   godot --path . --resolution 1280x720 --script res://tools/teste_jogo.gd
# Roteiro: Refúgio (chão, diálogo com o Vane) -> caminho bloqueado -> portal norte -> Bosque Velado (lobo e Gorath)
#          -> volta ao Refúgio -> portal leste -> Ferrogris (Kaelor) -> Cratera (Ignis-Maw) -> Valdoria (Solon) -> fim.
# O bot teleporta para perto do alvo e golpeia. TRUQUE DO TESTE: se a vida do jogador cai abaixo de 35, ela é refeita
# (conta em `curas`). Isso valida o fluxo e o dano, mas não prova que a luta é vencível sem recuperar vida.

const PASTA := "tools/capturas/"

var jogo: Jogo
var jog: Jogador
var checks := {}
var curas := 0
var inicio_ms := 0
var fim_de_jogo_visto := false


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	jogo.fim_de_jogo.connect(func() -> void: fim_de_jogo_visto = true)
	inicio_ms = Time.get_ticks_msec()
	_rodar.call_deferred()


func _t() -> String:
	return "%5.1fs" % ((Time.get_ticks_msec() - inicio_ms) / 1000.0)


func esperar(s: float) -> void:
	await create_timer(s).timeout


func foto(nome: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(PASTA + "jogo_" + nome + ".png")
	print(_t(), " FOTO ", nome)


func marcar(nome: String, ok: bool, detalhe := "") -> void:
	checks[nome] = ok
	print(_t(), "  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + detalhe + "]") if detalhe != "" else "")


func esperar_area(nome: String) -> void:
	var limite := 0
	while (jogo.area_nome != nome or jogo._trocando) and limite < 600:
		await create_timer(0.2).timeout
		limite += 1
	await esperar(1.2)   # deixa o jogador pousar e a física assentar


func chao_ok() -> bool:
	return absf(jog.global_position.y - jogo.area.altura_em(jog.global_position.x, jog.global_position.z)) < 0.4


func lutar(alvo: Inimigo, limite: float, nome_foto := "") -> bool:
	var t := 0.0
	var fotografou := false
	var golpes := 0
	while alvo != null and is_instance_valid(alvo) and alvo.estado != Inimigo.Estado.MORTO and t < limite and not jog.morto:
		var d := alvo.global_position - jog.global_position
		d.y = 0.0
		var raio := jog.alcance_golpe + alvo.raio_colisao
		if d.length() > raio * 0.9:
			jog.global_position += d.normalized() * (d.length() - raio * 0.6)
		jog.rotation.y = atan2(-d.x, -d.z)
		jog.camera.yaw = jog.rotation.y
		jog.golpear()
		golpes += 1
		await create_timer(1.1).timeout
		t += 1.1
		if jog.vida < 35:
			jog.vida = jog.vida_max
			jog.vida_mudou.emit(jog.vida, jog.vida_max)
			curas += 1
		if nome_foto != "" and not fotografou and t >= 2.2:
			fotografou = true
			await foto(nome_foto)
	var morreu := alvo == null or not is_instance_valid(alvo) or alvo.estado == Inimigo.Estado.MORTO
	print(_t(), "  luta: ", alvo.nome if is_instance_valid(alvo) else "?", " golpes=", golpes, " vida_do_alvo=", alvo.vida if is_instance_valid(alvo) else 0,
		" vida_do_torin=", jog.vida, " morto=", morreu)
	return morreu


func lutar_contra_chefe(id: String, nome_chefe: String, limite: float, foto_nome: String) -> void:
	var chefe: Inimigo = jogo.area.get("chefe")
	marcar("%s existe na área" % nome_chefe, chefe != null and chefe.chefe)
	if chefe == null:
		return
	jog.global_position = chefe.global_position + Vector3(0, 0.3, 6.0)
	jog.camera.yaw = 0.0
	await esperar(1.0)
	var barra_visivel: bool = jogo.hud._chefe_caixa.visible
	marcar("barra de vida de %s apareceu ao chegar perto" % nome_chefe, barra_visivel)
	var venceu := await lutar(chefe, limite, foto_nome)
	marcar("%s foi derrotado" % nome_chefe, venceu)
	await esperar(0.8)
	marcar("progresso registrou %s" % id, jogo.derrotados.has(id))
	if id != "solon" and jogo.area.get("destino_proximo") != "":   # o Gorath não tem portal: o caminho segue pelo Refúgio
		marcar("portal da próxima área abriu depois de %s" % nome_chefe, jogo.area.get("portal_aberto") == true)


func _rodar() -> void:
	await esperar_area("refugio_do_pinhal")
	print(_t(), " Refúgio carregado | NPCs=", jogo.area.npcs.size(), " | jogador y=", snapped(jog.global_position.y, 0.01))
	marcar("Refúgio: 6 NPCs presentes", jogo.area.npcs.size() == 6)
	marcar("Refúgio: jogador pisa no chão", chao_ok(), "y=%s" % snapped(jog.global_position.y, 0.01))
	await foto("01_refugio")

	# diálogo com o Vane
	jog.global_position = Vector3(0, 0.3, -16.2)
	jog.camera.yaw = 0.0
	await esperar(1.0)
	jogo.interagir()
	await process_frame
	marcar("Diálogo abriu perto do Vane", jogo.hud.dialogo_aberto and jog.travado)
	await foto("02_dialogo")
	var n := 0
	while jogo.hud.dialogo_aberto and n < 6:
		jogo.interagir()
		n += 1
		await process_frame
	marcar("Diálogo fechou e liberou o jogador", not jogo.hud.dialogo_aberto and not jog.travado, "%d falas" % n)

	# caminho bloqueado antes do chefe
	jogo.ir_para("fronteira_ferrogris", "Entrada")
	await esperar(0.4)
	marcar("Passagem para Ferrogris bloqueada sem derrotar o Gorath", jogo.area_nome == "refugio_do_pinhal")

	# portal norte, andando de verdade
	jog.global_position = Vector3(0, jogo.area.altura_em(0, -141) + 0.4, -141)
	jog.rotation.y = 0.0
	jog.camera.yaw = 0.0
	jog.entrada_forcada = Vector2(0, -1)
	var espera := 0.0
	while jogo.area_nome != "bosque_velado" and espera < 8.0:
		await create_timer(0.2).timeout
		espera += 0.2
	jog.entrada_forcada = Vector2.ZERO
	marcar("Portal norte levou ao Bosque Velado", jogo.area_nome == "bosque_velado", "%.1fs" % espera)
	await esperar_area("bosque_velado")
	marcar("Bosque: jogador pisa no chão", chao_ok())
	await foto("03_bosque")

	# inimigo comum
	var lobo: Inimigo = null
	for i in get_nodes_in_group("inimigos"):
		if (i as Inimigo).nome == "Lobo-cinza":
			lobo = i
			break
	marcar("Bosque: há Lobo-cinza", lobo != null)
	if lobo:
		jog.global_position = lobo.global_position + Vector3(0, 0.3, 4.0)
		await esperar(0.6)
		var ok := await lutar(lobo, 30.0, "04_luta_lobo")
		marcar("Lobo-cinza foi derrotado", ok)
	await lutar_contra_chefe("gorath", "Gorath", 120.0, "05_gorath")
	await foto("06_gorath_derrotado")

	# volta e leste
	jogo.ir_para("refugio_do_pinhal", "DaFronteira")
	await esperar_area("refugio_do_pinhal")
	jog.global_position = Vector3(138, jogo.area.altura_em(138, -1) + 0.4, -1)
	jog.rotation.y = -PI / 2.0
	jog.camera.yaw = -PI / 2.0
	jog.entrada_forcada = Vector2(0, -1)
	espera = 0.0
	while jogo.area_nome != "fronteira_ferrogris" and espera < 8.0:
		await create_timer(0.2).timeout
		espera += 0.2
	jog.entrada_forcada = Vector2.ZERO
	marcar("Portal leste (já liberado) levou à Fortaleza de Ferrogris", jogo.area_nome == "fronteira_ferrogris", "%.1fs" % espera)
	await esperar_area("fronteira_ferrogris")
	await foto("07_ferrogris")
	await lutar_contra_chefe("kaelor", "Kaelor", 150.0, "08_kaelor")

	jogo.ir_para("cratera_ignis", "Entrada")
	await esperar_area("cratera_ignis")
	marcar("Cratera liberada depois de Kaelor", jogo.area_nome == "cratera_ignis")
	await foto("09_cratera")
	await lutar_contra_chefe("ignis_maw", "Ignis-Maw", 200.0, "10_ignis_maw")

	jogo.ir_para("valdoria", "Entrada")
	await esperar_area("valdoria")
	marcar("Valdoria liberada depois de Ignis-Maw", jogo.area_nome == "valdoria")
	await foto("11_valdoria")
	await lutar_contra_chefe("solon", "Solon", 260.0, "12_solon")
	await esperar(1.0)
	marcar("Fim de jogo disparou depois de Solon", fim_de_jogo_visto)
	await foto("13_fim")

	var tudo := true
	for k in checks:
		tudo = tudo and checks[k]
	print("CURAS_FORCADAS_PELO_BOT ", curas)
	print("TEMPO_TOTAL ", _t())
	print("RESULTADO ", "TUDO PASSOU" if tudo else "HA FALHAS")
	quit(0 if tudo else 1)
