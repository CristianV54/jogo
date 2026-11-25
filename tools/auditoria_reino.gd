extends SceneTree
# AUDITORIA DO REINO: confere, casa por casa e portão por portão, o que foto de longe não mostra.
#   1. casa enterrada ou flutuando (chão debaixo dos 4 cantos contra o piso da casa: mais de 0,35 m é defeito);
#   2. casa em cima de rua ou trilha (meio da casa a menos de 6 m do eixo);
#   3. casa encavalada em outra (meios a menos de 9 m);
#   4. casa encostada na muralha (a menos de 12 m do círculo) ou do lado de fora por engano;
#   5. portão entupido (uma bola de 1,2 m no meio de cada portão não pode tocar em nada sólido que não seja o chão);
#   6. gente ou bicho do reino nascido dentro de parede (bola de 0,4 m no peito tocando sólido).
# Relatório em docs/auditoria/REINO_<data>.md.   godot --headless --path . --script res://tools/auditoria_reino.gd
var jogo: Jogo
var linhas: PackedStringArray = []
var defeitos := 0


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _defeito(tipo: String, onde: Vector2, detalhe: String) -> void:
	defeitos += 1
	linhas.append("| %s | (%d, %d) | %s |" % [tipo, int(onde.x), int(onde.y), detalhe])


func _toca_solido(p: Vector3, raio: float) -> String:
	var q := PhysicsShapeQueryParameters3D.new()
	var bola := SphereShape3D.new()
	bola.radius = raio
	q.shape = bola
	q.transform = Transform3D(Basis.IDENTITY, p)
	q.collision_mask = 1
	for r in jogo.mundo.get_world_3d().direct_space_state.intersect_shape(q, 6):
		var no := r.collider as Node
		if no is StaticBody3D and String(no.name) != "Colisao":
			return String(no.get_path()).right(60)
	return ""


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	var m: Mundo = jogo.mundo
	var c: Vector2 = MundoDados.REINO["centro"]
	var r: float = MundoDados.REINO["raio"]
	for pid in m.povoados:   # o reino inteiro precisa estar com a física ligada para as conferências 5 e 6
		if (m.povoados[pid]["centro"] as Vector2).distance_to(c) < r + 150.0:
			(m.povoados[pid]["no"] as Node3D).process_mode = Node.PROCESS_MODE_INHERIT
	await physics_frame
	await physics_frame
	var casas: Array[Node3D] = []
	for n in get_nodes_in_group("casas"):
		var n3 := n as Node3D
		var p := Vector2(n3.global_position.x, n3.global_position.z)
		if p.distance_to(c) < r + 40.0 and not m._em_alguma_area(p):
			casas.append(n3)
	for casa in casas:
		var p := Vector2(casa.global_position.x, casa.global_position.z)
		var pior := 0.0
		for canto in [Vector3(-3, 0, -2.5), Vector3(3, 0, -2.5), Vector3(-3, 0, 2.5), Vector3(3, 0, 2.5)]:
			var g: Vector3 = casa.global_transform * canto
			pior = maxf(pior, absf(m.terreno.altura_em(g.x, g.z) - casa.global_position.y))
		if pior > 0.35:
			_defeito("casa enterrada ou flutuando", p, "%.2f m de diferença num canto (%s)" % [pior, casa.name])
		if m.terreno.distancia_caminho(p.x, p.y) < 6.0:
			_defeito("casa em cima de rua", p, "%.1f m do eixo (%s)" % [m.terreno.distancia_caminho(p.x, p.y), casa.name])
		if absf(p.distance_to(c) - r) < 12.0:
			_defeito("casa encostada na muralha", p, String(casa.name))
		for outra in casas:
			if outra != casa and outra.get_instance_id() > casa.get_instance_id() and Vector2(outra.global_position.x, outra.global_position.z).distance_to(p) < 9.0:
				_defeito("casa encavalada", p, "%s com %s" % [casa.name, outra.name])
	for g in m.muralha.portoes:
		var toca := _toca_solido(Vector3(g.x, m.terreno.altura_em(g.x, g.y) + 1.6, g.y), 1.2)
		if toca != "":
			_defeito("portão entupido", g, toca)
	var seres := 0
	for grupo in ["npcs", "animais"]:
		for e in get_nodes_in_group(grupo):
			var n3 := e as Node3D
			var p := Vector2(n3.global_position.x, n3.global_position.z)
			if p.distance_to(c) > r + 150.0 or m._em_alguma_area(p):
				continue
			seres += 1
			var toca := _toca_solido(n3.global_position + Vector3(0, 1.1, 0), 0.4)
			if toca != "":
				_defeito("ser dentro de parede", p, "%s toca %s" % [n3.name, toca])
	var data := Time.get_date_string_from_system()
	var texto := "# Auditoria do reino, %s\n\nConferidos: %d casas, %d portões, %d pessoas e bichos. Defeitos: **%d**.\n\n" % [data, casas.size(), m.muralha.portoes.size(), seres, defeitos]
	if defeitos > 0:
		texto += "| Defeito | Onde (x, z) | Detalhe |\n|---|---|---|\n" + "\n".join(linhas) + "\n"
	var f := FileAccess.open("res://docs/auditoria/REINO_%s.md" % data, FileAccess.WRITE)
	f.store_string(texto)
	f.close()
	print("AUDITORIA DO REINO: ", casas.size(), " casas, ", seres, " seres, DEFEITOS ", defeitos)
	for l in linhas.slice(0, 25):
		print("  ", l)
	quit(0)
