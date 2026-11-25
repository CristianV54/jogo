class_name Cidadela
extends Node3D
## A CIDADELA DE VALDORIA, no alto do penhasco (planta do Reino de Aethelgard que o Cristian tinha feito em blocos):
##   - muralha branca na borda do topo, com 13 torres de alturas diferentes e o portão a OESTE (onde chega a rampa);
##   - o PALÁCIO com o andar alto, o torreão de menagem, a torre mais alta do reino e as torres dos cantos;
##   - ala norte, capela real, quartel, cavalariça, poço e árvores no pátio;
##   - o SALÃO DO TRONO (o salão sul), oco: entra-se pela porta do lado do pátio e lá dentro estão o rei e a corte;
##   - a mureta da rampa, do lado do precipício.
## As medidas da planta de blocos foram passadas para metros (1 unidade = 12,7 cm na planta, 12,4 cm na altura).
## Tudo é pedra clara; os telhados são de ardósia azul, a cor do rei.

const PEDRA_CLARA := Color(0.9, 0.88, 0.84)
const AZUL_DO_REI := Color(0.14, 0.2, 0.5)
const ARDOSIA := Color(0.2, 0.26, 0.5)
const PLANTA := 0.127
const ALTO := 0.124

var mundo: Mundo
var npcs: Array[Npc] = []
var torres := 0
var predios := 0
var topo_mais_alto := 0.0
var _corpo: StaticBody3D
var _caixas: Array[Transform3D] = []
var _cilindros: Array[Transform3D] = []
var _pontas: Array[Transform3D] = []
var _predios: Array = [[], []]
var _telhados: Array = [[], []]
var _h := MundoDados.PENHASCO_ALTURA
var _rng := RandomNumberGenerator.new()


func montar() -> void:
	name = "Cidadela"
	_rng.seed = 1183
	_corpo = StaticBody3D.new()
	_corpo.name = "Solidos"
	add_child(_corpo)
	_muralha_do_topo()
	_palacio_e_torres()
	_salao_do_trono()
	_mureta_da_rampa()
	_corte()
	_multimesh("Pedras", BoxMesh.new(), Pedra.material(PEDRA_CLARA), _caixas)
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.radial_segments = 14
	_multimesh("Torres", cil, Pedra.material(PEDRA_CLARA), _cilindros)
	var cone := CylinderMesh.new()
	cone.height = 1.0
	cone.top_radius = 0.02
	cone.radial_segments = 10
	var ardosia := StandardMaterial3D.new()
	ardosia.albedo_color = ARDOSIA
	ardosia.roughness = 0.9
	_multimesh("Pontas", cone, ardosia, _pontas)
	_multimesh("Predios", BoxMesh.new(), Fachadas.material("pedra"), _predios[0], _predios[1])
	_multimesh("Telhados", PrismMesh.new(), Fachadas.material("telhado"), _telhados[0], _telhados[1])
	print("Cidadela: ", torres, " torres (a mais alta com o topo a ", snappedf(topo_mais_alto, 0.1), " m acima da cidade), ", predios, " prédios, ", npcs.size(), " pessoas")


# ---------------------------------------------------------------- peças

func _bloco(pos: Vector3, tam: Vector3, giro := 0.0, colidir := true) -> void:
	_caixas.append(Transform3D(Basis(Vector3.UP, giro).scaled_local(tam), pos))
	if colidir:
		_caixa_solida(pos, tam, giro)


func _caixa_solida(pos: Vector3, tam: Vector3, giro := 0.0) -> void:
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tam
	cs.shape = caixa
	cs.position = pos
	cs.rotation.y = giro
	_corpo.add_child(cs)


