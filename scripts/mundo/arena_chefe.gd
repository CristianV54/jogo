extends AreaBase
## Área de combate de um chefe. Um script, quatro estilos: "mata", "forte", "cratera" e "castelo".
## O chefe fica no centro e acorda quando o jogador chega perto. Quando cai, abre-se o portal para a próxima área.

signal chefe_vida(nome: String, atual: int, maximo: int)
signal chefe_morreu(id: String)

@export var estilo := "mata"
@export var nome_da_area := ""
@export var id_chefe := ""
@export var cena_chefe: PackedScene
@export var comuns: PackedStringArray = []     # cenas de inimigos comuns, espalhados na metade sul
@export var destino_volta := ""
@export var spawn_volta := ""
@export var destino_proximo := ""
@export var semente := 11

const TAM := 260.0
const ESTILOS := {
	"mata": {"topo": Color(0.22, 0.38, 0.6), "horizonte": Color(0.6, 0.68, 0.7), "neblina": Color(0.5, 0.6, 0.58), "densidade": 0.0042,
			"sol": Color(0.9, 0.95, 0.85), "energia": 0.8, "grama": Color(0.24, 0.38, 0.17), "mata": Color(0.14, 0.26, 0.13), "terra": Color(0.36, 0.28, 0.2), "pedra": Color(0.4, 0.4, 0.38)},
	"forte": {"topo": Color(0.45, 0.52, 0.62), "horizonte": Color(0.72, 0.74, 0.76), "neblina": Color(0.66, 0.68, 0.7), "densidade": 0.004,
			"sol": Color(1.0, 0.97, 0.9), "energia": 1.05, "grama": Color(0.4, 0.44, 0.24), "mata": Color(0.32, 0.36, 0.2), "terra": Color(0.5, 0.42, 0.32), "pedra": Color(0.5, 0.49, 0.47)},
	"cratera": {"topo": Color(0.16, 0.08, 0.09), "horizonte": Color(0.55, 0.22, 0.1), "neblina": Color(0.34, 0.14, 0.1), "densidade": 0.008,
			"sol": Color(1.0, 0.55, 0.3), "energia": 0.85, "grama": Color(0.34, 0.22, 0.19), "mata": Color(0.22, 0.15, 0.14), "terra": Color(0.42, 0.28, 0.21), "pedra": Color(0.36, 0.3, 0.29)},
	"castelo": {"topo": Color(0.32, 0.38, 0.52), "horizonte": Color(0.66, 0.66, 0.7), "neblina": Color(0.58, 0.58, 0.62), "densidade": 0.005,
			"sol": Color(0.95, 0.85, 0.85), "energia": 0.8, "grama": Color(0.28, 0.32, 0.22), "mata": Color(0.22, 0.26, 0.18), "terra": Color(0.4, 0.36, 0.34), "pedra": Color(0.5, 0.48, 0.5)},
}
const PEDRA := {
	"parede": "Wall_UnevenBrick_Straight", "porta": "Wall_UnevenBrick_Door_Round", "janela": "Wall_UnevenBrick_Window_Wide_Round",
	"piso": "Floor_UnevenBrick", "canto": "Corner_Exterior_Brick"}

var terreno: Terreno
var chefe: Inimigo
var engajado := false
var portal_aberto := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	nome_area = nome_da_area
	_rng.seed = semente
	_ambiente()
	_terreno()
	match estilo:
		"mata":
			_mata()
		"forte":
			_forte()
		"cratera":
			_cratera()
		"castelo":
			_castelo()
	_novo_spawn("Entrada", Vector3(0, 0, 46), Vector3(0, 0, -10))
	_novo_spawn("Principal", Vector3(0, 0, 46), Vector3(0, 0, -10))
	if destino_volta != "":
		_portal(Vector3(0, terreno.altura_em(0, 56), 56), destino_volta, spawn_volta)
	_chefe()
	_comuns()


func altura_em(x: float, z: float) -> float:
	return terreno.altura_em(x, z)


func _ambiente() -> void:
	var e_cfg: Dictionary = ESTILOS[estilo]
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = e_cfg["topo"]
	ceu.sky_horizon_color = e_cfg["horizonte"]
	ceu.ground_horizon_color = e_cfg["horizonte"]
	ceu.ground_bottom_color = e_cfg["neblina"]
	var sky := Sky.new()
	sky.sky_material = ceu
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.fog_enabled = true
	e.fog_light_color = e_cfg["neblina"]
	e.fog_density = e_cfg["densidade"]
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	sol.light_color = e_cfg["sol"]
	sol.light_energy = e_cfg["energia"]
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 130.0
	add_child(sol)


