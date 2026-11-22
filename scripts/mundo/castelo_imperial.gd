extends AreaAberta
## Castelo Imperial (Capítulo V), sobre uma plataforma elevada (3 m). De sul a norte: Escadaria monumental -> Pátio
## Externo (Estábulos Reais, Sala de Armas) -> Galeria de Estandartes e Prisão Subterrânea -> Pátio do Duelo (Vane)
## -> Salão do Trono com o Grande Obelisco e seus 4 focos de energia. O portão do salão abre quando Vane cai; Solon
## só aparece depois que os 4 focos caem, protegido por um escudo que a Fagulha quebra na metade da luta.

signal chefe_vida(nome: String, atual: int, maximo: int)
signal chefe_morreu(id: String)

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const PLAT := 3.0
const SUL_Z := 106.0
const NORTE_Z := -124.0
const LADO := 75.0
const DUELO := Vector2(0.0, 0.0)
const TRONO := Vector2(0.0, -100.0)
const COR_DRAKKAR := Color(0.65, 0.1, 0.08)

var vane: Inimigo
var solon: Inimigo
var portao_salao: Portao
var focos: Array[AncoraDeObelisco] = []
var presos: Array[CelaTrancada] = []
var escudo := false
var duelo_iniciado := false
var _focos_restantes := 4
var _luz_obelisco: OmniLight3D
var _mat_obelisco: StandardMaterial3D
var _vida_solon_antes := 0
var _t_brasas := 8.0
var _fase_vane := 0


func altura_em(x: float, z: float) -> float:
	if z < SUL_Z:
		return PLAT
	if z < SUL_Z + 18.0 and absf(x) < 12.0:   # a escadaria monumental sobe 3 m
		return PLAT * (SUL_Z + 18.0 - z) / 18.0
	return 0.0


func _ready() -> void:
	nome_area = "Castelo Imperial"
	paleta_casas = {"parede": Color(0.95, 0.95, 1.0), "telhado": Color(0.45, 0.5, 0.7)}   # pedra clara real e telhado azul-ardósia
	tam = 300.0
	_rng.seed = 97
	_ambiente()
	_montar_terreno(61, 0.0, [], PackedVector2Array([Vector2(0, 155), Vector2(0, 150), Vector2(0, -100)]), Color(0.3, 0.28, 0.28), Color(0.25, 0.23, 0.23), 260.0)
	_horizonte(Color(0.38, 0.36, 0.4), 140.0, true)
	_plataforma()
	_muralhas()
	_patio_externo()
	_galeria_e_prisao()
	_patio_do_duelo()
	_salao()
	_gente()
	_novo_spawn("Entrada", Vector3(0, 0, 138), Vector3(0, 0, 100))
	_novo_spawn("Principal", Vector3(0, 0, 138), Vector3(0, 0, 100))
	_portal(Vector3(0, 0, 146), "valdoria", "DoCastelo", 16.0)
	var m := GerenciadorMissoes.instancia
	if m:
		m.missao_concluida.connect(_ao_missao_concluida)
		if m.concluidas.has("C5-M2"):
			portao_salao.abrir()
			if vane and is_instance_valid(vane):
				vane.queue_free()
		if m.concluidas.has("C5-M3") and not m.concluidas.has("C5-M4"):
			_spawn_solon()


func _ambiente() -> void:
	_ambiente_padrao()
	var we := get_node("Ambiente") as WorldEnvironment
	var e := we.environment
	var ceu := e.sky.sky_material as ProceduralSkyMaterial
	ceu.sky_top_color = Color(0.32, 0.3, 0.38)
	ceu.sky_horizon_color = Color(0.72, 0.58, 0.45)
	e.fog_light_color = Color(0.62, 0.52, 0.45)
	e.fog_density = 0.0025
	e.ambient_light_energy = 0.55
	(get_node("Sol") as DirectionalLight3D).light_energy = 0.6


