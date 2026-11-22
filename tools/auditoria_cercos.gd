extends SceneTree
# Auditoria de cercos do mundo aberto, sem janela. Anda numa grade de 4 m (cápsula do jogador; ligações conferidas com raio):
#   1) com as barreiras FECHADAS, do Refúgio só se alcança a bacia do sul e o Pomar: Bosque, Acampamento, Fortaleza, Cratera,
#      Valdoria e Castelo ficam trancados (ninguém contorna uma barreira pelo mato);
#   2) com as barreiras ABERTAS, o Torin chega de pé ao ponto de partida de TODAS as regiões e a todos os povoados.
#   godot --headless --path . --script res://tools/auditoria_cercos.gd
var jogo: Jogo
var _cap := CapsuleShape3D.new()
const PASSO := 4.0


func _init() -> void:
	_cap.radius = 0.4
	_cap.height = 1.8
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _rodar() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jogo.jogador.global_position = Vector3(9000.0, 500.0, 9000.0)
	jogo.jogador.set_physics_process(false)
	for i in 6:
		await physics_frame
	var m: Mundo = jogo.mundo
	m.set_process(false)   # tudo ligado: o mundo só liga a colisão do que está perto do jogador
	for id in m.regioes:
		m._ligar(m.regioes[id], true)
	for pid in m.povoados:
		if m.povoados[pid].has("no"):
			m._ligar(m.povoados[pid]["no"], true)
	for i in 4:
		await physics_frame
	for p in m.find_children("*", "Portao", true, false):
		if not (p.get_parent() is Barreira):
			(p as Portao).abrir()   # portões das áreas (a fortaleza abre ao vencer o chefe)
	for cp in m.find_children("ColisaoPorta", "StaticBody3D", true, false):
		(cp as StaticBody3D).collision_layer = 0
	await physics_frame
	var lim := MundoDados.LIMITES
	var nx := int(lim.size.x / PASSO) + 1
	var nz := int(lim.size.y / PASSO) + 1
	var espaco := jogo.get_world_3d().direct_space_state
	var gy := PackedFloat32Array()
	gy.resize(nx * nz)
	var livre := PackedByteArray()
	livre.resize(nx * nz)
	for i in nx:
		for j in nz:
			var x := lim.position.x + i * PASSO
			var z := lim.position.y + j * PASSO
			var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 80.0, z), Vector3(x, -30.0, z), 1))
			if h.is_empty():
				gy[i * nz + j] = -999.0
				continue
			var y: float = h.position.y
			gy[i * nz + j] = y
			var sq := PhysicsShapeQueryParameters3D.new()
			sq.shape = _cap
			sq.transform = Transform3D(Basis.IDENTITY, Vector3(x, y + 0.25 + 0.9, z))
			sq.collision_mask = 5
			var ok := 1
			for r in espaco.intersect_shape(sq, 8):
				if r.collider is StaticBody3D:
					ok = 0
					break
			livre[i * nz + j] = ok
	var problemas := 0
	var inicio := m.spawn_global("refugio_do_pinhal", "Principal").origin
	# 1) barreiras fechadas
	var fechado := _bfs(espaco, gy, livre, nx, nz, lim, inicio)
	var trancadas := ["bosque_velado", "acampamento_ruptura", "fronteira_ferrogris", "cratera_ignis", "valdoria", "castelo_imperial"]
	var abertas := ["refugio_do_pinhal", "pomar_alto"]
	for id in trancadas:
		var c := MundoDados.centro(id)
		var vazou := _alcanca(fechado, nx, nz, lim, c)
		print("  ", "PASSOU " if not vazou else "FALHOU ", "Com as barreiras fechadas ", id, " NÃO se alcança a pé")
		if vazou:
			problemas += 1
	for id in abertas:
		var ok := _alcanca(fechado, nx, nz, lim, MundoDados.centro(id))
		print("  ", "PASSOU " if ok else "FALHOU ", "Com as barreiras fechadas ", id, " se alcança a pé")
		if not ok:
			problemas += 1
	var livres_sul := ["beira_rio", "rio_claro", "pescador", "pedras_altas", "posto_de_caca"]
	for pid in livres_sul:
		var ok := _alcanca(fechado, nx, nz, lim, m.povoados[pid]["centro"])
		print("  ", "PASSOU " if ok else "FALHOU ", "Povoado ", pid, " alcançável do Refúgio")
		if not ok:
			problemas += 1
	# 2) barreiras abertas
	for id in m.barreiras:
		(m.barreiras[id] as Barreira)._abrir()
	await create_timer(0.3).timeout
	await physics_frame
	for i in nx:   # as barreiras abertas deixam de ser parede: refaz a grade só perto delas
		for j in nz:
			pass
	var aberto := _bfs(espaco, gy, _regrade(espaco, gy, nx, nz, lim), nx, nz, lim, inicio)
	for id in MundoDados.REGIOES:
		var c: Vector2 = MundoDados.centro(id)
		var ok := _alcanca(aberto, nx, nz, lim, c)
		print("  ", "PASSOU " if ok else "FALHOU ", "Com as barreiras abertas ", id, " se alcança a pé")
		if not ok:
			problemas += 1
	var sem: Array[String] = []
	for pid in m.povoados:
		if not _alcanca(aberto, nx, nz, lim, m.povoados[pid]["centro"]):
			sem.append(String(pid))
	print("  ", "PASSOU " if sem.is_empty() else "FALHOU ", "Com as barreiras abertas todos os ", m.povoados.size(), " povoados se alcançam a pé ", sem)
	problemas += sem.size()
	var fino := ""
	for k in 17:   # perfil fino do topo da escadaria de Valdoria, de meio em meio metro
		var zz := -1982.0 - k * 0.5
		var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(584.0, 80.0, zz), Vector3(584.0, -30.0, zz), 1))
		fino += "%.1f " % (h.position.y if not h.is_empty() else -99.0)
	print("PERFIL_FINO z -1982 a -1990: ", fino)
	print("AUDITORIA_CERCOS_PROBLEMAS ", problemas)
	quit(0)


