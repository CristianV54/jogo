extends SceneTree
# Cartaz lido com E abre a cena de diálogo com todas as linhas; os NPCs novos (Pomar, Ferrogris) existem e falam.
#   godot --headless --path . --script res://tools/teste_cartaz.gd
var jogo: Jogo
var falhas := 0
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
	var cartazes := get_nodes_in_group("interagiveis").filter(func(n): return n is Cartaz)
	_m("7 cartazes no mundo (Refúgio, Pomar, Bosque, Ferrogris, Cratera, Valdoria e estátua)", cartazes.size() == 7, str(cartazes.size()))
	var c: Cartaz = cartazes[0]
	jogo.jogador.global_position = c.global_position + Vector3(0, 0.5, 2.0)
	c.acionar()
	await create_timer(0.3).timeout
	_m("ler o cartaz abre o diálogo", jogo.hud.dialogo_aberto)
	_m("cartaz menciona o Imperador Solon", c.linhas.any(func(l: String) -> bool: return l.contains("SOLON")))
	for n in ["Ilsa", "Teo", "Cuidadora dos Dragões", "Soldado Rendido"]:
		var achou := false
		for npc in jogo.mundo.find_children(n, "Npc", true, false):
			achou = (npc as Npc).falas.size() >= 2
		_m("NPC %s existe com falas" % n, achou)
	var solon_no_mundo := 0
	for nome in ["refugio_do_pinhal", "pomar_alto", "bosque_velado", "fronteira_ferrogris", "cratera_ignis"]:
		for x in get_nodes_in_group("interagiveis"):
			if x is Cartaz and jogo.mundo.regioes[nome].is_ancestor_of(x) and (x as Cartaz).linhas.any(func(l: String) -> bool: return l.contains("Solon") or l.contains("SOLON") or l.contains("Imperador")):
				solon_no_mundo += 1
				break
	_m("o Solon aparece em cartazes de 6 regiões antes do Castelo", solon_no_mundo == 6, str(solon_no_mundo))
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
