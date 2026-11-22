class_name Mundo
extends Node3D
## O mundo contínuo: as 8 regiões já construídas postas lado a lado, ligadas por estradas, com rios, pontes, florestas,
## barreiras de história, povoados e fazendas no caminho. Sem portais: dá para ir de qualquer região a outra a pé.
## As áreas continuam com as próprias coordenadas locais (cada uma é um nó posto na sua posição do mundo).

signal progresso(texto: String)

static var ativo := false
static var instancia: Mundo

var regioes: Dictionary = {}       # id -> AreaBase
var estilos: Dictionary = {}       # id -> estilo do ar (neblina, sol...), tirado do ambiente de cada área
var terreno: TerrenoMundo
var estradas: Dictionary = {}      # id -> PackedVector2Array (curva do eixo)
var barreiras: Dictionary = {}     # id -> Barreira
var condicoes: Dictionary = {}     # id -> Callable (o Jogo diz quando cada barreira abre)
var povoados: Dictionary = {}      # id -> Dictionary (centro, nome, raio, tipo, no)
var fauna: FaunaDoMundo
var _paredes: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _t_atividade := 0.0
const RAIO_ATIVO := 230.0    # regiões e povoados mais longe que isto ficam parados e invisíveis (fogueiras, gente e bichos custam CPU)
const RAIO_FAUNA := 200.0
const RAIO_ANIMACAO := 60.0  # gente e bichos mais longe que isto não animam nem aparecem


# ---------------------------------------------------------------- ajudas para as áreas

## A área pede, antes de gerar o terreno, que ele se misture com o chão do mundo nas bordas.
static func preparar_terreno(t: Terreno, area: Node3D) -> void:
	if not ativo:
		return
	t.origem = Vector2(area.position.x, area.position.z)
	t.externa = instancia.terreno.altura_em
	t.cor_externa = instancia.terreno.cor_do_mundo


## Paredes invisíveis na borda do mapa de uma área. No mundo contínuo elas têm vãos onde as estradas entram.
static func paredes_de_borda(area: Node3D, tam: float, corpo: StaticBody3D) -> void:
	var meio := tam / 2.0
	var vaos := {"N": [], "S": [], "L": [], "O": []}   # lado -> [[centro, largura]]
	if ativo:
		vaos = instancia._vaos_da_area(String(area.name), meio)
	for lado in ["N", "S", "L", "O"]:
		var lista: Array = vaos[lado]
		lista.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var ini := -meio
		var trechos: Array = []
		for v in lista:
			trechos.append([ini, float(v[0]) - float(v[1]) / 2.0])
			ini = float(v[0]) + float(v[1]) / 2.0
		trechos.append([ini, meio])
		for t in trechos:
			var comp: float = t[1] - t[0]
			if comp < 1.0:
				continue
			var meio_t: float = (t[0] + t[1]) / 2.0
			var cs := CollisionShape3D.new()
			var caixa := BoxShape3D.new()
			var pos := Vector3.ZERO
			match lado:
				"N":
					caixa.size = Vector3(comp, 16.0, 2.0)
					pos = Vector3(meio_t, 8.0, -meio)
				"S":
					caixa.size = Vector3(comp, 16.0, 2.0)
					pos = Vector3(meio_t, 8.0, meio)
				"L":
					caixa.size = Vector3(2.0, 16.0, comp)
					pos = Vector3(meio, 8.0, meio_t)
				_:
					caixa.size = Vector3(2.0, 16.0, comp)
					pos = Vector3(-meio, 8.0, meio_t)
			cs.shape = caixa
			cs.position = pos
			corpo.add_child(cs)


func _vaos_da_area(id: String, meio: float) -> Dictionary:
	var vaos := {"N": [], "S": [], "L": [], "O": []}
	var pontas: Array = []   # pontos do mundo onde uma estrada toca esta área
	for e in MundoDados.ESTRADAS:
		var curva: PackedVector2Array = estradas.get(e["id"], PackedVector2Array())
		if curva.is_empty():
			continue
		if e["a"] == id:
			pontas.append([curva[0], float(e["meia"])])
		if e["b"] == id:
			pontas.append([curva[curva.size() - 1], float(e["meia"])])
	if id == "valdoria":
		pontas.append([MundoDados.centro(id) + Vector2(0, -meio), 20.0])   # a escadaria leva ao viaduto do castelo
	if id == "castelo_imperial":
		pontas.append([MundoDados.centro(id) + Vector2(0, meio), 20.0])
	var c := MundoDados.centro(id)
	for p in pontas:
		var l: Vector2 = p[0] - c
		var largura: float = maxf(26.0, float(p[1]) * 2.0 + 6.0)
		if absf(absf(l.y) - meio) < absf(absf(l.x) - meio):
			vaos["N" if l.y < 0.0 else "S"].append([l.x, largura])
		else:
			vaos["O" if l.x < 0.0 else "L"].append([l.y, largura])
	return vaos


