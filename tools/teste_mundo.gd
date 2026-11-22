extends SceneTree
# Mundo contínuo, sem janela: constrói tudo, confere regiões, barreiras, rios, pontes e anda de verdade pelas estradas.
#   godot --headless --path . --script res://tools/teste_mundo.gd
var jogo: Jogo
var t0 := 0


func _init() -> void:
	t0 = Time.get_ticks_msec()
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.2).timeout
	print("MUNDO construído em ", (Time.get_ticks_msec() - t0) / 1000.0, " s")
	var m: Mundo = jogo.mundo
	print("MUNDO regiões=", m.regioes.size(), " barreiras=", m.barreiras.size(), " povoados=", m.povoados.size(), " estradas=", m.estradas.size())
	print("MUNDO jogador em ", jogo.jogador.global_position, " lugar=", m.nome_do_lugar(jogo.jogador.global_position))
	quit(0)