func _plataforma() -> void:
	var pedra := VilaRefugio._mat(Color(0.34, 0.32, 0.32))
	VilaRefugio._caixa(Vector3(0.0, PLAT / 2.0, (SUL_Z + NORTE_Z) / 2.0), Vector3(LADO * 2.0 + 4.0, PLAT, SUL_Z - NORTE_Z + 4.0), pedra, true)
	var comp := 18.0
	var ang := atan2(PLAT, comp)
	var rampa := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(24.0, 0.6, sqrt(comp * comp + PLAT * PLAT) + 1.0)
	cs.shape = forma
	rampa.add_child(cs)
	rampa.position = Vector3(0.0, PLAT / 2.0 - 0.3, SUL_Z + comp / 2.0)
	rampa.rotation.x = ang   # sobe para o norte (-Z)
	add_child(rampa)
	var degraus := VilaRefugio._mat(Color(0.55, 0.52, 0.48))
	for i in 12:   # degraus da escadaria monumental (desenho; a colisão é a rampa)
		var t := (i + 0.5) / 12.0
		VilaRefugio._caixa(Vector3(0.0, PLAT * (1.0 - t) - 0.2, SUL_Z + comp * t), Vector3(24.0, 0.45, comp / 12.0 + 0.1), degraus)
	_placa_em_poste(Vector2(16.0, SUL_Z + 20.0), "Escadaria Monumental do Castelo")


func _muralhas() -> void:
	var cor := Color(0.4, 0.38, 0.4)
	_muralha(Vector2(-LADO, SUL_Z), Vector2(-14.0, SUL_Z), 9.0, cor)
	_muralha(Vector2(14.0, SUL_Z), Vector2(LADO, SUL_Z), 9.0, cor)
	_muralha(Vector2(-LADO, SUL_Z), Vector2(-LADO, NORTE_Z), 9.0, cor)
	_muralha(Vector2(LADO, SUL_Z), Vector2(LADO, NORTE_Z), 9.0, cor)
	_muralha(Vector2(-LADO, NORTE_Z), Vector2(LADO, NORTE_Z), 9.0, cor)
	for t in [Vector2(-16.0, SUL_Z), Vector2(16.0, SUL_Z), Vector2(-LADO, SUL_Z), Vector2(LADO, SUL_Z), Vector2(-LADO, NORTE_Z), Vector2(LADO, NORTE_Z)]:
		_torre_de_vigia(t, 11.0)
	for x in range(-60, 61, 20):
		_bandeira(Vector2(float(x), SUL_Z - 4.0), COR_DRAKKAR)


# ---------------------------------------------------------------- pátio externo

func _patio_externo() -> void:
	_edificio("EstabulosReais", Vector2(-50.0, 84.0), PI / 2.0, REF.ESTILO_PEDRA, "Estábulos Reais", "deposito")
	_edificio("SalaDeArmas", Vector2(50.0, 84.0), -PI / 2.0, REF.ESTILO_PEDRA, "Sala de Armas", "moradia")
	var curral := Vector2(-34.0, 62.0)
	for lado in [[Vector2(-7, -5), Vector2(7, -5)], [Vector2(-7, -5), Vector2(-7, 5)], [Vector2(7, -5), Vector2(7, 5)], [Vector2(-7, 5), Vector2(7, 5)]]:
		_muralha(curral + lado[0], curral + lado[1], 1.5, Color(0.3, 0.2, 0.11))
	for k in 3:
		var a := AnimalVila.new()
		a.modelo = load("res://assets/models/criaturas/cavalo/cavalo.glb")
		a.nome = "Cavalo Real"
		a.especie = "cavalo"
		a.raio_vagar = 2.0
		a.altura_em = altura_em
		a.position = Vector3(curral.x - 3.0 + k * 3.0, _y(curral), curral.y)
		add_child(a)
	for k in 4:   # arsenal do pátio
		var p := Vector2(38.0 + k * 3.0, 64.0)
		ConstrutorCasa._movel(self, _solidos, "WeaponStand", p.x, p.y, 0.0, _y(p))
	for p in [Vector2(-14.0, 76.0), Vector2(14.0, 76.0)]:
		_fogueira(p, 0.7, 10.0)
	_placa_em_poste(Vector2(10.0, 98.0), "Pátio Externo")
	for p in [Vector2(-12.0, 90.0), Vector2(12.0, 90.0), Vector2(-14.0, 66.0), Vector2(14.0, 66.0)]:
		_inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(p.x, _y(p) + 0.2, p.y), "Guarda Real", "guarda_real")
	for t in [Vector2(-20.0, 50.0), Vector2(20.0, 50.0)]:
		_inimigo("res://scenes/inimigos/arqueiro.tscn", _torre_de_vigia(t, 7.0) + Vector3(0, 0.3, 0), "Arqueiro Real", "arqueiro")


# ---------------------------------------------------------------- galeria de estandartes e prisão subterrânea

