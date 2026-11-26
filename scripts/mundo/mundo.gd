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
var tubarao: Tubarao
var muralha: MuralhaDoReino
var marcos_de_estrada := 0
var _cabeceiras: Array = []   # [ponto, sentido para a ponte, meia largura] de cada ponta de ponte
var montanha: MontanhaDosDragoes
var cidadela: Cidadela
var trilhas: Array[PackedVector2Array] = []
var arvores: ColisoresDeArvores
var capim: CapimDoMundo
var mapa_floresta: ImageTexture   # a imagem pintada do mapa (tecla M), ver PinturaDoMapa
var _rng := RandomNumberGenerator.new()
var _t_atividade := 0.0
const RAIO_ATIVO := 230.0    # regiões e povoados mais longe que isto ficam parados e invisíveis (fogueiras, gente e bichos custam CPU)
const RAIO_FAUNA := 200.0
const RAIO_VISIVEL := 800.0  # até aqui as casas, muralhas e torres continuam à vista (paradas): cidade e vila aparecem de longe, não "brotam" na cara
const RAIO_ANIMACAO := 60.0  # gente e bichos mais longe que isto não animam nem aparecem


# ---------------------------------------------------------------- ajudas para as áreas

## A área pede, antes de gerar o terreno, que ele se misture com o chão do mundo nas bordas.
static func preparar_terreno(t: Terreno, area: Node3D) -> void:
	if not ativo:
		return
	t.origem = Vector2(area.position.x, area.position.z)
	t.origem_y = area.position.y
	t.externa = instancia.terreno.altura_em
	t.cor_externa = instancia.terreno.cor_do_mundo


## Paredes invisíveis na borda do mapa de uma área. No mundo contínuo não há: as bordas das áreas são abertas
## (quem fecha o caminho são as cristas de rocha e a borda do mundo).
static func paredes_de_borda(area: Node3D, tam: float, corpo: StaticBody3D) -> void:
	if ativo:
		return
	var meio := tam / 2.0
	for lado in [[Vector3(0, 8, -meio), Vector3(tam, 16, 2)], [Vector3(0, 8, meio), Vector3(tam, 16, 2)], [Vector3(-meio, 8, 0), Vector3(2, 16, tam)], [Vector3(meio, 8, 0), Vector3(2, 16, tam)]]:
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = lado[1]
		cs.shape = caixa
		cs.position = lado[0]
		corpo.add_child(cs)


# ---------------------------------------------------------------- construção

func construir() -> void:
	ativo = true
	instancia = self
	_rng.seed = 2026
	var t0 := Time.get_ticks_msec()
	var etapa := func(nome: String) -> void:   # tempo de cada etapa do carregamento, no log
		print("Mundo: etapa ", nome, " em ", (Time.get_ticks_msec() - t0) / 1000.0, " s")
	_planejar()
	etapa.call("planejar")
	for id in MundoDados.REGIOES:
		progresso.emit("Erguendo %s..." % MundoDados.REGIOES[id]["nome"])
		var area := (load(MundoDados.REGIOES[id]["cena"]) as PackedScene).instantiate() as AreaBase
		area.name = id
		var c := MundoDados.centro(id)
		area.position = Vector3(c.x, MundoDados.altura(id), c.y)   # o Castelo fica no alto do morro; o resto, no nível do reino
		add_child(area)
		regioes[id] = area
		_colher_estilo(id, area)
		await get_tree().process_frame
	progresso.emit("Moldando o chão entre as regiões...")
	await get_tree().process_frame
	etapa.call("regioes")
	terreno.gerar()
	add_child(terreno)
	etapa.call("terreno")
	_paredes = StaticBody3D.new()
	_paredes.name = "CristasEBordas"
	add_child(_paredes)
	progresso.emit("Erguendo as serras e abrindo as estradas...")
	await get_tree().process_frame
	_pontes()
	_cristas()
	_viaduto()
	_barreiras()
	progresso.emit("Plantando florestas...")
	await get_tree().process_frame
	muralha = MuralhaDoReino.new()
	muralha.mundo = self
	add_child(muralha)
	muralha.montar()
	_beira_das_estradas()
	montanha = MontanhaDosDragoes.new()
	montanha.mundo = self
	add_child(montanha)
	montanha.montar()
	etapa.call("pontes, mar e muralha do reino")
	_floresta()
	_horizonte()
	etapa.call("floresta e mapa")
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
	var piso := CalcamentoDoReino.new()
	piso.mundo = self
	add_child(piso)
	piso.montar()
	var vida := VidaDasRuas.new()
	vida.mundo = self
	add_child(vida)
	vida.montar()
	var casario := CasarioDoReino.new()
	casario.mundo = self
	add_child(casario)
	casario.montar()
	etapa.call("povoados e casario do reino")
	progresso.emit("Traçando os caminhos da gente...")
	await get_tree().process_frame
	NavegacaoLocal.assar(regioes["refugio_do_pinhal"], Vector3(0, 0, 0), Vector2(48, 48), false)
	progresso.emit("Soltando os bichos...")
	await get_tree().process_frame
	await get_tree().physics_frame   # o motor só enxerga os corpos novos depois de um passo de física: sem isso a conferência de "há pedra aqui?" não vê nada
	await get_tree().physics_frame
	fauna = FaunaDoMundo.new()
	fauna.mundo = self
	add_child(fauna)
	etapa.call("navegacao")
	fauna.povoar()
	etapa.call("fauna")
	capim = CapimDoMundo.new()
	capim.mundo = self
	add_child(capim)
	capim.iniciar()
	etapa.call("capim (fim)")
	progresso.emit("Pronto.")


