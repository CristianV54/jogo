extends AreaBase
## Refúgio do Pinhal: acampamento do bando de exilados numa clareira de 45 m de raio, cercada de pinheiros,
## no limite da fronteira selvagem. Saídas: norte (Bosque Velado, mina do Gorath) e leste (Fronteira de Ferrogris).

const TAM := 320.0
const RAIO_CERCA := 40.0

const ESTILO_MADEIRA := {
	"parede": "Wall_Plaster_Straight", "porta": "Wall_Plaster_Door_Flat", "janela": "Wall_Plaster_Window_Wide_Flat",
	"piso": "Floor_WoodDark", "canto": "Corner_Exterior_Wood"}
const ESTILO_PEDRA := {
	"parede": "Wall_UnevenBrick_Straight", "porta": "Wall_UnevenBrick_Door_Round", "janela": "Wall_UnevenBrick_Window_Wide_Round",
	"piso": "Floor_UnevenBrick", "canto": "Corner_Exterior_Brick"}

var terreno: Terreno
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	nome_area = "Refúgio do Pinhal"
	_rng.seed = 2026
	_ambiente()
	_terreno()
	_floresta()
	_casas()
	_cerca()
	_fogueira()
	_adereços()
	_postos_de_trabalho()
	_chao_vivo()
	_npcs()
	_animais()
	_saidas()


func altura_em(x: float, z: float) -> float:
	return terreno.altura_em(x, z)


func _ambiente() -> void:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(0.32, 0.5, 0.78)
	ceu.sky_horizon_color = Color(0.74, 0.8, 0.86)
	ceu.ground_horizon_color = Color(0.62, 0.68, 0.66)
	ceu.ground_bottom_color = Color(0.3, 0.38, 0.32)
	var sky := Sky.new()
	sky.sky_material = ceu
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.fog_enabled = true
	e.fog_light_color = Color(0.72, 0.79, 0.84)
	e.fog_density = 0.0035
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sol.light_energy = 1.15
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 130.0
	add_child(sol)


func _terreno() -> void:
	terreno = Terreno.new()
	terreno.name = "Terreno"
	terreno.tamanho = TAM
	terreno.caminhos = [
		PackedVector2Array([Vector2(0, 0), Vector2(0, -40), Vector2(6, -80), Vector2(-5, -120), Vector2(0, -160)]),
		PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(80, 7), Vector2(120, -4), Vector2(160, 0)]),
	]
	add_child(terreno)
	terreno.gerar()


func _multimesh(malha: Mesh, transformacoes: Array[Transform3D], nome_no: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha
	mm.instance_count = transformacoes.size()
	for i in transformacoes.size():
		mm.set_instance_transform(i, transformacoes[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome_no
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)


func _livre(x: float, z: float, folga_caminho: float, inclinacao_min: float) -> bool:
	if Vector2(x, z).length() < terreno.clareira_raio * 1.02:
		return false
	if terreno.distancia_caminho(x, z) < folga_caminho:
		return false
	return terreno.normal_em(x, z).y >= inclinacao_min


func _floresta() -> void:
	var troncos := StaticBody3D.new()
	troncos.name = "TroncosColisao"
	add_child(troncos)
	var pinheiros: Array[Transform3D] = []
	var colisoes := 0
	for k in 3600:
		var x := _rng.randf_range(-TAM / 2.0 * 0.97, TAM / 2.0 * 0.97)
		var z := _rng.randf_range(-TAM / 2.0 * 0.97, TAM / 2.0 * 0.97)
		if not _livre(x, z, 4.5, 0.74):
			continue
		var d := Vector2(x, z).length()
		if _rng.randf() > 0.25 + 0.75 * smoothstep(terreno.clareira_raio, terreno.clareira_raio * 1.5, d):
			continue
		var s := _rng.randf_range(0.8, 1.6)
		var base := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s))
		var h := terreno.altura_em(x, z)
		pinheiros.append(Transform3D(base, Vector3(x, h - 0.15, z)))
		if d < 130.0 and colisoes < 500:
			colisoes += 1
			var cs := CollisionShape3D.new()
			var cil := CylinderShape3D.new()
			cil.radius = 0.45 * s
			cil.height = 4.0
			cs.shape = cil
			cs.position = Vector3(x, h + 2.0, z)
			troncos.add_child(cs)
	_multimesh(FabricaNatureza.pinheiro(), pinheiros, "Pinheiros")

	for v in 3:
		var pedras: Array[Transform3D] = []
		for k in 70:
			var x := _rng.randf_range(-TAM / 2.0 * 0.95, TAM / 2.0 * 0.95)
			var z := _rng.randf_range(-TAM / 2.0 * 0.95, TAM / 2.0 * 0.95)
			if not _livre(x, z, 3.0, 0.0):
				continue
			var s := _rng.randf_range(0.5, 2.4)
			var base := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.7, 1.3), s))
			pedras.append(Transform3D(base, Vector3(x, terreno.altura_em(x, z) - 0.1, z)))
		_multimesh(FabricaNatureza.pedra(1.0 + v * 7.3), pedras, "Pedras%d" % v)

	var arbustos: Array[Transform3D] = []
	for k in 500:
		var x := _rng.randf_range(-TAM / 2.0 * 0.95, TAM / 2.0 * 0.95)
		var z := _rng.randf_range(-TAM / 2.0 * 0.95, TAM / 2.0 * 0.95)
		if not _livre(x, z, 2.5, 0.8):
			continue
		var s := _rng.randf_range(0.6, 1.4)
		arbustos.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(x, terreno.altura_em(x, z) - 0.05, z)))
	_multimesh(FabricaNatureza.arbusto(), arbustos, "Arbustos")