func _galeria_e_prisao() -> void:
	var pedra := VilaRefugio._mat(Color(0.5, 0.47, 0.44))
	var cores := [Color(0.65, 0.1, 0.08), Color(0.15, 0.3, 0.5), Color(0.2, 0.4, 0.2), Color(0.6, 0.45, 0.1), Color(0.35, 0.2, 0.4), Color(0.5, 0.5, 0.5)]
	for k in 6:   # colunata com os estandartes das regiões conquistadas
		var z := 44.0 - k * 6.0
		for lado in [-1.0, 1.0]:
			var y := _y(Vector2(lado * 14.0, z))
			VilaRefugio._cilindro(Vector3(lado * 14.0, y + 3.5, z), 0.8, 7.0, pedra, true, 10)
			VilaRefugio._caixa(Vector3(lado * 13.2, y + 4.2, z), Vector3(0.06, 3.0, 1.6), VilaRefugio._mat(cores[(k + int(lado)) % 6]))
	for lado in [-1.0, 1.0]:
		VilaRefugio._caixa(Vector3(lado * 14.0, _y(Vector2(lado * 14.0, 28.0)) + 7.2, 28.0), Vector3(1.4, 0.5, 36.0), pedra)
	_placa_em_poste(Vector2(8.0, 50.0), "Galeria de Estandartes")
	_edificio("PrisaoSubterranea", Vector2(52.0, 30.0), -PI / 2.0, REF.ESTILO_PEDRA, "Prisão Subterrânea", "deposito")
	var cela := CelaTrancada.new()
	cela.tipo = "civis"
	var pos := Vector2(34.0, 14.0)
	cela.position = Vector3(pos.x, _y(pos), pos.y + 2.0)
	add_child(cela)
	var preso := Npc.new()
	preso.nome = "Prisioneiro de Valdoria"
	preso.papel = "Preso"
	preso.falas = PackedStringArray(["O Imperador manda prender quem pergunta demais. Se tiver a chave, abra."])
	preso.cena = load("res://scenes/personagens/cativo.tscn")
	preso.rotina = [{"esperar": 8.0, "anim": "Idle"}, {"esperar": 5.0, "anim": "Crouch_Idle"}]
	preso.altura_em = altura_em
	preso.position = Vector3(pos.x, _y(pos), pos.y)
	add_child(preso)
	npcs.append(preso)
	cela.ocupantes.append(preso)
	presos.append(cela)
	var carcereiro := _inimigo("res://scenes/inimigos/guarda_imperial.tscn", Vector3(40.0, _y(Vector2(40.0, 20.0)) + 0.2, 20.0), "Carcereiro Real", "guarda_real", {"chave": [1, 1]})
	carcereiro.name = "Carcereiro"


# ---------------------------------------------------------------- pátio do duelo (Vane)

func _patio_do_duelo() -> void:
	var y := _y(DUELO)
	var piso := VilaRefugio._cilindro(Vector3(DUELO.x, y + 0.04, DUELO.y), 24.0, 0.08, VilaRefugio._mat(Color(0.34, 0.3, 0.3)), false, 28)
	piso.name = "PisoDoDuelo"
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 23.6
	t.outer_radius = 24.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.15, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.2, 0.1)
	t.material = mat
	anel.mesh = t
	anel.position = Vector3(DUELO.x, y + 0.1, DUELO.y)
	add_child(anel)
	for k in 8:
		var a := TAU * k / 8.0
		var p := DUELO + Vector2(cos(a), sin(a)) * 27.0
		_fogueira(p, 0.7, 11.0)
		_bandeira(DUELO + Vector2(cos(a + PI / 8.0), sin(a + PI / 8.0)) * 30.0, COR_DRAKKAR)
	_placa_em_poste(Vector2(8.0, 34.0), "Pátio do Duelo")
	vane = (load("res://scenes/inimigos/vane_duelista.tscn") as PackedScene).instantiate() as Inimigo
	vane.alcance_visao = 0.0   # só acorda depois da conversa
	vane.position = Vector3(DUELO.x, y + 0.1, DUELO.y - 8.0)
	add_child(vane)
	vane.vida_mudou.connect(_ao_vida_do_vane)
	vane.morreu.connect(_ao_vane_cair)


# ---------------------------------------------------------------- salão do trono e Grande Obelisco

