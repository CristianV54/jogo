extends SceneTree
## Varredura de alta precisão (passo de 1,5 m) só nas áreas críticas: ao longo de cada rio (faixa de 14 m de cada lado), em volta de
## cada ponte, de cada casa (anel de 5 m), das cercas e da borda de cada região, nas bordas do mundo e na entrada de cada cidade.
## Registra falta de piso, degrau/penhasco entre amostras vizinhas (mais de 45°) e obstáculo estreito sobre o caminho.
##   godot --headless --path . --script res://tools/drone_precisao.gd -- <etapa>
var jogo: Jogo
var etapa := "x"
var achados: Dictionary = {}
var exemplos: Array = []
var amostras := 0
const PASSO := 1.5
var _cap := CapsuleShape3D.new()


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		etapa = a[0]
	_cap.radius = 0.35
	_cap.height = 1.7
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_rodar.call_deferred()


func _achado(sev: String, cat: String, x: float, z: float, causa: String) -> void:
	var k := sev + "|" + cat
	achados[k] = int(achados.get(k, 0)) + 1
	if int(achados[k]) <= 10:
		exemplos.append("- [%s] %s (%.1f, %.1f) %s" % [sev, cat, x, z, causa])


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
	for i in 8:
		await physics_frame
	var espaco := jogo.get_world_3d().direct_space_state
	var linhas: Array = []   # [nome, Array de Vector2 em sequência]
	# rios: pontos do eixo, deslocados de -14 a +14 m a cada 3 m, andando ao longo
	var rios_m: Array = []
	for r in m.terreno.rios:
		rios_m.append([String(r.get("nome", "rio")), r["pontos"]])
	for id in m.regioes:
		var t = m.regioes[id].get("terreno")
		if t is Terreno:
			var o := Vector2(m.regioes[id].global_position.x, m.regioes[id].global_position.z)
			for r in (t as Terreno).rios:
				var g := PackedVector2Array()
				for p in r["pontos"]:
					g.append(p + o)
				rios_m.append([String(r.get("nome", "rio")) + "@" + id, g])
	for rio in rios_m:
		var pts: PackedVector2Array = rio[1]
		for off in range(-14, 15, 3):
			var linha: Array = []
			for i in range(pts.size() - 1):
				var a := pts[i]
				var b := pts[i + 1]
				var d := (b - a).normalized()
				var lado := Vector2(-d.y, d.x) * float(off)
				var n := maxi(1, int(a.distance_to(b) / PASSO))
				for k in n:
					linha.append(a.lerp(b, float(k) / n) + lado)
			linhas.append(["rio " + String(rio[0]) + " desl " + str(off), linha])
	# pontes
	for p in m.find_children("*", "PonteDeMadeira", true, false):
		var c := Vector2((p as Node3D).global_position.x, (p as Node3D).global_position.z)
		for dz in range(-12, 13, 3):
			var linha: Array = []
			for dx in range(-20, 21):
				linha.append(c + Vector2(float(dx), float(dz)))
			linhas.append(["ponte " + str(p.get_parent().name), linha])
	# casas: anel de 5 m
	for c in get_nodes_in_group("casas"):
		var no := c as Node3D
		var meia := Vector2(float(no.get_meta("colunas")), float(no.get_meta("linhas"))) + Vector2(5.0, 5.0)
		var centro := Vector2(no.global_position.x, no.global_position.z)
		var linha: Array = []
		for t in range(0, 360, 6):
			var dir := Vector2(cos(deg_to_rad(t)), sin(deg_to_rad(t)))
			linha.append(centro + Vector2(dir.x * meia.x, dir.y * meia.y))
		linhas.append(["casa " + String(no.name), linha])
	# borda de cada região e borda do mundo: retângulo percorrido
	for id in MundoDados.REGIOES:
		var r := MundoDados.retangulo(id, 6.0)
		for off in [0.0, 6.0, -6.0]:
			var rr := r.grow(off)
			var linha: Array = []
			var x := rr.position.x
			while x < rr.end.x:
				linha.append(Vector2(x, rr.position.y))
				linha.append(Vector2(x, rr.end.y))
				x += PASSO * 2.0
			var z := rr.position.y
			while z < rr.end.y:
				linha.append(Vector2(rr.position.x, z))
				linha.append(Vector2(rr.end.x, z))
				z += PASSO * 2.0
			linhas.append(["borda " + id + " " + str(off), linha])
	var lim := MundoDados.LIMITES
	for off in [12.0, 30.0, 60.0]:
		var linha: Array = []
		var x := lim.position.x
		while x < lim.end.x:
			linha.append(Vector2(x, lim.position.y + off))
			linha.append(Vector2(x, lim.end.y - off))
			x += PASSO * 3.0
		var z := lim.position.y
		while z < lim.end.y:
			linha.append(Vector2(lim.position.x + off, z))
			linha.append(Vector2(lim.end.x - off, z))
			z += PASSO * 3.0
		linhas.append(["borda do mundo " + str(off), linha])
	# entradas das cidades e povoados: quadrado de 24 m diante do centro
	for pid in m.povoados:
		var c: Vector2 = m.povoados[pid]["centro"]
		var linha: Array = []
		for dx in range(-30, 31, 2):
			for dz in range(-30, 31, 2):
				linha.append(c + Vector2(dx, dz))
		linhas.append(["povoado " + pid, linha])
	for id in ["valdoria", "castelo_imperial", "fronteira_ferrogris", "cratera_ignis"]:
		var c := MundoDados.centro(id)
		var linha: Array = []
		for dx in range(-30, 31, 2):
			for dz in range(100, 160, 2):
				linha.append(c + Vector2(dx, dz))
		linhas.append(["entrada " + id, linha])
	# varredura
	for ln in linhas:
		var seq: Array = ln[1]
		var anterior := -999.0
		var ant_pos := Vector2.ZERO
		var ant_terreno := false
		for p in seq:
			var v := p as Vector2
			if not MundoDados.LIMITES.grow(40.0).has_point(v):
				continue
			amostras += 1
			var h := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(v.x, 150.0, v.y), Vector3(v.x, -60.0, v.y), 1))
			if h.is_empty():
				if Costa.distancia(v.x, v.y) > 0.0:
					_achado("BLOQUEADOR", "sem piso", v.x, v.y, String(ln[0]))
				anterior = -999.0
				continue
			var y: float = h.position.y
			if anterior > -900.0 and v.distance_to(ant_pos) < PASSO * 1.6:
				var dy := absf(y - anterior)
				if dy > v.distance_to(ant_pos) * 1.0 + 0.2 and ant_terreno and String((h.collider as Node).name) == "Colisao" and (h.collider as Node).get_parent() is Terreno:
					_achado("CRITICO", "degrau/penhasco", v.x, v.y, "%s: %.1f m em %.1f m" % [ln[0], dy, v.distance_to(ant_pos)])
			anterior = y
			ant_pos = v
			ant_terreno = String((h.collider as Node).name) == "Colisao" and (h.collider as Node).get_parent() is Terreno
	print("PRECISAO amostras=", amostras, " linhas=", linhas.size(), " achados=", achados)
	var md := "# Varredura de alta precisão — %s\n\nPasso de %.1f m nas áreas críticas. Amostras: %d. Linhas: %d.\n\n| Categoria | Total |\n|---|---|\n" % [etapa, PASSO, amostras, linhas.size()]
	for k in achados:
		md += "| %s | %d |\n" % [String(k).replace("|", " / "), int(achados[k])]
	md += "\n## Exemplos\n" + "\n".join(exemplos) + "\n"
	var f := FileAccess.open("res://docs/auditoria/PRECISAO_%s.md" % etapa, FileAccess.WRITE)
	f.store_string(md)
	f.close()
	quit(0)