# ---------------------------------------------------------------- construção

func construir() -> void:
	ativo = true
	instancia = self
	_rng.seed = 2026
	_planejar()
	for id in MundoDados.REGIOES:
		progresso.emit("Erguendo %s..." % MundoDados.REGIOES[id]["nome"])
		var area := (load(MundoDados.REGIOES[id]["cena"]) as PackedScene).instantiate() as AreaBase
		area.name = id
		var c := MundoDados.centro(id)
		area.position = Vector3(c.x, 0.0, c.y)
		add_child(area)
		regioes[id] = area
		_colher_estilo(id, area)
		await get_tree().process_frame
	progresso.emit("Moldando o chão entre as regiões...")
	await get_tree().process_frame
	terreno.gerar()
	add_child(terreno)
	_paredes = StaticBody3D.new()
	_paredes.name = "ParedesDosCorredores"
	add_child(_paredes)
	progresso.emit("Abrindo estradas, pontes e corredores...")
	await get_tree().process_frame
	_pontes()
	_corredores()
	_viaduto()
	_barreiras()
	progresso.emit("Plantando florestas...")
	await get_tree().process_frame
	_floresta()
	_horizonte()
	progresso.emit("Erguendo povoados e fazendas...")
	await get_tree().process_frame
	for id in povoados:
		var pv := Povoado.new()
		pv.mundo = self
		pv.dados = povoados[id]
		add_child(pv)
		pv.montar()
		povoados[id]["no"] = pv
		var cp: Vector2 = povoados[id]["centro"]
		NavegacaoLocal.assar(pv, Vector3(cp.x, terreno.altura_em(cp.x, cp.y), cp.y), Vector2(1, 1) * float(povoados[id]["raio"]) * 0.65, true)
	progresso.emit("Traçando os caminhos da gente...")
	await get_tree().process_frame
	NavegacaoLocal.assar(regioes["refugio_do_pinhal"], Vector3(0, 0, 0), Vector2(48, 48), false)
	var vcen := MundoDados.centro("valdoria")
	NavegacaoLocal.assar(regioes["valdoria"], Vector3(vcen.x, 0, vcen.y), Vector2(80, 105), false)
	progresso.emit("Soltando os bichos...")
	await get_tree().process_frame
	fauna = FaunaDoMundo.new()
	fauna.mundo = self
	add_child(fauna)
	fauna.povoar()
	progresso.emit("Pronto.")


func _planejar() -> void:
	terreno = TerrenoMundo.new()
	terreno.name = "ChaoDoMundo"
	terreno.limites = MundoDados.LIMITES
	terreno.passo = 8.0
	terreno.semente = 4242
	for id in MundoDados.REGIOES:
		terreno.retangulos.append(MundoDados.retangulo(id))
	for e in MundoDados.ESTRADAS:
		var curva := Terreno.curva(e["pontos"], 4.0)
		estradas[e["id"]] = curva
		terreno.estradas_mundo.append(curva)
	var rios: Array = []
	for r in MundoDados.RIOS:
		rios.append({"pontos": Terreno.curva(r["pontos"], 4.0), "largura": r["largura"], "margem": r["margem"], "fundo": r["fundo"], "agua": true})
	terreno.rios = rios
	terreno.preparar()
	for p in MundoDados.POVOADOS:   # onde fica cada povoado: ao lado da estrada, do lado indicado
		var s := float(p["t"]) * comprimento_da_estrada(p["estrada"])
		var par := ponto_na_estrada(p["estrada"], s)
		var dir: Vector2 = par[1]
		var esq := Vector2(-dir.y, dir.x)
		var centro: Vector2 = par[0] + esq * float(p["lado"]) * float(p["raio"]) * 0.55
		terreno.planos.append(Vector3(centro.x, centro.y, float(p["raio"]) * 0.7))   # o chão do povoado fica nivelado
		povoados[p["id"]] = {"id": p["id"], "lado": p["lado"], "centro": centro, "nome": p["nome"], "raio": p["raio"], "tipo": p["tipo"], "estrada": p["estrada"], "dir": dir, "ponto_da_estrada": par[0]}