func _salao() -> void:
	var cor := Color(0.3, 0.28, 0.32)
	_muralha(Vector2(-30.0, -50.0), Vector2(-7.0, -50.0), 14.0, cor)
	_muralha(Vector2(7.0, -50.0), Vector2(30.0, -50.0), 14.0, cor)
	_muralha(Vector2(-30.0, -50.0), Vector2(-30.0, -118.0), 14.0, cor)
	_muralha(Vector2(30.0, -50.0), Vector2(30.0, -118.0), 14.0, cor)
	_muralha(Vector2(-30.0, -118.0), Vector2(30.0, -118.0), 14.0, cor)
	portao_salao = Portao.new()
	portao_salao.position = Vector3(0, _y(Vector2(0, -50)), -50.0)
	portao_salao.largura = 14.0
	add_child(portao_salao)
	_placa_em_poste(Vector2(10.0, -44.0), "Salão do Trono")
	VilaRefugio._caixa(Vector3(0, _y(Vector2(0, -80)) + 0.05, -80.0), Vector3(8.0, 0.1, 60.0), VilaRefugio._mat(Color(0.5, 0.08, 0.08)))   # tapete
	for k in 5:   # colunas do salão
		for lado in [-1.0, 1.0]:
			var z := -60.0 - k * 11.0
			VilaRefugio._cilindro(Vector3(lado * 24.0, _y(Vector2(lado * 24.0, z)) + 6.0, z), 1.0, 12.0, VilaRefugio._mat(Color(0.42, 0.4, 0.42)), true, 10)
	var y := _y(TRONO)
	VilaRefugio._caixa(Vector3(0, y + 0.4, TRONO.y), Vector3(14.0, 0.8, 9.0), VilaRefugio._mat(Color(0.32, 0.3, 0.32)), true)   # estrado
	VilaRefugio._caixa(Vector3(0, y + 1.6, TRONO.y - 2.0), Vector3(2.4, 1.6, 2.0), VilaRefugio._mat(Color(0.1, 0.1, 0.12)), true)   # trono
	VilaRefugio._caixa(Vector3(0, y + 3.2, TRONO.y - 2.9), Vector3(2.4, 3.0, 0.4), VilaRefugio._mat(Color(0.1, 0.1, 0.12)))
	# Grande Obelisco: atravessa o teto (aqui sem teto) atrás do trono, emitindo luz negra
	var corpo := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.7
	c.bottom_radius = 3.6
	c.height = 46.0
	c.radial_segments = 4
	var negro := StandardMaterial3D.new()   # luz negra: preto liso que não reflete o céu
	negro.albedo_color = Color(0.02, 0.02, 0.04)
	negro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	c.material = negro
	corpo.mesh = c
	corpo.position = Vector3(0, y + 23.0, -113.0)
	add_child(corpo)
	_mat_obelisco = StandardMaterial3D.new()
	_mat_obelisco.albedo_color = Color(0.7, 0.85, 1.0)
	_mat_obelisco.emission_enabled = true
	_mat_obelisco.emission = Color(0.6, 0.8, 1.0)
	_mat_obelisco.emission_energy_multiplier = 3.0
	for k in 4:
		var veio := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.2, 30.0, 0.2)
		b.material = _mat_obelisco
		veio.mesh = b
		veio.position = Vector3(cos(k * PI / 2.0 + PI / 4.0) * 1.9, y + 17.0, -113.0 + sin(k * PI / 2.0 + PI / 4.0) * 1.9)
		add_child(veio)
	_luz_obelisco = OmniLight3D.new()
	_luz_obelisco.light_color = Color(0.5, 0.7, 1.0)
	_luz_obelisco.light_energy = 4.0
	_luz_obelisco.omni_range = 40.0
	_luz_obelisco.position = Vector3(0, y + 8.0, -108.0)
	add_child(_luz_obelisco)
	_placa_em_poste(Vector2(-12.0, -108.0), "Câmara do Grande Obelisco")
	for pos in [Vector2(-18.0, -68.0), Vector2(18.0, -68.0), Vector2(-18.0, -90.0), Vector2(18.0, -90.0)]:   # 4 focos de energia
		var f := AncoraDeObelisco.new()
		f.vida = 90
		f.position = Vector3(pos.x, _y(pos), pos.y)
		add_child(f)
		focos.append(f)
		f.destruida.connect(_ao_foco_destruido)
		var de := f.position + Vector3(0, 4.0, 0)
		var para := Vector3(0, y + 4.0, -113.0)
		var elo := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.3, 0.3, de.distance_to(para))
		b.material = _mat_obelisco
		elo.mesh = b
		add_child(elo)
		elo.look_at_from_position((de + para) / 2.0, para, Vector3.UP)
		f.corrente = elo


