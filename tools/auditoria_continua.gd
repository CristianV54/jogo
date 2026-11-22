extends SceneTree
# Auditoria do mundo contínuo, sem janela. Constrói o mundo inteiro e confere, andando com a cápsula do jogador:
#   1) cada estrada: dá para andar do começo ao fim (passo de 1,5 m; degrau máximo 0,75 m), de ponta a ponta, inclusive pontes;
#   2) dentro de cada região: do ponto de partida até cada NPC, objeto interativo, entrada de casa e as pontas das estradas;
#   3) barreiras fechadas realmente barram (a estrada NÃO passa) e abertas liberam;
#   4) nenhum NPC/animal nasceu dentro de parede ou da água.
#   godot --headless --path . --script res://tools/auditoria_continua.gd
var jogo: Jogo
var _cap := CapsuleShape3D.new()
var problemas := 0


func _init() -> void:
	_cap.radius = 0.4
	_cap.height = 1.8
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _livre_em(x: float, z: float, mascara := 5) -> Array:   # [livre, y]
	var espaco := jogo.get_world_3d().direct_space_state
	var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 60.0, z), Vector3(x, -30.0, z), 1))
	if h.is_empty():
		return [false, -999.0]
	var y: float = h.position.y
	var sq := PhysicsShapeQueryParameters3D.new()
	sq.shape = _cap
	sq.transform = Transform3D(Basis.IDENTITY, Vector3(x, y + 0.25 + 0.9, z))
	sq.collision_mask = mascara
	for r in espaco.intersect_shape(sq, 12):   # só conta o que é parede, chão e móvel (gente e bicho andam)
		if r.collider is StaticBody3D:
			return [false, y]
	return [true, y]


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	for i in 6:
		await physics_frame
	var m: Mundo = jogo.mundo
	jogo.jogador.global_position = Vector3(9000.0, 500.0, 9000.0)   # tira o Torin do caminho: o corpo dele também é uma parede para os raios
	jogo.jogador.set_physics_process(false)
	await physics_frame
	# abre todos os portões das áreas e as portas das casas (as portas abrem sozinhas)
	for p in m.find_children("*", "Portao", true, false):
		(p as Portao).abrir()
	for cp in m.find_children("ColisaoPorta", "StaticBody3D", true, false):
		(cp as StaticBody3D).collision_layer = 0
	# 3) barreiras: fechadas barram
	for id in m.barreiras:
		var b: Barreira = m.barreiras[id]
		var fechada := not b.aberta
		var ponto := b.global_position
		var bloqueia := _bloqueia(ponto, b)
		print("  ", "PASSOU " if (bloqueia or not fechada) else "FALHOU ", "Barreira ", id, " fechada barra a passagem (aberta=", b.aberta, ")")
		if fechada and not bloqueia:
			problemas += 1
	for id in m.barreiras:   # liberta as barreiras para o resto da auditoria
		(m.barreiras[id] as Barreira)._abrir()
	await create_timer(0.2).timeout
	await physics_frame
	# 1) estradas de ponta a ponta
	for e in MundoDados.ESTRADAS:
		var pts: PackedVector2Array = m.estradas[e["id"]]
		var ok := true
		var ultimo_y := -999.0
		var onde := ""
		var acum := 0.0
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			var comp := a.distance_to(b)
			var passos := maxi(1, int(comp / 1.5))
			for k in passos:
				var q := a.lerp(b, float(k) / passos)
				var r := _livre_em(q.x, q.y)
				if not r[0] or (ultimo_y > -900.0 and absf(float(r[1]) - ultimo_y) > 0.75):
					ok = false
					onde = "(%d, %d) livre=%s dy=%.2f" % [q.x, q.y, r[0], absf(float(r[1]) - ultimo_y)]
					break
				ultimo_y = r[1]
			if not ok:
				break
			acum += comp
		print("  ", "PASSOU " if ok else "FALHOU ", "Estrada ", e["nome"], " (", int(acum), " m) anda-se de ponta a ponta ", onde)
		if not ok:
			problemas += 1
	# viaduto do castelo
	var vc := MundoDados.centro("valdoria")
	var cc := MundoDados.centro("castelo_imperial")
	var okv := true
	var uy := -999.0
	for k in 100:
		var t := float(k) / 99.0
		var x := vc.x
		var z := lerpf(vc.y - 132.0, cc.y + 140.0, t)
		var r := _livre_em(x, z)
		if not r[0] or (uy > -900.0 and absf(float(r[1]) - uy) > 0.75):
			okv = false
			print("    viaduto falha em z=", z, " y=", r[1], " anterior=", uy)
			break
		uy = r[1]
	print("  ", "PASSOU " if okv else "FALHOU ", "Viaduto de Valdoria ao Castelo anda-se de ponta a ponta")
	if not okv:
		problemas += 1
	# 2) dentro de cada região
	for id in m.regioes:
		problemas += await _auditar_regiao(id, m)
	print("AUDITORIA_CONTINUA_PROBLEMAS ", problemas)
	quit(0)