func _casa(nome_casa: String, posicao: Vector3, colunas: int, linhas: int, estilo: Dictionary, interior := "moradia") -> Node3D:
	var casa := ConstrutorCasa.montar(colunas, linhas, estilo, true, interior)
	casa.name = nome_casa
	casa.position = posicao
	casa.rotation.y = atan2(-posicao.x, -posicao.z)   # a porta (+Z da casa) olha para o centro da clareira
	add_child(casa)
	return casa


func _casas() -> void:
	_casa("CasaDoVane", Vector3(0, 0, -27), 4, 6, ESTILO_MADEIRA)
	_casa("Forja", Vector3(-27, 0, -4), 3, 3, ESTILO_PEDRA, "forja")
	_casa("Cabana1", Vector3(27, 0, -12), 3, 3, ESTILO_MADEIRA)
	_casa("Cabana2", Vector3(21, 0, 24), 2, 3, ESTILO_MADEIRA)
	_casa("Cabana3", Vector3(-19, 0, 25), 3, 3, ESTILO_MADEIRA)


func _cerca() -> void:
	var cerca := Node3D.new()
	cerca.name = "Palicada"
	add_child(cerca)
	var corpo := StaticBody3D.new()
	cerca.add_child(corpo)
	var comprimento := 2.06
	var n := int(TAU * RAIO_CERCA / comprimento)
	for i in n:
		var ang := TAU * i / n
		var pos := Vector3(cos(ang) * RAIO_CERCA, 0.0, sin(ang) * RAIO_CERCA)
		if (pos.z < 0.0 and absf(pos.x) < 8.0) or (pos.x > 0.0 and absf(pos.z) < 8.0):
			continue   # saídas norte e leste
		var tangente := Vector3(-sin(ang), 0.0, cos(ang))
		var p := ConstrutorCasa.peca("Prop_WoodenFence_Single")
		p.position = pos
		p.rotation.y = atan2(-tangente.z, tangente.x)
		cerca.add_child(p)
		var cs := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(comprimento, 1.2, 0.3)
		cs.shape = caixa
		cs.transform = Transform3D(Basis(Vector3.UP, p.rotation.y), pos + Vector3(0, 0.6, 0))
		corpo.add_child(cs)


## Manchas de cor no solo, tufos de grama e anéis de flores, longe das casas, do fogo e dos caminhos.
func _chao_vivo() -> void:
	var exclusoes: Array = [[Vector2.ZERO, 3.2]]   # a fogueira
	for no in get_children():
		if no.has_meta("colunas"):
			var meia := Vector2(no.get_meta("colunas"), no.get_meta("linhas"))   # meia largura = colunas (módulo de 2 m)
			exclusoes.append([Vector2(no.position.x, no.position.z), meia.length() + 1.2])
	VegetacaoRasteira.espalhar(self, terreno, _rng, RAIO_CERCA - 2.0, exclusoes)