func _planejar() -> void:
	terreno = TerrenoMundo.new()
	terreno.name = "ChaoDoMundo"
	terreno.limites = MundoDados.LIMITES
	terreno.passo = 4.0   # 4 m: com 8 m um rio de 7 m de largura caía em 2 células e a margem virava serrilhado
	terreno.semente = 4242
	for id in MundoDados.REGIOES:
		terreno.retangulos.append(MundoDados.retangulo(id))
	for e in MundoDados.ESTRADAS:
		var curva := Terreno.curva(e["pontos"], 4.0)
		estradas[e["id"]] = curva
		terreno.estradas_mundo.append(curva)
	var rios: Array = []
	for r in MundoDados.RIOS:
		rios.append({"id": r["id"], "nome": r["nome"], "pontos": Terreno.curva(r["pontos"], 4.0), "largura": r["largura"], "margem": r["margem"], "fundo": r["fundo"], "agua": true})
	terreno.rios = rios
	for p in MundoDados.POVOADOS:   # povoados na beira de uma estrada: ao lado dela, do lado indicado
		var s := float(p["t"]) * comprimento_da_estrada(p["estrada"])
		var par := ponto_na_estrada(p["estrada"], s)
		var dir: Vector2 = par[1]
		var esq := Vector2(-dir.y, dir.x)
		var centro: Vector2 = par[0] + esq * float(p["lado"]) * float(p["raio"]) * 0.55
		_registrar_povoado(p, centro, dir, par[0])
	for p in MundoDados.POVOADOS_LIVRES:   # povoados espalhados pelo mundo, com uma trilha até a estrada mais perto
		_registrar_povoado(p, p["centro"], p["dir"], p["centro"])
		if String(p["liga"]) != "":
			var pts: PackedVector2Array = estradas[p["liga"]]
			var melhor := pts[0]
			for q in pts:
				if q.distance_to(p["centro"]) < melhor.distance_to(p["centro"]):
					melhor = q
			var meio: Vector2 = (melhor + p["centro"]) / 2.0 + Vector2(-(melhor - p["centro"]).y, (melhor - p["centro"]).x).normalized() * 12.0
			var trilha := Terreno.curva([p["centro"], meio, melhor], 4.0)
			trilhas.append(trilha)
			terreno.estradas_mundo.append(trilha)
	Costa.protegidos.clear()   # a costa recua perto de regiões e povoados
	for id in MundoDados.REGIOES:
		Costa.protegidos.append([MundoDados.centro(id), float(MundoDados.REGIOES[id]["meia"]) * 1.42 + 20.0])
	for pid in povoados:
		Costa.protegidos.append([povoados[pid]["centro"], float(povoados[pid]["raio"]) * 1.1 + 20.0])
	terreno.preparar()   # depois de todas as estradas, trilhas e áreas aplanadas