func _gente() -> void:
	_npc("Garth", "Mestre de Armas", "res://scenes/personagens/dorn.tscn", Vector2(44.0, 72.0), PackedStringArray(["Treino a guarda real há vinte anos. Hoje ninguém mais quer lutar."]),
		[{"fazer": "Sword_Attack", "seg": 8.0, "olhar": Vector2(38.0, 70.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 72.0)}])
	_npc("Tom", "Estribeiro", "res://scenes/personagens/orin.tscn", Vector2(-40.0, 70.0), PackedStringArray(["Os cavalos reais não gostam do cheiro de dragão. Fique longe deles."]),
		[{"fazer": "Interact", "seg": 6.0, "olhar": Vector2(-34.0, 62.0)}, {"ir": Vector2(-38.0, 76.0), "vel": 1.2}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(-34.0, 62.0)}, {"ir": Vector2(-40.0, 70.0), "vel": 1.2}])
	_npc("Arauto", "Arauto do Império", "res://scenes/personagens/oren.tscn", Vector2(0.0, 30.0), PackedStringArray(["O Império de Drakkar é eterno! ...ou era, até hoje cedo."]),
		[{"esperar": 7.0, "anim": "Idle_Talking", "olhar": Vector2(0.0, 60.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 60.0)}])
	_npc("Lis", "Criada do castelo", "res://scenes/personagens/cativa.tscn", Vector2(-20.0, 40.0), PackedStringArray(["Levo toalhas para a ala do Imperador. Ele não sai de lá."]),
		[{"ir": Vector2(-20.0, 20.0), "vel": 1.4}, {"esperar": 3.0, "anim": "Interact", "olhar": Vector2(-20.0, 14.0)}, {"ir": Vector2(-20.0, 40.0), "vel": 1.4}, {"esperar": 3.0, "anim": "Idle", "olhar": Vector2(0.0, 40.0)}])


# ---------------------------------------------------------------- duelo com Vane

func _process(delta: float) -> void:
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog == null:
		return
	if vane and is_instance_valid(vane) and not duelo_iniciado:
		var m := GerenciadorMissoes.instancia
		if m and m.ativas.has("C5-M2") and jog.global_position.distance_to(vane.global_position) < 22.0:
			_comecar_duelo()
	if vane and is_instance_valid(vane) and _fase_vane >= 1 and vane.estado != Inimigo.Estado.MORTO:
		_t_brasas -= delta
		if _t_brasas <= 0.0:
			_t_brasas = 10.0
			_brasas_corrompidas(jog)
	if solon and is_instance_valid(solon) and solon.estado != Inimigo.Estado.MORTO:
		var loc := to_local(solon.global_position)   # TRONO está nas coordenadas da área
		var rel := Vector2(loc.x - TRONO.x, loc.z - (TRONO.y + 30.0))
		if rel.length() > 36.0:   # o salão é a arena
			rel = rel.normalized() * 36.0
			solon.global_position = to_global(Vector3(TRONO.x + rel.x, loc.y, TRONO.y + 30.0 + rel.y))


func _comecar_duelo() -> void:
	duelo_iniciado = true
	var jogo := get_tree().get_first_node_in_group("jogo")
	var fim := func() -> void:
		vane.alcance_visao = 60.0
		chefe_vida.emit(vane.nome, vane.vida, vane.vida_max)
	if jogo == null:
		fim.call()
		return
	jogo.cena_dialogo([
		["Vane", "Você chegou até aqui, Torin. Eu sabia que chegaria."],
		["Torin", "Vane, o Império usou você. O Ferro Negro está te consumindo."],
		["Vane", "Eu aprendi com você, e o Ferro Negro me ensinou o resto. Mostre o que aprendeu comigo."],
	], fim)


func _ao_vida_do_vane(atual: int, maximo: int) -> void:
	chefe_vida.emit(vane.nome, atual, maximo)
	if _fase_vane == 0 and float(atual) / maximo <= 0.5:
		_fase_vane = 1
		GerenciadorMissoes.instancia.aviso.emit("O Ferro Negro toma o Vane: ataques corrompidos!", 3.0)