func _terreno() -> void:
	var c: Dictionary = ESTILOS[estilo]
	terreno = Terreno.new()
	terreno.name = "Terreno"
	terreno.tamanho = 240.0
	terreno.semente = semente
	terreno.clareira_raio = 42.0
	terreno.cor_grama = c["grama"]
	terreno.cor_mata = c["mata"]
	terreno.cor_terra = c["terra"]
	terreno.cor_pedra = c["pedra"]
	terreno.caminhos = [PackedVector2Array([Vector2(0, 0), Vector2(0, 50), Vector2(3, 90), Vector2(0, 120)])]
	add_child(terreno)
	terreno.gerar()


func _chefe() -> void:
	if cena_chefe == null:
		return
	chefe = cena_chefe.instantiate() as Inimigo
	chefe.position = Vector3(0, terreno.altura_em(0, -10) + 0.1, -10)
	add_child(chefe)
	chefe.vida_mudou.connect(func(a: int, m: int) -> void: chefe_vida.emit(chefe.nome, a, m))
	chefe.morreu.connect(_ao_morrer_chefe)


func _comuns() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente + 5
	for caminho in comuns:
		var cena: PackedScene = load(caminho)
		var ini := cena.instantiate() as Inimigo
		var ang := rng.randf_range(0.15 * PI, 0.85 * PI)   # metade sul
		var raio := rng.randf_range(14.0, 30.0)
		var x := cos(ang) * raio * (1.0 if rng.randf() > 0.5 else -1.0)
		var z := sin(ang) * raio
		ini.position = Vector3(x, terreno.altura_em(x, z) + 0.1, z)
		add_child(ini)


func _process(_delta: float) -> void:
	if chefe == null or chefe.estado == Inimigo.Estado.MORTO or engajado:
		return
	var js := get_tree().get_nodes_in_group("jogador")
	if js.size() > 0 and (js[0] as Node3D).global_position.distance_to(chefe.global_position) < 32.0:
		engajado = true
		chefe_vida.emit(chefe.nome, chefe.vida, chefe.vida_max)


func _ao_morrer_chefe(_i: Inimigo) -> void:
	chefe_morreu.emit(id_chefe)
	if destino_proximo != "" and not portal_aberto:
		portal_aberto = true
		var pos := Vector3(0, terreno.altura_em(0, -56), -56)
		_portal(pos, destino_proximo, "Entrada")
		var marca := MeshInstance3D.new()   # pilar de luz para o jogador ver o caminho aberto
		var cil := CylinderMesh.new()
		cil.top_radius = 0.6
		cil.bottom_radius = 1.4
		cil.height = 14.0
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.85, 0.4, 0.5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cil.material = m
		marca.mesh = cil
		marca.position = pos + Vector3(0, 7.0, 0)
		add_child(marca)
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.85, 0.5)
		luz.light_energy = 3.0
		luz.omni_range = 18.0
		luz.position = pos + Vector3(0, 2.0, 0)
		add_child(luz)


# ---------------------------------------------------------------- estilos
func _mata() -> void:
	Povoador.pinheiros(self, terreno, _rng, 240.0, 4200)
	Povoador.pedras(self, terreno, _rng, 240.0, 80, 0.6, 2.8)
	# entrada da mina do Gorath: dois pilares de pedra, um lintel e a boca escura
	var mat := FabricaNatureza.material()
	for lado in [-1, 1]:
		var p := MeshInstance3D.new()
		p.mesh = FabricaNatureza.pedra(9.0 + lado)
		p.material_override = mat
		p.scale = Vector3(4.0, 8.0, 4.0)
		p.position = Vector3(lado * 6.0, 0.0, -38.0)
		add_child(p)
	var lintel := MeshInstance3D.new()
	lintel.mesh = FabricaNatureza.pedra(21.0)
	lintel.material_override = mat
	lintel.scale = Vector3(7.5, 2.0, 3.2)
	lintel.position = Vector3(0, 4.6, -38.0)
	add_child(lintel)
	var boca := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(8.0, 5.5, 1.0)
	var mn := StandardMaterial3D.new()
	mn.albedo_color = Color(0.02, 0.02, 0.025)
	caixa.material = mn
	boca.mesh = caixa
	boca.position = Vector3(0, 2.7, -38.8)
	add_child(boca)
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(20, 6, 4)
	cs.shape = bx
	cs.position = Vector3(0, 3, -39)
	corpo.add_child(cs)


