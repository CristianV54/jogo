extends SceneTree
# Marco 3 ponta a ponta, sem janela: C1-M2, C1-M3 e C1-M4 pelo fluxo real (interação, entrega, combate, montaria, zonas).
#   godot --headless --path . --script res://tools/teste_marco3.gd
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
	while (jogo.area_nome != nome or jogo._trocando) and t < 200:
		await esperar(0.1)
		t += 1
	await esperar(0.6)


func perto(pos: Vector3, dist := 1.3) -> void:
	jog.global_position = pos + Vector3(dist, 0.5, 0)
	jog.velocity = Vector3.ZERO
	await esperar(0.15)


func falar_com(nome: String) -> void:
	for n in jogo.area.npcs:
		if n.nome == nome:
			await perto(n.global_position)
			break
	jogo.interagir()
	var g := 0
	while jogo.hud.dialogo_aberto and g < 10:
		jogo.interagir()
		g += 1


func ler_quadro() -> void:
	var q: QuadroDeAvisos = jogo.area.get_node("QuadroDeAvisos")
	await perto(q.global_position, 1.3)
	jogo.interagir()
	await esperar(0.1)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.0)
	m = jogo.missoes
	jogo.clima.congelado = true   # o tempo não muda no meio do teste
	jogo.clima.tempo_automatico = false
	# Marco 1 (já testado em teste_missoes): conclui por eventos
	for e in [["falar", "vane", 1], ["falar", "brenn", 1], ["golpear", "boneco_treino", 3], ["interagir", "tocha_treino", 3]]:
		GerenciadorMissoes.evento(e[0], e[1], e[2])
	marcar("C1-M1 concluída e quadro liberado", m.concluidas.has("C1-M1") and m.quadro_liberado)
	marcar("Fagulha começa ferida: não segue o jogador e fica na clareira", jogo.fagulha.alvo == null and not jogo.fagulha_livre and jogo.fagulha.global_position.distance_to(jogo.area.pos_fagulha_ferida()) < 1.0)
	await jogo.get_tree().create_timer(0.1).timeout
	# bloqueio do Halk
	jogo.ir_para("bosque_velado", "Entrada")
	await esperar(0.5)
	marcar("Portão norte barrado antes do resgate", jogo.area_nome == "refugio_do_pinhal")

	print("== C1-M2 ==")
	await ler_quadro()
	marcar("Quadro oferece C1-M2", m.ativas == ["C1-M2"])
	await ir_para_area("pomar_alto", "Principal")
	var macieiras := get_nodes_in_group("interagiveis").filter(func(x): return x is MacieiraColhivel)
	marcar("Pomar Alto tem 35 macieiras em 5 fileiras", macieiras.size() == 35, str(macieiras.size()))
	for i in 6:
		await perto(macieiras[i].global_position, 1.2)
		jogo.interagir()
		await esperar(0.1)
	marcar("6 maçãs colhidas no inventário e na missão", int(jog.inventario.get("maca", 0)) == 6 and m.feito("C1-M2", "macas") == 6, str(jog.inventario))
	marcar("Rastros imperiais apareceram na cerca", jogo.area._rastros_postos)
	var cesto: CestoVirado = null
	for x in get_nodes_in_group("interagiveis"):
		if x is CestoVirado:
			cesto = x
	await perto(cesto.global_position, 1.0)
	jogo.interagir()
	marcar("Cesto endireitado", m.feito("C1-M2", "cesto") == 1)
	await ir_para_area("refugio_do_pinhal", "DoPomar")
	await falar_com("Oren")
	marcar("Falou com Oren (fala da missão)", m.feito("C1-M2", "oren") == 1)
	await falar_com("Mara")
	marcar("Entregou 3 maçãs à Mara", m.feito("C1-M2", "mara") == 3 and int(jog.inventario.get("maca", 0)) == 3, str(jog.inventario))
	marcar("C1-M2 concluída com recompensa (+2 carnes: 4 no total com a da M1)", m.concluidas.has("C1-M2") and int(jog.inventario.get("carne", 0)) == 4)

	print("== C1-M3 ==")
	await ler_quadro()
	await esperar(0.5)
	marcar("Quadro oferece C1-M3", m.ativas == ["C1-M3"])
	var lobos := jogo.area.find_children("*", "Inimigo", false, false).filter(func(x): return x.especie == "lobo")
	marcar("3 lobos rondam o cercado", lobos.size() == 3, str(lobos.size()))
	for lobo in lobos:
		(lobo as Inimigo).receber_dano(9999, jog)
	await esperar(0.3)
	marcar("3 lobos derrotados contam", m.feito("C1-M3", "lobos") == 3)
	var cavalos := get_nodes_in_group("cavalo_perdido")
	marcar("Cavalo fugido na estrada leste", cavalos.size() == 1)
	var cavalo: AnimalVila = cavalos[0]
	await perto(cavalo.global_position, 2.0)
	jogo.interagir()
	marcar("Cavalo acalmado", m.feito("C1-M3", "cavalo") == 1)
	await esperar(0.2)
	jogo.interagir()
	await esperar(1.3)
	marcar("Montou o cavalo fugido", jog.montaria != null and jog.montaria.dono == cavalo)
	jog.global_position = Vector3(-30.0, jogo.area.altura_em(-30.0, 13.0) + 0.3, 13.0)
	await esperar(1.0)
	marcar("Cavalo devolvido ao curral: C1-M3 concluída (couro x2)", m.concluidas.has("C1-M3") and int(jog.inventario.get("couro", 0)) == 2, str(m.concluidas))
	jogo.interagir()
	await esperar(1.0)

	print("== C1-M4 ==")
	await ler_quadro()
	await esperar(0.3)
	marcar("Quadro oferece C1-M4", m.ativas == ["C1-M4"])
	var clareira: Vector3 = jogo.area.CLAREIRA
	jog.global_position = clareira + Vector3(0, 0.5, 18.0)
	await esperar(0.5)
	jog.global_position = clareira + Vector3(0, 0.5, 6.0)
	await esperar(0.7)
	marcar("Clareira encontrada", m.feito("C1-M4", "clareira") == 1)
	var batedores := jogo.area.find_children("*", "Inimigo", false, false).filter(func(x): return x.especie == "batedor")
	marcar("3 batedores imperiais de guarda", batedores.size() == 3, str(batedores.size()))
	for b in batedores:
		(b as Inimigo).receber_dano(9999, jog)
	await esperar(0.3)
	marcar("3 batedores derrotados contam", m.feito("C1-M4", "batedores") == 3)
	var estaca: EstacaDeFerroNegro = jogo.area.get_node("EstacaDeFerroNegro")
	for i in 3:
		await perto(estaca.global_position, 1.0)
		jogo.interagir()
		await esperar(0.2)
	marcar("Estaca arrancada em 3 interações", m.feito("C1-M4", "estaca") == 3 and estaca.puxadas == 3)
	await perto(jogo.area.pos_fagulha_ferida() + Vector3(-2.5, 0, -1.5), 0.8)
	jog.coletar("carne", 1)
	jogo.interagir()
	await esperar(0.3)
	marcar("Fagulha alimentada: C1-M4 concluída", m.concluidas.has("C1-M4"))
	marcar("Fagulha passa a acompanhar o Torin (fase 1: segue no chão, ainda não pode ser montada)", jogo.fagulha_livre and jogo.fagulha.alvo == jog and jogo.fagulha.fase == 1 and not jogo.fagulha.montaria.ativa)
	await ir_para_area("bosque_velado", "Entrada")
	marcar("Portão norte aberto depois do resgate", jogo.area_nome == "bosque_velado")

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