## Lê o ar da região (névoa, sol, céu) do ambiente que a área criou e tira o ambiente dela: quem manda no céu é o Clima.
func _colher_estilo(id: String, a: AreaBase) -> void:
	var amb := a.get_node_or_null("Ambiente") as WorldEnvironment
	var sol := a.get_node_or_null("Sol") as DirectionalLight3D
	var estilo := {}
	if amb and amb.environment:
		var e := amb.environment
		estilo["neblina"] = e.fog_light_color
		estilo["densidade"] = e.fog_density
		estilo["ambiente"] = e.ambient_light_energy
		var ceu: ProceduralSkyMaterial = null
		if e.sky:
			ceu = e.sky.sky_material as ProceduralSkyMaterial
		if ceu:
			estilo["topo"] = ceu.sky_top_color
			estilo["horizonte"] = ceu.sky_horizon_color
	if sol:
		estilo["sol"] = sol.light_color
		estilo["energia"] = sol.light_energy
	estilos[id] = estilo
	if amb:
		a.remove_child(amb)
		amb.queue_free()
	if sol:
		a.remove_child(sol)
		sol.queue_free()


# ---------------------------------------------------------------- só o que está perto roda

func _process(delta: float) -> void:
	_t_atividade -= delta
	if _t_atividade <= 0.0:
		_t_atividade = 0.5
		atualizar_atividade()


## Liga o que está perto do jogador e desliga o que está longe: áreas inteiras, povoados e bichos soltos. O mundo todo
## ligado ao mesmo tempo (centenas de fogueiras com partículas, gente e bichos) deixava o jogo a 6 quadros por segundo.
func atualizar_atividade() -> void:
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog == null:
		return
	var p := Vector2(jog.global_position.x, jog.global_position.z)
	for id in regioes:
		var r := MundoDados.retangulo(id)
		var dx := maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
		var dz := maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
		_ligar(regioes[id], sqrt(dx * dx + dz * dz) < RAIO_ATIVO)
	for pid in povoados:
		if povoados[pid].has("no"):
			_ligar(povoados[pid]["no"], p.distance_to(povoados[pid]["centro"]) < RAIO_ATIVO)
	if fauna:
		for c in fauna.get_children():
			var n3 := c as Node3D
			if n3:
				_ligar(n3, p.distance_to(Vector2(n3.global_position.x, n3.global_position.z)) < RAIO_FAUNA)


	# Animações só perto: no renderizador de compatibilidade cada malha com esqueleto sincroniza com a GPU a cada quadro
	# (~1 ms cada no Mac), então gente e bichos longe ficam parados e escondidos.
	for grupo in ["npcs", "inimigos", "animais"]:
		for e in get_tree().get_nodes_in_group(grupo):
			var n3 := e as Node3D
			if n3 == null or not n3.is_inside_tree():
				continue
			var d := p.distance_to(Vector2(n3.global_position.x, n3.global_position.z))
			var perto: bool = d < (RAIO_ANIMACAO + 20.0 if bool(n3.get_meta("anim_ligada", true)) else RAIO_ANIMACAO)
			if perto != bool(n3.get_meta("anim_ligada", true)):
				n3.set_meta("anim_ligada", perto)
				_animacao(n3, perto)


func _animacao(e: Node3D, ligada: bool) -> void:
	if not e.has_meta("players"):
		e.set_meta("players", e.find_children("*", "AnimationPlayer", true, false))
	for ap in e.get_meta("players"):
		if is_instance_valid(ap):
			(ap as AnimationPlayer).active = ligada
	for v in e.find_children("*", "MeshInstance3D", true, false):
		(v as MeshInstance3D).visible = ligada


func _ligar(no: Node3D, ligado: bool) -> void:
	var modo := Node.PROCESS_MODE_INHERIT if ligado else Node.PROCESS_MODE_DISABLED
	if no.process_mode != modo:
		no.process_mode = modo
		no.visible = ligado


# ---------------------------------------------------------------- consultas

