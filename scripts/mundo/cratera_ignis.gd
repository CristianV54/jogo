extends AreaAberta
## Cratera de Ignis (Capítulo IV): complexo industrial sobre um vulcão. De sul a norte: Ponte de Basalto sobre a fenda
## de lava -> zona de calor e patrulhas com os minérios -> Passarela A -> pátio das forjas (alojamento, depósito de
## lingotes, sala de controle das correntes, guindastes, 3 fornalhas negras) -> Passarela B -> arena de Ignis-Maw com a
## Caldeira Ancestral. Lava queima quem pisa nela. Ignis-Maw não morre: ao quebrar a 4ª âncora ele ruge, voa para longe
## e destrói parte das forjas. Expõe os sinais de chefe que o Jogo espera.

signal chefe_vida(nome: String, atual: int, maximo: int)
signal chefe_morreu(id: String)

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const ARENA := Vector2(0.0, -100.0)
const RAIO_ANCORAS := 28.0
const RAIO_MAX := 40.0
const FENDAS := [[98.0, 28.0, 7.0], [36.0, 12.0, 3.4], [-46.0, 12.0, 3.4]]   # z do centro, largura da fenda, largura da ponte

var ignis: Inimigo
var ancoras: Array[AncoraDeObelisco] = []
var fornalhas: Array[FornalhaNegra] = []
var minerios: Array[PilhaDeItem] = []
var brenn: Npc
var engajado := false
var solto := false
var _restantes := 4
var _t_onda := 7.0
var _t_brasas := 5.0
var _brasas: Array[Fogo] = []


func _ready() -> void:
	nome_area = "Cratera de Ignis"
	tam = 300.0
	_rng.seed = 73
	_ambiente()
	_montar_terreno(41, 0.0, [], PackedVector2Array([Vector2(0, 155), Vector2(0, 140), Vector2(0, -100), Vector2(0, -155)]), Color(0.3, 0.2, 0.17), Color(0.22, 0.15, 0.14), 260.0)
	_horizonte(Color(0.3, 0.14, 0.12), 170.0)
	_paredoes()
	for f in FENDAS:
		_fenda(f[0], f[1], f[2])
	_acesso()
	_forjas()
	_arena()
	_gente()
	_novo_spawn("Entrada", Vector3(0, altura_em(0, 130), 130), Vector3(0, 0, 90))
	_novo_spawn("Principal", Vector3(0, altura_em(0, 130), 130), Vector3(0, 0, 90))
	_novo_spawn("DeValdoria", Vector3(0, altura_em(0, -138), -138), Vector3(0, 0, 0))
	_portal(Vector3(0, altura_em(0, 142), 142), "fronteira_ferrogris", "DaCratera", 16.0)
	_portal(Vector3(0, altura_em(0, -146), -146), "valdoria", "Entrada", 14.0)
	var m := GerenciadorMissoes.instancia
	if m:
		m.missao_concluida.connect(_ao_missao_concluida)
		if m.concluidas.has("C4-M2"):
			_acordar_ignis()
		if m.concluidas.has("C4-M3"):
			_forja_de_campo()


func _ambiente() -> void:
	_ambiente_padrao()
	var we := get_node("Ambiente") as WorldEnvironment
	var e := we.environment
	var ceu := e.sky.sky_material as ProceduralSkyMaterial
	ceu.sky_top_color = Color(0.16, 0.08, 0.09)
	ceu.sky_horizon_color = Color(0.55, 0.22, 0.1)
	ceu.ground_horizon_color = Color(0.4, 0.16, 0.08)
	ceu.ground_bottom_color = Color(0.2, 0.08, 0.06)
	e.fog_light_color = Color(0.34, 0.14, 0.1)
	e.fog_density = 0.008
	e.ambient_light_energy = 0.8
	var sol := get_node("Sol") as DirectionalLight3D
	sol.light_color = Color(1.0, 0.55, 0.3)
	sol.light_energy = 0.85