func _registrar_povoado(p: Dictionary, centro: Vector2, dir: Vector2, ponto_estrada: Vector2) -> void:
	terreno.planos.append(Vector3(centro.x, centro.y, float(p["raio"]) * 1.0))   # o chão do povoado fica nivelado (campos e quintal inclusos)
	povoados[p["id"]] = {"id": p["id"], "lado": p["lado"], "centro": centro, "nome": p["nome"], "raio": p["raio"], "tipo": p["tipo"], "dir": dir, "ponto_da_estrada": ponto_estrada}


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
		_ligar(regioes[id], sqrt(dx * dx + dz * dz))
	for pid in povoados:
		if povoados[pid].has("no"):
			_ligar(povoados[pid]["no"], p.distance_to(povoados[pid]["centro"]))
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


## Perto (RAIO_ATIVO) o lugar vive; mais longe fica parado; muito longe (RAIO_VISIVEL) some.
func _ligar(no: Node3D, distancia: float) -> void:
	no.visible = distancia < RAIO_VISIVEL
	var ligado := distancia < RAIO_ATIVO
	var modo := Node.PROCESS_MODE_INHERIT if ligado else Node.PROCESS_MODE_DISABLED
	if no.process_mode != modo:
		no.process_mode = modo
		if ligado:   # a gente da região já acorda no horário certo (deitada à noite, de pé de dia)
			for e in no.find_children("*", "Npc", true, false):
				(e as Npc).acomodar_ao_horario()


# ---------------------------------------------------------------- consultas

func spawn_global(id: String, nome: String) -> Transform3D:
	var area: AreaBase = regioes[id]
	return area.global_transform * area.ponto_de_spawn(nome)


## Altura do chão onde se pisa de verdade em (x, z) do mundo: o chão da região, se o ponto está dentro de uma (cada região tem
## o terreno próprio), ou o chão do mundo. Quem anda sem física (bichos, gente) precisa desta função, não de `terreno.altura_em`.
func chao_em(x: float, z: float) -> float:
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id, -1.0).has_point(Vector2(x, z)):
			var area: Node3D = regioes.get(id)
			if area != null:
				var c := MundoDados.centro(id)
				return (area as AreaBase).altura_em(x - c.x, z - c.y) + area.position.y
	return terreno.altura_em(x, z)


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
	if MundoDados.ate_a_muralha(p.x, p.z) < 120.0:   # Valdoria: ar limpo e dourado, para a cidadela se ver de qualquer rua
		return {"neblina": Color(0.8, 0.85, 0.9), "densidade": 0.0009, "sol": Color(1.0, 0.93, 0.8), "energia": 1.25, "ambiente": 1.0, "topo": Color(0.26, 0.48, 0.84), "horizonte": Color(0.7, 0.82, 0.93)}   # céu azul (com o horizonte bege o céu inteiro ficava cor de areia)
	if Vector2(p.x, p.z).distance_to(MundoDados.MONTANHA_CENTRO) < MundoDados.MONTANHA_RAIO + 900.0:   # a Montanha dos Dragões: ar limpo e alaranjado, para o pico se ver de longe
		return {"neblina": Color(0.86, 0.78, 0.7), "densidade": 0.0007, "sol": Color(1.0, 0.86, 0.7), "energia": 1.2, "ambiente": 1.0, "topo": Color(0.3, 0.42, 0.72), "horizonte": Color(0.9, 0.72, 0.56)}
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
	if v.distance_to(MundoDados.MONTANHA_CENTRO) < MundoDados.MONTANHA_RAIO:
		return "Ninho dos Dragões" if v.distance_to(MundoDados.MONTANHA_CENTRO) < MundoDados.MONTANHA_TOPO + 6.0 else "Montanha dos Dragões"
	if float(MundoDados.penhasco(p.x, p.z)[2]) <= 1.0:
		return "Cidadela de Valdoria"
	if MundoDados.ate_a_muralha(p.x, p.z) < 0.0:
		return "Valdoria"
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

func _em_alguma_area(p: Vector2) -> bool:
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id, -2.0).has_point(p):
			return true
	return false


