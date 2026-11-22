extends SceneTree
# O jogador pula PARA CIMA: parado, sobe ~1,4 m e desce no mesmo lugar; correndo, mantém o avanço. Conferido com física real.
#   godot --headless --path . --script res://tools/teste_pulo.gd
var cena: Node
var jog: Jogador

func _init() -> void:
	cena = load("res://scenes/teste/cena_teste.tscn").instantiate()
	(cena.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(cena)
	jog = cena.get_node("Jogador")
	_rodar.call_deferred()

func _pular_e_medir(rotulo: String, entrada: Vector2) -> Dictionary:
	jog.entrada_forcada = entrada
	await create_timer(0.8).timeout
	var p0 := jog.global_position
	jog.pular()
	var y_max := p0.y
	var anims := {}
	var t := 0.0
	while t < 1.6:
		await physics_frame
		t += 1.0 / 60.0
		y_max = maxf(y_max, jog.global_position.y)
		anims[jog.animacao_atual] = true
	jog.entrada_forcada = Vector2.ZERO
	await create_timer(0.5).timeout
	var p1 := jog.global_position
	var sobe := y_max - p0.y
	var deriva := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	print("PULO ", rotulo, " | subiu ", snappedf(sobe, 0.01), " m | deslocamento horizontal ", snappedf(deriva, 0.01), " m | no chão no fim=", jog.is_on_floor(), " | animações=", anims.keys())
	return {"sobe": sobe, "deriva": deriva, "chao": jog.is_on_floor(), "anims": anims}

func _rodar() -> void:
	await create_timer(1.0).timeout
	var parado := await _pular_e_medir("parado", Vector2.ZERO)
	var correndo := await _pular_e_medir("andando para frente", Vector2(0, -1))
	var ok1: bool = parado["sobe"] > 1.0 and parado["sobe"] < 1.9 and parado["deriva"] < 0.1 and parado["chao"]
	var ok2: bool = correndo["sobe"] > 1.0 and correndo["deriva"] > 2.0 and correndo["chao"]
	var ok3: bool = parado["anims"].has("Jump_Start") and parado["anims"].has("Jump")
	print("  ", "PASSOU " if ok1 else "FALHOU ", "pulo parado sobe na vertical (1,0 a 1,9 m) e não desliza")
	print("  ", "PASSOU " if ok2 else "FALHOU ", "pulo andando mantém o avanço e pousa")
	print("  ", "PASSOU " if ok3 else "FALHOU ", "toca Jump_Start e Jump no ar")
	print("RESULTADO_PULO ", "OK" if ok1 and ok2 and ok3 else "FALHAS")
	quit(0 if ok1 and ok2 and ok3 else 1)