func _regrade(espaco: PhysicsDirectSpaceState3D, gy: PackedFloat32Array, nx: int, nz: int, lim: Rect2) -> PackedByteArray:
	var livre := PackedByteArray()
	livre.resize(nx * nz)
	for i in nx:
		for j in nz:
			var y := gy[i * nz + j]
			if y < -900.0:
				continue
			var sq := PhysicsShapeQueryParameters3D.new()
			sq.shape = _cap
			sq.transform = Transform3D(Basis.IDENTITY, Vector3(lim.position.x + i * PASSO, y + 1.15, lim.position.y + j * PASSO))
			sq.collision_mask = 5
			var ok := 1
			for r in espaco.intersect_shape(sq, 8):
				if r.collider is StaticBody3D:
					ok = 0
					break
			livre[i * nz + j] = ok
	return livre


func _bfs(espaco: PhysicsDirectSpaceState3D, gy: PackedFloat32Array, livre: PackedByteArray, nx: int, nz: int, lim: Rect2, inicio: Vector3) -> PackedByteArray:
	var visto := PackedByteArray()
	visto.resize(nx * nz)
	var ci := clampi(int(round((inicio.x - lim.position.x) / PASSO)), 0, nx - 1)
	var cj := clampi(int(round((inicio.z - lim.position.y) / PASSO)), 0, nz - 1)
	var ini := ci * nz + cj
	for r in 6:
		var achou := false
		for di in range(-r, r + 1):
			for dj in range(-r, r + 1):
				var k := (ci + di) * nz + (cj + dj)
				if k >= 0 and k < nx * nz and livre[k] == 1:
					ini = k
					achou = true
					break
			if achou:
				break
		if achou:
			break
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
			if visto[nk] == 1 or livre[nk] != 1 or absf(gy[nk] - gy[k]) > 1.6:
				continue
			var a := Vector3(lim.position.x + i * PASSO, gy[k] + 1.0, lim.position.y + j * PASSO)   # a ligação também não pode atravessar parede fina
			var b := Vector3(lim.position.x + ni * PASSO, gy[nk] + 1.0, lim.position.y + nj * PASSO)
			var q := PhysicsRayQueryParameters3D.create(a, b, 1)
			var hit := espaco.intersect_ray(q)
			if not hit.is_empty() and hit.collider is StaticBody3D:
				continue
			visto[nk] = 1
			fila.append(nk)
	return visto


func _alcanca(visto: PackedByteArray, nx: int, nz: int, lim: Rect2, p: Vector2) -> bool:
	var ci := clampi(int(round((p.x - lim.position.x) / PASSO)), 0, nx - 1)
	var cj := clampi(int(round((p.y - lim.position.y) / PASSO)), 0, nz - 1)
	for di in range(-4, 5):
		for dj in range(-4, 5):
			var i := ci + di
			var j := cj + dj
			if i >= 0 and j >= 0 and i < nx and j < nz and visto[i * nz + j] == 1:
				return true
	return false


func _diag(espaco: PhysicsDirectSpaceState3D, gy: PackedFloat32Array, visto: PackedByteArray, nx: int, nz: int, lim: Rect2, alvo: Vector2) -> void:
	var melhor := 1e9
	var bk := -1
	for k in nx * nz:
		if visto[k] != 1:
			continue
		var p := Vector2(lim.position.x + (k / nz) * PASSO, lim.position.y + (k % nz) * PASSO)
		var d := p.distance_to(alvo)
		if d < melhor:
			melhor = d
			bk = k
	var bp := Vector2(lim.position.x + (bk / nz) * PASSO, lim.position.y + (bk % nz) * PASSO)
	print("DIAG alvo ", alvo, " mais perto alcançado ", bp, " a ", snappedf(melhor, 0.1), " m; y=", gy[bk])
	var dir: Vector2 = (alvo - bp).normalized()
	for passo in [1, 2, 3]:
		var q: Vector2 = bp + dir * PASSO * float(passo)
		var i := int(round((q.x - lim.position.x) / PASSO))
		var j := int(round((q.y - lim.position.y) / PASSO))
		var y := gy[i * nz + j]
		var sq := PhysicsShapeQueryParameters3D.new()
		sq.shape = _cap
		sq.transform = Transform3D(Basis.IDENTITY, Vector3(q.x, y + 1.15, q.y))
		sq.collision_mask = 5
		var nomes: Array[String] = []
		for r in espaco.intersect_shape(sq, 8):
			nomes.append(str((r.collider as Node).get_path()))
		print("   passo ", passo, " ", q, " y=", snappedf(y, 0.1), " colisores ", nomes)