## Ataque corrompido do Vane: brasas negras em volta do jogador.
func _brasas_corrompidas(jog: Jogador) -> void:
	for k in 3:
		var f := Fogo.new()
		f.escala = 1.3
		f.dano = 6
		f.raio_dano = 1.5
		var a := _rng.randf() * TAU
		var lj := to_local(jog.global_position)
		var p := Vector2(lj.x, lj.z) + Vector2(cos(a), sin(a)) * _rng.randf_range(2.0, 5.0)
		f.position = Vector3(p.x, _y(p), p.y)
		add_child(f)
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			if is_instance_valid(f):
				f.queue_free())


func _ao_vane_cair(_i: Inimigo) -> void:
	portao_salao.abrir()
	chefe_morreu.emit("vane")
	var jogo := get_tree().get_first_node_in_group("jogo")
	if jogo:
		jogo.cena_dialogo([
			["Vane", "Eu só queria proteger o bando... e o poder me escolheu primeiro."],
			["Vane", "Vá, Torin. O salão do trono está aberto. Acabe com isso."],
		])


# ---------------------------------------------------------------- focos, Solon

func _ao_foco_destruido() -> void:
	_focos_restantes -= 1
	if _focos_restantes <= 0:
		create_tween().tween_property(_luz_obelisco, "light_energy", 0.0, 3.0)
		create_tween().tween_property(_mat_obelisco, "emission_energy_multiplier", 0.0, 3.0)
		GerenciadorMissoes.instancia.aviso.emit("A luz negra do Grande Obelisco se apaga!", 4.0)


func _ao_missao_concluida(id: String) -> void:
	if id == "C5-M3":
		_spawn_solon()


func _spawn_solon() -> void:
	if solon != null:
		return
	solon = (load("res://scenes/inimigos/solon.tscn") as PackedScene).instantiate() as Inimigo
	solon.especie = "solon"
	solon.position = Vector3(TRONO.x, _y(TRONO) + 1.0, TRONO.y + 8.0)
	add_child(solon)
	escudo = true
	_vida_solon_antes = solon.vida_max
	solon.vida_mudou.connect(_ao_vida_do_solon)
	solon.morreu.connect(func(_i: Inimigo) -> void: chefe_morreu.emit("solon"))
	chefe_vida.emit("Imperador Solon (escudo do obelisco)", solon.vida_max, solon.vida_max)
	GerenciadorMissoes.instancia.aviso.emit("O Imperador Solon se levanta do trono!", 4.0)


func _ao_vida_do_solon(atual: int, maximo: int) -> void:
	if escudo:   # o escudo do obelisco absorve 70% do dano
		var perda := _vida_solon_antes - atual
		solon.vida = _vida_solon_antes - int(perda * 0.3)
		atual = solon.vida
	_vida_solon_antes = atual
	chefe_vida.emit("Imperador Solon (escudo do obelisco)" if escudo else "Imperador Solon", atual, maximo)
	if escudo and float(atual) / maximo <= 0.5:
		escudo = false
		_fagulha_quebra_o_escudo()


## A Fagulha mergulha sobre o Solon, quebra o escudo e causa dano.
func _fagulha_quebra_o_escudo() -> void:
	GerenciadorMissoes.instancia.aviso.emit("Fagulha mergulha sobre o Solon! O escudo do obelisco se quebra!", 4.0)
	var f := (load("res://scenes/criaturas/fagulha.tscn") as PackedScene).instantiate() as Node3D
	add_child(f)
	var alvo := solon.global_position + Vector3(0, 3.0, 0)
	f.global_position = alvo + Vector3(-30.0, 22.0, 30.0)
	f.look_at(alvo, Vector3.UP)
	f.rotate_y(PI)
	if f.has_method("tocar"):
		f.call("tocar", "Fly", 0.1)
	var tw := create_tween()
	tw.tween_property(f, "global_position", alvo, 1.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if solon and is_instance_valid(solon) and solon.estado != Inimigo.Estado.MORTO:
			solon.receber_dano(80)
		var chama := Fogo.new()
		chama.escala = 2.5
		chama.energia_luz = 4.0
		add_child(chama)
		chama.global_position = alvo - Vector3(0, 2.5, 0)
		get_tree().create_timer(4.0).timeout.connect(func() -> void:
			if is_instance_valid(chama):
				chama.queue_free()))
	tw.tween_property(f, "global_position", alvo + Vector3(30.0, 30.0, -30.0), 2.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(f.queue_free)
