extends SceneTree
# Auditoria do mundo, sem janela: para cada área confere
#   1) casas: todas têm telhado?  2) alcance: de cada spawn dá para ANDAR (cápsula do jogador, grade de 1 m) até
#   cada portal, NPC, objeto interativo e o centro de cada casa (porta funciona)?
#   godot --headless --path . --script res://tools/auditoria_mundo.gd [-- id_da_area]
const AREAS := ["refugio_do_pinhal", "pomar_alto", "bosque_velado", "acampamento_ruptura", "fronteira_ferrogris", "cratera_ignis", "valdoria", "castelo_imperial"]
const PASSO := 1.0
var _cap := CapsuleShape3D.new()


func _init() -> void:
	_cap.radius = 0.4
	_cap.height = 1.8
	_rodar.call_deferred()


func _rodar() -> void:
	var so: PackedStringArray = OS.get_cmdline_user_args()
	var total := 0
	for id in AREAS:
		if so.size() > 0 and so[0] != id:
			continue
		total += await _auditar(id)
	print("AUDITORIA_TOTAL_PROBLEMAS ", total)
	quit(0)


func _tem_telhado(casa: Node3D) -> bool:
	for n in casa.find_children("*", "Node3D", true, false):
		if String(n.name).begins_with("Roof_") and not String(n.name).begins_with("Roof_Front"):
			return true
	return false


func _auditar(id: String) -> int:
	var area := load("res://scenes/areas/%s.tscn" % id).instantiate() as AreaBase
	root.add_child(area)
	for i in 4:
		await physics_frame
	for p in area.find_children("*", "Portao", true, false):
		(p as Portao).abrir()   # portões trancados por história abrem (a chave/chefe são testados nos testes de marco)
	var furos: Array[String] = []   # paredes por onde o jogador atravessaria: raios a cada 0,5 m, de fora para dentro, a 1 m de altura
	var espaco0 := area.get_world_3d().direct_space_state
	for n in area.find_children("*", "Node3D", true, false):
		if not n.has_meta("colunas"):
			continue
		var cx := float(n.get_meta("colunas"))
		var lz := float(n.get_meta("linhas"))
		var passes := 0
		for lado in 4:
			var comp := (2.0 * cx) if lado < 2 else (2.0 * lz)
			for t in int(comp / 0.5):
				var u := -comp / 2.0 + 0.25 + t * 0.5
				var de: Vector3
				var para: Vector3
				match lado:
					0: de = Vector3(u, 1.0, lz + 1.5); para = Vector3(u, 1.0, lz - 1.0)
					1: de = Vector3(u, 1.0, -lz - 1.5); para = Vector3(u, 1.0, -lz + 1.0)
					2: de = Vector3(cx + 1.5, 1.0, u); para = Vector3(cx - 1.0, 1.0, u)
					_: de = Vector3(-cx - 1.5, 1.0, u); para = Vector3(-cx + 1.0, 1.0, u)
				var rq := PhysicsRayQueryParameters3D.create((n as Node3D).to_global(de), (n as Node3D).to_global(para), 1)
				if espaco0.intersect_ray(rq).is_empty():
					passes += 1
		if passes > 0:
			furos.append("%s: %d raios passaram" % [n.name, passes])
	for cp in area.find_children("ColisaoPorta", "StaticBody3D", true, false):
		(cp as StaticBody3D).collision_layer = 0   # as portas abrem sozinhas quando o jogador chega perto
	await physics_frame
	var problemas := 0
	var casas: Array[Node3D] = []
	for n in area.find_children("*", "Node3D", true, false):
		if n.has_meta("colunas"):
			casas.append(n)
	var sem_teto: Array[String] = []
	for c in casas:
		if not _tem_telhado(c):
			sem_teto.append("%s(%d,%d)" % [c.name, c.get_meta("colunas"), c.get_meta("linhas")])
	var espaco := area.get_world_3d().direct_space_state
	var lavas: Array = area.find_children("*", "ZonaDeCalor", true, false)
	var meio := 158
	var n := int(2 * meio / PASSO) + 1
	var gy := PackedFloat32Array()
	gy.resize(n * n)
	var livre := PackedByteArray()
	livre.resize(n * n)
	for i in n:
		for j in n:
			var x := -meio + i * PASSO
			var z := -meio + j * PASSO
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, 40.0, z), Vector3(x, -5.0, z), 1)
			var h := espaco.intersect_ray(q)
			var k := i * n + j
			if h.is_empty():
				gy[k] = -999.0
				continue
			var y: float = h.position.y
			gy[k] = y
			var bloq := false
			for l in lavas:
				var d: Vector3 = Vector3(x, y, z) - (l as Node3D).global_position
				if absf(d.x) < l.tamanho.x / 2.0 and absf(d.z) < l.tamanho.y / 2.0 and d.y < l.altura_max:
					bloq = true
					break
			if bloq:
				continue
			var sq := PhysicsShapeQueryParameters3D.new()
			sq.shape = _cap
			sq.transform = Transform3D(Basis.IDENTITY, Vector3(x, y + 0.25 + 0.9, z))
			sq.collision_mask = 1 | 4
			livre[k] = 0 if not espaco.intersect_shape(sq, 1).is_empty() else 1
	var relatorio := "AREA %s | casas=%d sem_teto=%s" % [id, casas.size(), str(sem_teto)]
	problemas += sem_teto.size() + furos.size()
	if not furos.is_empty():
		print("  PAREDES COM FURO: ", furos)
	var alvos: Array = []   # [descrição, posição]
	for c in casas:
		var xp: float = c.get_meta("x_porta")
		var mz := float(c.get_meta("linhas"))   # meia profundidade = linhas (módulo 2 m, dividido por 2)
		alvos.append(["entrada da casa " + String(c.name), c.to_global(Vector3(xp, 0.0, mz - 1.4))])
	for p in area.find_children("*", "Portal", true, false):
		alvos.append(["portal " + String((p as Portal).destino), (p as Node3D).global_position])
	for p in area.find_children("*", "Npc", true, false):
		alvos.append(["npc " + String((p as Npc).nome), (p as Node3D).global_position])
	for p in get_nodes_in_group("interagiveis"):
		if area.is_ancestor_of(p):
			alvos.append(["interagivel " + String(p.name) + " " + String(p.get("texto")), (p as Node3D).global_position])
	print(relatorio)
	for sp in area.spawns:
		var t: Transform3D = area.spawns[sp]
		var ci := clampi(int(round((t.origin.x + meio) / PASSO)), 0, n - 1)
		var cj := clampi(int(round((t.origin.z + meio) / PASSO)), 0, n - 1)
		if sp != "Principal" and area.spawns.size() > 2 and sp == "Entrada":
			pass
		var ini := _perto_livre(livre, n, ci, cj)
		var alcance := _bfs(livre, gy, n, ini)
		var tam_reg := 0
		for b in alcance:
			tam_reg += b
		var amostra := ""
		for zz in [-85, -95, -105, -110, -112, -114, -116, -120]:
			var kk: int = (0 + meio) * n + (zz + meio)
			amostra += "z%d:%d/%d(y%.2f) " % [zz, alcance[kk], livre[kk], gy[kk]]
		print("  [amostra] ", amostra)
		print("  [debug] ", sp, " inicio=(", ini / n - meio, ",", ini % n - meio, ") y=", snappedf(gy[ini], 0.01), " celulas=", tam_reg)
		var sem: Array[String] = []
		for a in alvos:
			var pos: Vector3 = a[1]
			if not _alcanca(alcance, livre, n, pos, meio):
				sem.append(a[0])
		print("  spawn ", sp, ": alcançadas ", alvos.size() - sem.size(), " de ", alvos.size(), " | NÃO alcança: ", sem)
		problemas += sem.size()
	area.queue_free()
	await physics_frame
	return problemas


