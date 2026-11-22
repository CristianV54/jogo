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

const CLAREIRA := Vector3(-65.0, 0.0, -105.0)   # clareira do pinhal (missão C1-M4)

var terreno: Terreno
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	nome_area = "Refúgio do Pinhal"
	_rng.seed = 2026
	_ambiente()
	_terreno()
	Horizonte.montar(self, TAM, Color(0.2, 0.34, 0.16), Color(0.36, 0.46, 0.4), 120.0, true, 3, -12.0)
	_floresta()
	_casas()
	_cerca()
	_pontes()
	_fogueira()
	_adereços()
	_postos_de_trabalho()
	_patio_de_treino()
	var ocupado := VilaRefugio.construir(self, altura_em)
	_chao_vivo(ocupado)
	_npcs()
	_animais()
	_saidas()
	_clareira_do_pinhal()
	var m := GerenciadorMissoes.instancia
	if m:
		m.missao_iniciada.connect(_ao_missao_iniciada)
		if m.ativas.has("C1-M3"):
			_ao_missao_iniciada("C1-M3")


func altura_em(x: float, z: float) -> float:
	return terreno.altura_em(x, z)


func _ambiente() -> void:
	_ambiente_padrao()


## Uma ponte em cada estrada que cruza o Riacho do Pinhal (oeste, norte e leste).
func _pontes() -> void:
	for it in [[Vector2(-74.0, 3.9), Vector2(-58.0, 3.9)], [Vector2(3.3, -70.0), Vector2(3.3, -54.0)], [Vector2(56.0, 4.2), Vector2(72.0, 4.2)]]:
		var a: Vector2 = it[0]
		var b: Vector2 = it[1]
		var ponte := PonteDeMadeira.new()
		add_child(ponte)
		ponte.ligar(Vector3(a.x, terreno.altura_em(a.x, a.y), a.y), Vector3(b.x, terreno.altura_em(b.x, b.y), b.y))


func _terreno() -> void:
	terreno = Terreno.new()
	terreno.name = "Terreno"
	terreno.tamanho = TAM
	terreno.caminhos = [
		PackedVector2Array([Vector2(0, 0), Vector2(0, -40), Vector2(6, -80), Vector2(-5, -120), Vector2(0, -160)]),
		PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(80, 7), Vector2(120, -4), Vector2(160, 0)]),
		PackedVector2Array([Vector2(0, 0), Vector2(-40, 0), Vector2(-80, 6), Vector2(-120, -4), Vector2(-160, 0)]),   # trilha do Pomar Alto
		PackedVector2Array([Vector2(6, -80), Vector2(-15, -93), Vector2(-45, -100), Vector2(-62, -105)]),   # trilha escondida do pinhal
	]
	terreno.planos = [Vector3(CLAREIRA.x, CLAREIRA.z, 12.0)]   # a clareira do pinhal é plana
	# Riacho do Pinhal: contorna a vila por oeste, norte e leste e cruza as três estradas (uma ponte em cada)
	var eixo := Terreno.curva([Vector2(-76, 150), Vector2(-70, 90), Vector2(-67, 40), Vector2(-66, 3.9), Vector2(-62, -28), Vector2(-40, -52), Vector2(3.3, -62), Vector2(42, -52), Vector2(60, -28), Vector2(64, 4.2), Vector2(67, 40), Vector2(72, 90), Vector2(78, 150)], 3.0)
	terreno.rios = [{"pontos": eixo, "largura": 4.4, "margem": 8.0, "fundo": 0.8, "agua": true}]
	for i in range(0, eixo.size(), 5):   # corredor plano em volta do rio, para as margens ficarem calmas
		terreno.planos.append(Vector3(eixo[i].x, eixo[i].y, 11.0))
	add_child(terreno)
	Mundo.preparar_terreno(terreno, self)
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
	if Vector2(x, z).distance_to(Vector2(CLAREIRA.x, CLAREIRA.z)) < 17.0:
		return false   # a clareira do pinhal fica limpa de árvores
	if Vector2(x, z).length() < terreno.clareira_raio * 1.02:
		return false
	if terreno.distancia_caminho(x, z) < folga_caminho or terreno.na_agua(x, z, 3.0):
		return false
	return terreno.normal_em(x, z).y >= inclinacao_min


