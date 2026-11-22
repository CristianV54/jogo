extends SceneTree
## Varredura completa do mundo, sem o Torin: grade de raios sobre todo o mapa, água contra terreno, começo e fim de cada rio,
## pontas das pontes, seres no chão e casas completas. Escreve docs/auditoria/RELATORIO_<etapa>.md e .json com coordenada,
## severidade (BLOQUEADOR, CRITICO, VISUAL, MENOR) e causa provável.
##   godot --headless --path . --script res://tools/drone_auditoria.gd -- <etapa>
var jogo: Jogo
var achados: Array = []
var etapa := "x"
var _contagem: Dictionary = {}   # categoria -> total (o relatório lista no máximo 12 exemplos por categoria)
const PASSO := 6.0
const MAX_EXEMPLOS := 12


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		etapa = a[0]
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _achado(sev: String, cat: String, x: float, z: float, objeto: String, causa: String) -> void:
	var k := sev + "|" + cat
	_contagem[k] = int(_contagem.get(k, 0)) + 1
	if int(_contagem[k]) <= MAX_EXEMPLOS:
		achados.append({"severidade": sev, "categoria": cat, "x": snappedf(x, 0.1), "z": snappedf(z, 0.1), "objeto": objeto, "causa": causa})


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
	var espaco := jogo.get_world_3d().direct_space_state
	_grade(m, espaco)
	_agua(m)
	_rios_pontas(m)
	_pontes(m, espaco)
	_seres(m, espaco)
	_casas(m)
	_escrever()
	quit(0)


## 1) Grade de raios verticais sobre todo o mapa jogável.
func _grade(m: Mundo, espaco: PhysicsDirectSpaceState3D) -> void:
	var lim := MundoDados.LIMITES
	var nx := int(lim.size.x / PASSO) + 1
	var nz := int(lim.size.y / PASSO) + 1
	var alturas := PackedFloat32Array()
	alturas.resize(nx * nz)
	var tipo := PackedByteArray()
	tipo.resize(nx * nz)   # 0 sem chão, 1 chão do terreno, 2 outro (pedra, telhado, ponte)
	var total := 0
	for i in nx:
		for j in nz:
			var x := lim.position.x + i * PASSO + 1.3
			var z := lim.position.y + j * PASSO + 0.9
			var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 150.0, z), Vector3(x, -60.0, z), 1))
			total += 1
			if h.is_empty():
				alturas[i * nz + j] = -999.0
				if Costa.distancia(x, z) > 0.0:
					_achado("BLOQUEADOR", "sem piso em terra", x, z, "", "nenhum colisor sob o ponto: cai no vazio")
				continue
			alturas[i * nz + j] = h.position.y
			var nome := String((h.collider as Node).name)
			tipo[i * nz + j] = 1 if nome == "Colisao" else 2
	var ingremes := 0
	for i in range(1, nx - 1):
		for j in range(1, nz - 1):
			var k := i * nz + j
			if tipo[k] != 1:
				continue
			for d in [[1, 0], [0, 1]]:
				var k2: int = (i + d[0]) * nz + (j + d[1])
				if tipo[k2] != 1 or alturas[k] < -900.0 or alturas[k2] < -900.0:
					continue
				var dy := absf(alturas[k] - alturas[k2])
				if dy > 4.5:
					_achado("CRITICO", "penhasco no terreno", lim.position.x + i * PASSO, lim.position.y + j * PASSO, "terreno", "desnível de %.1f m em %d m: o jogador não sobe nem desce" % [dy, int(PASSO)])
	print("GRADE ", total, " células, ", nx, "x", nz)


