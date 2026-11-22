extends SceneTree
# Todo portal leva a uma área que existe, a um spawn que existe, e a área de destino tem portal de volta.
#   godot --headless --path . --script res://tools/auditoria_portais.gd
const AREAS := ["refugio_do_pinhal", "pomar_alto", "bosque_velado", "acampamento_ruptura", "fronteira_ferrogris", "cratera_ignis", "valdoria", "castelo_imperial"]


func _init() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var portais := {}   # area -> [[destino, spawn], ...]
	var spawns := {}
	for id in AREAS:
		var a := load("res://scenes/areas/%s.tscn" % id).instantiate() as AreaBase
		root.add_child(a)
		await process_frame
		spawns[id] = a.spawns.keys()
		portais[id] = []
		for p in a.find_children("*", "Portal", true, false):
			portais[id].append([(p as Portal).destino, (p as Portal).spawn])
		a.queue_free()
		await process_frame
	var jogo_areas: Dictionary = Jogo.AREAS
	var problemas := 0
	for id in AREAS:
		for p in portais[id]:
			var ok_area: bool = jogo_areas.has(p[0])
			var ok_spawn: bool = ok_area and spawns.has(p[0]) and p[1] in spawns[p[0]]
			var volta := false
			if ok_area and portais.has(p[0]):
				for q in portais[p[0]]:
					if q[0] == id:
						volta = true
			print("  ", "OK    " if (ok_area and ok_spawn and volta) else "ERRO  ", id, " -> ", p[0], " (spawn ", p[1], ") volta=", volta)
			if not (ok_area and ok_spawn and volta):
				problemas += 1
	print("PORTAIS_PROBLEMAS ", problemas)
	quit(0)
