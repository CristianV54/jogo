extends SceneTree
# Sem janela, em tempo acelerado (8x): cada NPC cumpre a rotina? Mede distância andada, animações vistas e se ficou preso.
#   godot --headless --path . --script res://tools/teste_rotinas.gd
var area: AreaBase
var dados := {}


func _init() -> void:
	area = load("res://scenes/areas/refugio_do_pinhal.tscn").instantiate()
	root.add_child(area)
	_rodar.call_deferred()


func _rodar() -> void:
	await create_timer(0.5).timeout
	for n in area.npcs:
		dados[n.nome] = {"inicio": n.global_position, "ultimo": n.global_position, "andou": 0.0, "anims": {}, "max_longe": 0.0, "parado": 0.0, "pior_parado": 0.0}
	Engine.time_scale = 8.0
	var t := 0.0
	while t < 50.0:   # 50 s de jogo
		await physics_frame
		t += 1.0 / 60.0
		for n in area.npcs:
			var d: Dictionary = dados[n.nome]
			var mov: float = (n.global_position - d["ultimo"]).length()
			d["andou"] += mov
			d["ultimo"] = n.global_position
			d["max_longe"] = maxf(d["max_longe"], n.global_position.distance_to(d["inicio"]))
			d["anims"][n.visual.animacoes.current_animation] = true
			d["parado"] = d["parado"] + 1.0 / 60.0 if mov < 0.0005 and n.visual.animacoes.current_animation == "Walk" else 0.0
			d["pior_parado"] = maxf(d["pior_parado"], d["parado"])
	var falhas := 0
	for nome in dados:
		var d: Dictionary = dados[nome]
		var ok: bool = d["andou"] > 2.0 and d["pior_parado"] < 2.0 and d["max_longe"] < 45.0
		print("  ", "PASSOU " if ok else "FALHOU ", nome, " | andou ", snapped(d["andou"], 0.1), " m | foi até ", snapped(d["max_longe"], 0.1), " m do posto | animações: ", d["anims"].keys(), " | maior tempo andando sem sair do lugar: ", snapped(d["pior_parado"], 0.1), " s")
		if not ok:
			falhas += 1
	print("RESULTADO ", "TUDO PASSOU" if falhas == 0 else "HA %d FALHAS" % falhas)
	quit(0)