## Paredões de rocha escura em volta da cratera.
func _paredoes() -> void:
	for k in 44:
		var t := float(k) / 44.0 * 4.0
		var lado := int(t)
		var u := (t - lado) * 2.0 - 1.0
		var p := Vector2.ZERO
		match lado:
			0: p = Vector2(u * 140.0, -142.0)
			1: p = Vector2(142.0, u * 140.0)
			2: p = Vector2(-u * 140.0, 142.0)
			_: p = Vector2(-142.0, -u * 140.0)
		if absf(p.x) < 9.0 and absf(p.y) > 130.0:
			continue   # as passagens dos portais ficam livres
		_rocha(p, 9.0 + _rng.randf() * 4.0, false, 200.0 + k)


# ---------------------------------------------------------------- fendas de lava e pontes

func _fenda(z: float, largura: float, ponte: float) -> void:
	var lava := ZonaDeCalor.new()
	lava.tamanho = Vector2(tam - 4.0, largura)
	lava.position = Vector3(0, 0.0, z)
	add_child(lava)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.4, 0.1)
	luz.light_energy = 3.0
	luz.omni_range = 40.0
	luz.position = Vector3(0, 4.0, z)
	add_child(luz)
	var madeira := VilaRefugio._mat(Color(0.16, 0.14, 0.14) if ponte > 5.0 else Color(0.3, 0.2, 0.11))
	VilaRefugio._caixa(Vector3(0, 0.11, z), Vector3(ponte, 0.1, largura + 4.0), madeira, true)
	for lado in [-1.0, 1.0]:   # degrau de entrada e de saída (a ponte fica 0,16 m acima do chão)
		VilaRefugio._caixa(Vector3(0, 0.05, z + lado * (largura / 2.0 + 2.5)), Vector3(ponte, 0.1, 1.2), madeira, true)
	for lado in [-1.0, 1.0]:   # corrimão e pilares
		for k in int((largura + 4.0) / 4.0) + 1:
			var zz := z - (largura + 4.0) / 2.0 + k * 4.0
			VilaRefugio._caixa(Vector3(lado * ponte / 2.0, 0.8, zz), Vector3(0.3, 1.4, 0.3), madeira, true)
		VilaRefugio._caixa(Vector3(lado * ponte / 2.0, 1.4, z), Vector3(0.15, 0.15, largura + 4.0), madeira)
	_placa_em_poste(Vector2(ponte / 2.0 + 3.0, z + largura / 2.0 + 5.0), "Ponte de Basalto" if ponte > 5.0 else "Passarela")


# ---------------------------------------------------------------- zona de acesso: calor, fumaça, patrulhas, minérios

func _guindaste(pos: Vector2) -> void:
	var y := _y(pos)
	var ferro := VilaRefugio._mat(Color(0.18, 0.16, 0.16))
	VilaRefugio._caixa(Vector3(pos.x, y + 0.6, pos.y), Vector3(3.0, 1.2, 3.0), ferro, true)
	VilaRefugio._caixa(Vector3(pos.x, y + 7.0, pos.y), Vector3(0.9, 13.0, 0.9), ferro)
	VilaRefugio._caixa(Vector3(pos.x + 4.0, y + 13.4, pos.y), Vector3(10.0, 0.8, 0.8), ferro)
	VilaRefugio._caixa(Vector3(pos.x + 7.5, y + 10.4, pos.y), Vector3(0.12, 5.6, 0.12), VilaRefugio._mat(Color(0.4, 0.35, 0.3)))
	VilaRefugio._caixa(Vector3(pos.x + 7.5, y + 7.4, pos.y), Vector3(1.2, 0.8, 1.2), VilaRefugio._mat(Color(0.5, 0.1, 0.06)))