func _fogueira() -> void:
	var f := Node3D.new()
	f.name = "Fogueira"
	add_child(f)
	var mat := FabricaNatureza.material()
	for i in 8:
		var ang := TAU * i / 8.0
		var mi := MeshInstance3D.new()
		mi.mesh = FabricaNatureza.pedra(3.0 + i)
		mi.material_override = mat
		mi.scale = Vector3.ONE * 0.38
		mi.position = Vector3(cos(ang) * 1.1, 0.0, sin(ang) * 1.1)
		f.add_child(mi)
		if i == 0:
			continue   # abertura de ~0,9 m no círculo: dá para chegar ao fogo (e se queimar)
		var pedra_solida := StaticBody3D.new()   # cada pedra do círculo bloqueia (só o fogo em si é atravessável)
		var cs_pedra := CollisionShape3D.new()
		var cil_pedra := CylinderShape3D.new()
		cil_pedra.radius = 0.34
		cil_pedra.height = 0.6
		cs_pedra.shape = cil_pedra
		pedra_solida.position = mi.position + Vector3(0.0, 0.3, 0.0)
		pedra_solida.add_child(cs_pedra)
		f.add_child(pedra_solida)
	for i in 3:
		var tora := MeshInstance3D.new()
		tora.mesh = FabricaNatureza.toras()
		tora.material_override = mat
		tora.scale = Vector3(0.7, 0.55, 0.7)
		tora.rotation = Vector3(deg_to_rad(65.0), TAU * i / 3.0, 0.0)
		tora.position = Vector3(0, 0.15, 0)
		f.add_child(tora)
	var fogo := Fogo.new()   # chama, fumaça, fagulhas, luz que tremula; queima quem entra
	fogo.name = "Fogo"
	fogo.escala = 1.0
	fogo.dano = 6
	fogo.raio_dano = 0.8
	fogo.position = Vector3(0.0, 0.15, 0.0)
	f.add_child(fogo)


func _adereços() -> void:
	var itens := [
		["Prop_Wagon", Vector3(-19, 0, 10), 40.0],
		["Prop_Crate", Vector3(-23.5, 0, -9.5), 10.0],
		["Prop_Crate", Vector3(-22.2, 0, -10.6), 55.0],
		["Prop_Crate", Vector3(-4.5, 0, -19.5), 20.0],
		["Prop_Crate", Vector3(4.0, 0, -19.8), 80.0],
		["Prop_Crate", Vector3(23.0, 0, 16.5), 35.0],
	]
	var solidos := StaticBody3D.new()   # carroça, caixotes, lenha e pedras da fogueira: o jogador não os atravessa
	solidos.name = "SolidosDoCenario"
	add_child(solidos)
	for it in itens:
		var p := ConstrutorCasa.peca(it[0])
		p.position = it[1]
		p.rotation_degrees.y = it[2]
		add_child(p)
		p.add_to_group("props_solidos")
		Solidos.colidir_com(p, solidos, 0.92)
	# pilha de lenha do Dorn
	var mat := FabricaNatureza.material()
	for fila in 3:
		for i in 4 - fila:
			var t := MeshInstance3D.new()
			t.mesh = FabricaNatureza.toras()
			t.material_override = mat
			t.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
			t.position = Vector3(19.5 + (i + fila * 0.5) * 0.4, 0.2 + fila * 0.33, -26.0)
			add_child(t)
	var lenha := CollisionShape3D.new()   # a pilha inteira como um bloco
	var caixa_lenha := BoxShape3D.new()
	caixa_lenha.size = Vector3(1.9, 1.0, 0.5)
	lenha.shape = caixa_lenha
	lenha.position = Vector3(20.3, 0.5, -26.0)
	solidos.add_child(lenha)


func _npc(nome_npc: String, papel: String, cena: String, pos: Vector3, anim: String, falas: PackedStringArray, olhar_para: Vector3 = Vector3.ZERO, rotina: Array = []) -> Npc:
	var n := Npc.new()
	n.rotina = rotina
	n.altura_em = altura_em
	n.nome = nome_npc
	n.papel = papel
	n.falas = falas
	n.animacao = anim
	n.cena = load(cena)
	n.position = pos
	add_child(n)
	n.olhar_para(olhar_para)
	npcs.append(n)
	return n


## Onde cada um trabalha: bigorna do Brenn (ao lado da forja), cepo do Dorn (perto da lenha), caldeirão da Tessa (perto da fogueira).
const BIGORNA := Vector3(-22.5, 0.0, -1.5)
const CEPO := Vector3(23.6, 0.0, -24.2)
const CALDEIRAO := Vector3(2.6, 0.0, 2.2)