func _muralha(meia: float, camadas: int, lacuna_sul: int) -> void:
	var n := int(2.0 * meia / 2.0)
	var corpo := StaticBody3D.new()
	corpo.name = "MuralhaColisao"
	add_child(corpo)
	for lado in 4:
		var girar: float = [0.0, 180.0, 90.0, -90.0][lado]
		for i in n:
			var t := -meia + 1.0 + i * 2.0
			if lado == 0 and absf(t) < lacuna_sul:
				continue   # portão ao sul
			var pos: Vector3
			match lado:
				0: pos = Vector3(t, 0, meia)
				1: pos = Vector3(t, 0, -meia)
				2: pos = Vector3(meia, 0, t)
				_: pos = Vector3(-meia, 0, t)
			var fora := Vector3(0, 0, 1)
			match lado:
				1: fora = Vector3(0, 0, -1)
				2: fora = Vector3(1, 0, 0)
				3: fora = Vector3(-1, 0, 0)
			for c in camadas:
				var p := ConstrutorCasa.peca("Wall_UnevenBrick_Straight")
				p.position = pos + Vector3(0, c * 3.12, 0)
				p.rotation_degrees.y = girar + 180.0   # o tijolo olha para dentro, onde se luta
				add_child(p)
				var p2 := ConstrutorCasa.peca("Wall_UnevenBrick_Straight")   # segunda camada, costas coladas: tijolo para fora
				p2.position = pos + Vector3(0, c * 3.12, 0) + fora * 0.42
				p2.rotation_degrees.y = girar
				add_child(p2)
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		var comprimento := 2.0 * meia
		bx.size = Vector3(comprimento, 3.12 * camadas, 1.0) if lado < 2 else Vector3(1.0, 3.12 * camadas, comprimento)
		cs.shape = bx
		match lado:
			0: cs.position = Vector3(0, bx.size.y / 2.0, meia)
			1: cs.position = Vector3(0, bx.size.y / 2.0, -meia)
			2: cs.position = Vector3(meia, bx.size.y / 2.0, 0)
			_: cs.position = Vector3(-meia, bx.size.y / 2.0, 0)
		if lado == 0:   # o portão deixa passar: encurta o bloco sul em duas metades
			bx.size.x = meia - lacuna_sul
			var cs2 := CollisionShape3D.new()
			var bx2 := BoxShape3D.new()
			bx2.size = bx.size
			cs2.shape = bx2
			cs.position.x = -(meia + lacuna_sul) / 2.0
			cs2.position = Vector3((meia + lacuna_sul) / 2.0, cs.position.y, meia)
			corpo.add_child(cs2)
		corpo.add_child(cs)


func _forte() -> void:
	Povoador.pinheiros(self, terreno, _rng, 240.0, 700)
	Povoador.pedras(self, terreno, _rng, 240.0, 60, 0.6, 2.4)
	_muralha(24.0, 1, 3)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var torre := ConstrutorCasa.montar(2, 2, PEDRA)
			torre.position = Vector3(sx * 24.0, 0, sz * 24.0)
			torre.rotation.y = atan2(-torre.position.x, -torre.position.z)
			add_child(torre)


func _castelo() -> void:
	Povoador.pedras(self, terreno, _rng, 240.0, 30, 0.8, 2.4)
	var piso := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(66, 66)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.29, 0.3)
	m.roughness = 0.9
	plano.material = m
	piso.mesh = plano
	piso.position.y = 0.04
	add_child(piso)
	_muralha(32.0, 2, 4)
	var salao := ConstrutorCasa.montar(8, 4, PEDRA)
	salao.position = Vector3(0, 0, -50)
	salao.name = "SalaoDoTrono"
	add_child(salao)
	for i in 8:   # tochas
		var ang := TAU * i / 8.0
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.65, 0.35)
		luz.light_energy = 1.8
		luz.omni_range = 14.0
		luz.position = Vector3(cos(ang) * 26.0, 3.0, sin(ang) * 26.0)
		add_child(luz)


func _cratera() -> void:
	var brasa := OmniLight3D.new()   # luz de brasa sobre o chefe
	brasa.light_color = Color(1.0, 0.5, 0.25)
	brasa.light_energy = 3.5
	brasa.omni_range = 40.0
	brasa.position = Vector3(0, 8.0, -10)
	add_child(brasa)
	Povoador.pedras(self, terreno, _rng, 240.0, 130, 1.0, 5.0, true)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.38, 0.08)
	for k in 14:
		var ang := _rng.randf() * TAU
		var raio := _rng.randf_range(52.0, 100.0)
		var x := cos(ang) * raio
		var z := sin(ang) * raio
		var disco := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		var r := _rng.randf_range(3.0, 8.0)
		cil.top_radius = r
		cil.bottom_radius = r
		cil.height = 0.12
		cil.material = mat
		disco.mesh = cil
		disco.position = Vector3(x, terreno.altura_em(x, z) + 0.08, z)
		add_child(disco)
		if k < 7:
			var luz := OmniLight3D.new()
			luz.light_color = Color(1.0, 0.4, 0.15)
			luz.light_energy = 2.4
			luz.omni_range = 22.0
			luz.position = disco.position + Vector3(0, 2.5, 0)
			add_child(luz)