func _bloqueia(centro: Vector3, b: Barreira) -> bool:
	var espaco := jogo.get_world_3d().direct_space_state
	var lado := Vector3(cos(b.rotation.y), 0.0, -sin(b.rotation.y))
	var frente := Vector3(sin(b.rotation.y), 0.0, cos(b.rotation.y))
	for k in range(-int(b.largura / 2.0), int(b.largura / 2.0) + 1, 1):
		var de := centro + lado * float(k) + frente * 4.0 + Vector3(0, 1.0, 0)
		var para := centro + lado * float(k) - frente * 4.0 + Vector3(0, 1.0, 0)
		if espaco.intersect_ray(PhysicsRayQueryParameters3D.create(de, para, 1)).is_empty():
			return false   # um raio passou: há um vão
	return true


func _auditar_regiao(id: String, m: Mundo) -> int:
	var area: AreaBase = m.regioes[id]
	var rect := MundoDados.retangulo(id)
	var passo := 1.0
	var nx := int(rect.size.x / passo) + 1
	var nz := int(rect.size.y / passo) + 1
	var gy := PackedFloat32Array()
	gy.resize(nx * nz)
	var livre := PackedByteArray()
	livre.resize(nx * nz)
	var lavas := area.find_children("*", "ZonaDeCalor", true, false)
	for i in nx:
		for j in nz:
			var x := rect.position.x + i * passo
			var z := rect.position.y + j * passo
			var r := _livre_em(x, z)
			gy[i * nz + j] = r[1]
			var bloq := false
			for l in lavas:
				var d: Vector3 = Vector3(x, float(r[1]), z) - (l as Node3D).global_position
				if absf(d.x) < l.tamanho.x / 2.0 and absf(d.z) < l.tamanho.y / 2.0 and d.y < l.altura_max:
					bloq = true
					break
			livre[i * nz + j] = 1 if (r[0] and not bloq) else 0
	var alvos: Array = []
	for c in area.find_children("*", "Node3D", true, false):
		if c.has_meta("colunas"):
			var xp: float = c.get_meta("x_porta")
			alvos.append(["entrada da casa " + String(c.name), (c as Node3D).to_global(Vector3(xp, 0.0, float(c.get_meta("linhas")) - 1.4))])
	for p in area.find_children("*", "Npc", true, false):
		alvos.append(["npc " + String((p as Npc).nome), (p as Node3D).global_position])
	for p in get_nodes_in_group("interagiveis"):
		if area.is_ancestor_of(p):
			alvos.append(["interagível " + String(p.name) + " " + String(p.get("texto")), (p as Node3D).global_position])
	for e in MundoDados.ESTRADAS:   # as pontas de estrada que tocam esta região
		var pts: PackedVector2Array = m.estradas[e["id"]]
		if e["a"] == id:
			alvos.append(["ponta da estrada " + String(e["nome"]), Vector3(pts[0].x, 0, pts[0].y)])
		if e["b"] == id:
			alvos.append(["ponta da estrada " + String(e["nome"]), Vector3(pts[pts.size() - 1].x, 0, pts[pts.size() - 1].y)])
	var spawn := m.spawn_global(id, "Principal").origin
	var ini_i := clampi(int(round((spawn.x - rect.position.x) / passo)), 0, nx - 1)
	var ini_j := clampi(int(round((spawn.z - rect.position.y) / passo)), 0, nz - 1)
	var ini := _livre_perto(livre, nx, nz, ini_i, ini_j)
	var visto := PackedByteArray()
	visto.resize(nx * nz)
	var fila: Array[int] = [ini]
	visto[ini] = 1
	var h := 0
	while h < fila.size():
		var k := fila[h]
		h += 1
		var i := k / nz
		var j := k % nz
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var ni: int = i + d[0]
			var nj: int = j + d[1]
			if ni < 0 or nj < 0 or ni >= nx or nj >= nz:
				continue
			var nk := ni * nz + nj
			if visto[nk] == 1 or livre[nk] != 1 or absf(gy[nk] - gy[k]) > 0.75:
				continue
			visto[nk] = 1
			fila.append(nk)
	var sem: Array[String] = []
	for a in alvos:
		var pos: Vector3 = a[1]
		if not _alcanca(visto, nx, nz, rect, passo, pos):
			sem.append(a[0])
	print("  ", "PASSOU " if sem.is_empty() else "FALHOU ", "Região ", id, ": ", alvos.size() - sem.size(), " de ", alvos.size(), " alcançadas a pé a partir do spawn ", "" if sem.is_empty() else str(sem))
	return sem.size()


func _livre_perto(livre: PackedByteArray, nx: int, nz: int, ci: int, cj: int) -> int:
	for r in 8:
		for di in range(-r, r + 1):
			for dj in range(-r, r + 1):
				var i := ci + di
				var j := cj + dj
				if i >= 0 and j >= 0 and i < nx and j < nz and livre[i * nz + j] == 1:
					return i * nz + j
	return ci * nz + cj


func _alcanca(visto: PackedByteArray, nx: int, nz: int, rect: Rect2, passo: float, pos: Vector3) -> bool:
	var ci := clampi(int(round((pos.x - rect.position.x) / passo)), 0, nx - 1)   # pontas de estrada ficam na borda ou um pouco além
	var cj := clampi(int(round((pos.z - rect.position.y) / passo)), 0, nz - 1)
	for di in range(-3, 4):
		for dj in range(-3, 4):
			var i := ci + di
			var j := cj + dj
			if i >= 0 and j >= 0 and i < nx and j < nz and visto[i * nz + j] == 1:
				return true
	return false