## 2) A água de cada rio contra o terreno em volta: a faixa de água não pode ficar no ar sobre chão mais baixo.
func _agua(m: Mundo) -> void:
	var fontes: Array = [[m.terreno, "mundo", Vector2.ZERO]]
	for id in m.regioes:
		var t = m.regioes[id].get("terreno")
		if t is Terreno:
			fontes.append([t, id, Vector2(m.regioes[id].global_position.x, m.regioes[id].global_position.z)])
	for f in fontes:
		var ter: Terreno = f[0]
		for r in ter.rios:
			if not r.get("agua", true):
				continue
			var pts: PackedVector2Array = r["pontos"]
			var meia: float = float(r["largura"]) / 2.0 + 5.0
			var flutuando := 0
			var amostras := 0
			var pior := 0.0
			var onde := Vector2.ZERO
			for i in range(0, pts.size() - 1):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[i + 1]
				var dir := (b - a).normalized()
				var lado := Vector2(-dir.y, dir.x)
				var y_agua: float = ter._altura_base(a.x, a.y) - 0.55
				for o in [-1.0, -0.6, -0.3, 0.3, 0.6, 1.0]:
					var p: Vector2 = a + lado * (o * meia)
					amostras += 1
					var h: float = ter.altura_em(p.x, p.y)
					var falta: float = y_agua - h
					if falta > 0.35:
						flutuando += 1
						if falta > pior:
							pior = falta
							onde = p + f[2]
			if flutuando > 0:
				var sev := "CRITICO" if pior > 1.5 else "VISUAL"
				_achado(sev, "água no ar sobre chão mais baixo", onde.x, onde.y, "%s/%s" % [f[1], r.get("nome", "rio")], "%d de %d amostras; pior %.1f m abaixo da faixa de água" % [flutuando, amostras, pior])


## 3) Começo e fim de cada trecho de rio: precisa terminar em outro rio, no mar, na borda de uma região com rio ou numa nascente.
func _rios_pontas(m: Mundo) -> void:
	var todos: Array = []   # [nome, pontos globais]
	for r in m.terreno.rios:
		todos.append([String(r.get("nome", "rio")), r["pontos"], true])
	for id in m.regioes:
		var t = m.regioes[id].get("terreno")
		if t is Terreno:
			var o := Vector2(m.regioes[id].global_position.x, m.regioes[id].global_position.z)
			for r in (t as Terreno).rios:
				var g := PackedVector2Array()
				for p in r["pontos"]:
					g.append(p + o)
				todos.append([String(r.get("nome", "rio")) + "@" + String(id), g, false])
	for r in m.terreno.rios:
		for trecho in m.terreno._trechos_fora_das_areas(r["pontos"]):
			for fim in [trecho[0], trecho[trecho.size() - 1]]:
				if _ponta_ok(fim, trecho, todos, r):
					continue
				_achado("CRITICO", "rio sem começo ou fim", fim.x, fim.y, String(r.get("nome", "rio")), "a ponta não encosta em outro rio, no mar nem numa nascente")


func _ponta_ok(p: Vector2, propria: PackedVector2Array, todos: Array, r: Dictionary) -> bool:
	if Costa.distancia(p.x, p.y) < 14.0:
		return true   # desemboca no mar
	if bool(r.get("nascente", false)) and p.distance_to(propria[0]) < 1.0:
		return true
	for o in todos:
		var pts: PackedVector2Array = o[1]
		if pts == propria:
			continue
		for i in range(pts.size() - 1):
			var ab := pts[i + 1] - pts[i]
			var t := clampf((p - pts[i]).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
			if p.distance_to(pts[i] + ab * t) < 14.0:
				return true
	return false


## 4) Pontes: as duas pontas precisam encostar no chão.
func _pontes(m: Mundo, espaco: PhysicsDirectSpaceState3D) -> void:
	for p in m.find_children("*", "PonteDeMadeira", true, false):
		var caixas: Array = []
		for c in p.find_children("*", "CollisionShape3D", true, false):
			if (c as CollisionShape3D).shape is BoxShape3D and ((c as CollisionShape3D).shape as BoxShape3D).size.z > 1.5:
				caixas.append(c)
		if caixas.is_empty():
			continue
		var c: CollisionShape3D = caixas[0]
		var comp: float = ((c.shape as BoxShape3D).size.z)
		for sinal in [-1.0, 1.0]:
			var ponta: Vector3 = c.global_transform * Vector3(0.0, 0.0, sinal * comp / 2.0)
			var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(ponta + Vector3(0, 2.0, 0), ponta + Vector3(0, -6.0, 0), 1))
			var chao: float = h.position.y if not h.is_empty() else -999.0
			if absf(ponta.y - chao) > 1.0:
				_achado("CRITICO", "ponte termina no ar", ponta.x, ponta.z, String(p.get_parent().name), "ponta a %.1f m do chão" % (ponta.y - chao))


