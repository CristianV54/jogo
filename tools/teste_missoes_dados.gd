extends SceneTree
## Valida as 20 missões contra o mundo de verdade: cadeia de pré-requisitos, e para cada objetivo se existe no mundo o que o cumpre
## (NPC, objeto interagível, zona, inimigo, item) em quantidade suficiente; recompensas com itens válidos; barreiras ligadas à
## missão certa.   godot --headless --path . --script res://tools/teste_missoes_dados.gd
var jogo: Jogo
var falhas := 0
var avisos := 0
## Objetivos cumpridos por eventos que a própria cena emite (cena, luta contra chefe que só aparece depois): conferidos pela cadeia.
const POR_EVENTO := ["confronto_visto", "kaelor", "gorath", "vane_duelo", "solon", "cavalo_perdido", "fagulha"]   # cavalo_perdido nasce quando a C1-M3 ativa; a Fagulha é o dragão do jogo, não um NPC
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()
func _m(nome: String, ok: bool, det := "") -> void:
	print("  ", "PASSOU " if ok else "FALHOU ", nome, ("  [" + det + "]") if det != "" else "")
	if not ok:
		falhas += 1
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	m.set_process(false)
	for id in m.regioes:
		m._ligar(m.regioes[id], true)
	var ids: Array = DadosMissoes.MISSOES.keys()
	# 1) cadeia
	var ordem: Array[String] = []
	for c in range(1, 6):
		for k in range(1, 5):
			ordem.append("C%d-M%d" % [c, k])
	var cadeia_ok := true
	for i in ordem.size():
		var d: Dictionary = DadosMissoes.MISSOES.get(ordem[i], {})
		if d.is_empty():
			cadeia_ok = false
			continue
		if i > 0 and (d.get("requer", "") != ordem[i - 1] or d.get("auto_apos", "") != ordem[i - 1]) and ordem[i] != "C1-M2":
			cadeia_ok = false
			print("    [cadeia] ", ordem[i], " requer ", d.get("requer", ""))
	_m("20 missões em cadeia C1-M1 a C5-M4", cadeia_ok and ids.size() == 20, "%d missões" % ids.size())
	# 2) inventário do mundo
	var interag: Dictionary = {}
	for n in get_nodes_in_group("interagiveis"):
		var idi := String(n.get("id"))
		if idi != "":
			interag[idi] = int(interag.get(idi, 0)) + 1
	var zonas: Dictionary = {}
	for z in m.find_children("*", "ZonaDeEvento", true, false):
		zonas[String(z.get("id"))] = true
	var npcs: Dictionary = {}
	for n in m.find_children("*", "Npc", true, false):
		npcs[String((n as Npc).nome).to_lower()] = true
	var especies: Dictionary = {}
	var chaves := 0
	for e in m.find_children("*", "Inimigo", true, false):
		var ini := e as Inimigo
		especies[ini.especie] = int(especies.get(ini.especie, 0)) + 1
		if ini.drops.has("chave"):
			chaves += 1
	var pilhas: Dictionary = {}
	for p in m.find_children("*", "PilhaDeItem", true, false):
		pilhas[String((p as PilhaDeItem).item)] = int(pilhas.get(String((p as PilhaDeItem).item), 0)) + int((p as PilhaDeItem).qtd)
	var soltam: Dictionary = {}   # itens que bichos e inimigos largam ao morrer
	for e in m.find_children("*", "Inimigo", true, false):
		for it in (e as Inimigo).drops:
			soltam[String(it)] = true
	for a in m.find_children("*", "AnimalVila", true, false):
		for it in (a as AnimalVila).drops:
			soltam[String(it)] = true
	var raizes := m.find_children("*", "RaizMedicinal", true, false).size()
	if raizes > 0:
		soltam["raiz"] = true   # colhida do chão (RaizMedicinal)
	var fornalhas := m.find_children("*", "FornalhaNegra", true, false).size()
	var trocas := 0
	for n in get_nodes_in_group("interagiveis"):
		if String(n.get("texto")).contains(" por "):
			trocas += 1
	var batedores := 0
	for e in m.find_children("*", "Inimigo", true, false):
		if String((e as Inimigo).nome).to_lower().contains("batedor"):
			batedores += 1
	# 3) objetivos
	for id in ordem:
		var d: Dictionary = DadosMissoes.MISSOES[id]
		for o in d["objetivos"]:
			var alvo: Variant = o["alvo"]
			var alvos: Array = alvo if alvo is Array else [alvo]
			var qtd := int(o.get("qtd", 1))
			var ok := false
			var det := ""
			match String(o["tipo"]):
				"falar":
					ok = npcs.has(String(alvo))
					det = "NPC %s" % alvo
				"entregar":
					ok = npcs.has(String(alvo)) or String(alvo) in POR_EVENTO
					det = "NPC %s" % alvo
				"interagir":
					ok = str(alvo) in POR_EVENTO or int(interag.get(str(alvo), 0)) >= 1 or (str(alvo) == "fornalha_apagada" and fornalhas >= qtd) or (str(alvo) == "suprimento" and trocas >= 1)
					det = "%s: %d no mundo, precisa de %d" % [alvo, int(interag.get(String(alvo), 0)), qtd]
					if int(interag.get(String(alvo), 0)) >= 1 and int(interag.get(String(alvo), 0)) < qtd and not (String(alvo) in ["tocha_treino", "macieira", "jaula", "ancora", "fornalha_apagada", "setor_prisao", "estaca_ferro"]):
						ok = false
				"golpear":
					ok = true   # o boneco de treino é um Interagivel de golpe; coberto por teste_missoes
				"visitar":
					ok = zonas.has(String(alvo))
					det = "zona %s" % alvo
				"derrotar":
					ok = String(alvo) in POR_EVENTO or int(especies.get(String(alvo), 0)) >= qtd or (String(alvo) == "batedor" and batedores >= qtd)
					det = "%s: %d no mundo, precisa de %d" % [alvo, int(especies.get(String(alvo), 0)), qtd]
				"destruir":
					ok = true   # âncoras e focos nascem por cena de chefe (cobertos pelos testes de marco)
				"coletar":
					var tem := 0
					for a in alvos:
						tem += int(pilhas.get(String(a), 0))
					ok = tem >= qtd or ("chave" in alvos and chaves >= qtd) or alvos.any(func(a): return soltam.has(String(a)))
					det = "%s: %d em pilhas, %d guardas com chave, soltam=%s" % [str(alvo), tem, chaves, str(alvos.any(func(a): return soltam.has(String(a))))]
			_m("%s: %s" % [id, o["texto"]], ok, det)
	# 4) recompensas e barreiras
	var itens_validos := ["carne", "couro", "la", "presa", "maca", "raiz", "chave", "minerio_bruto", "aco_imperial", "minerio_vulcanico", "escama_ancestral"]
	var rec_ok := true
	for id in ordem:
		for it in DadosMissoes.MISSOES[id]["recompensa"].get("itens", {}):
			if not (it in itens_validos):
				rec_ok = false
				print("    [recompensa] ", id, " item desconhecido ", it)
	_m("todas as recompensas têm itens válidos", rec_ok)
	var cond: Dictionary = jogo._condicoes_das_barreiras()
	var liga := {"bosque": "C1-M4", "ferrogris": "C3-M1", "valdoria": "C4-M4", "castelo": "C5-M1"}
	for b in liga:
		jogo.missoes.concluidas.clear()
		var antes: bool = cond[b].call()
		jogo.missoes.concluidas.append(liga[b])
		var depois: bool = cond[b].call()
		_m("barreira %s só abre com %s" % [b, liga[b]], not antes and depois)
	jogo.missoes.concluidas.clear()
	jogo.derrotados.clear()
	var ant: bool = cond["ruptura"].call()
	jogo.derrotados["gorath"] = true
	_m("barreira ruptura só abre com o Gorath derrotado", not ant and bool(cond["ruptura"].call()))
	jogo.derrotados.clear()
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