## O que fica à beira das estradas: cabeceiras de pedra com lampião em cada ponta de ponte, um marco de pedra a cada
## 240 m e, a cada 4 marcos, um pouso (banco, lampião de poste e carga) para quem viaja.
func _beira_das_estradas() -> void:
	var kit := PecasDaRua.new()
	kit.name = "BeiraDasEstradas"
	add_child(kit)
	for c in _cabeceiras:
		var q: Vector2 = c[0]
		kit.cabeceira_de_ponte(Vector3(q.x, terreno.altura_em(q.x, q.y), q.y), c[1], float(c[2]))
	for e in MundoDados.ESTRADAS:
		var est: PackedVector2Array = estradas[e["id"]]
		var andado := 120.0
		var n := 0
		for i in range(est.size() - 1):
			var trecho := est[i].distance_to(est[i + 1])
			var dir := (est[i + 1] - est[i]).normalized()
			var lado := Vector2(-dir.y, dir.x)
			while andado < trecho:
				var q := est[i] + dir * andado + lado * 5.2
				andado += 240.0
				var livre := MundoDados.ate_a_muralha(q.x, q.y) > 40.0 and not _em_alguma_area(q) and not terreno.na_agua(q.x, q.y, 6.0) and Costa.distancia(q.x, q.y) > 30.0
				for pid in povoados:
					if q.distance_to(povoados[pid]["centro"]) < float(povoados[pid]["raio"]) + 12.0:
						livre = false
				if not livre:
					continue
				var chao := Vector3(q.x, terreno.altura_em(q.x, q.y), q.y)
				kit.marco_de_estrada(chao, atan2(dir.x, dir.y) + PI / 2.0)
				marcos_de_estrada += 1
				n += 1
				if n % 4 == 0:
					var b := q + dir * 3.0 + lado * 1.2
					kit.banco(Vector3(b.x, terreno.altura_em(b.x, b.y), b.y), -lado)
					var l := q - dir * 2.5
					kit.lampiao_de_poste(Vector3(l.x, terreno.altura_em(l.x, l.y), l.y), -lado)
					var cg := q + dir * 6.0 + lado * 0.8
					kit.carga(Vector3(cg.x, terreno.altura_em(cg.x, cg.y), cg.y), dir, 2, n)
			andado -= trecho
	kit.fechar()
	print("Mundo: ", marcos_de_estrada, " marcos de estrada e ", _cabeceiras.size(), " cabeceiras de ponte")


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
					var meia := float(r["largura"]) / 2.0 + 1.4 + float(r["margem"]) + 0.5   # as pontas ficam já no chão sem mexida (depois da barranca e da margem do rio)
					var a := p - dir * meia
					var b := p + dir * meia
					var ponte := PonteDeMadeira.new()
					add_child(ponte)
					ponte.ligar(Vector3(a.x, terreno.altura_em(a.x, a.y), a.y), Vector3(b.x, terreno.altura_em(b.x, b.y), b.y))
					_cabeceiras.append([a, dir, ponte.largura / 2.0])
					_cabeceiras.append([b, -dir, ponte.largura / 2.0])
					feito = true
					break


## Viaduto de pedra do alto da escadaria de Valdoria até a entrada do Castelo (desce 6,7 m ao longo de ~140 m).
func _viaduto() -> void:   # a subida do castelo é da Cidadela (escadaria de pedra); aqui só ela é montada
	cidadela = Cidadela.new()
	cidadela.mundo = self
	add_child(cidadela)
	cidadela.montar()


func _barreiras() -> void:
	for b in MundoDados.BARREIRAS:
		var p: Vector2 = b["pos"]
		var dir: Vector2 = b["dir"]
		var bar := Barreira.new()
		bar.tipo = b["tipo"]
		bar.texto = b["texto"]
		bar.largura = float(b["largura"])
		bar.condicao = condicoes.get(b["id"], Callable())
		bar.position = Vector3(p.x, float(b["altura_y"]) if b.has("altura_y") else terreno.altura_em(p.x, p.y), p.y)
		bar.rotation.y = atan2(dir.x, dir.y)   # a barreira atravessa a estrada: o lado largo (X local) é perpendicular a ela
		add_child(bar)
		barreiras[b["id"]] = bar