## Torre redonda de base em `y0`, com coroamento e telhado em ponta (ou ameias); devolve a altura do topo.
func _torre(x: float, z: float, y0: float, raio: float, altura: float, ameias := false, bandeira := false) -> float:
	_cilindros.append(Transform3D(Basis.from_scale(Vector3(raio * 2.0, altura + 2.0, raio * 2.0)), Vector3(x, y0 + altura / 2.0 - 1.0, z)))
	_cilindros.append(Transform3D(Basis.from_scale(Vector3(raio * 2.0 + 1.4, 1.2, raio * 2.0 + 1.4)), Vector3(x, y0 + altura + 0.6, z)))
	var topo := y0 + altura + 1.2
	if ameias:
		for k in 8:
			var a := TAU * k / 8.0
			_bloco(Vector3(x + cos(a) * (raio + 0.3), topo + 0.7, z + sin(a) * (raio + 0.3)), Vector3(1.3, 1.4, 1.0), -a + PI / 2.0, false)
		topo += 1.4
	else:
		var alt_p := raio * 3.0
		_pontas.append(Transform3D(Basis.from_scale(Vector3(raio * 2.0 + 1.2, alt_p, raio * 2.0 + 1.2)), Vector3(x, topo + alt_p / 2.0, z)))
		topo += alt_p
		if bandeira:
			_bloco(Vector3(x, topo + 1.6, z), Vector3(0.18, 3.6, 0.18), 0.0, false)
			var pano := MeshInstance3D.new()
			var malha := BoxMesh.new()
			malha.size = Vector3(2.4, 1.5, 0.06)
			var m := StandardMaterial3D.new()
			m.albedo_color = AZUL_DO_REI
			malha.material = m
			pano.mesh = malha
			pano.position = Vector3(x + 1.3, topo + 2.6, z)
			add_child(pano)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = altura
	cs.shape = forma
	cs.position = Vector3(x, y0 + altura / 2.0, z)
	_corpo.add_child(cs)
	torres += 1
	topo_mais_alto = maxf(topo_mais_alto, topo)
	return topo


## Prédio de pedra maciço (não se entra), com janelas pintadas e telhado de duas águas de ardósia.
func _predio(x: float, z: float, larg: float, prof: float, y0: float, altura: float, telhado := 0.0, cumeeira_em_z := false) -> void:
	_predios[0].append(Transform3D(Basis.from_scale(Vector3(larg, altura + 1.0, prof)), Vector3(x, y0 + altura / 2.0 - 0.5, z)))
	_predios[1].append(Color(1.0, 0.98, 0.95) * _rng.randf_range(0.92, 1.0))
	_caixa_solida(Vector3(x, y0 + altura / 2.0, z), Vector3(larg, altura, prof))
	if telhado > 0.0:
		var base := Basis(Vector3.UP, 0.0 if cumeeira_em_z else PI / 2.0)
		var tam := Vector3(larg + 1.2, telhado, prof + 1.2) if cumeeira_em_z else Vector3(prof + 1.2, telhado, larg + 1.2)
		_telhados[0].append(Transform3D(base.scaled_local(tam), Vector3(x, y0 + altura + telhado / 2.0, z)))
		_telhados[1].append(Color(0.44, 0.5, 0.72) * _rng.randf_range(0.88, 1.0))
	predios += 1


func _pl(v: float) -> float:   # medida da planta de blocos, em metros
	return v * PLANTA


# ---------------------------------------------------------------- construção