func spawn_global(id: String, nome: String) -> Transform3D:
	var area: AreaBase = regioes[id]
	return area.global_transform * area.ponto_de_spawn(nome)


func regiao_em(p: Vector3) -> String:
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id).has_point(Vector2(p.x, p.z)):
			return id
	return ""


func _regiao_mais_perto(p: Vector2) -> String:
	var melhor := ""
	var dmin := 1e9
	for id in MundoDados.REGIOES:
		var r := MundoDados.retangulo(id)
		var dx := maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
		var dz := maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
		var d := sqrt(dx * dx + dz * dz)
		if d < dmin:
			dmin = d
			melhor = id
	return melhor


## O ar de quem anda entre regiões é o da região mais próxima.
func estilo_em(p: Vector3) -> Dictionary:
	return estilos.get(_regiao_mais_perto(Vector2(p.x, p.z)), {})


## Nome do lugar onde se está: a região, o povoado, a estrada ou "Terras Selvagens".
func nome_do_lugar(p: Vector3) -> String:
	var id := regiao_em(p)
	if id != "":
		return MundoDados.REGIOES[id]["nome"]
	var v := Vector2(p.x, p.z)
	for pid in povoados:
		if v.distance_to(povoados[pid]["centro"]) < float(povoados[pid]["raio"]):
			return povoados[pid]["nome"]
	var info := info_estrada(v)
	if not info.is_empty() and float(info["distancia"]) < 70.0:
		return MundoDados.estrada(info["id"])["nome"]
	return "Terras Selvagens"


## Estrada mais perto: {id, distancia, s (metros desde o começo), lado (+1 esquerda, -1 direita), tangente}.
func info_estrada(p: Vector2) -> Dictionary:
	var melhor := {}
	var dmin := 1e9
	for id in estradas:
		var pts: PackedVector2Array = estradas[id]
		var acum := 0.0
		for i in range(pts.size() - 1):
			var a := pts[i]
			var ab := pts[i + 1] - a
			var comp := ab.length()
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var q := a + ab * t
			var d := p.distance_to(q)
			if d < dmin:
				dmin = d
				var tang := ab / comp
				var esq := Vector2(-tang.y, tang.x)
				melhor = {"id": id, "distancia": d, "s": acum + t * comp, "lado": 1.0 if (p - q).dot(esq) >= 0.0 else -1.0, "tangente": tang, "ponto": q}
			acum += comp
	return melhor


func comprimento_da_estrada(id: String) -> float:
	var pts: PackedVector2Array = estradas[id]
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total


## Ponto e direção a `s` metros do começo da estrada: [posição, tangente].
func ponto_na_estrada(id: String, s: float) -> Array:
	var pts: PackedVector2Array = estradas[id]
	var acum := 0.0
	for i in range(pts.size() - 1):
		var comp := pts[i].distance_to(pts[i + 1])
		if acum + comp >= s or i == pts.size() - 2:
			var t := clampf((s - acum) / comp, 0.0, 1.0)
			return [pts[i].lerp(pts[i + 1], t), (pts[i + 1] - pts[i]) / comp]
		acum += comp
	return [pts[0], Vector2.RIGHT]


# ---------------------------------------------------------------- estradas, pontes, corredores

func _largura_do_corredor(id: String, s: float, lado: float) -> float:
	var e := MundoDados.estrada(id)
	var comp := comprimento_da_estrada(id)
	var w: float = e["meia"]
	for p in MundoDados.POVOADOS:   # o corredor se alarga do lado do povoado
		if p["estrada"] == id and float(p["lado"]) == lado:
			var s0 := float(p["t"]) * comp
			var meio := float(p["raio"]) * 1.4
			var x := absf(s - s0) / meio
			if x < 1.0:
				w = maxf(w, lerpf(w, float(p["raio"]) * 1.3, 0.5 + 0.5 * cos(PI * x)))
	for b in MundoDados.BARREIRAS:   # e se estreita no pescoço da barreira
		if b.get("estrada", "") == id:
			var s0 := float(b["t"]) * comp
			var x := absf(s - s0) / 40.0
			if x < 1.0:
				w = lerpf(w, 9.0, 0.5 + 0.5 * cos(PI * x))
	return w


