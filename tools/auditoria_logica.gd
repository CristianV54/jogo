extends SceneTree
# Auditoria de LÓGICA do mundo (sem janela): o que está no lugar errado em relação ao resto, em todas as regiões e povoados.
#   A) construções (casas, campos) uma sobre a outra;  B) coisa solta dentro de campo ou dentro de casa (feno, bebedouro, poço...);
#   C) casa/campo flutuando, enterrado ou em chão inclinado;  D) NPC e bicho nascendo dentro de parede;  E) porta de casa bloqueada;
#   F) casa em cima de estrada ou trilha.
#   godot --headless --path . --script res://tools/auditoria_logica.gd
var jogo: Jogo
var problemas := 0
var _cap := CapsuleShape3D.new()


func _init() -> void:
	_cap.radius = 0.4
	_cap.height = 1.8
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


## Qual forma de colisão foi a atingida: nome, posição e tamanho (para achar o objeto culpado).
func _det(r: Dictionary) -> String:
	var co := r.collider as CollisionObject3D
	var dono := co.shape_owner_get_owner(co.shape_find_owner(r.shape)) as CollisionShape3D
	if dono == null:
		return ""
	var tam := ""
	if dono.shape is BoxShape3D:
		tam = str((dono.shape as BoxShape3D).size)
	elif dono.shape is CylinderShape3D:
		tam = "cil r=%.1f" % (dono.shape as CylinderShape3D).radius
	return " [forma em %s tam %s]" % [str(dono.global_position.snapped(Vector3(0.1, 0.1, 0.1))), tam]


func _ruim(cat: String, texto: String) -> void:
	problemas += 1
	print("  PROBLEMA [", cat, "] ", texto)


func _pegada(no: Node3D) -> Rect2:
	var ini := Vector2(1e9, 1e9)
	var fim := Vector2(-1e9, -1e9)
	var achou := false
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var caixa := m.global_transform * m.get_aabb()
		for k in 8:
			var q := caixa.get_endpoint(k)
			ini = Vector2(minf(ini.x, q.x), minf(ini.y, q.z))
			fim = Vector2(maxf(fim.x, q.x), maxf(fim.y, q.z))
			achou = true
	return Rect2(ini, fim - ini) if achou else Rect2()


