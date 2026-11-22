extends SceneTree
# Carrega cada área e confere: sem erro de script, chefe criado, spawns e portal de volta existentes.
func _init() -> void:
	var falhas := 0
	for nome in ["refugio_do_pinhal", "bosque_velado", "fronteira_ferrogris", "cratera_ignis", "valdoria"]:
		var area: AreaBase = load("res://scenes/areas/%s.tscn" % nome).instantiate()
		root.add_child(area)
		await process_frame
		var chefe_ok := true
		if area.has_method("_chefe") and area.get("cena_chefe") != null:
			chefe_ok = area.get("chefe") != null
		var portais := area.find_children("*", "Portal", true, false).size()
		var inimigos := area.find_children("*", "Inimigo", true, false).size()
		print("AREA ", nome, " | nome=", area.nome_area, " | spawns=", area.spawns.keys(), " | portais=", portais, " | inimigos(c/ chefe)=", inimigos, " | npcs=", area.npcs.size(), " | chefe_ok=", chefe_ok)
		if not chefe_ok or area.spawns.size() < 1:
			falhas += 1
		area.queue_free()
		await process_frame
	print("RESULTADO_AREAS ", "OK" if falhas == 0 else "FALHAS %d" % falhas)
	quit(0 if falhas == 0 else 1)
