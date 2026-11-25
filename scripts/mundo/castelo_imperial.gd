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
const BEIRA_SUL := SUL_Z + 2.0   # face sul da plataforma (a caixa dela passa 2 m da muralha): é ali que a escadaria tem de chegar
const NORTE_Z := -124.0
const LADO := 75.0
const DUELO := Vector2(0.0, 0.0)
const TRONO := Vector2(0.0, -100.0)
const COR_DRAKKAR := Color(0.14, 0.2, 0.5)   # hoje é a cor do rei de Valdoria: azul (o vermelho de Drakkar era da história antiga)
const PEDRA_BRANCA := Color(0.86, 0.84, 0.8)   # o castelo é de pedra clara, para se ver de toda a cidade

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
var _i_obelisco := 0   # o obelisco, os veios, a luz e os focos são os filhos de _i_obelisco até _f_obelisco (peças da história antiga)
var _f_obelisco := 0


func altura_em(x: float, z: float) -> float:
	if z < BEIRA_SUL:
		return PLAT
	if z < BEIRA_SUL + 18.0 and absf(x) < 12.0:   # a escadaria monumental sobe 3 m
		return PLAT * (BEIRA_SUL + 18.0 - z) / 18.0
	return 0.0


func _ready() -> void:
	nome_area = "Castelo de Valdoria"
	paleta_casas = {"parede": Color(0.95, 0.95, 1.0), "telhado": Color(0.45, 0.5, 0.7)}   # pedra clara real e telhado azul-ardósia
	tam = 260.0   # o castelo ocupa quase toda a região: sem faixa de terreno sobrando em volta da muralha
	_rng.seed = 97
	_ambiente()
	_montar_terreno(61, 0.0, [], PackedVector2Array([Vector2(0, 155), Vector2(0, 150), Vector2(0, -100)]), Color(0.5, 0.48, 0.44), Color(0.44, 0.42, 0.4), 260.0)   # o alto do rochedo é pedra, não gramado
	_horizonte(Color(0.38, 0.36, 0.4), 140.0, true)
	_plataforma()
	_muralhas()
	_rochedo()
	_patio_externo()
	_galeria_e_prisao()
	_patio_do_duelo()
	_salao()
	_gente()
	_novo_spawn("Entrada", Vector3(0, 0, 138), Vector3(0, 0, 100))
	_novo_spawn("Principal", Vector3(0, 0, 138), Vector3(0, 0, 100))
	_portal(Vector3(0, 0, 146), "valdoria", "DoCastelo", 16.0)
	if not Jogo.historia:
		_corte_do_rei()
		return
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
	var pedra := Pedra.material(Color(0.7, 0.68, 0.64))
	VilaRefugio._caixa(Vector3(0.0, PLAT / 2.0, (SUL_Z + NORTE_Z) / 2.0), Vector3(LADO * 2.0 + 4.0, PLAT, SUL_Z - NORTE_Z + 4.0), pedra, true)
	var comp := 18.0
	var ang := atan2(PLAT, comp)
	var rampa := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(24.0, 0.6, sqrt(comp * comp + PLAT * PLAT) + 1.0)
	cs.shape = forma
	rampa.add_child(cs)
	# A rampa chega ao alto na FACE da plataforma. Antes chegava na linha da muralha, 2 m para dentro: na face faltavam 0,33 m,
	# virava um degrau e não dava para entrar no Castelo a pé (os testes de marco teleportam, por isso não pegavam).
	rampa.position = Vector3(0.0, PLAT / 2.0 - 0.3, BEIRA_SUL + comp / 2.0)
	rampa.rotation.x = ang   # sobe para o norte (-Z)
	add_child(rampa)
	var degraus := VilaRefugio._mat(Color(0.55, 0.52, 0.48))
	for i in 12:   # degraus da escadaria monumental (desenho; a colisão é a rampa)
		var t := (i + 0.5) / 12.0
		VilaRefugio._caixa(Vector3(0.0, PLAT * (1.0 - t) - 0.2, BEIRA_SUL + comp * t), Vector3(24.0, 0.45, comp / 12.0 + 0.1), degraus)
	_placa_em_poste(Vector2(16.0, SUL_Z + 20.0), "Escadaria Monumental do Castelo")