## Terreno que vale em (x, z) do mundo: o da região (coordenadas locais) ou o chão do mundo.
func _alt(m: Mundo, p: Vector2) -> float:
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id).has_point(p):
			var area: Node3D = m.regioes[id]
			var c := MundoDados.centro(id)
			var t = area.get("terreno")
			if t is Terreno:
				return (t as Terreno).altura_em(p.x - c.x, p.y - c.y) + area.global_position.y
	return m.terreno.altura_em(p.x, p.y)


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.jogador.global_position = Vector3(9000.0, 500.0, 9000.0)
	jogo.jogador.set_physics_process(false)
	var m: Mundo = jogo.mundo
	m.set_process(false)
	var donos: Array = []   # [nome, no]
	for id in m.regioes:
		m._ligar(m.regioes[id], true)
		donos.append([id, m.regioes[id]])
	for pid in m.povoados:
		if m.povoados[pid].has("no"):
			m._ligar(m.povoados[pid]["no"], true)
			donos.append([pid, m.povoados[pid]["no"]])
	if m.fauna:
		for c in m.fauna.get_children():
			if c is Node3D:
				m._ligar(c, true)   # liga os bichos para conferir o nascimento de cada um
	for i in 8:
		await physics_frame
	var espaco := jogo.get_world_3d().direct_space_state
	var construcoes: Array = []   # {dono, nome, no, rect, campo}
	var soltos: Array = []        # filhos diretos que têm malha (props)
	for par in donos:
		for f in (par[1] as Node).get_children():
			var n3 := f as Node3D
			if n3 == null or not n3.is_inside_tree():
				continue
			var campo := n3 is Plantacao
			var casa := n3.has_meta("colunas")
			if campo or casa:
				var r := _pegada(n3)
				if campo:
					var pl := n3 as Plantacao
					var meia := Vector2(pl.largura / 2.0 + 1.0, pl.profundidade / 2.0 + 1.0)
					var c := Vector2(n3.global_position.x, n3.global_position.z)
					r = Rect2(c - meia, meia * 2.0)
					if absf(sin(n3.global_rotation.y)) > 0.7:   # girado 90 graus: troca os lados
						r = Rect2(c - Vector2(meia.y, meia.x), Vector2(meia.y, meia.x) * 2.0)
				construcoes.append({"dono": par[0], "nome": "%s/%s" % [par[0], n3.name], "no": n3, "rect": r, "campo": campo})
			elif not (n3 is StaticBody3D) and not (n3 is Npc) and not (n3 is AnimalVila) and not (n3 is MultiMeshInstance3D) and n3.find_children("*", "MeshInstance3D", true, false).size() > 0 and String(n3.name) != "Navegacao":
				soltos.append({"dono": par[0], "nome": "%s/%s" % [par[0], n3.name], "no": n3})
	print("construções: ", construcoes.size(), "  objetos soltos: ", soltos.size())
	# A) uma sobre a outra
	for i in construcoes.size():
		for j in range(i + 1, construcoes.size()):
			var a: Dictionary = construcoes[i]
			var b: Dictionary = construcoes[j]
			if (a["rect"] as Rect2).grow(0.3).intersects(b["rect"]):
				_ruim("sobreposição", "%s encosta/atravessa %s" % [a["nome"], b["nome"]])
	# B) coisa solta dentro de campo ou de casa
	for s in soltos:
		var p := Vector2((s["no"] as Node3D).global_position.x, (s["no"] as Node3D).global_position.z)
		for c in construcoes:
			if c["dono"] == s["dono"] and (c["rect"] as Rect2).has_point(p):
				_ruim("dentro de " + ("campo" if c["campo"] else "casa"), "%s está dentro de %s" % [s["nome"], c["nome"]])
	# C) flutuando, enterrado, chão inclinado
	for c in construcoes:
		var no: Node3D = c["no"]
		var r: Rect2 = c["rect"]
		var hs: Array[float] = []
		for k in [r.position, r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), r.end, r.get_center()]:
			hs.append(_alt(m, k))
		var minimo: float = hs.min()
		var maximo: float = hs.max()
		if maximo - minimo > 3.1:   # até 2,8 m o plinto de pedra sob a casa esconde o desnível
			_ruim("chão inclinado", "%s em chão com %.1f m de desnível" % [c["nome"], maximo - minimo])
		var base_y := no.global_position.y
		var plataforma := 3.1 if String(c["dono"]) == "castelo_imperial" else 0.0   # o castelo fica numa plataforma de 3 m
		if base_y - maximo - plataforma > 0.6:
			_ruim("flutuando", "%s a %.1f m acima do chão" % [c["nome"], base_y - maximo])
		elif minimo + plataforma - base_y > 0.6 and not c["campo"]:
			_ruim("enterrado", "%s %.1f m abaixo do chão" % [c["nome"], minimo - base_y])
	# D) gente e bicho dentro de parede
	for grupo in ["npcs", "animais"]:
		for e in get_nodes_in_group(grupo):
			var n3 := e as Node3D
			if n3 == null:
				continue
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = _cap
			q.transform = Transform3D(Basis.IDENTITY, n3.global_position + Vector3(0, 1.1, 0))
			q.collision_mask = 1
			for r in espaco.intersect_shape(q, 4):
				if r.collider is StaticBody3D and not (r.collider as Node).get_parent() is Terreno and String((r.collider as Node).name) != "Colisao":
					_ruim("nasceu na parede", "%s (%s) em %s dentro de %s" % [n3.name, grupo, str(n3.global_position.snapped(Vector3(0.1, 0.1, 0.1))), str((r.collider as Node).get_path()) + _det(r)])
					break
	# E) porta bloqueada
	for c in construcoes:
		if c["campo"]:
			continue
		var casa: Node3D = c["no"]
		if not casa.has_meta("x_porta"):
			continue
		var frente := casa.global_transform * Vector3(float(casa.get_meta("x_porta")), 1.0, float(casa.get_meta("linhas")) + 1.6)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = _cap
		q.transform = Transform3D(Basis.IDENTITY, frente)
		q.collision_mask = 1
		for r in espaco.intersect_shape(q, 4):
			if r.collider is StaticBody3D and String((r.collider as Node).name) != "Colisao":
				_ruim("porta bloqueada", "%s: a 1,6 m da porta há %s" % [c["nome"], str((r.collider as Node).get_path()) + _det(r)])
				break
	# F) casa sobre estrada ou trilha
	for s in soltos:
		if String((s["no"] as Node).name) == "Anvil":
			print("  [info] bigorna em ", (s["no"] as Node3D).global_position, " pegada ", _pegada(s["no"]))
	for c in construcoes:
		if String(c["nome"]).ends_with("/Forja"):
			print("  [info] forja pegada ", c["rect"])
	for c in construcoes:
		if c["campo"]:
			continue
		var ctr: Vector2 = (c["rect"] as Rect2).get_center()
		for id in MundoDados.REGIOES:
			pass
		if m.terreno.distancia_caminho(ctr.x, ctr.y) < 2.0 and not m.regiao_em(Vector3(ctr.x, 0, ctr.y)) != "":
			_ruim("sobre o caminho", "%s está em cima de estrada/trilha" % c["nome"])
	# H) casa sem telhado / sem frontão / sem porta (o kit só tem alguns tamanhos de telhado)
	for c in construcoes:
		if c["campo"]:
			continue
		var casa: Node3D = c["no"]
		var tem_telhado := false
		var tem_porta := false
		for f in casa.get_children():
			if f.has_meta("peca"):
				var nm: String = f.get_meta("peca")
				if nm.begins_with("Roof_") and not nm.begins_with("Roof_Front"):
					tem_telhado = true
				if nm.contains("Door"):
					tem_porta = true
		if not tem_telhado:
			_ruim("sem telhado", "%s (%dx%d) não tem telhado" % [c["nome"], int(casa.get_meta("colunas")), int(casa.get_meta("linhas"))])
		if not tem_porta:
			_ruim("sem porta", "%s não tem porta" % c["nome"])
	# I) estrutura (torre, muro) em volta de nada / solta: só conta casas que se cruzam com plinto fora do chão
	# G) povoado encostando em serra de rocha ou em outra região
	for pid in m.povoados:
		var cp: Vector2 = m.povoados[pid]["centro"]
		var raio: float = float(m.povoados[pid]["raio"])
		for c in MundoDados.CRISTAS:
			var a: Vector2 = c["de"]
			var b: Vector2 = c["para"]
			var t := clampf((cp - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
			if cp.distance_to(a + (b - a) * t) < raio * 0.8 + 4.0:
				_ruim("povoado na serra", "%s (raio %.0f) invade a serra %s" % [pid, raio, c["id"]])
		for id in MundoDados.REGIOES:
			if MundoDados.retangulo(id, 4.0).intersects(Rect2(cp - Vector2(raio, raio) * 0.8, Vector2(raio, raio) * 1.6)):
				_ruim("povoado na região", "%s invade %s" % [pid, id])
	print("AUDITORIA_LOGICA_PROBLEMAS ", problemas)
	quit(0)