func _corredores() -> void:
	for e in MundoDados.ESTRADAS:
		var pts: PackedVector2Array = estradas[e["id"]]
		var acum := 0.0
		var anterior := {}   # lado -> ponto
		for i in pts.size():
			var dir := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
			var esq := Vector2(-dir.y, dir.x)
			if i > 0:
				acum += pts[i].distance_to(pts[i - 1])
			for lado in [1.0, -1.0]:
				var w := _largura_do_corredor(e["id"], acum, lado)
				var p: Vector2 = pts[i] + esq * lado * w
				if anterior.has(lado):
					var a: Vector2 = anterior[lado]
					if not (_em_alguma_area(a) or _em_alguma_area(p)):
						_parede(a, p)
				anterior[lado] = p


func _em_alguma_area(p: Vector2) -> bool:
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id, -2.0).has_point(p):
			return true
	return false


func _parede(a: Vector2, b: Vector2) -> void:
	var d := b - a
	if d.length() < 0.5:
		return
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.2, 24.0, d.length() + 1.0)
	cs.shape = caixa
	var m := (a + b) / 2.0
	cs.transform = Transform3D(Basis(Vector3.UP, atan2(d.x, d.y)), Vector3(m.x, terreno.altura_em(m.x, m.y) + 8.0, m.y))
	_paredes.add_child(cs)


## Pontes onde uma estrada cruza um rio do mundo (fora das áreas).
func _pontes() -> void:
	for e in MundoDados.ESTRADAS:
		var est: PackedVector2Array = estradas[e["id"]]
		for r in terreno.rios:
			var rio: PackedVector2Array = r["pontos"]
			var feito := false
			for i in range(est.size() - 1):
				if feito:
					break
				for j in range(rio.size() - 1):
					var cruz: Variant = Geometry2D.segment_intersects_segment(est[i], est[i + 1], rio[j], rio[j + 1])
					if cruz == null:
						continue
					var p: Vector2 = cruz
					if _em_alguma_area(p):
						continue
					var dir := (est[i + 1] - est[i]).normalized()
					var meia := (float(r["largura"]) / 2.0 + float(r["margem"]) * 0.85)
					var a := p - dir * meia
					var b := p + dir * meia
					var ponte := PonteDeMadeira.new()
					add_child(ponte)
					ponte.ligar(Vector3(a.x, terreno.altura_em(a.x, a.y), a.y), Vector3(b.x, terreno.altura_em(b.x, b.y), b.y))
					feito = true
					break


## Viaduto de pedra do alto da escadaria de Valdoria até a entrada do Castelo (desce 6,7 m ao longo de ~140 m).
func _viaduto() -> void:
	var vc := MundoDados.centro("valdoria")
	var cc := MundoDados.centro("castelo_imperial")
	var de := Vector3(vc.x, 6.7, vc.y - 132.0)
	var ate := Vector3(cc.x, 0.0, cc.y + 140.0)
	var ponte := PonteDeMadeira.new()
	ponte.largura = 12.0
	add_child(ponte)
	ponte.ligar(de, ate)
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color(0.45, 0.42, 0.4)
	for k in 9:   # pilares de pedra sob o viaduto
		var t := float(k) / 8.0
		var p := de.lerp(ate, t)
		var h := maxf(p.y - terreno.altura_em(p.x, p.z), 0.0)
		if h < 0.8:
			continue
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(10.0, h, 3.0)
		b.material = pedra
		mi.mesh = b
		mi.position = Vector3(p.x, p.y - h / 2.0 - 0.3, p.z)
		add_child(mi)


func _barreiras() -> void:
	for b in MundoDados.BARREIRAS:
		var p: Vector2
		var dir := Vector2(0, -1)
		if b.has("pos"):
			p = b["pos"]
		else:
			var s := float(b["t"]) * comprimento_da_estrada(b["estrada"])
			var par := ponto_na_estrada(b["estrada"], s)
			p = par[0]
			dir = par[1]
		var bar := Barreira.new()
		bar.tipo = b["tipo"]
		bar.texto = b["texto"]
		bar.largura = float(b.get("largura", 18.0))
		bar.condicao = condicoes.get(b["id"], Callable())
		bar.position = Vector3(p.x, 6.7 if b.has("pos") else terreno.altura_em(p.x, p.y), p.y)
		bar.rotation.y = atan2(dir.x, dir.y)   # a barreira atravessa a estrada: o lado largo (X local) é perpendicular a ela
		add_child(bar)
		barreiras[b["id"]] = bar


# ---------------------------------------------------------------- floresta e horizonte