func _muralhas() -> void:
	var cor := PEDRA_BRANCA
	_muralha(Vector2(-LADO, SUL_Z), Vector2(-14.0, SUL_Z), 14.0, cor)
	_muralha(Vector2(14.0, SUL_Z), Vector2(LADO, SUL_Z), 14.0, cor)
	_muralha(Vector2(-LADO, SUL_Z), Vector2(-LADO, NORTE_Z), 14.0, cor)
	_muralha(Vector2(LADO, SUL_Z), Vector2(LADO, NORTE_Z), 14.0, cor)
	_muralha(Vector2(-LADO, NORTE_Z), Vector2(LADO, NORTE_Z), 14.0, cor)
	for t in [Vector2(-16.0, SUL_Z), Vector2(16.0, SUL_Z)]:   # torres do portão
		_torre_de_vigia(t, 19.0, PEDRA_BRANCA)
	var ardosia := VilaRefugio._mat(Color(0.28, 0.32, 0.5))
	for t in [Vector2(-LADO, SUL_Z), Vector2(LADO, SUL_Z), Vector2(-LADO, NORTE_Z), Vector2(LADO, NORTE_Z)]:   # torres dos cantos: altas, com telhado em ponta
		_torre_de_vigia(t, 26.0, PEDRA_BRANCA)
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.1
		cm.bottom_radius = 4.6
		cm.height = 9.0
		cm.radial_segments = 8
		cm.material = ardosia
		cone.mesh = cm
		cone.position = Vector3(t.x, _y(t) + 26.0 + 4.5, t.y)
		add_child(cone)
	# Torres de menagem: quatro torres altas nos cantos do Salão do Trono, com telhado em ponta e bandeira no topo. São elas
	# que dão ao castelo a silhueta de castelo, vista de qualquer rua do reino por cima das muralhas.
	var pedra_alta := Pedra.material(PEDRA_BRANCA)
	for t in [Vector2(-34.0, -46.0), Vector2(34.0, -46.0), Vector2(-34.0, -122.0), Vector2(34.0, -122.0)]:
		var alt := 46.0 if t.y < -100.0 else 38.0
		var yb := _y(t)
		VilaRefugio._caixa(Vector3(t.x, yb + alt / 2.0, t.y), Vector3(9.0, alt, 9.0), pedra_alta, true)
		VilaRefugio._caixa(Vector3(t.x, yb + alt + 0.5, t.y), Vector3(11.0, 1.0, 11.0), pedra_alta)   # cornija
		var ponta := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.1
		pm.bottom_radius = 6.6
		pm.height = 12.0
		pm.radial_segments = 8
		pm.material = ardosia
		ponta.mesh = pm
		ponta.position = Vector3(t.x, yb + alt + 7.0, t.y)
		add_child(ponta)
		VilaRefugio._caixa(Vector3(t.x, yb + alt + 15.5, t.y), Vector3(0.2, 5.0, 0.2), VilaRefugio._mat(Color(0.2, 0.15, 0.1)))   # mastro
		VilaRefugio._caixa(Vector3(t.x + 1.5, yb + alt + 16.8, t.y), Vector3(2.8, 1.8, 0.08), VilaRefugio._mat(COR_DRAKKAR))   # bandeira
	for x in range(-60, 61, 20):
		if x == 0:
			continue   # no eixo do portão não: o mastro ficava no meio da entrada e barrava quem vinha reto pela escadaria
		_bandeira(Vector2(float(x), SUL_Z - 4.0), COR_DRAKKAR)


## O castelo fica sobre um afloramento de rocha: blocos enormes em volta da plataforma, com a rampa do portão livre.
func _rochedo() -> void:
	var e := 0
	for camada in 2:
		var fora := 8.0 + camada * 9.0
		var x0 := -LADO - fora
		var x1 := LADO + fora
		var z0 := NORTE_Z - fora
		var z1 := SUL_Z + fora * 0.5
		var passo := 9.5 - camada * 1.0
		var pontos: Array[Vector2] = []
		var x := x0
		while x <= x1:
			pontos.append(Vector2(x, z0))
			if absf(x) > 22.0 + camada * 8.0:   # o portão e a escadaria ficam abertos
				pontos.append(Vector2(x, z1))
			x += passo
		var z := z0
		while z <= z1:
			pontos.append(Vector2(x0, z))
			pontos.append(Vector2(x1, z))
			z += passo
		for p in pontos:
			e += 1
			_rocha(p + Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0)), _rng.randf_range(6.5, 11.5) + camada * 2.0, true, 300.0 + e)


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
	var cor := PEDRA_BRANCA * 0.94
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
	_i_obelisco = get_child_count()
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

	_f_obelisco = get_child_count()