## Muralha branca na borda do topo, com o vão do portão a oeste e as torres.
func _muralha_do_topo() -> void:
	var ca := MundoDados.PENHASCO_EIXOS.x * 0.93
	var cb := MundoDados.PENHASCO_EIXOS.y * 0.93
	var passos := 110
	for k in passos:
		var a0 := TAU * k / passos
		var a1 := TAU * (k + 1) / passos
		var p0 := Vector2(cos(a0) * ca, sin(a0) * cb)
		var p1 := Vector2(cos(a1) * ca, sin(a1) * cb)
		var meio := (p0 + p1) / 2.0
		if meio.x < 0.0 and absf(meio.y) < 6.5:
			continue   # o vão do portão
		var giro := atan2((p1 - p0).x, (p1 - p0).y)
		_bloco(Vector3(meio.x, _h + 6.0, meio.y), Vector3(2.8, 16.0, p0.distance_to(p1) + 0.3), giro)
		if k % 2 == 0:
			_bloco(Vector3(meio.x, _h + 14.6, meio.y), Vector3(3.0, 1.2, 1.8), giro, false)
	var alturas := [24.0, 24.0, 32.0, 32.0, 42.0, 52.0]
	for g in [0, 24, 48, 72, 96, 120, 144, 216, 240, 264, 288, 312, 336]:   # 180 graus é o portão
		var a := deg_to_rad(float(g))
		_torre(cos(a) * ca, sin(a) * cb, _h, _rng.randf_range(4.2, 5.2), alturas[_rng.randi() % alturas.size()] + _rng.randf_range(-2.0, 2.0), g % 48 == 24 and _rng.randf() < 0.4, true)
	for s in [-1.0, 1.0]:   # portão oeste: duas torres, a verga por cima e o estandarte
		_torre(-ca, s * 10.0, _h, 4.4, 30.0)
	_bloco(Vector3(-ca, _h + 15.0, 0.0), Vector3(5.8, 9.0, 12.0), 0.0, false)
	var pano := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = Vector3(0.1, 6.6, 4.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = AZUL_DO_REI
	malha.material = m
	pano.mesh = malha
	pano.position = Vector3(-ca - 3.0, _h + 15.0, 0.0)
	add_child(pano)


## Palácio, torreão, torre mais alta, alas e prédios do pátio.
func _palacio_e_torres() -> void:
	_predio(_pl(40), _pl(-50), _pl(300), _pl(230), _h, 250 * ALTO, 130 * ALTO)                         # palácio
	_predio(_pl(40), _pl(-70), _pl(190), _pl(150), _h + 250 * ALTO, 150 * ALTO, 110 * ALTO)            # andar alto do palácio
	_torre(_pl(50), _pl(-180), _h, _pl(64) / 2.0, 700 * ALTO, false, true)                               # a torre mais alta
	var yk := _torre(_pl(-30), _pl(-110), _h, _pl(150) / 2.0, 430 * ALTO, true)                           # torreão de menagem
	_torre(_pl(-30), _pl(-110), yk - 2.5, _pl(74) / 2.0, 250 * ALTO, false, true)                         # a torre de cima do torreão
	_torre(_pl(135), _pl(-70), _h, _pl(90) / 2.0, 500 * ALTO, false, true)
	for t in [[-110, 65, 56, 330], [190, 65, 56, 330], [-110, -165, 56, 300], [190, -165, 56, 380]]:     # cantos do palácio
		_torre(_pl(t[0]), _pl(t[1]), _h, _pl(t[2]) / 2.0, float(t[3]) * ALTO)
	_predio(_pl(30), _pl(-285), _pl(300), _pl(80), _h, 150 * ALTO, 9.0)                                  # ala norte
	_torre(_pl(-120), _pl(-285), _h, _pl(60) / 2.0, 260 * ALTO)
	_torre(_pl(180), _pl(-285), _h, _pl(60) / 2.0, 300 * ALTO)
	_predio(_pl(310), _pl(-20), _pl(120), _pl(230), _h, 190 * ALTO, 90 * ALTO, true)                     # capela real
	_torre(_pl(310), _pl(120), _h, _pl(66) / 2.0, 400 * ALTO, false, true)
	_torre(_pl(-100), _pl(200), _h, _pl(56) / 2.0, 250 * ALTO)                                           # torres do salão sul
	_torre(_pl(180), _pl(200), _h, _pl(60) / 2.0, 290 * ALTO)
	_predio(_pl(-270), _pl(-190), _pl(120), _pl(70), _h, 90 * ALTO, 5.5)                                 # quartel
	_predio(_pl(-260), _pl(200), _pl(120), _pl(70), _h, 84 * ALTO, 5.5)                                  # cavalariça
	var poco := Vector3(_pl(-300), _h, _pl(-70))
	_cilindros.append(Transform3D(Basis.from_scale(Vector3(3.6, 1.4, 3.6)), poco + Vector3(0, 0.7, 0)))
	_caixa_solida(poco + Vector3(0, 0.7, 0), Vector3(3.2, 1.4, 3.2))
	var copas: Array[Transform3D] = []
	for q in [[-200, 110], [-370, 90], [-190, -110], [-350, -110]]:
		copas.append(Transform3D(Basis.from_scale(Vector3(1.2, 1.2, 1.2)), Vector3(_pl(q[0]), _h, _pl(q[1]))))
		mundo.arvores.adicionar(_pl(q[0]), _pl(q[1]), 0.5)
	_multimesh("ArvoresDoPatio", FabricaNatureza.folhosa(), FabricaNatureza.material(), copas)


## O Salão do Trono é o "salão sul" da planta, só que oco: paredes, porta do lado do pátio (norte), telhado, tapete,
## trono e lampiões. Lá dentro ficam o rei e a corte.
func _salao_do_trono() -> void:
	var c := Vector2(_pl(40), _pl(200))
	var larg := _pl(260)
	var prof := _pl(100)
	var alt := 160 * ALTO
	var esp := 1.2
	_bloco(Vector3(c.x, _h + alt / 2.0, c.y + prof / 2.0), Vector3(larg, alt, esp))                       # parede sul
	for s in [-1.0, 1.0]:
		_bloco(Vector3(c.x + s * larg / 2.0, _h + alt / 2.0, c.y), Vector3(esp, alt, prof))               # paredes leste e oeste
	var vao := 4.4   # porta de 4,4 m, no meio da parede norte
	for s in [-1.0, 1.0]:
		_bloco(Vector3(c.x + s * (larg / 4.0 + vao / 4.0), _h + alt / 2.0, c.y - prof / 2.0), Vector3(larg / 2.0 - vao / 2.0, alt, esp))
	_bloco(Vector3(c.x, _h + 5.0 + (alt - 5.0) / 2.0, c.y - prof / 2.0), Vector3(vao, alt - 5.0, esp), 0.0, false)   # verga por cima da porta
	var telhado := MeshInstance3D.new()
	var prisma := PrismMesh.new()
	prisma.size = Vector3(prof + 1.4, 8.0, larg + 1.4)
	var ardosia := StandardMaterial3D.new()
	ardosia.albedo_color = Color(0.3, 0.36, 0.6)
	ardosia.cull_mode = BaseMaterial3D.CULL_DISABLED   # visto de dentro é o forro do salão
	prisma.material = ardosia
	telhado.mesh = prisma
	telhado.position = Vector3(c.x, _h + alt + 4.0, c.y)
	telhado.rotation.y = PI / 2.0
	add_child(telhado)
	var tapete := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(larg - 6.0, 0.06, 3.0)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = AZUL_DO_REI
	tm.material = mt
	tapete.mesh = tm
	tapete.position = Vector3(c.x, _h + 0.05, c.y)
	add_child(tapete)
	var trono := Vector3(c.x + larg / 2.0 - 3.0, _h, c.y)
	_bloco(trono + Vector3(-0.5, 0.3, 0.0), Vector3(5.0, 0.6, 6.0))                                      # estrado
	_bloco(trono + Vector3(0.6, 1.2, 0.0), Vector3(1.4, 1.2, 1.8))                                       # trono
	_bloco(trono + Vector3(1.2, 2.6, 0.0), Vector3(0.3, 2.8, 1.8), 0.0, false)                           # espaldar
	for dx in [-10.0, 0.0, 10.0]:
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.82, 0.55)
		luz.light_energy = 2.4
		luz.omni_range = 16.0
		luz.position = Vector3(c.x + dx, _h + 6.0, c.y)
		add_child(luz)
	predios += 1