func _lingotes(pos: Vector2) -> void:
	var mat := VilaRefugio._mat(Color(0.22, 0.2, 0.22))
	var brilho := VilaRefugio._mat(Color(0.7, 0.3, 0.1))
	for linha in 3:
		for k in 3 - linha:
			var q := pos + Vector2(k * 1.5 + linha * 0.75, 0.0)
			VilaRefugio._caixa(Vector3(q.x, _y(q) + 0.35 + linha * 0.7, q.y), Vector3(1.4, 0.65, 2.0), brilho if (k + linha) % 2 == 0 else mat, linha == 0)


func _acesso() -> void:
	_guindaste(Vector2(-30.0, 76.0))
	_guindaste(Vector2(30.0, 56.0))
	_lingotes(Vector2(-44.0, 62.0))
	_lingotes(Vector2(40.0, 76.0))
	for k in 14:   # rochas vulcânicas espalhadas
		_rocha(Vector2(_rng.randf_range(-100.0, 100.0), _rng.randf_range(50.0, 86.0)), _rng.randf_range(1.5, 3.2), true, 300.0 + k)
	var pontos := [Vector2(-22.0, 74.0), Vector2(24.0, 58.0), Vector2(-30.0, 22.0), Vector2(32.0, -6.0)]
	for p in pontos:   # cada minério fica no meio de um foco de calor e fumaça
		var pilha := PilhaDeItem.new()
		pilha.item = "minerio_vulcanico"
		pilha.position = Vector3(p.x, _y(p), p.y)
		add_child(pilha)
		minerios.append(pilha)
		for dx in [-2.4, 2.4]:
			var fogo := Fogo.new()
			fogo.escala = 1.3
			fogo.dano = 4
			fogo.raio_dano = 1.6
			fogo.position = Vector3(p.x + dx, _y(p), p.y + 1.5)
			add_child(fogo)
	_placa_em_poste(Vector2(8.0, 122.0), "Cratera de Ignis")
	_placa_em_poste(Vector2(-8.0, 60.0), "Calor: o chão queima")
	for p in [Vector2(-8.0, 68.0), Vector2(12.0, 52.0)]:   # patrulhas
		_inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(p.x, _y(p) + 0.2, p.y), "Guarda da Cratera", "guarda_cratera")
	_inimigo("res://scenes/inimigos/cao_de_guerra.tscn", Vector3(0, _y(Vector2(0, 62)) + 0.3, 62), "Cão de Guerra", "cao_guerra")
	_inimigo("res://scenes/inimigos/arqueiro.tscn", _torre_de_vigia(Vector2(-60.0, 44.0), 6.0) + Vector3(0, 0.3, 0), "Arqueiro Imperial", "arqueiro")


# ---------------------------------------------------------------- pátio das forjas

func _forjas() -> void:
	_edificio("AlojamentoDosTrabalhadores", Vector2(-50.0, 12.0), PI / 2.0, REF.ESTILO_MADEIRA, "Alojamento dos Trabalhadores", "moradia")
	_edificio("DepositoDeLingotes", Vector2(50.0, 12.0), -PI / 2.0, REF.ESTILO_PEDRA, "Depósito de Lingotes", "deposito")
	_edificio("SalaDeControleDasCorrentes", Vector2(58.0, -24.0), -PI / 2.0, REF.ESTILO_PEDRA, "Sala de Controle das Correntes", "moradia")
	_lingotes(Vector2(34.0, 4.0))
	_lingotes(Vector2(36.0, 22.0))
	_guindaste(Vector2(-22.0, 0.0))
	_guindaste(Vector2(22.0, 26.0))
	var zona := ZonaDeEvento.new()
	zona.id = "alojamento_ignis"
	zona.raio = 9.0
	zona.position = Vector3(-38.0, _y(Vector2(-38.0, 12.0)), 12.0)
	add_child(zona)
	var posicoes := [Vector2(-40.0, -20.0), Vector2(40.0, -20.0), Vector2(0.0, -30.0)]
	for k in 3:
		var f := FornalhaNegra.new()
		f.tipo = k
		f.position = Vector3(posicoes[k].x, _y(posicoes[k]), posicoes[k].y)
		add_child(f)
		fornalhas.append(f)
	for p in [Vector2(-6.0, 8.0), Vector2(8.0, -8.0)]:
		_inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(p.x, _y(p) + 0.2, p.y), "Guarda da Cratera", "guarda_cratera")
	_placa_em_poste(Vector2(8.0, 34.0), "Pátio das Forjas Negras")
	for p in [Vector2(-60.0, -10.0), Vector2(62.0, -6.0), Vector2(-20.0, 20.0)]:
		ConstrutorCasa._movel(self, _solidos, "Barrel", p.x, p.y, 0.0, _y(p))
		ConstrutorCasa._movel(self, _solidos, "Chest_Wood", p.x + 1.4, p.y, 20.0, _y(p))