func _floresta() -> void:
	var visuais: Array[Transform3D] = []
	var solidos: Array[Transform3D] = []
	var corpo := StaticBody3D.new()
	corpo.name = "TroncosDoCorredor"
	add_child(corpo)
	for k in 42000:
		var x := _rng.randf_range(MundoDados.LIMITES.position.x, MundoDados.LIMITES.end.x)
		var z := _rng.randf_range(MundoDados.LIMITES.position.y, MundoDados.LIMITES.end.y)
		var p := Vector2(x, z)
		if _em_alguma_area(p) or terreno.na_agua(x, z, 3.0):
			continue
		var info := info_estrada(p)
		var perto_estrada: float = info["distancia"] if not info.is_empty() else 1e9
		var dist_area := terreno._distancia_a_area(p)
		if perto_estrada > 170.0 and dist_area > 150.0:
			continue
		var povoado := false
		for pid in povoados:
			if p.distance_to(povoados[pid]["centro"]) < float(povoados[pid]["raio"]) * 1.1:
				povoado = true
		if povoado or perto_estrada < 6.5:
			continue
		var meia := 20.0
		if not info.is_empty():
			meia = _largura_do_corredor(info["id"], info["s"], info["lado"])
		var dentro := perto_estrada < meia
		if dentro and _rng.randf() > 0.12:
			continue   # dentro do corredor a mata é rala
		var y := terreno.altura_em(x, z)
		var s := _rng.randf_range(0.8, 1.7)
		var t := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s)), Vector3(x, y - 0.15, z))
		visuais.append(t)
		if dentro:
			var cs := CollisionShape3D.new()
			var cil := CylinderShape3D.new()
			cil.radius = 0.45 * s
			cil.height = 4.0
			cs.shape = cil
			cs.position = Vector3(x, y + 2.0, z)
			corpo.add_child(cs)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = FabricaNatureza.pinheiro()
	mm.instance_count = visuais.size()
	for i in visuais.size():
		mm.set_instance_transform(i, visuais[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "FlorestaDoMundo"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)


## Montanhas em volta do mundo inteiro e chão até onde a vista alcança.
func _horizonte() -> void:
	var lim := MundoDados.LIMITES
	var chao := MeshInstance3D.new()
	chao.name = "ChaoDistante"
	var plano := BoxMesh.new()
	plano.size = Vector3(9000.0, 0.2, 9000.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.28, 0.17)
	m.roughness = 1.0
	plano.material = m
	chao.mesh = plano
	chao.position = Vector3(lim.get_center().x, -14.0, lim.get_center().y)
	chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(chao)
	var serra := Node3D.new()
	serra.name = "Montanhas"
	add_child(serra)
	var perimetro := lim.grow(260.0)
	var passo := 120.0
	var total := int((perimetro.size.x + perimetro.size.y) * 2.0 / passo)
	for k in total:
		var d := k * passo
		var p := Vector2.ZERO
		var w := perimetro.size.x
		var h := perimetro.size.y
		if d < w:
			p = Vector2(perimetro.position.x + d, perimetro.position.y)
		elif d < w + h:
			p = Vector2(perimetro.end.x, perimetro.position.y + (d - w))
		elif d < 2.0 * w + h:
			p = Vector2(perimetro.end.x - (d - w - h), perimetro.end.y)
		else:
			p = Vector2(perimetro.position.x, perimetro.end.y - (d - 2.0 * w - h))
		p += Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(-40.0, 40.0))
		var alt := _rng.randf_range(140.0, 260.0)
		var cone := CylinderMesh.new()
		cone.top_radius = _rng.randf_range(0.0, 8.0)
		cone.bottom_radius = _rng.randf_range(60.0, 110.0)
		cone.height = alt
		cone.radial_segments = _rng.randi_range(5, 7)
		cone.rings = 1
		var tom := _rng.randf_range(0.8, 1.15)
		var cor := Color(0.34, 0.4, 0.38)
		if p.y < -1100.0:
			cor = Color(0.3, 0.16, 0.13) if p.y > -1700.0 else Color(0.4, 0.34, 0.27)
		cone.material = _mat(Color(cor.r * tom, cor.g * tom, cor.b * tom))
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.position = Vector3(p.x, alt / 2.0 - 14.0, p.y)
		mi.rotation.y = _rng.randf() * TAU
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		serra.add_child(mi)


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	return m