## Mureta de pedra do lado do precipício, ao longo da rampa inteira.
func _mureta_da_rampa() -> void:
	var e := MundoDados.PENHASCO_EIXOS
	var r := MundoDados.RAMPA_R1 - 0.015
	var t := MundoDados.RAMPA_TS - 0.06
	while t > MundoDados.RAMPA_TE:
		var p := Vector2(-cos(t) * e.x * r, sin(t) * e.y * r)
		var q := Vector2(-cos(t - 0.02) * e.x * r, sin(t - 0.02) * e.y * r)
		var y := MundoDados.altura_da_rampa(t)
		_bloco(Vector3(p.x, y + 0.5, p.y), Vector3(0.9, 1.6, p.distance_to(q) + 0.2), atan2((q - p).x, (q - p).y))
		t -= 0.02


# ---------------------------------------------------------------- a corte

func _npc(nome_n: String, papel: String, cena: String, p: Vector2, falas: Array, rotina: Array = []) -> void:
	var n := Npc.new()
	n.nome = nome_n
	n.papel = papel
	n.falas = PackedStringArray(falas)
	n.cena = load("res://scenes/personagens/%s.tscn" % cena)
	for passo in rotina:
		for chave in ["ir", "olhar"]:
			if passo.has(chave) and passo[chave] is Vector2:
				var v: Vector2 = passo[chave]
				passo[chave] = Vector3(v.x, _h, v.y)
	n.rotina = rotina
	n.altura_em = mundo.terreno.altura_em
	n.position = Vector3(p.x, _h, p.y)
	add_child(n)
	npcs.append(n)