## 5) Seres (NPC, bicho, inimigo): no chão, sem estar dentro de parede.
func _seres(m: Mundo, espaco: PhysicsDirectSpaceState3D) -> void:
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.4
	for grupo in ["npcs", "animais", "inimigos"]:
		for e in get_nodes_in_group(grupo):
			var n3 := e as Node3D
			if n3 == null or not n3.is_inside_tree():
				continue
			var p := n3.global_position
			var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 6.0, 0), p + Vector3(0, -12.0, 0), 1))
			var chao: float = h.position.y if not h.is_empty() else -999.0
			if absf(p.y - chao) > 0.8:
				_achado("CRITICO", "ser flutuando ou enterrado", p.x, p.z, String(n3.name), "a %.1f m do chão" % (p.y - chao))
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = cap
			q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 1.0, 0))
			q.collision_mask = 1
			for r in espaco.intersect_shape(q, 4):
				var nome := String((r.collider as Node).name)
				if r.collider is StaticBody3D and nome != "Colisao" and nome != "ColisaoPorta":
					_achado("CRITICO", "ser dentro de parede", p.x, p.z, String(n3.name), "dentro de " + str((r.collider as Node).get_path()))
					break


## 6) Casas: telhado, porta e colisão.
func _casas(m: Mundo) -> void:
	for c in get_nodes_in_group("casas"):
		var casa := c as Node3D
		var telhado := false
		var porta := false
		for f in casa.get_children():
			if f.has_meta("peca"):
				var nm: String = f.get_meta("peca")
				if nm.begins_with("Roof_") and not nm.begins_with("Roof_Front"):
					telhado = true
				if nm.contains("Door"):
					porta = true
		if not telhado:
			_achado("CRITICO", "casa sem telhado", casa.global_position.x, casa.global_position.z, String(casa.name), "sem peça de telhado")
		if not porta:
			_achado("CRITICO", "casa sem porta", casa.global_position.x, casa.global_position.z, String(casa.name), "sem peça de porta")
		if casa.get_node_or_null("Colisao") == null:
			_achado("CRITICO", "casa sem colisão", casa.global_position.x, casa.global_position.z, String(casa.name), "sem corpo de colisão")


func _escrever() -> void:
	var por_sev := {"BLOQUEADOR": 0, "CRITICO": 0, "VISUAL": 0, "MENOR": 0}
	for k in _contagem:
		por_sev[String(k).split("|")[0]] += int(_contagem[k])
	var md := "# Relatório de auditoria — %s\n\nGerado por `tools/drone_auditoria.gd` (varredura sem o Torin).\n\n" % etapa
	md += "| Severidade | Total |\n|---|---|\n"
	for s in por_sev:
		md += "| %s | %d |\n" % [s, por_sev[s]]
	md += "\n## Por categoria (total, e até %d exemplos com coordenada)\n" % MAX_EXEMPLOS
	var chaves := _contagem.keys()
	chaves.sort()
	for k in chaves:
		md += "\n### %s: %d\n" % [String(k).replace("|", " / "), int(_contagem[k])]
		for a in achados:
			if a["severidade"] + "|" + a["categoria"] == k:
				md += "- (%s, %s) `%s` %s\n" % [a["x"], a["z"], a["objeto"], a["causa"]]
	DirAccess.make_dir_recursive_absolute("res://docs/auditoria")
	var f := FileAccess.open("res://docs/auditoria/RELATORIO_%s.md" % etapa, FileAccess.WRITE)
	f.store_string(md)
	f.close()
	var j := FileAccess.open("res://docs/auditoria/RELATORIO_%s.json" % etapa, FileAccess.WRITE)
	j.store_string(JSON.stringify({"etapa": etapa, "por_severidade": por_sev, "contagem": _contagem, "exemplos": achados}, "  "))
	j.close()
	print("AUDITORIA_DRONE ", etapa, " ", por_sev)
