extends SceneTree
# Rios: o jogador fica de pé em cima da ponte (não atravessa o tabuleiro) e consegue estar dentro da água rasa (pisa no leito).
#   godot --headless --path . --script res://tools/teste_rio.gd
var jogo: Jogo
var jog: Jogador


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	jog = jogo.get_node("Jogador")
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.2).timeout
	await create_timer(1.0).timeout
	var a: Node = jogo.area
	var falhas := 0
	var t: Terreno = a.terreno
	# 1) ponte norte: no meio do tabuleiro o jogador fica sobre ele, acima do leito
	var meio := Vector3(3.3, 0.0, -62.0)
	var leito := t.altura_em(meio.x, meio.z)
	jog.global_position = Vector3(meio.x, leito + 3.0, meio.z)
	jog.velocity = Vector3.ZERO
	await create_timer(1.2).timeout
	var y_ponte := jog.global_position.y
	var ok1 := y_ponte > leito + 0.4
	print("  ", "PASSOU " if ok1 else "FALHOU ", "Em cima da ponte norte (y=%.2f, leito=%.2f)" % [y_ponte, leito])
	if not ok1:
		falhas += 1
	# 2) fora da ponte, no meio do rio: pisa no leito, abaixo do nível do chão em volta
	var rio := Vector3(30.0, 0.0, -57.0)
	var d := t.distancia_rio(rio.x, rio.z)
	jog.global_position = Vector3(rio.x, t.altura_em(rio.x, rio.z) + 3.0, rio.z)
	jog.velocity = Vector3.ZERO
	await create_timer(1.2).timeout
	var y_rio := jog.global_position.y
	var chao := t.altura_em(rio.x, rio.z)
	var ok2 := absf(y_rio - chao) < 0.3 and d < 0.5
	print("  ", "PASSOU " if ok2 else "FALHOU ", "No leito do rio (y=%.2f, chão=%.2f, distância à água=%.2f)" % [y_rio, chao, d])
	if not ok2:
		falhas += 1
	# 3) nenhuma árvore dentro d'água
	var arvores := 0
	var mm := a.find_child("Pinheiros", true, false) as MultiMeshInstance3D
	if mm:
		for i in mm.multimesh.instance_count:
			var o := mm.multimesh.get_instance_transform(i).origin
			if t.na_agua(o.x, o.z, 1.0):
				arvores += 1
	print("  ", "PASSOU " if arvores == 0 else "FALHOU ", "Nenhuma árvore na água (%d dentro)" % arvores)
	if arvores > 0:
		falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