func _postos_de_trabalho() -> void:
	var solidos := StaticBody3D.new()
	solidos.name = "SolidosDosPostos"
	add_child(solidos)
	ConstrutorCasa._movel(self, solidos, "Anvil", BIGORNA.x, BIGORNA.z, 90.0, altura_em(BIGORNA.x, BIGORNA.z))
	ConstrutorCasa._movel(self, solidos, "Cauldron", CALDEIRAO.x, CALDEIRAO.z, 0.0, altura_em(CALDEIRAO.x, CALDEIRAO.z))
	var cepo := MeshInstance3D.new()   # cepo de cortar lenha: tronco curto de madeira
	cepo.name = "CepoDoDorn"
	var cil := CylinderMesh.new()
	cil.top_radius = 0.3
	cil.bottom_radius = 0.34
	cil.height = 0.55
	cil.radial_segments = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.28, 0.16)
	mat.roughness = 1.0
	cil.material = mat
	cepo.mesh = cil
	cepo.position = Vector3(CEPO.x, altura_em(CEPO.x, CEPO.z) + 0.275, CEPO.z)
	add_child(cepo)
	var cs := CollisionShape3D.new()
	var cs_forma := CylinderShape3D.new()
	cs_forma.radius = 0.34
	cs_forma.height = 0.55
	cs.shape = cs_forma
	cs.position = cepo.position
	solidos.add_child(cs)


func _npcs() -> void:
	_npc("Vane", "Líder do bando", "res://scenes/personagens/vane.tscn", Vector3(0, 0, -19.0), "Idle",
		PackedStringArray(["Torin. Os dragões voltaram a rondar a fronteira.", "Quem sobrevive aqui, sobrevive junto. Lembre disso."]), Vector3.ZERO,
		[{"esperar": 5.0, "anim": "Idle"}, {"ir": Vector3(0, 0, -5.0), "vel": 1.4}, {"esperar": 7.0, "anim": "Idle_Talking", "olhar": Vector3.ZERO},
		 {"ir": Vector3(0, 0, -19.0), "vel": 1.4}])
	_npc("Brenn", "Ferreira", "res://scenes/personagens/brenn.tscn", Vector3(-21.3, 0, -1.5), "Idle",
		PackedStringArray(["Traga couro, ferro e carvão que eu melhoro essa lâmina.", "Ferro bom não se compra, se arranca da mina."]), BIGORNA,
		[{"fazer": "Sword_Attack", "seg": 9.0, "olhar": BIGORNA}, {"esperar": 3.0, "anim": "Idle_Talking"},
		 {"fazer": "Sword_Attack", "seg": 9.0, "olhar": BIGORNA}, {"ir": Vector3(-20.0, 0, -5.5)},
		 {"esperar": 2.5, "anim": "Idle", "olhar": Vector3(-27, 0, -4)}, {"ir": Vector3(-21.3, 0, -1.5)}])
	_npc("Orin", "Vigia", "res://scenes/personagens/orin.tscn", Vector3(35.0, 0, 7.0), "Idle",
		PackedStringArray(["Fico de olho na estrada de Ferrogris. Patrulhas do Império passam por lá.", "Se ouvir asas, corra para a fogueira."]),
		Vector3(60, 0, 0),
		[{"esperar": 6.0, "anim": "Idle", "olhar": Vector3(60, 0, 7)}, {"ir": Vector3(33.5, 0, 13.0), "vel": 1.3}, {"ir": Vector3(31.0, 0, 18.5), "vel": 1.3},
		 {"esperar": 6.0, "anim": "Idle", "olhar": Vector3(50, 0, 24)}, {"ir": Vector3(33.5, 0, 13.0), "vel": 1.3}, {"ir": Vector3(35.0, 0, 7.0), "vel": 1.3}])
	_npc("Tessa", "Cozinheira", "res://scenes/personagens/tessa.tscn", Vector3(3.9, 0, 2.2), "Idle_Talking",
		PackedStringArray(["Sopa quente para quem volta da caçada.", "Você está magro, Torin. Coma."]), CALDEIRAO,
		[{"fazer": "Interact", "seg": 7.0, "olhar": CALDEIRAO}, {"fazer": "PickUp_Table", "seg": 2.5, "olhar": CALDEIRAO},
		 {"esperar": 3.0, "anim": "Idle_Talking", "olhar": CALDEIRAO}, {"ir": Vector3(6.0, 0, 6.5)},
		 {"esperar": 2.5, "anim": "PickUp_Table", "olhar": Vector3(8, 0, 8)}, {"ir": Vector3(3.9, 0, 2.2)}])
	_npc("Dorn", "Lenhador", "res://scenes/personagens/dorn.tscn", Vector3(22.4, 0, -24.2), "Idle",
		PackedStringArray(["Esses pinheiros seguram o telhado do mundo.", "A trilha do norte leva à mina. Cuidado com o Gorath."]), CEPO,
		[{"fazer": "Sword_Attack", "seg": 10.0, "olhar": CEPO}, {"ir": Vector3(20.4, 0, -24.6)},
		 {"esperar": 3.0, "anim": "PickUp_Table", "olhar": Vector3(20.3, 0, -26.0)}, {"ir": Vector3(22.4, 0, -24.2)}])
	_npc("Mira", "Caçadora", "res://scenes/personagens/mira.tscn", Vector3(-12.0, 0, 14.0), "Crouch_Idle",
		PackedStringArray(["Rastros frescos no Bosque Velado. Algo grande passou por lá.", "Fale baixo."]), Vector3.ZERO,
		[{"ir": Vector3(-26.0, 0, 18.0), "vel": 1.3}, {"esperar": 7.0, "anim": "Crouch_Idle", "olhar": Vector3(-60, 0, 22)},
		 {"ir": Vector3(-12.0, 0, 14.0), "vel": 1.3}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector3(-12, 0, 30)}])