## Mar em volta da costa: plano de água e uma fileira de paredes invisíveis um pouco antes da água funda.
func _mar() -> void:
	var lim := MundoDados.LIMITES
	var mat_mar := Terreno.material_agua()
	var mat_mar_longe := Terreno.material_agua(false)
	var lado := 160.0   # o mar é feito de ladrilhos: um plano só, do tamanho do mundo, ficava sempre na tela e forçava a cópia do buffer de profundidade a cada quadro
	var mx := lim.position.x - 240.0
	while mx < lim.end.x + 240.0:
		var mz := lim.position.y - 240.0
		while mz < lim.end.y + 240.0:
			var perto_do_mar := false
			for ax in [0.0, 0.5, 1.0]:
				for az in [0.0, 0.5, 1.0]:
					if Costa.distancia(mx + lado * ax, mz + lado * az) < 24.0:
						perto_do_mar = true
			if perto_do_mar:
				var plano := MeshInstance3D.new()
				plano.name = "Mar"
				var pm := PlaneMesh.new()
				pm.size = Vector2(lado, lado)
				plano.mesh = pm
				plano.material_override = mat_mar
				plano.position = Vector3(mx + lado / 2.0, Costa.NIVEL_MAR, mz + lado / 2.0)
				plano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				plano.visibility_range_end = 130.0
				plano.visibility_range_end_margin = 20.0
				add_child(plano)
				var longe := MeshInstance3D.new()
				longe.name = "MarLonge"
				longe.mesh = pm
				longe.material_override = mat_mar_longe
				longe.position = plano.position
				longe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				longe.visibility_range_begin = 110.0
				longe.visibility_range_begin_margin = 20.0
				longe.visibility_range_end = 700.0
				longe.visibility_range_end_margin = 50.0
				add_child(longe)
			mz += lado
		mx += lado
	var n := 0   # parede invisível bem mar adentro: o raso é livre, e quem insiste encontra o tubarão antes da parede
	var x := lim.position.x
	while x <= lim.end.x:
		var z := lim.position.y
		while z <= lim.end.y:
			var d := Costa.distancia(x, z)
			if d < -Costa.PAREDE + 4.0 and d > -Costa.PAREDE - 4.0:
				var cs := CollisionShape3D.new()
				var caixa := BoxShape3D.new()
				caixa.size = Vector3(8.0, 30.0, 8.0)
				cs.shape = caixa
				cs.position = Vector3(x, Costa.NIVEL_MAR + 6.0, z)
				_paredes.add_child(cs)
				n += 1
			z += 6.0
		x += 6.0
	tubarao = Tubarao.new()
	tubarao.name = "Tubarao"
	add_child(tubarao)
	print("Mundo: costa com ", n, " blocos de parede")


