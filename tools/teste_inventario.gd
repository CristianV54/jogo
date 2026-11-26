extends SceneTree
# Inventário na cena principal, com teclas de verdade: I abre, clique seleciona, Enter usa, Esc/I fecham.
#   godot --path . --resolution 1280x720 --script res://tools/teste_inventario.gd
var jogo: Jogo
var jog: Jogador
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


func tecla(k: Key) -> void:
	for pressionada in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = k
		e.keycode = k
		e.pressed = pressionada
		Input.parse_input_event(e)
	await esperar(0.15)


func foto(nome: String) -> void:
	for i in 4:
		await process_frame
	var im := root.get_viewport().get_texture().get_image()
	if im == null:   # rodando sem janela (--headless) não há imagem: o teste segue sem a foto
		return
	im.save_png("tools/capturas/inv_" + nome + ".png")
	print("FOTO ", nome)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await esperar(0.2)
	await esperar(1.5)
	var hud: Hud = jogo.hud
	var painel: PainelInventario = hud._painel
	marcar("Começa com a espada curta, 2 pães e 15 moedas, e o painel fechado", int(jog.inventario.get("espada_curta", 0)) == 1 and int(jog.inventario.get("pao", 0)) == 2 and int(jog.inventario.get("moeda", 0)) == 15 and not hud.inventario_aberto and not painel.visible, str(jog.inventario))
	jog.inventario.clear()   # daqui em diante o teste usa só o que ele mesmo põe na bolsa, sem fome
	jog.inventario_mudou.emit(jog.inventario)
	jog.fome = 100.0

	jog.coletar("carne", 3)
	jog.coletar("couro", 2)
	jog.coletar("la", 1)
	jog.coletar("presa", 1)
	await esperar(0.3)
	marcar("Lista do canto mostra os itens", hud._inventario_label.text.contains("Carne  x3") and hud._inventario_label.text.contains("Presa  x1"), hud._inventario_label.text.replace("\n", " | "))

	jog.vida = 50
	jog.vida_mudou.emit(jog.vida, jog.vida_max)
	await tecla(KEY_I)
	marcar("Tecla I abre o painel", hud.inventario_aberto and painel.visible)
	marcar("Jogador fica travado com o painel aberto", jog.travado)
	var p0 := jog.global_position
	jog.entrada_forcada = Vector2(0, -1)
	await esperar(0.6)
	jog.entrada_forcada = Vector2.ZERO
	marcar("Jogador não anda com o painel aberto", jog.global_position.distance_to(p0) < 0.3, "%.2f m" % jog.global_position.distance_to(p0))
	var ocupados := 0
	for i in painel._slots.size():
		if painel._id_do_slot[i] != "":
			ocupados += 1
	marcar("4 espaços ocupados, resto vazio", ocupados == 4 and painel._slots.size() == 30, "%d ocupados de %d" % [ocupados, painel._slots.size()])
	var icone: TextureRect = painel._slots[0].get_node("Icone")
	marcar("Espaço da carne tem ícone", icone.texture != null)
	marcar("Selecionado de início é a carne", painel._selecionado == "carne" and painel._nome.text == "Carne", painel._nome.text)
	await foto("aberto")

	painel._slots[1].pressed.emit()   # clique no couro
	await esperar(0.2)
	marcar("Clique seleciona o couro e mostra a descrição", painel._selecionado == "couro" and painel._nome.text == "Couro" and painel._descricao.text.contains("Pele"), painel._nome.text)
	marcar("Couro não é comestível: botão Usar desligado", painel._usar.disabled)
	await foto("couro")

	painel._slots[0].pressed.emit()   # volta para a carne
	await esperar(0.2)
	marcar("Carne comestível: botão Usar ligado", not painel._usar.disabled)
	await tecla(KEY_ENTER)
	marcar("Enter come a carne: vida 50 -> 70 (até 72: a vida também volta sozinha enquanto o teste espera)", jog.vida >= 70 and jog.vida <= 72, "vida %d" % jog.vida)
	marcar("Carne x3 -> x2", int(jog.inventario.get("carne", 0)) == 2, str(jog.inventario))
	marcar("Painel e lista mostram a quantidade nova", painel._quantidade.text == "Quantidade: 2" and hud._inventario_label.text.contains("Carne  x2"), painel._quantidade.text)
	jog.vida = 95
	jog._comendo = 0.0   # o gesto de comer leva um instante; o teste não espera por ele
	painel._usar.pressed.emit()   # clique no botão Usar
	await esperar(0.2)
	marcar("Comer perto do limite: vida sobe só até 100", jog.vida == 100, "vida %d" % jog.vida)
	jog._comendo = 0.0
	painel._usar.pressed.emit()
	await esperar(0.2)
	marcar("Com vida cheia e sem fome não gasta a carne", int(jog.inventario.get("carne", 0)) == 0 + 1, str(jog.inventario))
	await foto("depois_de_comer")

	await tecla(KEY_ESCAPE)
	marcar("Esc fecha o painel e destrava o jogador", not hud.inventario_aberto and not painel.visible and not jog.travado)
	await tecla(KEY_I)
	marcar("I abre de novo", hud.inventario_aberto)
	await tecla(KEY_I)
	marcar("I fecha", not hud.inventario_aberto and not jog.travado)

	jog._comendo = 0.0
	jog.usar_item("carne")
	jog.vida = 40
	jog._comendo = 0.0
	jog.usar_item("carne")
	await esperar(0.2)
	marcar("Comer o último esvazia o espaço", not jog.inventario.has("carne"), str(jog.inventario))
	await tecla(KEY_I)
	marcar("Painel sem carne: 3 espaços ocupados", painel._id_do_slot.filter(func(x): return x != "").size() == 3)
	await foto("sem_carne")
	await tecla(KEY_I)

	var falhas := 0
	for k in checks:
		if not checks[k]:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