func _floresta() -> void:
	var troncos := StaticBody3D.new()
	troncos.name = "TroncosColisao"
	add_child(troncos)
	Mundo.paredes_de_borda(self, TAM, troncos)
	var pinheiros: Array[Transform3D] = []
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
		# toda árvore tem tronco sólido
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
	_casa("Deposito", Vector3(-30, 0, -20), 3, 2, ESTILO_MADEIRA, "deposito")
	_placas()


## Placa de madeira acima de cada porta com a função da casa.
func _placas() -> void:
	var nomes := {"CasaDoVane": "Casa do Vane", "Forja": "Forja", "Cabana1": "Casa do Oren", "Cabana2": "Casa da Tessa", "Cabana3": "Casa da Mara", "Deposito": "Depósito de Grãos"}
	for id in nomes:
		var casa: Node3D = get_node(id)
		var x_porta: float = casa.get_meta("x_porta")
		var meia_z := float(casa.get_meta("linhas"))
		var tabua := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(2.0, 0.42, 0.06)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.3, 0.2, 0.11)
		b.material = m
		tabua.mesh = b
		tabua.position = Vector3(x_porta, 2.62, meia_z + 0.3)
		casa.add_child(tabua)
		var rotulo := Label3D.new()
		rotulo.text = nomes[id]
		rotulo.font_size = 40
		rotulo.pixel_size = 0.0045
		rotulo.outline_size = 8
		rotulo.modulate = Color(0.95, 0.85, 0.6)
		rotulo.position = Vector3(x_porta, 2.62, meia_z + 0.35)
		casa.add_child(rotulo)


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
		if (pos.z < 0.0 and absf(pos.x) < 8.0) or (absf(pos.z) < 8.0):
			continue   # saídas norte, leste e oeste
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
func _chao_vivo(ocupado: Array = []) -> void:
	var exclusoes: Array = [[Vector2.ZERO, 3.2]]   # a fogueira
	for o in ocupado:
		exclusoes.append(o)   # currais, galinheiro, horta, poço, canil
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
	var zona_curral := ZonaDeEvento.new()   # o cavalo fugido, ao chegar ao curral dos cavalos, conta para C1-M3
	zona_curral.id = "curral_cavalo"
	zona_curral.raio = 5.5
	zona_curral.grupo_alvo = "cavalo_perdido"
	zona_curral.position = Vector3(-30.0, 0.0, 13.0)
	add_child(zona_curral)
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