## Cristas de rocha (muralhas naturais com vão só onde há barreira) e a borda do mundo.
func _cristas() -> void:
	var rocha := FabricaNatureza.pedra(3.0)
	var transf: Array[Transform3D] = []
	for c in MundoDados.CRISTAS:
		var de: Vector2 = c["de"]
		var para: Vector2 = c["para"]
		var comp := de.distance_to(para)
		var dir := (para - de) / comp
		var vaos: Array = c["vaos"]
		var cortes: Array = [0.0]   # intervalos [ini, fim] ao longo da crista, sem os vãos
		var intervalos: Array = []
		var posicoes: Array = []
		for v in vaos:
			posicoes.append((v - de).dot(dir))
		posicoes.sort()
		var ini := 0.0
		for pv in posicoes:
			intervalos.append([ini, pv - 10.0])
			ini = pv + 10.0
		intervalos.append([ini, comp])
		var altura := float(c["altura"])
		for it in intervalos:
			var a: float = it[0]
			var b: float = it[1]
			if b - a < 1.0:
				continue
			var meio := de + dir * ((a + b) / 2.0)
			var cs := CollisionShape3D.new()
			var caixa := BoxShape3D.new()
			caixa.size = Vector3(9.0, altura + 12.0, b - a)
			cs.shape = caixa
			cs.transform = Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y)), Vector3(meio.x, terreno.altura_em(meio.x, meio.y) + altura / 2.0 - 6.0, meio.y))
			_paredes.add_child(cs)
			var t := a
			while t < b:   # rochas gigantes ao longo da crista
				var q := de + dir * t + Vector2(-dir.y, dir.x) * _rng.randf_range(-3.0, 3.0)
				var e := _rng.randf_range(9.0, 15.0)
				var h := e * _rng.randf_range(0.9, 1.5) * (1.0 if altura > 10.0 else 0.35)
				var base := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(e, h, e))
				transf.append(Transform3D(base, Vector3(q.x, terreno.altura_em(q.x, q.y) - 1.0, q.y)))
				t += 13.0
	_mar()
	var lim := MundoDados.LIMITES
	for lado in [[Vector2(lim.position.x, lim.get_center().y), Vector2(4, lim.size.y)], [Vector2(lim.end.x, lim.get_center().y), Vector2(4, lim.size.y)], [Vector2(lim.get_center().x, lim.position.y), Vector2(lim.size.x, 4)], [Vector2(lim.get_center().x, lim.end.y), Vector2(lim.size.x, 4)]]:
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(lado[1].x, 80.0, lado[1].y)
		cs.shape = caixa
		cs.position = Vector3(lado[0].x, 30.0, lado[0].y)
		_paredes.add_child(cs)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rocha
	mm.instance_count = transf.size()
	for i in transf.size():
		mm.set_instance_transform(i, transf[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "RochasDasCristas"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)


# ---------------------------------------------------------------- floresta e horizonte

func _floresta() -> void:
	var rng_f := FastNoiseLite.new()
	rng_f.seed = 77
	rng_f.frequency = 0.0032
	rng_f.fractal_octaves = 2
	arvores = ColisoresDeArvores.new()
	arvores.altura_em = terreno.altura_em
	add_child(arvores)
	arvores.iniciar(220)
	var tiles: Dictionary = {}   # "bloco_x,bloco_z,tipo" -> Array[Transform3D]; tipo: 0 pinheiro, 1 folhosa, 2 morta, 3 arbusto, 4 pedra, 5 cogumelo
	var cores_pedra: Dictionary = {}   # mesma chave -> Array[Color]
	var passo := 7.5
	var lim := MundoDados.LIMITES
	var gw := int(lim.size.x / 20.0) + 1   # grade do mapa (tecla M): quantas árvores em cada quadrado de 20 m
	var gh := int(lim.size.y / 20.0) + 1
	var mata := PackedFloat32Array()
	mata.resize(gw * gh)
	var nx := int(lim.size.x / passo)
	var nz := int(lim.size.y / passo)
	var contagem_bioma: Dictionary = {}
	for i in nx:
		for j in nz:
			var x := lim.position.x + (i + _rng.randf()) * passo
			var z := lim.position.y + (j + _rng.randf()) * passo
			var p := Vector2(x, z)
			if _em_alguma_area(p) or terreno.na_agua(x, z, 3.0) or terreno.distancia_caminho(x, z) < 7.0 or Costa.distancia(x, z) < 14.0:
				continue
			if p.distance_to(MundoDados.MONTANHA_CENTRO) < MundoDados.MONTANHA_RAIO and float(MundoDados.montanha(x, z)[0]) > 6.0:
				continue   # a encosta da Montanha dos Dragões é rocha nua
			if MundoDados.ate_a_muralha(x, z) < 12.0:
				continue   # dentro da muralha do reino (e encostado nela) não nasce mata: é cidade, casa colada em casa
			var no_povoado := false
			for pid in povoados:
				if p.distance_to(povoados[pid]["centro"]) < float(povoados[pid]["raio"]) * 1.05:
					no_povoado = true
					break
			if no_povoado:
				continue
			var bioma := Biomas.em(x, z)
			var y := terreno.altura_em(x, z)
			var k := "%d,%d," % [int(floor(x / 160.0)), int(floor(z / 160.0))]
			var dens := smoothstep(0.38, 0.78, rng_f.get_noise_2d(x, z) * 0.5 + 0.5)   # bosques e clareiras
			var chance: float = (dens * 0.85 + 0.06) * float(Biomas.DENSIDADE[bioma])
			if _rng.randf() <= chance:
				var tp := Biomas.tipo(bioma, _rng.randf())
				var s := _rng.randf_range(0.8, 1.7) if tp != 3 else _rng.randf_range(0.7, 1.4)
				var t := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s)), Vector3(x, y - 0.15, z))
				var kk := k + str(tp)
				if not tiles.has(kk):
					tiles[kk] = []
				(tiles[kk] as Array).append(t)
				if tp != 3:
					arvores.adicionar(x, z, (0.45 if tp == 0 else 0.4 if tp == 1 else 0.3) * s)
				mata[int((z - lim.position.y) / 20.0) * gw + int((x - lim.position.x) / 20.0)] += 1.0
				contagem_bioma[bioma] = int(contagem_bioma.get(bioma, 0)) + 1
			elif _rng.randf() <= float(Biomas.PEDRAS[bioma]):   # pedra solta (e com tronco/colisão se for grande)
				var tam := _rng.randf_range(0.5, 1.6) * (1.6 if bioma == "cratera" or bioma == "ferrogris" else 1.0)
				var tr := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(tam, tam * _rng.randf_range(0.6, 1.0), tam)), Vector3(x, y - 0.2 * tam, z))
				var kk := k + "4"
				if not tiles.has(kk):
					tiles[kk] = []
					cores_pedra[kk] = []
				(tiles[kk] as Array).append(tr)
				(cores_pedra[kk] as Array).append(Biomas.TOM_PEDRA[bioma])
				if tam > 0.9:
					arvores.adicionar(x, z, 0.55 * tam)
			elif Biomas.COGUMELOS.has(bioma) and _rng.randf() <= float(Biomas.COGUMELOS[bioma]):
				var kk := k + "5"
				if not tiles.has(kk):
					tiles[kk] = []
				for c in _rng.randi_range(3, 6):
					var q := Vector2(x, z) + Vector2(_rng.randf_range(-1.2, 1.2), _rng.randf_range(-1.2, 1.2))
					var e := _rng.randf_range(0.8, 1.6)
					(tiles[kk] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(e, e, e)), Vector3(q.x, terreno.altura_em(q.x, q.y) - 0.02, q.y)))
	mapa_floresta = PinturaDoMapa.pintar(mata, gw, gh, 20.0, terreno.altura_em)
	var malhas := [FabricaNatureza.pinheiro(), FabricaNatureza.folhosa(), FabricaNatureza.morta(), FabricaNatureza.arbusto(2.0), FabricaNatureza.pedra(5.0), FabricaNatureza.cogumelo()]
	var mat := FabricaNatureza.material()
	var total := 0
	for kk in tiles:   # um MultiMesh por bloco de 160 m e por tipo: o motor esconde os distantes e os fora da tela
		var lista: Array = tiles[kk]
		var tipo_i := int(String(kk).split(",")[2])
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = tipo_i == 4
		mm.mesh = malhas[tipo_i]
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, lista[i])
			if tipo_i == 4:
				mm.set_instance_color(i, (cores_pedra[kk] as Array)[i])
		var inst := MultiMeshInstance3D.new()
		inst.name = "Mata_" + String(kk).replace(",", "_")
		inst.multimesh = mm
		inst.material_override = mat
		inst.visibility_range_end = 420.0 if tipo_i < 3 else 200.0
		if tipo_i >= 4:
			inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)
		if tipo_i < 3:
			total += lista.size()
	print("Mundo: ", total, " árvores em ", tiles.size(), " blocos; por bioma ", contagem_bioma)