# ---------------------------------------------------------------- arena de Ignis-Maw

func _arena() -> void:
	var piso := MeshInstance3D.new()   # círculo de runas gravado no chão
	var c := CylinderMesh.new()
	c.top_radius = RAIO_MAX
	c.bottom_radius = RAIO_MAX
	c.height = 0.05
	c.material = VilaRefugio._mat(Color(0.2, 0.1, 0.09))
	piso.mesh = c
	piso.position = Vector3(ARENA.x, _y(ARENA) + 0.03, ARENA.y)
	add_child(piso)
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = RAIO_MAX - 0.4
	t.outer_radius = RAIO_MAX
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.05)
	mat.emission_energy_multiplier = 2.0
	t.material = mat
	anel.mesh = t
	anel.position = Vector3(ARENA.x, _y(ARENA) + 0.1, ARENA.y)
	add_child(anel)
	# Caldeira Ancestral: poço de lava cercado de pedra, a oeste da arena
	var caldeira := Vector2(-66.0, -120.0)
	var lava := ZonaDeCalor.new()
	lava.tamanho = Vector2(16.0, 16.0)
	lava.position = Vector3(caldeira.x, _y(caldeira), caldeira.y)
	add_child(lava)
	for k in 12:
		var a := TAU * k / 12.0
		_rocha(caldeira + Vector2(cos(a), sin(a)) * 11.0, 2.6, true, 400.0 + k)
	_placa_em_poste(caldeira + Vector2(0.0, 14.0), "Caldeira Ancestral")
	_placa_em_poste(Vector2(8.0, -56.0), "Arena de Ignis-Maw")
	for k in 4:
		var a := TAU * k / 4.0
		var pos := ARENA + Vector2(cos(a), sin(a)) * RAIO_ANCORAS
		_bandeira(ARENA + Vector2(cos(a + PI / 4.0), sin(a + PI / 4.0)) * (RAIO_ANCORAS + 6.0), Color(0.9, 0.35, 0.05))
		var an := AncoraDeObelisco.new()
		an.vida = 110
		an.position = Vector3(pos.x, _y(pos), pos.y)
		an.visible = false   # as âncoras só aparecem quando Ignis-Maw acorda (depois da C4-M2)
		an.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(an)
		ancoras.append(an)


