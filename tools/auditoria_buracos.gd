extends SceneTree
# Acha buracos no chão do mundo (pontos sem chão sob eles) e confere a borda. Grade de 3 m sobre todo o mundo + 40 m de margem.
#   godot --headless --path . --script res://tools/auditoria_buracos.gd
var jogo: Jogo


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.jogador.global_position = Vector3(9000.0, 500.0, 9000.0)
	jogo.jogador.set_physics_process(false)
	var m: Mundo = jogo.mundo
	m.set_process(false)
	for id in m.regioes:
		m._ligar(m.regioes[id], true)
	for pid in m.povoados:
		if m.povoados[pid].has("no"):
			m._ligar(m.povoados[pid]["no"], true)
	for i in 6:
		await physics_frame
	var lim := MundoDados.LIMITES
	var espaco := jogo.get_world_3d().direct_space_state
	var passo := 3.0
	var buracos: Dictionary = {}   # bloco de 40 m -> quantidade
	var total := 0
	var n := 0
	var x := lim.position.x - 40.0 + 1.37   # fora do alinhamento da malha do chão (8 m): raio exato na aresta escapa
	while x <= lim.end.x + 40.0:
		var z := lim.position.y - 40.0 + 0.91
		while z <= lim.end.y + 40.0:
			n += 1
			var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 120.0, z), Vector3(x, -60.0, z), 1))
			if h.is_empty():
				var dentro := lim.has_point(Vector2(x, z))
				if dentro:
					total += 1
					if total % 12 == 1:
						print("  CELULA ", snappedf(x, 0.1), " ", snappedf(z, 0.1))
					var k := Vector2i(int(floor(x / 40.0)), int(floor(z / 40.0)))
					buracos[k] = int(buracos.get(k, 0)) + 1
			z += passo
		x += passo
	print("AMOSTRAS ", n, " sem chão dentro dos limites: ", total)
	var lista: Array = buracos.keys()
	lista.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return buracos[a] > buracos[b])
	for k in lista.slice(0, 25):
		print("  BURACO perto de (", k.x * 40, ", ", k.y * 40, ") células sem chão=", buracos[k])
	# borda: dá para sair do mundo? uma parede sólida precisa barrar cada lado
	var saidas := 0
	for lado in [["oeste", Vector3(lim.position.x - 30.0, 30.0, lim.get_center().y), Vector3(lim.position.x + 30.0, 30.0, lim.get_center().y)],
			["leste", Vector3(lim.end.x + 30.0, 30.0, lim.get_center().y), Vector3(lim.end.x - 30.0, 30.0, lim.get_center().y)],
			["norte", Vector3(lim.get_center().x, 30.0, lim.position.y - 30.0), Vector3(lim.get_center().x, 30.0, lim.position.y + 30.0)],
			["sul", Vector3(lim.get_center().x, 30.0, lim.end.y + 30.0), Vector3(lim.get_center().x, 30.0, lim.end.y - 30.0)]]:
		var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(lado[1], lado[2], 1))
		print("  BORDA ", lado[0], ": ", "parede ok" if not h.is_empty() else "SEM PAREDE")
		if h.is_empty():
			saidas += 1
	print("AUDITORIA_BURACOS_PROBLEMAS ", total + saidas)
	quit(0)