## O rei no Salão do Trono com o conselheiro e a guarda real; sentinelas no portão da cidadela; gente no pátio.
func _corte() -> void:
	var c := Vector2(_pl(40), _pl(200))
	var larg := _pl(260)
	_npc("Rei Aldren", "Rei de Valdoria", "solon", c + Vector2(larg / 2.0 - 6.5, 0.0), ["Então você é o batedor do Pinhal de quem falam. Aproxime-se.", "Um reino se guarda com muralha, e se mantém com gente. Ande pelas ruas, veja como vive o meu povo.", "Há lobos nas estradas e coisa pior nas terras queimadas. Quem as limpa tem a gratidão da coroa."],
		[{"esperar": 8.0, "anim": "Idle", "olhar": c}, {"esperar": 5.0, "anim": "Idle_Talking", "olhar": c + Vector2(larg / 2.0 - 8.0, 3.0)}])
	_npc("Conselheiro Meren", "Conselheiro do rei", "oren", c + Vector2(larg / 2.0 - 8.5, 3.2), ["Fale com respeito e em poucas palavras. Sua Majestade recebe muita gente.", "As contas do reino fecham com o comércio das feiras. Proteja as estradas e todos ganham."],
		[{"esperar": 7.0, "anim": "Idle_Talking", "olhar": c + Vector2(larg / 2.0 - 6.5, 0.0)}, {"esperar": 5.0, "anim": "Idle", "olhar": c}])
	for k in 3:   # guarda real perfilada dos dois lados do tapete
		for lado in [-1.0, 1.0]:
			_npc("Guarda real", "Guarda do rei", "guarda_imperial", c + Vector2(-6.0 + k * 6.0, lado * 3.6), ["A guarda real não conversa em serviço."])
	var portao := Vector2(-MundoDados.PENHASCO_EIXOS.x * 0.93 + 4.0, 0.0)
	for lado in [-1.0, 1.0]:
		_npc("Sentinela da cidadela", "Sentinela", "guarda_imperial", portao + Vector2(0.0, lado * 4.6), ["O rei recebe no Salão do Trono: atravesse o pátio e contorne o palácio pelo sul. Arma na bainha."])
	_npc("Mestre de armas", "Mestre de armas", "dorn", Vector2(_pl(-270), _pl(-120)), ["Treino a guarda real há vinte anos. Daqui de cima dá para ver o reino inteiro."],
		[{"fazer": "Sword_Attack", "seg": 8.0, "olhar": Vector2(_pl(-300), _pl(-120))}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector2(_pl(-300), _pl(-70))}])
	_npc("Criada do castelo", "Criada", "cativa", Vector2(_pl(-300), _pl(-40)), ["Levo água do poço para a cozinha do palácio. São muitos degraus."],
		[{"fazer": "Interact", "seg": 5.0, "olhar": Vector2(_pl(-300), _pl(-70))}, {"ir": Vector2(_pl(-180), _pl(120)), "vel": 1.3}, {"esperar": 4.0, "anim": "Idle"}, {"ir": Vector2(_pl(-300), _pl(-40)), "vel": 1.3}])


func _multimesh(nome: String, malha: Mesh, mat: Material, lista: Array, cores: Array = []) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not cores.is_empty()
	mm.mesh = malha
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
		if not cores.is_empty():
			mm.set_instance_color(i, cores[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)