## Pátio de treino do Vane (boneco e três tochas) e o quadro de avisos da praça.
func _patio_de_treino() -> void:
	var boneco := BonecoDeTreino.new()
	boneco.name = "BonecoDeTreino"
	boneco.position = Vector3(-10.0, altura_em(-10.0, -13.0), -13.0)
	add_child(boneco)
	for p in [Vector2(-14.0, -11.0), Vector2(-10.0, -8.5), Vector2(-6.0, -11.0)]:
		var tocha := TochaDeTreino.new()
		tocha.name = "TochaDeTreino"
		tocha.position = Vector3(p.x, altura_em(p.x, p.y), p.y)
		add_child(tocha)
	var quadro := QuadroDeAvisos.new()
	quadro.name = "QuadroDeAvisos"
	quadro.position = Vector3(7.0, altura_em(7.0, -5.5), -5.5)
	quadro.rotation.y = atan2(-7.0, 5.5)   # a frente do quadro olha para a fogueira
	add_child(quadro)


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
	_npc("Halk", "Guarda do portão", "res://scenes/personagens/orin.tscn", Vector3(37.0, 0, 5.5), "Idle",
		PackedStringArray(["Portão do Refúgio. Ninguém sai sem a minha palavra.", "Batedores do Império rondam a estrada. Volte vivo, rapaz."]),
		Vector3(60, 0, 5.5),
		[{"esperar": 6.0, "anim": "Idle", "olhar": Vector3(60, 0, 5.5)}, {"ir": Vector3(37.0, 0, -5.5), "vel": 1.3},
		 {"esperar": 6.0, "anim": "Idle", "olhar": Vector3(60, 0, -5.5)}, {"ir": Vector3(37.0, 0, 5.5), "vel": 1.3}])
	_npc("Oren", "Agricultor", "res://scenes/personagens/oren.tscn", Vector3(12.8, 0, -12.3), "Idle",
		PackedStringArray(["Sem o pomar, o Refúgio passa fome. Cada maçã conta.", "Se passar pelo pomar, traga cestos cheios."]), Vector3(12.4, 0, -13.4),
		[{"fazer": "Fixing_Kneeling", "seg": 9.0, "olhar": Vector3(12.4, 0, -13.4)}, {"ir": Vector3(17.6, 0, -12.3)},
		 {"fazer": "Fixing_Kneeling", "seg": 9.0, "olhar": Vector3(17.6, 0, -13.4)}, {"ir": Vector3(12.8, 0, -12.3)}])
	_npc("Mara", "Cuidadora do curral", "res://scenes/personagens/mara.tscn", Vector3(3.0, 0, 27.5), "Idle",
		PackedStringArray(["Os animais sentem o medo da gente. Calma, e o cavalo vem.", "Mantenha as ovelhas longe da cerca: os lobos rondam."]), Vector3(0, 0, 31),
		[{"ir": Vector3(-4.5, 0, 33.0)}, {"fazer": "PickUp_Table", "seg": 3.0, "olhar": Vector3(-6.0, 0, 34.5)},
		 {"ir": Vector3(4.5, 0, 33.5)}, {"fazer": "PickUp_Table", "seg": 3.0, "olhar": Vector3(6.0, 0, 34.5)},
		 {"ir": Vector3(3.0, 0, 27.5)}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector3(0, 0, 31)}])
	_npc("Tessa", "Mensageira", "res://scenes/personagens/tessa.tscn", Vector3(1.5, 0, -18.0), "Idle_Talking",
		PackedStringArray(["Vi rastros de botas imperiais perto da estrada. Avise o Vane.", "Corro mais do que qualquer um aqui."]), Vector3(0, 0, -27),
		[{"esperar": 4.0, "anim": "Idle_Talking", "olhar": Vector3(0, 0, -27)}, {"ir": Vector3(0, 0, -10.0), "vel": 3.2, "anim": "Jog_Fwd"},
		 {"ir": Vector3(10, 0, -8.0), "vel": 3.2, "anim": "Jog_Fwd"}, {"ir": Vector3(20, 0, -1.0), "vel": 3.2, "anim": "Jog_Fwd"},
		 {"ir": Vector3(34, 0, -1.0), "vel": 3.2, "anim": "Jog_Fwd"}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector3(60, 0, -1)},
		 {"ir": Vector3(20, 0, -1.0), "vel": 3.2, "anim": "Jog_Fwd"}, {"ir": Vector3(10, 0, -8.0), "vel": 3.2, "anim": "Jog_Fwd"},
		 {"ir": Vector3(0, 0, -10.0), "vel": 3.2, "anim": "Jog_Fwd"}, {"ir": Vector3(1.5, 0, -21.0), "vel": 3.2, "anim": "Jog_Fwd"}])
	var nilo := _npc("Nilo", "Menino curioso", "res://scenes/personagens/nilo.tscn", Vector3(-3.0, 0, -16.0), "Idle",
		PackedStringArray(["Você tem um dragão! Posso ver de perto?", "Quando crescer, vou ser caçador como a Mira."]))
	nilo.segue_jogador = true
	_npc("Dorn", "Lenhador", "res://scenes/personagens/dorn.tscn", Vector3(22.4, 0, -24.2), "Idle",
		PackedStringArray(["Esses pinheiros seguram o telhado do mundo.", "A trilha do norte leva à mina. Cuidado com o Gorath."]), CEPO,
		[{"fazer": "Sword_Attack", "seg": 10.0, "olhar": CEPO}, {"ir": Vector3(20.4, 0, -24.6)},
		 {"esperar": 3.0, "anim": "PickUp_Table", "olhar": Vector3(20.3, 0, -26.0)}, {"ir": Vector3(22.4, 0, -24.2)}])
	_npc("Mira", "Caçadora", "res://scenes/personagens/mira.tscn", Vector3(-12.0, 0, 14.0), "Idle",
		PackedStringArray(["Rastros frescos no Bosque Velado. Algo grande passou por lá.", "Fale baixo."]), Vector3.ZERO,
		[{"ir": Vector3(-23.0, 0, 19.0), "vel": 1.3}, {"esperar": 6.0, "anim": "Crouch_Idle", "olhar": Vector3(-60, 0, 22)},
		 {"ir": Vector3(3.9, 0, 2.2), "vel": 1.4}, {"fazer": "Interact", "seg": 7.0, "olhar": CALDEIRAO},
		 {"ir": Vector3(-12.0, 0, 14.0), "vel": 1.4}, {"esperar": 4.0, "anim": "Idle", "olhar": Vector3(-12, 0, 30)}])