func _gente() -> void:
	_npc("Garth", "Mestre de Armas", "res://scenes/personagens/dorn.tscn", Vector2(44.0, 72.0), PackedStringArray(["Treino a guarda real há vinte anos. Hoje ninguém mais quer lutar.", "O Vane chegou aqui pedindo emprego e eu o testei. Lutava como quem tem uma dor que não larga. Falei para o Imperador que era perigoso. Ele sorriu."]),
		[{"fazer": "Sword_Attack", "seg": 8.0, "olhar": Vector2(38.0, 70.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 72.0)}])
	_npc("Tom", "Estribeiro", "res://scenes/personagens/orin.tscn", Vector2(-40.0, 70.0), PackedStringArray(["Os cavalos reais não gostam do cheiro de dragão. Fique longe deles."]),
		[{"fazer": "Interact", "seg": 6.0, "olhar": Vector2(-34.0, 62.0)}, {"ir": Vector2(-38.0, 76.0), "vel": 1.2}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(-34.0, 62.0)}, {"ir": Vector2(-40.0, 70.0), "vel": 1.2}])
	_npc("Arauto", "Arauto do Império", "res://scenes/personagens/oren.tscn", Vector2(0.0, 30.0), PackedStringArray(["O Império de Drakkar é eterno! ...ou era, até hoje cedo.", "Eu li as ordens do Imperador por trinta anos. Nunca ouvi a voz dele: só o papel. Hoje desconfio que ele também esqueceu como se fala."]),
		[{"esperar": 7.0, "anim": "Idle_Talking", "olhar": Vector2(0.0, 60.0)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(0.0, 60.0)}])
	_npc("Lis", "Criada do castelo", "res://scenes/personagens/cativa.tscn", Vector2(-20.0, 40.0), PackedStringArray(["Levo toalhas para a ala do Imperador. Ele não sai de lá."]),
		[{"ir": Vector2(-20.0, 20.0), "vel": 1.4}, {"esperar": 3.0, "anim": "Interact", "olhar": Vector2(-20.0, 14.0)}, {"ir": Vector2(-20.0, 40.0), "vel": 1.4}, {"esperar": 3.0, "anim": "Idle", "olhar": Vector2(0.0, 40.0)}])


# ---------------------------------------------------------------- a corte (jogo sem a história antiga)