func _gente() -> void:
	var tarn := _npc("Tarn", "Trabalhador da forja", "res://scenes/personagens/cativo.tscn", Vector2(-38.0, 20.0),
		PackedStringArray(["Estou há anos aqui. O calor não perdoa.", "Se vai mexer nas forjas, cuidado com a lava."]),
		[{"esperar": 8.0, "anim": "Idle_Talking", "olhar": Vector2(-10.0, 20.0)}, {"fazer": "Interact", "seg": 6.0, "olhar": Vector2(-44.0, 20.0)}])
	tarn.nome = "Tarn"
	_npc("Trabalhador Cansado", "Trabalhador", "res://scenes/personagens/soldado_ferido.tscn", Vector2(-30.0, 4.0),
		PackedStringArray(["Dizem que o dragão acorda quando as forjas apagam.", "Quando isso acontecer, corra para longe da arena."]),
		[{"esperar": 7.0, "anim": "Crouch_Idle", "olhar": Vector2(-30.0, -10.0)}, {"ir": Vector2(-34.0, 10.0), "vel": 1.2}, {"esperar": 5.0, "anim": "Idle", "olhar": Vector2(-30.0, 10.0)}, {"ir": Vector2(-30.0, 4.0), "vel": 1.2}])
	_npc("Operário da Fornalha", "Trabalhador", "res://scenes/personagens/cativa.tscn", Vector2(30.0, -6.0),
		PackedStringArray(["Cada fornalha tem o seu truque. A das runas pede ordem, a dos canos pede força, a do sopro pede pressa."]),
		[{"fazer": "Interact", "seg": 6.0, "olhar": Vector2(40.0, -20.0)}, {"esperar": 5.0, "anim": "Idle", "olhar": Vector2(30.0, 10.0)}])


func _forja_de_campo() -> void:
	if brenn != null:
		return
	var p := Vector2(-30.0, 14.0)
	ConstrutorCasa._movel(self, _solidos, "Anvil", p.x + 1.8, p.y, 0.0, _y(p))
	_fogueira(p + Vector2(-2.0, 0.0), 0.8, 10.0)
	brenn = _npc("Brenn", "Ferreira", "res://scenes/personagens/brenn.tscn", p,
		PackedStringArray(["Montei uma forja de campo. Traga o que a lâmina precisa."]),
		[{"fazer": "Sword_Attack", "seg": 9.0, "olhar": p + Vector2(1.8, 0.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 20.0)}])


# ---------------------------------------------------------------- Ignis-Maw

func _acordar_ignis() -> void:
	if ignis != null:
		return
	ignis = (load("res://scenes/inimigos/ignis_maw.tscn") as PackedScene).instantiate() as Inimigo
	ignis.especie = "ignis_maw"
	ignis.enfurece_em = 0.0
	ignis.position = Vector3(ARENA.x, _y(ARENA) + 0.1, ARENA.y)
	add_child(ignis)
	ignis.vida_mudou.connect(func(_a: int, _m: int) -> void: ignis.vida = ignis.vida_max)   # ele não morre a golpes: só as âncoras o libertam
	for an in ancoras:
		an.visible = true
		an.process_mode = Node.PROCESS_MODE_INHERIT
		an.destruida.connect(_ao_ancora_destruida)
		_corrente(an)


## Corrente de ferro da âncora até o peito do Ignis-Maw; some quando a âncora cai.
func _corrente(an: AncoraDeObelisco) -> void:
	var de := an.position + Vector3(0, 4.0, 0)
	var para := Vector3(ARENA.x, _y(ARENA) + 5.0, ARENA.y)
	var elo := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.35, 0.35, de.distance_to(para))
	b.material = VilaRefugio._mat(Color(0.12, 0.12, 0.14))
	elo.mesh = b
	add_child(elo)
	elo.position = (de + para) / 2.0
	elo.look_at_from_position(elo.position, para, Vector3.UP)
	an.corrente = elo


func _ao_ancora_destruida() -> void:
	_restantes -= 1
	chefe_vida.emit("Ignis-Maw (âncoras)", _restantes, 4)
	if ignis and _restantes > 0:   # cada âncora que cai o deixa mais furioso
		ignis.velocidade *= 1.12
		ignis.intervalo_ataque *= 0.9
	if _restantes <= 0:
		_libertar()