const NOMES_DE_ANIMAIS := {"vaca": "Vaca", "cavalo": "Cavalo", "ovelha": "Ovelha", "porco": "Porco", "cao": "Cão", "galinha": "Galinha"}
const VIDA_DE_ANIMAIS := {"vaca": 40, "cavalo": 50, "ovelha": 20, "porco": 25, "cao": 20, "galinha": 6}
const DROPS_DE_ANIMAIS := {
	"vaca": {"carne": [2, 3], "couro": [1, 1]},
	"cavalo": {"carne": [2, 3], "couro": [1, 2]},
	"ovelha": {"carne": [1, 2], "la": [1, 2]},
	"porco": {"carne": [2, 3]},
	"cao": {"couro": [1, 1]},
	"galinha": {"carne": [1, 1]},
}
const RAIO_DE_ANIMAIS := {"vaca": 1.0, "cavalo": 1.1, "ovelha": 0.6, "porco": 0.6, "cao": 0.4, "galinha": 0.3}


func _animal(arquivo: String, pos: Vector3, raio: float, velocidade: float) -> AnimalVila:
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
	return a


func _animais() -> void:
	# currais: vacas e ovelhas ao sul, porcos a oeste da casa do Vane, cavalos a oeste; galinheiro a sudeste; cães no canil do portão leste
	_animal("vaca", Vector3(-3, 0, 31), 3.0, 0.9)
	_animal("vaca", Vector3(4, 0, 32), 3.0, 0.9)
	_animal("ovelha", Vector3(0, 0, 28.5), 3.0, 0.8)
	_animal("ovelha", Vector3(-5, 0, 33), 2.5, 0.8)
	_animal("ovelha", Vector3(6, 0, 29.5), 2.5, 0.8)
	_animal("porco", Vector3(-16, 0, -28), 1.8, 0.8)
	_animal("porco", Vector3(-14, 0, -29.5), 1.8, 0.8)
	_animal("cavalo", Vector3(-31, 0, 12), 2.2, 1.3)
	_animal("cavalo", Vector3(-28.5, 0, 15), 2.2, 1.3)
	for k in 6:
		_animal("galinha", Vector3(10.5 + k * 0.6, 0, 20.5 + (k % 2) * 1.5), 1.8, 0.7)
	_animal("cao", Vector3(36.0, 0, -4.0), 2.0, 1.4)
	_animal("cao", Vector3(34.0, 0, -7.0), 2.0, 1.4)
	_animal("cao", Vector3(-17, 0, -6), 3.0, 1.4)


func _saidas() -> void:
	_novo_spawn("Principal", Vector3(0, 0, 14), Vector3(0, 0, -30))
	_novo_spawn("DoBosque", Vector3(0, 0, -43), Vector3(0, 0, 0))
	_novo_spawn("DaFronteira", Vector3(43, 0, 0), Vector3(0, 0, 0))
	_novo_spawn("DoPomar", Vector3(-43, 0, 0), Vector3(0, 0, 0))
	_portal(Vector3(-150, terreno.altura_em(-150, 0), 0), "pomar_alto", "Entrada").rotation.y = deg_to_rad(90.0)
	_portal(Vector3(0, terreno.altura_em(0, -150), -150), "bosque_velado", "Entrada")
	_portal(Vector3(150, terreno.altura_em(150, -1), -1), "acampamento_ruptura", "Entrada").rotation.y = deg_to_rad(90.0)


## Onde a Fagulha ferida fica deitada até o resgate (C1-M4).
func pos_fagulha_ferida() -> Vector3:
	var p := CLAREIRA + Vector3(5.0, 0.0, 3.0)
	return Vector3(p.x, altura_em(p.x, p.z), p.z)