const NOMES_DE_ANIMAIS := {"vaca": "Vaca", "cavalo": "Cavalo", "ovelha": "Ovelha", "porco": "Porco", "cao": "Cão"}
const VIDA_DE_ANIMAIS := {"vaca": 40, "cavalo": 50, "ovelha": 20, "porco": 25, "cao": 20}
const DROPS_DE_ANIMAIS := {
	"vaca": {"carne": [2, 3], "couro": [1, 1]},
	"cavalo": {"carne": [2, 3], "couro": [1, 2]},
	"ovelha": {"carne": [1, 2], "la": [1, 2]},
	"porco": {"carne": [2, 3]},
	"cao": {"couro": [1, 1]},
}
const RAIO_DE_ANIMAIS := {"vaca": 1.0, "cavalo": 1.1, "ovelha": 0.6, "porco": 0.6, "cao": 0.4}


func _animal(arquivo: String, pos: Vector3, raio: float, velocidade: float) -> void:
	var a := AnimalVila.new()
	a.name = arquivo.capitalize()
	a.nome = NOMES_DE_ANIMAIS[arquivo]
	a.vida_max = VIDA_DE_ANIMAIS[arquivo]
	a.raio_colisao = RAIO_DE_ANIMAIS[arquivo]
	a.montavel = arquivo == "cavalo"
	a.especie = arquivo
	a.drops = DROPS_DE_ANIMAIS[arquivo]
	a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [arquivo, arquivo])
	a.raio_vagar = raio
	a.velocidade = velocidade
	a.altura_em = altura_em
	a.position = Vector3(pos.x, altura_em(pos.x, pos.z), pos.z)
	a.rotation.y = _rng.randf() * TAU
	add_child(a)


func _animais() -> void:
	# pasto ao sul (entre as cabanas 2 e 3), chiqueiro a oeste da casa do Vane, cavalos a oeste, cão perto da forja
	_animal("vaca", Vector3(-4, 0, 31), 5.0, 0.9)
	_animal("vaca", Vector3(5, 0, 32), 5.0, 0.9)
	_animal("ovelha", Vector3(0, 0, 28), 5.0, 0.8)
	_animal("ovelha", Vector3(-6, 0, 33), 5.0, 0.8)
	_animal("ovelha", Vector3(7, 0, 29), 5.0, 0.8)
	_animal("porco", Vector3(-16, 0, -28), 3.0, 0.8)
	_animal("porco", Vector3(-14, 0, -30), 3.0, 0.8)
	_animal("cavalo", Vector3(-33, 0, 12), 4.0, 1.3)
	_animal("cavalo", Vector3(-31, 0, 16), 4.0, 1.3)
	_animal("cao", Vector3(-17, 0, -6), 3.0, 1.4)


func _saidas() -> void:
	_novo_spawn("Principal", Vector3(0, 0, 14), Vector3(0, 0, -30))
	_novo_spawn("DoBosque", Vector3(0, 0, -43), Vector3(0, 0, 0))
	_novo_spawn("DaFronteira", Vector3(43, 0, 0), Vector3(0, 0, 0))
	_portal(Vector3(0, terreno.altura_em(0, -150), -150), "bosque_velado", "Entrada")
	_portal(Vector3(150, terreno.altura_em(150, -1), -1), "fronteira_ferrogris", "Entrada").rotation.y = deg_to_rad(90.0)