func _libertar() -> void:
	solto = true
	ignis.set_physics_process(false)
	for b in _brasas:
		if is_instance_valid(b):
			b.queue_free()
	GerenciadorMissoes.instancia.aviso.emit("As correntes se partem! Ignis-Maw ruge e se ergue!", 4.0)
	var v := ignis.visual
	var tw := create_tween()
	tw.tween_property(v, "scale", v.scale * 1.15, 0.6)
	tw.tween_property(v, "scale", v.scale, 0.4)
	tw.tween_property(ignis, "global_position", ignis.global_position + Vector3(0, 60.0, -90.0), 5.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		ignis.queue_free()
		for f in fornalhas:
			f.desabar()
		var escama := Pickup.new()
		escama.item = "escama_ancestral"
		escama.quantidade = 1
		add_child(escama)
		escama.position = Vector3(ARENA.x, _y(ARENA) + 0.5, ARENA.y)
		chefe_morreu.emit("ignis_maw"))


func _process(delta: float) -> void:
	if ignis == null or solto or not is_instance_valid(ignis):
		return
	var loc := to_local(ignis.global_position)   # ARENA está nas coordenadas da área
	var rel := Vector2(loc.x - ARENA.x, loc.z - ARENA.y)
	if rel.length() > RAIO_MAX - 4.0:   # preso às correntes: não sai da arena
		rel = rel.normalized() * (RAIO_MAX - 4.0)
		ignis.global_position = to_global(Vector3(ARENA.x + rel.x, loc.y, ARENA.y + rel.y))
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog == null:
		return
	if not engajado and jog.global_position.distance_to(ignis.global_position) < 60.0:
		engajado = true
		chefe_vida.emit("Ignis-Maw (âncoras)", _restantes, 4)
	if not engajado:
		return
	_t_onda -= delta
	if _t_onda <= 0.0:
		_t_onda = 9.0
		_onda_de_calor()
	_t_brasas -= delta
	if _t_brasas <= 0.0:
		_t_brasas = 12.0
		_chuva_de_brasas(jog)


## Onda de calor: um anel que se expande a partir do Ignis-Maw. Só fere quem está no chão quando ele passa (pule!).
func _onda_de_calor() -> void:
	var centro := ignis.global_position
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.1)
	mat.emission_energy_multiplier = 3.0
	t.material = mat
	anel.mesh = t
	add_child(anel)
	var c_loc := to_local(centro)
	anel.position = Vector3(c_loc.x, _y(Vector2(c_loc.x, c_loc.z)) + 0.3, c_loc.z)
	GerenciadorMissoes.instancia.aviso.emit("Onda de calor! Pule!", 1.5)
	var tw := create_tween()
	tw.tween_method(func(r: float) -> void:
		anel.scale = Vector3(r, 1.0, r)
		var jog := get_tree().get_first_node_in_group("jogador") as Jogador
		if jog and not jog.morto and jog.is_on_floor():
			var d := Vector2(jog.global_position.x - centro.x, jog.global_position.z - centro.z).length()
			if absf(d - r) < 1.6 and not anel.has_meta("acertou"):
				anel.set_meta("acertou", true)
				jog.receber_dano(18, ignis), 3.0, RAIO_MAX + 4.0, 2.2)
	tw.tween_callback(anel.queue_free)


## Brasas: três focos de fogo caem em volta do jogador e queimam por alguns segundos.
func _chuva_de_brasas(jog: Jogador) -> void:
	for k in 3:
		var f := Fogo.new()
		f.escala = 1.4
		f.dano = 6
		f.raio_dano = 1.6
		var a := _rng.randf() * TAU
		var lj := to_local(jog.global_position)
		var p := Vector2(lj.x, lj.z) + Vector2(cos(a), sin(a)) * _rng.randf_range(2.0, 6.0)
		f.position = Vector3(p.x, _y(p), p.y)
		add_child(f)
		_brasas.append(f)
		get_tree().create_timer(6.0).timeout.connect(func() -> void:
			if is_instance_valid(f):
				f.queue_free())
	GerenciadorMissoes.instancia.aviso.emit("Brasas caem ao seu redor!", 1.8)


func _ao_missao_concluida(id: String) -> void:
	if id == "C4-M2":
		_acordar_ignis()
	elif id == "C4-M3":
		_forja_de_campo()