## Clareira escondida no pinhal: chão escuro, círculo de pedras, a estaca de Ferro Negro com correntes até a Fagulha,
## três batedores imperiais de guarda e a zona que conta como "encontrar a clareira".
func _clareira_do_pinhal() -> void:
	var h := altura_em(CLAREIRA.x, CLAREIRA.z)
	var disco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 10.0
	cil.bottom_radius = 10.0
	cil.height = 0.08
	cil.radial_segments = 20
	var solo := StandardMaterial3D.new()
	solo.albedo_color = Color(0.17, 0.14, 0.11)
	solo.roughness = 1.0
	cil.material = solo
	disco.mesh = cil
	disco.position = Vector3(CLAREIRA.x, h + 0.05, CLAREIRA.z)
	add_child(disco)
	for i in 9:   # círculo de pedras
		var a := TAU * i / 9.0
		var pedra := MeshInstance3D.new()
		pedra.mesh = FabricaNatureza.pedra(5.0 + i)
		pedra.material_override = FabricaNatureza.material()
		pedra.scale = Vector3.ONE * 1.1
		var px := CLAREIRA.x + cos(a) * 10.5
		var pz := CLAREIRA.z + sin(a) * 10.5
		pedra.position = Vector3(px, altura_em(px, pz) - 0.1, pz)
		add_child(pedra)
	var estaca := EstacaDeFerroNegro.new()
	estaca.name = "EstacaDeFerroNegro"
	estaca.position = Vector3(CLAREIRA.x, h, CLAREIRA.z)
	add_child(estaca)
	var fag := pos_fagulha_ferida()
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.1, 0.1, 0.12)
	ferro.metallic = 0.6
	for k in 2:   # correntes da estaca até a Fagulha
		var de := Vector3(CLAREIRA.x, h + 1.2, CLAREIRA.z)
		var para := Vector3(fag.x + (k - 0.5) * 1.2, fag.y + 0.9, fag.z)
		var corr := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.04
		cc.bottom_radius = 0.04
		cc.height = de.distance_to(para)
		cc.radial_segments = 4
		cc.material = ferro
		corr.mesh = cc
		corr.position = (de + para) / 2.0
		add_child(corr)
		corr.look_at(para, Vector3.UP)
		corr.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	var alimentar := FagulhaFerida.new()
	alimentar.position = Vector3(fag.x - 2.5, fag.y, fag.z - 1.5)
	add_child(alimentar)
	var zona := ZonaDeEvento.new()
	zona.id = "clareira_pinhal"
	zona.raio = 15.0
	zona.position = Vector3(CLAREIRA.x, h, CLAREIRA.z)
	add_child(zona)
	var m := GerenciadorMissoes.instancia
	if m == null or not m.concluidas.has("C1-M4"):
		for p in [Vector2(-8, 6), Vector2(8, 5), Vector2(0, 11)]:   # três batedores imperiais de guarda
			var batedor: Inimigo = (load("res://scenes/inimigos/guarda_imperial.tscn") as PackedScene).instantiate()
			batedor.especie = "batedor"
			batedor.position = Vector3(CLAREIRA.x + p.x, altura_em(CLAREIRA.x + p.x, CLAREIRA.z + p.y) + 0.3, CLAREIRA.z + p.y)
			add_child(batedor)


## C1-M3 começa: lobos rondam o cercado das ovelhas e um cavalo some pela estrada leste.
func _ao_missao_iniciada(id: String) -> void:
	if id != "C1-M3":
		return
	var m := GerenciadorMissoes.instancia
	var faltam := 3 - m.feito("C1-M3", "lobos")
	var pontos := [Vector2(14, 30), Vector2(-14, 34), Vector2(-12, 24)]
	for i in faltam:
		var lobo: Inimigo = (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate()
		lobo.position = Vector3(pontos[i].x, altura_em(pontos[i].x, pontos[i].y) + 0.3, pontos[i].y)
		add_child(lobo)
	if m.feito("C1-M3", "cavalo") == 0 and get_tree().get_nodes_in_group("cavalo_perdido").is_empty():
		var cavalo := _animal("cavalo", Vector3(78.0, 0.0, 9.0), 0.5, 0.5)
		cavalo.add_to_group("cavalo_perdido")
		var acalmar := Interagivel.new()
		acalmar.id = "cavalo_perdido"
		acalmar.texto = "Acalmar o cavalo"
		acalmar.raio = 3.5
		cavalo.add_child(acalmar)