## Montanhas em volta do mundo inteiro e chão até onde a vista alcança.
func _horizonte() -> void:   # a ilha fica no meio do oceano: para lá do mar de ladrilhos, um fundo azul até o horizonte
	var lim := MundoDados.LIMITES
	var chao := MeshInstance3D.new()
	chao.name = "OceanoDistante"
	var plano := BoxMesh.new()
	plano.size = Vector3(12000.0, 0.2, 12000.0)
	plano.material = _mat(Color(0.1, 0.24, 0.34))
	chao.mesh = plano
	chao.position = Vector3(lim.get_center().x, Costa.NIVEL_MAR - 7.0, lim.get_center().y)
	chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(chao)
	for id in MundoDados.REGIOES:   # de longe o chão das regiões some (só aparece de perto): um forro verde por baixo evita o "buraco azul"
		var forro := MeshInstance3D.new()
		forro.name = "ForroDe_" + id
		var pm := PlaneMesh.new()
		var meia: float = MundoDados.REGIOES[id]["meia"]
		pm.size = Vector2(meia * 2.0, meia * 2.0)
		var c := MundoDados.centro(id)
		pm.material = _mat(Biomas.cor_do_chao(c.x, c.y, 0.5) * 0.55)   # mais escuro: o chão de verdade recebe sombra e parece mais fechado
		forro.mesh = pm
		forro.position = Vector3(c.x, -5.0, c.y)
		forro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(forro)


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	return m