## Sem a história, o castelo é a casa do rei: nada de duelo, de focos de energia nem de carcereiro. O Salão do Trono fica
## aberto, o rei recebe o Torin diante do trono, com o conselheiro ao lado e a guarda real perfilada no tapete.
func _corte_do_rei() -> void:
	set_process(false)
	if vane and is_instance_valid(vane):
		vane.queue_free()
	for filho in get_children():   # todo soldado inimigo do castelo antigo sai: a guarda agora é do rei e não ataca
		if filho is Inimigo:
			filho.queue_free()
	var da_historia: Array[Node] = []
	for i in range(_i_obelisco, _f_obelisco):   # o Grande Obelisco, os veios de luz, os focos e as correntes saem
		da_historia.append(get_child(i))
	for n in da_historia:
		n.queue_free()
	focos.clear()
	_torre_de_menagem()
	_telhado_do_salao()
	portao_salao.abrir()
	_npc("Rei Aldren", "Rei de Valdoria", "res://scenes/personagens/solon.tscn", Vector2(0.0, -93.0), PackedStringArray(["Então você é o batedor do Pinhal de quem falam. Aproxime-se.", "Um reino se guarda com muralha, e se mantém com gente. Ande pelas ruas, veja como vive o meu povo.", "Há lobos nas estradas e coisa pior nas terras queimadas. Quem as limpa tem a gratidão da coroa."]),
		[{"esperar": 8.0, "anim": "Idle", "olhar": Vector2(0.0, -60.0)}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": Vector2(6.0, -88.0)}])
	_npc("Conselheiro Meren", "Conselheiro do rei", "res://scenes/personagens/oren.tscn", Vector2(7.0, -90.0), PackedStringArray(["Fale com respeito e em poucas palavras. Sua Majestade recebe muita gente.", "As contas do reino fecham com o comércio das feiras. Proteja as estradas e todos ganham."]),
		[{"esperar": 7.0, "anim": "Idle_Talking", "olhar": Vector2(0.0, -93.0)}, {"esperar": 5.0, "anim": "Idle", "olhar": Vector2(0.0, -60.0)}])
	for k in 4:   # guarda real perfilada dos dois lados do tapete
		for lado in [-1.0, 1.0]:
			_npc("Guarda real", "Guarda do rei", "res://scenes/personagens/guarda_imperial.tscn", Vector2(lado * 7.0, -58.0 - k * 9.0), PackedStringArray(["A guarda real não conversa em serviço."]), [])
	for p in [Vector2(-9.0, 100.0), Vector2(9.0, 100.0)]:   # sentinelas no portão do castelo, no alto da escadaria
		_npc("Sentinela do castelo", "Sentinela", "res://scenes/personagens/guarda_imperial.tscn", p, PackedStringArray(["O rei recebe no Salão do Trono, ao fundo. Arma na bainha."]), [])


## A TORRE DE MENAGEM: a torre mais alta do reino, atrás do trono, com quatro torrinhas nos cantos, telhado em ponta e a
## bandeira do rei. Mais duas torres largas guardam o pátio. É o que se vê de qualquer rua da cidade.
func _torre_de_menagem() -> void:
	var pedra := Pedra.material(PEDRA_BRANCA)
	var ardosia := VilaRefugio._mat(Color(0.2, 0.26, 0.5))
	var torres := [[Vector2(0.0, -113.0), 13.0, 58.0], [Vector2(-52.0, -20.0), 14.0, 40.0], [Vector2(52.0, -20.0), 14.0, 40.0], [Vector2(-52.0, 60.0), 11.0, 30.0], [Vector2(52.0, 60.0), 11.0, 30.0]]
	for t in torres:
		var p: Vector2 = t[0]
		var lado: float = t[1]
		var alt: float = t[2]
		var yb := _y(p)
		VilaRefugio._caixa(Vector3(p.x, yb + alt / 2.0, p.y), Vector3(lado, alt, lado), pedra, true)
		VilaRefugio._caixa(Vector3(p.x, yb + alt + 0.6, p.y), Vector3(lado + 2.4, 1.2, lado + 2.4), pedra)   # cornija
		for dx in [-1.0, 1.0]:   # torrinhas dos cantos
			for dz in [-1.0, 1.0]:
				var q := Vector3(p.x + dx * lado / 2.0, yb + alt + 3.0, p.y + dz * lado / 2.0)
				VilaRefugio._cilindro(q, 1.6, 7.0, pedra, false, 8)
				_ponta(q + Vector3(0, 6.0, 0), 2.0, 5.0, ardosia)
		_ponta(Vector3(p.x, yb + alt + 1.2 + lado * 0.6, p.y), lado * 0.62, lado * 1.2, ardosia)
		var topo := yb + alt + 1.2 + lado * 1.2
		VilaRefugio._caixa(Vector3(p.x, topo + 2.5, p.y), Vector3(0.25, 5.0, 0.25), VilaRefugio._mat(Color(0.2, 0.15, 0.1)))
		VilaRefugio._caixa(Vector3(p.x + 1.9, topo + 4.0, p.y), Vector3(3.6, 2.2, 0.08), VilaRefugio._mat(COR_DRAKKAR))


## O Salão do Trono ganha telhado: duas águas de ardósia azul apoiadas nas paredes (14 m), com o cume a 26 m. Lá dentro
## fica um salão coberto, alto, com as colunas e o tapete; lampiões dão a luz.
func _telhado_do_salao() -> void:
	var ardosia := VilaRefugio._mat(Color(0.22, 0.28, 0.52))
	ardosia.cull_mode = BaseMaterial3D.CULL_DISABLED   # visto de dentro o telhado também aparece (é o forro do salão)
	var y := _y(Vector2(0.0, -84.0)) + 14.0
	VilaRefugio._telhado(Vector3(0.0, y + 6.0, -84.0), Vector3(63.0, 12.0, 71.0), ardosia, 0.0)
	for z in [-62.0, -84.0, -104.0]:
		for lado in [-1.0, 1.0]:
			var luz := OmniLight3D.new()
			luz.light_color = Color(1.0, 0.82, 0.55)
			luz.light_energy = 2.2
			luz.omni_range = 26.0
			luz.position = Vector3(lado * 16.0, y - 7.0, z)
			add_child(luz)


func _ponta(pos: Vector3, raio: float, altura: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = raio
	cm.height = altura
	cm.radial_segments = 8
	cm.material = mat
	mi.mesh = cm
	mi.position = pos
	add_child(mi)


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
