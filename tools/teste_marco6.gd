extends SceneTree
# Marco 6 ponta a ponta, sem janela: C4-M1 a C4-M4 na Cratera de Ignis.
#   godot --headless --path . --script res://tools/teste_marco6.gd
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
	while (jogo.hud.dialogo_aberto or not jogo._cena.is_empty()) and g < 80:
		jogo.interagir()
		g += 1


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.0)
	m = jogo.missoes
	jogo.clima.congelado = true   # o tempo não muda no meio do teste
	jogo.clima.tempo_automatico = false
	for id in ["C1-M1", "C1-M2", "C1-M3", "C1-M4", "C2-M1", "C2-M2", "C2-M3", "C2-M4", "C3-M1", "C3-M2", "C3-M3", "C3-M4"]:
		m.concluidas.append(id)
	m.ativas.clear()
	m.quadro_liberado = true
	jogo.liberar_fagulha()
	jogo.derrotados["gorath"] = true
	jogo.derrotados["kaelor"] = true
	jog.vida_max = 99999
	jog.vida = 99999
	await ir_para_area("valdoria", "Entrada")
	marcar("Sem a lâmina (C4-M4) Valdoria fica fechada", jogo.area_nome != "valdoria")
	m.iniciar("C4-M1")
	await ir_para_area("cratera_ignis", "Entrada")
	var a: Node = jogo.area
	marcar("Chegou à Cratera de Ignis", a.nome_area == "Cratera de Ignis")
	marcar("3 fornalhas, 4 minérios, 4 âncoras, 3 NPCs", a.fornalhas.size() == 3 and a.minerios.size() == 4 and a.ancoras.size() == 4 and a.npcs.size() == 3, "%d/%d/%d/%d" % [a.fornalhas.size(), a.minerios.size(), a.ancoras.size(), a.npcs.size()])
	marcar("Âncoras escondidas até a C4-M2 e Ignis ainda dormindo", a.ignis == null and not a.ancoras[0].visible)

	print("== C4-M1 ==")
	jog.vida = jog.vida_max
	jog.global_position = a.to_global(Vector3(30.0, 0.5, 98.0))
	await esperar(1.3)
	var na_lava := jog.vida < jog.vida_max
	jog.vida = jog.vida_max
	jog.global_position = a.to_global(Vector3(0.0, 0.6, 98.0))
	await esperar(1.3)
	marcar("Lava queima, a ponte de basalto é segura", na_lava and jog.vida == jog.vida_max, "lava=%s ponte=%d/%d" % [na_lava, jog.vida, jog.vida_max])
	for p in a.minerios:
		await perto(p.global_position, 0.3)
		jogo.interagir()
		await esperar(0.1)
	marcar("4 minérios vulcânicos coletados", m.feito("C4-M1", "minerios") == 4 and int(jog.inventario.get("minerio_vulcanico", 0)) == 4, str(jog.inventario))
	jog.global_position = a.to_global(Vector3(-38.0, 1.0, 12.0))
	await esperar(0.7)
	marcar("Chegou ao alojamento: C4-M1 concluída", m.concluidas.has("C4-M1"), str(m.concluidas.slice(-2)))
	await esperar(6.6)
	marcar("C4-M2 começa sozinha", m.ativas == ["C4-M2"], str(m.ativas))

	print("== C4-M2 ==")
	var f0: FornalhaNegra = a.fornalhas[0]
	await perto(f0._valvulas[0].global_position, 0.3)
	jogo.interagir()
	await perto(f0._valvulas[1].global_position, 0.3)
	jogo.interagir()
	f0._janela = 0.05
	await esperar(0.5)
	marcar("Fornalha do Sopro: pressão volta se for devagar", f0._giradas == 0 and not f0.apagada and f0._valvulas.all(func(v): return v.disponivel()))
	for v in f0._valvulas:
		await perto(v.global_position, 0.3)
		jogo.interagir()
		await esperar(0.05)
	marcar("Fornalha do Sopro apagada (3 válvulas a tempo)", f0.apagada and m.feito("C4-M2", "fornalhas") == 1)
	var f1: FornalhaNegra = a.fornalhas[1]
	var canos := f1.get_children().filter(func(x): return x is FornalhaNegra.Cano)
	canos[0].receber_dano(99, jog)
	marcar("Fornalha dos Canos: um cano só não basta", not f1.apagada and m.feito("C4-M2", "fornalhas") == 1)
	canos[1].receber_dano(99, jog)
	marcar("Fornalha dos Canos apagada (2 canos quebrados)", f1.apagada and m.feito("C4-M2", "fornalhas") == 2)
	var f2: FornalhaNegra = a.fornalhas[2]
	var por_numero := {}
	for r in f2._runas:
		por_numero[int(r.get_meta("numero"))] = r
	await perto(por_numero[2].global_position, 0.3)
	jogo.interagir()
	marcar("Fornalha das Runas: ordem errada reinicia", f2._proxima == 1 and not f2.apagada)
	for n in [1, 2, 3]:
		await perto(por_numero[n].global_position, 0.3)
		jogo.interagir()
		await esperar(0.05)
	marcar("Fornalha das Runas apagada (1, 2, 3)", f2.apagada and m.feito("C4-M2", "fornalhas") == 3)
	marcar("C4-M2 concluída e Ignis-Maw acorda", m.concluidas.has("C4-M2") and a.ignis != null and a.ancoras[0].visible)
	await esperar(6.6)
	marcar("C4-M3 começa sozinha", m.ativas == ["C4-M3"], str(m.ativas))

	print("== C4-M3 ==")
	var ig: Inimigo = a.ignis
	ig.receber_dano(99999, jog)
	marcar("Ignis-Maw não morre a golpes", ig.estado != Inimigo.Estado.MORTO and ig.vida == ig.vida_max, str(ig.vida))
	ig.set_physics_process(false)
	a._t_onda = 999.0
	a._t_brasas = 999.0
	jog.global_position = a.to_global(Vector3(a.ARENA.x + 12.0, 0.8, a.ARENA.y))
	await esperar(0.6)
	var vida_antes := jog.vida
	a._onda_de_calor()
	await esperar(3.2)
	marcar("Onda de calor fere quem fica no chão (-18)", vida_antes - jog.vida == 18, "%d -> %d" % [vida_antes, jog.vida])
	var vel0 := ig.velocidade
	var fog0 := get_nodes_in_group("inimigos").size()
	for i in 4:
		a.ancoras[i].receber_dano(999, jog)
		await esperar(0.2)
		if i == 0:
			marcar("1ª âncora: Ignis fica mais rápido", ig.velocidade > vel0)
	marcar("4 âncoras quebradas contam na missão", m.feito("C4-M3", "ancoras") == 4 and a._restantes == 0)
	await esperar(8.0)
	marcar("Ignis-Maw voou para longe (não morreu)", not is_instance_valid(ig) and jogo.derrotados.has("ignis_maw"))
	marcar("Parte das forjas desabou", a.fornalhas.all(func(f): return f.scale.y < 0.5), str(a.fornalhas.map(func(f): return snappedf(f.scale.y, 0.01))))
	marcar("C4-M3 concluída e a Brenn montou a forja de campo", m.concluidas.has("C4-M3") and a.brenn != null)
	await pegar_pickups(a, "escama_ancestral")
	marcar("Escama ancestral coletada", int(jog.inventario.get("escama_ancestral", 0)) == 1, str(jog.inventario))
	await esperar(6.6)
	marcar("C4-M4 começa sozinha", m.ativas == ["C4-M4"], str(m.ativas))

	print("== C4-M4 ==")
	var golpe0 := jog.dano_golpe
	await falar_com("Brenn")
	await fechar_dialogo()
	await falar_com("Brenn")
	await fechar_dialogo()
	marcar("Entregou minérios e escama: C4-M4 concluída", m.concluidas.has("C4-M4"), "%d/%d" % [m.feito("C4-M4", "minerios"), m.feito("C4-M4", "escama")])
	marcar("Lâmina final (+14 golpe)", jog.dano_golpe == golpe0 + 14, "%d -> %d" % [golpe0, jog.dano_golpe])
	await ir_para_area("valdoria", "Entrada")
	marcar("O caminho para Valdoria abriu", jogo.area_nome == "valdoria")

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