func _perto_livre(livre: PackedByteArray, n: int, ci: int, cj: int) -> int:
	for r in 6:
		for di in range(-r, r + 1):
			for dj in range(-r, r + 1):
				var i := ci + di
				var j := cj + dj
				if i >= 0 and j >= 0 and i < n and j < n and livre[i * n + j] == 1:
					return i * n + j
	return ci * n + cj


func _bfs(livre: PackedByteArray, gy: PackedFloat32Array, n: int, ini: int) -> PackedByteArray:
	var visto := PackedByteArray()
	visto.resize(n * n)
	var fila: Array[int] = [ini]
	visto[ini] = 1
	var h := 0
	while h < fila.size():
		var k := fila[h]
		h += 1
		var i := k / n
		var j := k % n
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var ni: int = i + d[0]
			var nj: int = j + d[1]
			if ni < 0 or nj < 0 or ni >= n or nj >= n:
				continue
			var nk := ni * n + nj
			if visto[nk] == 1 or livre[nk] != 1 or absf(gy[nk] - gy[k]) > 0.75:
				continue
			visto[nk] = 1
			fila.append(nk)
	return visto


func _alcanca(visto: PackedByteArray, livre: PackedByteArray, n: int, pos: Vector3, meio: int) -> bool:
	var ci := int(round((pos.x + meio) / PASSO))
	var cj := int(round((pos.z + meio) / PASSO))
	for di in range(-3, 4):   # perto o bastante para apertar E (3 m)
		for dj in range(-3, 4):
			var i := ci + di
			var j := cj + dj
			if i >= 0 and j >= 0 and i < n and j < n and visto[i * n + j] == 1:
				return true
	return false
