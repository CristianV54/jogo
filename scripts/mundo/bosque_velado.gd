extends AreaBase
## Bosque Velado e Mina das Correntes (Capítulo II). Três zonas encadeadas de sul a norte:
##   Trilha dos Caçadores (acampamento, Elda) -> Riacho da Névoa (riacho, raízes, caça, Borin) -> Encosta da Mina
##   (andaimes, trilhos, elevador, caixas imperiais, entrada) -> corredor da mina (triagem, galeria alagada, depósito,
##   jaulas de Filhotes de Asa, Sava) -> praça do obelisco, onde se luta contra o Gorath com trilhos e carrinhos.
## Expõe os sinais de chefe que o Jogo espera (`chefe_vida`, `chefe_morreu`).

signal chefe_vida(nome: String, atual: int, maximo: int)
signal chefe_morreu(id: String)

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const TAM := 320.0
const ACAMPAMENTO := Vector2(0.0, 105.0)
const VALE := Vector2(0.0, 40.0)
const ENCOSTA := Vector2(0.0, -20.0)
const PRACA := Vector2(0.0, -112.0)
const TOCA := Vector2(-60.0, 70.0)

var terreno: Terreno
var chefe: Inimigo
var engajado := false
var obelisco: Obelisco
var _rng := RandomNumberGenerator.new()
var _solidos: StaticBody3D
var _ambiente_env: Environment
var _jaulas: Array[JaulaDeFilhote] = []
var _fauna: Array[AnimalVila] = []


func _ready() -> void:
	nome_area = "Bosque Velado"
	_rng.seed = 31
	_ambiente_nevoa()
	_terreno()
	_solidos = StaticBody3D.new()
	_solidos.name = "SolidosDoBosque"
	add_child(_solidos)
	VilaRefugio.preparar(self, altura_em, _solidos)
	Horizonte.montar(self, TAM, Color(0.14, 0.26, 0.15), Color(0.3, 0.38, 0.42), 130.0, true, 11)
	_floresta()
	_acampamento()
	_riacho()
	_encosta()
	_corredor()
	_praca()
	_jaulas_e_guardas()
	_animais()
	_npcs()
	VegetacaoRasteira.decorar_zonas(self, terreno, _rng, [[ACAMPAMENTO, 22.0, 1.0], [VALE, 48.0, 1.6], [ENCOSTA, 28.0, 0.8], [Vector2(0.0, 125.0), 24.0, 1.0]], [[ACAMPAMENTO, 3.0], [Vector2(0.0, VALE.y), 7.0]])
	_novo_spawn("Entrada", Vector3(0, altura_em(0, 135), 135), Vector3(0, 0, 100))
	_novo_spawn("Principal", Vector3(0, altura_em(0, 135), 135), Vector3(0, 0, 100))
	_portal(Vector3(0, altura_em(0, 152), 152), "refugio_do_pinhal", "DoBosque", 16.0)
	var m := GerenciadorMissoes.instancia
	if m:
		m.missao_concluida.connect(_ao_missao_concluida)
		if m.concluidas.has("C2-M3") and not m.concluidas.has("C2-M4"):
			_spawn_gorath()


func altura_em(x: float, z: float) -> float:
	return terreno.altura_em(x, z)


func _y(p: Vector2) -> float:
	return altura_em(p.x, p.y)


# ---------------------------------------------------------------- ambiente e terreno

func _ambiente_nevoa() -> void:
	_ambiente_padrao()
	var we := get_node("Ambiente") as WorldEnvironment
	_ambiente_env = we.environment
	_ambiente_env.fog_density = 0.013
	_ambiente_env.fog_light_color = Color(0.54, 0.63, 0.68)
	var ceu := _ambiente_env.sky.sky_material as ProceduralSkyMaterial
	ceu.sky_top_color = Color(0.26, 0.36, 0.5)
	ceu.sky_horizon_color = Color(0.6, 0.67, 0.72)
	(get_node("Sol") as DirectionalLight3D).light_energy = 0.85


func _terreno() -> void:
	terreno = Terreno.new()
	terreno.name = "Terreno"
	terreno.tamanho = TAM
	terreno.semente = 11
	terreno.amplitude = 9.0
	terreno.clareira_raio = 1.0
	terreno.cor_grama = Color(0.22, 0.36, 0.2)
	terreno.cor_mata = Color(0.14, 0.26, 0.15)
	terreno.cor_terra = Color(0.34, 0.28, 0.2)
	terreno.cor_pedra = Color(0.4, 0.4, 0.4)
	terreno.planos = [
		Vector3(ACAMPAMENTO.x, ACAMPAMENTO.y, 18.0), Vector3(VALE.x, VALE.y, 46.0), Vector3(ENCOSTA.x, ENCOSTA.y, 26.0),
		Vector3(0.0, -62.0, 14.0), Vector3(0.0, -80.0, 14.0), Vector3(PRACA.x, PRACA.y, 34.0), Vector3(TOCA.x, TOCA.y, 9.0),
	]
	terreno.caminhos = [PackedVector2Array([Vector2(0, 150), Vector2(0, 105), Vector2(2, 60), Vector2(0, 20), Vector2(0, -20), Vector2(0, -60), Vector2(0, -100)])]
	add_child(terreno)
	terreno.gerar()


## Círculos [centro, raio] onde não nascem árvores: acampamento, vale, encosta, corredor e praça.
func _zonas_livres() -> Array:
	return [[ACAMPAMENTO, 24.0], [VALE, 50.0], [ENCOSTA, 32.0], [Vector2(0, -62), 22.0], [Vector2(0, -82), 22.0], [PRACA, 40.0], [TOCA, 12.0], [Vector2(55, 80), 12.0]]


func _floresta() -> void:
	var livres := _zonas_livres()
	var pinheiros: Array[Transform3D] = []
	for k in 3200:
		var x := _rng.randf_range(-TAM / 2.0 * 0.97, TAM / 2.0 * 0.97)
		var z := _rng.randf_range(-TAM / 2.0 * 0.97, TAM / 2.0 * 0.97)
		var ok := true
		for l in livres:
			if Vector2(x, z).distance_to(l[0]) < l[1]:
				ok = false
				break
		if not ok or terreno.distancia_caminho(x, z) < 4.0 or terreno.normal_em(x, z).y < 0.72:
			continue
		var s := _rng.randf_range(0.8, 1.7)
		var h := altura_em(x, z)
		pinheiros.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s)), Vector3(x, h - 0.15, z)))
		# toda árvore tem tronco sólido
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 0.45 * s
		cil.height = 4.0
		cs.shape = cil
		cs.position = Vector3(x, h + 2.0, z)
		_solidos.add_child(cs)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = FabricaNatureza.pinheiro()
	mm.instance_count = pinheiros.size()
	for i in pinheiros.size():
		mm.set_instance_transform(i, pinheiros[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "Pinheiros"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)
	for lado in [[Vector3(0, 8, -158), Vector3(TAM, 16, 2)], [Vector3(0, 8, 158), Vector3(TAM, 16, 2)], [Vector3(-158, 8, 0), Vector3(2, 16, TAM)], [Vector3(158, 8, 0), Vector3(2, 16, TAM)]]:
		var cs := CollisionShape3D.new()   # paredes invisíveis na borda do mapa
		var caixa := BoxShape3D.new()
		caixa.size = lado[1]
		cs.shape = caixa
		cs.position = lado[0]
		_solidos.add_child(cs)


# ---------------------------------------------------------------- ajudantes

func _rocha(pos: Vector2, escala: float, colidir := true, semente := 1.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = FabricaNatureza.pedra(semente)
	mi.material_override = FabricaNatureza.material()
	mi.scale = Vector3(escala, escala * 1.1, escala)
	mi.position = Vector3(pos.x, _y(pos) - 0.2, pos.y)
	mi.rotation.y = _rng.randf() * TAU
	add_child(mi)
	if colidir:
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = escala * 0.55
		cil.height = escala * 1.6
		cs.shape = cil
		cs.position = Vector3(pos.x, _y(pos) + escala * 0.6, pos.y)
		_solidos.add_child(cs)


func _placa_em_poste(pos: Vector2, texto: String) -> Vector3:
	var y := _y(pos)
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	VilaRefugio._caixa(Vector3(pos.x, y + 1.3, pos.y), Vector3(0.18, 2.6, 0.18), madeira, true)
	VilaRefugio._caixa(Vector3(pos.x, y + 2.2, pos.y + 0.12), Vector3(2.4, 0.5, 0.06), madeira)
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.font_size = 44
	rotulo.pixel_size = 0.0048
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.position = Vector3(pos.x, y + 2.2, pos.y + 0.17)
	add_child(rotulo)
	return Vector3(pos.x, y + 2.5, pos.y)


func _tenda(pos: Vector2, giro: float, cor: Color) -> void:
	var y := _y(pos)
	var pano := VilaRefugio._mat(cor)
	VilaRefugio._telhado(Vector3(pos.x, y + 1.2, pos.y), Vector3(3.6, 2.4, 3.8), pano, giro)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.2, 2.2, 3.4)
	cs.shape = caixa
	cs.transform = Transform3D(Basis(Vector3.UP, giro), Vector3(pos.x, y + 1.1, pos.y))
	_solidos.add_child(cs)
	var frente := Vector3(sin(giro), 0.0, cos(giro)) * 1.9
	VilaRefugio._caixa(Vector3(pos.x + frente.x, y + 0.8, pos.y + frente.z), Vector3(0.9, 1.4, 0.06), VilaRefugio._mat(Color(0.08, 0.06, 0.05)), false, giro)


func _trilho(de: Vector2, para: Vector2) -> void:
	var dir := (para - de).normalized()
	var comp := de.distance_to(para)
	var giro := atan2(dir.x, dir.y)
	var ferro := VilaRefugio._mat(Color(0.18, 0.17, 0.17))
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	var lateral := Vector2(dir.y, -dir.x)
	for lado in [-0.6, 0.6]:
		var c: Vector2 = (de + para) / 2.0 + lateral * lado
		VilaRefugio._caixa(Vector3(c.x, _y(c) + 0.14, c.y), Vector3(0.1, 0.1, comp), ferro, false, giro)
	for i in int(comp / 1.1):
		var c := de + dir * (0.5 + i * 1.1)
		VilaRefugio._caixa(Vector3(c.x, _y(c) + 0.06, c.y), Vector3(1.9, 0.1, 0.22), madeira, false, giro)


func _bandeira(pos: Vector2) -> void:
	var y := _y(pos)
	VilaRefugio._caixa(Vector3(pos.x, y + 2.0, pos.y), Vector3(0.1, 4.0, 0.1), VilaRefugio._mat(Color(0.2, 0.15, 0.1)), true)
	VilaRefugio._caixa(Vector3(pos.x + 0.55, y + 3.3, pos.y), Vector3(1.0, 1.2, 0.04), VilaRefugio._mat(Color(0.08, 0.07, 0.09)))   # bandeira negra do Império
	VilaRefugio._caixa(Vector3(pos.x + 0.55, y + 3.3, pos.y + 0.03), Vector3(0.4, 0.4, 0.02), VilaRefugio._mat(Color(0.65, 0.1, 0.08)))


# ---------------------------------------------------------------- zona 1: Trilha dos Caçadores

func _acampamento() -> void:
	var c := ACAMPAMENTO
	var fogo := Fogo.new()
	fogo.escala = 0.9
	fogo.energia_luz = 2.0
	fogo.alcance_luz = 14.0
	fogo.position = Vector3(c.x, _y(c) + 0.15, c.y)
	add_child(fogo)
	for i in 8:   # pedras em volta da fogueira
		var a := TAU * i / 8.0
		_rocha(c + Vector2(cos(a), sin(a)) * 1.3, 0.35, false, 2.0 + i)
	_tenda(c + Vector2(-9, -6), 0.5, Color(0.42, 0.34, 0.22))
	_tenda(c + Vector2(9, -6), -0.5, Color(0.36, 0.3, 0.2))
	_tenda(c + Vector2(-10, 7), 2.4, Color(0.3, 0.38, 0.26))
	_tenda(c + Vector2(10, 7), -2.4, Color(0.45, 0.33, 0.2))
	var madeira := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	for lado in [-1.0, 1.0]:   # varais de couros secando
		var p := c + Vector2(lado * 15.0, 0.0)
		var y := _y(p)
		for dz in [-1.4, 1.4]:
			VilaRefugio._caixa(Vector3(p.x, y + 1.1, p.y + dz), Vector3(0.12, 2.2, 0.12), madeira, true)
		VilaRefugio._caixa(Vector3(p.x, y + 2.1, p.y), Vector3(0.1, 0.1, 3.0), madeira)
		for k in 3:
			var cor: Color = [Color(0.42, 0.3, 0.18), Color(0.5, 0.42, 0.3), Color(0.3, 0.2, 0.12)][k]
			VilaRefugio._caixa(Vector3(p.x, y + 1.5, p.y - 1.0 + k * 1.0), Vector3(0.05, 1.0, 0.7), VilaRefugio._mat(cor))
	var mesa := c + Vector2(0.0, 9.0)   # mesa de mapas
	ConstrutorCasa._movel(self, _solidos, "Table_Large", mesa.x, mesa.y, 0.0, _y(mesa))
	ConstrutorCasa._mapa_na_parede(self, mesa.x, mesa.y)
	var mapa := get_node("MapaDeArvendal") as MeshInstance3D
	mapa.position = Vector3(mesa.x, _y(mesa) + 0.84, mesa.y)
	mapa.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	mapa.scale = Vector3(1.15, 0.8, 1.0)
	for lado in [-1.0, 1.0]:
		var b := c + Vector2(lado * 3.6, 1.5)
		ConstrutorCasa._movel(self, _solidos, "Bench", b.x, b.y, 90.0 * lado, _y(b))
	var barris := c + Vector2(-13.0, -12.0)
	ConstrutorCasa._movel(self, _solidos, "Barrel", barris.x, barris.y, 0.0, _y(barris))
	ConstrutorCasa._movel(self, _solidos, "Chest_Wood", barris.x + 1.2, barris.y, 20.0, _y(barris))
	_placa_em_poste(Vector2(3.5, 128.0), "Trilha dos Caçadores")
	# pegadas: as de lobo levam à toca; as de bota levam a um acampamento abandonado, sem saída
	_pegadas([c + Vector2(-6, -6), Vector2(-20, 85), Vector2(-40, 78), TOCA + Vector2(5, 0)], false)
	_pegadas([c + Vector2(6, -6), Vector2(28, 92), Vector2(44, 84), Vector2(53, 80)], true)
	for k in 4:   # a toca do lobo: pedras em roda, ossos e uma boca escura
		var a := PI * (0.2 + k * 0.45)
		_rocha(TOCA + Vector2(cos(a), sin(a)) * 4.5, 2.2 + k * 0.3, true, 8.0 + k)
	for k in 5:
		var o := TOCA + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(0.5, 3.0))
		VilaRefugio._caixa(Vector3(o.x, _y(o) + 0.05, o.y), Vector3(0.5, 0.08, 0.1), VilaRefugio._mat(Color(0.85, 0.82, 0.72)), false, _rng.randf() * PI)
	var zona := ZonaDeEvento.new()
	zona.id = "toca_do_lobo"
	zona.raio = 7.0
	zona.position = Vector3(TOCA.x, _y(TOCA), TOCA.y)
	add_child(zona)
	var abandonado := Vector2(55, 80)   # acampamento abandonado (fim das pegadas de bota)
	for i in 5:
		_rocha(abandonado + Vector2(cos(TAU * i / 5.0), sin(TAU * i / 5.0)) * 1.1, 0.3, false, 3.0 + i)
	ConstrutorCasa._movel(self, _solidos, "Barrel", abandonado.x + 3.0, abandonado.y, 0.0, _y(abandonado))
	_placa_em_poste(abandonado + Vector2(-5.0, 3.0), "Acampamento abandonado")


func _pegadas(pontos: Array, bota: bool) -> void:
	var transf: Array[Transform3D] = []
	var cores: Array[Color] = []
	var lado := 1.0
	for i in pontos.size() - 1:
		var de: Vector2 = pontos[i]
		var para: Vector2 = pontos[i + 1]
		var dir := (para - de).normalized()
		var comp := de.distance_to(para)
		var lateral := Vector2(dir.y, -dir.x)
		for k in int(comp / 1.4):
			var p := de + dir * (k * 1.4) + lateral * 0.25 * lado
			lado = -lado
			var giro := atan2(dir.x, dir.y)
			if bota:
				transf.append(Transform3D(Basis(Vector3.UP, giro), Vector3(p.x, _y(p) + 0.04, p.y)))
				cores.append(Color(0.08, 0.06, 0.05))
			else:
				for dx in [-0.07, 0.07]:
					for dz in [-0.08, 0.08]:
						var q := p + Vector2(dx, dz).rotated(-giro)
						transf.append(Transform3D(Basis(Vector3.UP, giro), Vector3(q.x, _y(q) + 0.04, q.y)))
						cores.append(Color(0.1, 0.07, 0.05))
	var malha := BoxMesh.new()
	malha.size = Vector3(0.26, 0.03, 0.11) if bota else Vector3(0.06, 0.03, 0.08)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	VegetacaoRasteira._multimesh(self, malha, mat, transf, "PegadasDeBota" if bota else "PegadasDeLobo", cores)


# ---------------------------------------------------------------- zona 2: Riacho da Névoa

func _riacho() -> void:
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.08, 0.24, 0.4, 0.8)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.6
	var pontos: Array[Vector2] = []
	for x in range(-54, 56, 6):
		pontos.append(Vector2(x, VALE.y + 5.0 * sin(x * 0.12)))
	for i in pontos.size() - 1:
		var de := pontos[i]
		var para := pontos[i + 1]
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(3.8, 0.06, de.distance_to(para) + 0.8)
		b.material = agua
		mi.mesh = b
		var meio := (de + para) / 2.0
		mi.position = Vector3(meio.x, _y(meio) + 0.03, meio.y)
		mi.rotation.y = atan2((para - de).x, (para - de).y)
		add_child(mi)
	for k in 5:   # pedras de travessia, no cruzamento da trilha
		var p := Vector2(0.6, VALE.y - 1.8 + k * 0.9)
		_rocha(p, 0.5, false, 11.0 + k)
	for k in 14:   # pedras e raízes nas margens
		var x := -52.0 + k * 8.0
		_rocha(Vector2(x, VALE.y + 5.0 * sin(x * 0.12) + (3.4 if k % 2 == 0 else -3.4)), _rng.randf_range(0.5, 1.2), false, 20.0 + k)
	for k in 8:   # raízes medicinais colhíveis
		var x := -42.0 + k * 11.0
		var z := VALE.y + 5.0 * sin(x * 0.12) + (3.6 if k % 2 == 0 else -3.6)
		var raiz := RaizMedicinal.new()
		raiz.position = Vector3(x, altura_em(x, z), z)
		add_child(raiz)
	_placa_em_poste(Vector2(4.0, VALE.y + 12.0), "Riacho da Névoa")


# ---------------------------------------------------------------- zona 3: Encosta da Mina

func _andaime(pos: Vector2) -> void:
	var y := _y(pos)
	var madeira := VilaRefugio._mat(Color(0.34, 0.23, 0.13))
	for dx in [-2.0, 2.0]:
		for dz in [-2.0, 2.0]:
			VilaRefugio._caixa(Vector3(pos.x + dx, y + 3.5, pos.y + dz), Vector3(0.28, 7.0, 0.28), madeira, true)
	for nivel in [3.2, 6.4]:
		VilaRefugio._caixa(Vector3(pos.x, y + nivel, pos.y), Vector3(4.4, 0.2, 4.4), madeira)
	for lado in [-2.0, 2.0]:   # travessas diagonais
		var diag := VilaRefugio._caixa(Vector3(pos.x + lado, y + 1.7, pos.y - 2.0), Vector3(0.12, 3.9, 0.12), madeira)
		diag.rotation.z = 0.0
		VilaRefugio._caixa(Vector3(pos.x + lado, y + 5.0, pos.y + 2.0), Vector3(0.12, 3.3, 0.12), madeira)
	for degrau in 12:   # escada lateral
		VilaRefugio._caixa(Vector3(pos.x - 2.4, y + 0.3 + degrau * 0.58, pos.y), Vector3(0.1, 0.07, 0.8), madeira)


func _encosta() -> void:
	var e := ENCOSTA
	_trilho(Vector2(0, -2), Vector2(0, -44))
	var vagao := Vector2(0, -32)   # vagonete parado no trilho (decoração sólida)
	VilaRefugio._caixa(Vector3(vagao.x, _y(vagao) + 0.8, vagao.y), Vector3(1.5, 0.8, 2.2), VilaRefugio._mat(Color(0.3, 0.2, 0.11)), true)
	_andaime(e + Vector2(-14, -8))
	_andaime(e + Vector2(14, -14))
	var elevador := Vector2(-26, -42)   # elevador de carga: dois trilhos altos, plataforma e polia
	var ferro := VilaRefugio._mat(Color(0.15, 0.15, 0.16))
	var madeira := VilaRefugio._mat(Color(0.34, 0.23, 0.13))
	for dx in [-1.5, 1.5]:
		VilaRefugio._caixa(Vector3(elevador.x + dx, _y(elevador) + 5.0, elevador.y), Vector3(0.25, 10.0, 0.25), madeira, true)
	VilaRefugio._caixa(Vector3(elevador.x, _y(elevador) + 10.0, elevador.y), Vector3(3.3, 0.25, 0.25), madeira)
	VilaRefugio._caixa(Vector3(elevador.x, _y(elevador) + 3.0, elevador.y), Vector3(3.0, 0.2, 2.2), madeira)
	VilaRefugio._cilindro(Vector3(elevador.x, _y(elevador) + 10.4, elevador.y), 0.4, 0.3, ferro, false, 8).rotation_degrees.z = 90.0
	VilaRefugio._caixa(Vector3(elevador.x, _y(elevador) + 6.5, elevador.y), Vector3(0.04, 7.0, 0.04), VilaRefugio._mat(Color(0.5, 0.42, 0.3)))   # corda
	var preto := VilaRefugio._mat(Color(0.13, 0.08, 0.08))   # caixas imperiais
	for p in [Vector3(9, 0, -12), Vector3(10.4, 0, -12), Vector3(9.7, 1.0, -12), Vector3(-9, 0, -4), Vector3(-10.4, 0, -4.4)]:
		VilaRefugio._caixa(Vector3(p.x, _y(Vector2(p.x, p.z)) + 0.5 + p.y, p.z), Vector3(1.2, 1.0, 1.2), preto, true, _rng.randf_range(-0.2, 0.2))
	_bandeira(Vector2(-4, -8))
	_bandeira(Vector2(4, -8))
	# fachada da mina: dois pilares de pedra, lintel e boca escura (a passagem no meio fica livre)
	var mat := FabricaNatureza.material()
	for lado in [-1, 1]:
		var p := MeshInstance3D.new()
		p.mesh = FabricaNatureza.pedra(9.0 + lado)
		p.material_override = mat
		p.scale = Vector3(4.0, 9.0, 4.0)
		p.position = Vector3(lado * 7.0, _y(Vector2(lado * 7.0, -47.0)) - 0.2, -47.0)
		add_child(p)
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 2.4
		forma.height = 8.0
		cs.shape = forma
		cs.position = Vector3(lado * 7.0, _y(Vector2(lado * 7.0, -47.0)) + 4.0, -47.0)
		_solidos.add_child(cs)
	var lintel := MeshInstance3D.new()
	lintel.mesh = FabricaNatureza.pedra(21.0)
	lintel.material_override = mat
	lintel.scale = Vector3(9.0, 2.2, 3.4)
	lintel.position = Vector3(0, _y(Vector2(0, -47)) + 8.0, -47.0)
	add_child(lintel)
	VilaRefugio._caixa(Vector3(0, _y(Vector2(0, -47)) + 4.0, -49.0), Vector3(9.0, 8.0, 0.4), VilaRefugio._mat(Color(0.02, 0.02, 0.03)))
	_placa_em_poste(Vector2(-8.0, -42.0), "Mina das Correntes")
	for x in [-14.0, -21.0, -28.0, -35.0, -42.0, 14.0, 21.0, 28.0, 35.0, 42.0]:   # paredão de rocha dos dois lados da entrada
		_rocha(Vector2(x, -49.0), 6.0, true, 40.0 + x)


# ---------------------------------------------------------------- corredor da mina

func _corredor() -> void:
	for k in 11:   # paredões do corredor
		var z := -52.0 - k * 4.0
		_rocha(Vector2(-10.5, z), 4.2 + _rng.randf() * 1.0, true, 60.0 + k)
		_rocha(Vector2(10.5, z), 4.2 + _rng.randf() * 1.0, true, 80.0 + k)
	_trilho(Vector2(-2, -50), Vector2(-2, -96))
	var triagem := _casa_da_mina("Triagem", Vector3(-17, 0, -62), PI / 2.0, REF.ESTILO_PEDRA, "Sala de Triagem")
	var deposito := _casa_da_mina("DepositoDeMinerio", Vector3(17, 0, -84), -PI / 2.0, REF.ESTILO_MADEIRA, "Depósito de Minério")
	var agua := VilaRefugio._mat(Color(0.08, 0.24, 0.4, 0.8))   # galeria alagada
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var alagado := VilaRefugio._caixa(Vector3(5.0, _y(Vector2(5, -70)) + 0.1, -70.0), Vector3(6.0, 0.14, 22.0), agua)
	alagado.name = "GaleriaAlagada"
	VilaRefugio._caixa(Vector3(5.0, _y(Vector2(5, -70)) + 0.2, -70.0), Vector3(6.4, 0.1, 1.8), VilaRefugio._mat(Color(0.34, 0.23, 0.13)))   # passarela de tábuas
	_placa_em_poste(Vector2(-4.0, -58.0), "Galeria Alagada: cuidado")


func _casa_da_mina(nome_casa: String, pos: Vector3, giro: float, estilo: Dictionary, placa: String) -> Node3D:
	var casa := ConstrutorCasa.montar(3, 2, estilo, true, "deposito")
	casa.name = nome_casa
	casa.position = Vector3(pos.x, altura_em(pos.x, pos.z), pos.z)
	casa.rotation.y = giro
	add_child(casa)
	var x_porta: float = casa.get_meta("x_porta")
	var meia_z := float(casa.get_meta("linhas"))
	var tabua := VilaRefugio._mat(Color(0.3, 0.2, 0.11))
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(2.4, 0.42, 0.06)
	b.material = tabua
	mi.mesh = b
	mi.position = Vector3(x_porta, 2.62, meia_z + 0.3)
	casa.add_child(mi)
	var rotulo := Label3D.new()
	rotulo.text = placa
	rotulo.font_size = 40
	rotulo.pixel_size = 0.0045
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.position = Vector3(x_porta, 2.62, meia_z + 0.35)
	casa.add_child(rotulo)
	return casa


# ---------------------------------------------------------------- praça do obelisco e arena

func _praca() -> void:
	var c := PRACA
	for k in 24:   # anel de paredões em volta da praça, aberto ao sul (corredor)
		var graus := k * 15.0
		if graus > 62.0 and graus < 118.0:
			continue
		var a := deg_to_rad(graus)
		_rocha(c + Vector2(cos(a), sin(a)) * 31.0, 6.0, true, 100.0 + k)
	obelisco = Obelisco.new()
	obelisco.name = "Obelisco"
	obelisco.position = Vector3(c.x, _y(c), c.y)
	add_child(obelisco)
	obelisco.montar(altura_em)
	obelisco.caiu.connect(_ao_obelisco_cair)
	_trilho(Vector2(c.x - 24.0, c.y), Vector2(c.x + 24.0, c.y))   # trilhos em cruz: o vagonete rola e atropela
	_trilho(Vector2(c.x, c.y - 24.0), Vector2(c.x, c.y - 8.0))
	for it in [[Vector2(-18, 0), Vector3(1, 0, 0)], [Vector2(18, 0), Vector3(1, 0, 0)], [Vector2(0, -20), Vector3(0, 0, 1)]]:
		var carro := CarrinhoDeMinerio.new()
		carro.eixo = it[1]
		carro.position = Vector3(c.x + it[0].x, _y(c + it[0]) + 0.1, c.y + it[0].y)
		add_child(carro)
	var madeira := VilaRefugio._mat(Color(0.34, 0.23, 0.13))
	for lado in [-1.0, 1.0]:   # plataformas elevadas com degrau, para o Torin fugir do capataz
		var p := c + Vector2(lado * 21.0, -14.0)
		VilaRefugio._caixa(Vector3(p.x, _y(p) + 0.6, p.y), Vector3(4.4, 1.2, 4.4), madeira, true)
		VilaRefugio._caixa(Vector3(p.x, _y(p) + 0.3, p.y + 3.0), Vector3(2.4, 0.6, 1.6), madeira, true)


func _spawn_gorath() -> void:
	if chefe != null:
		return
	var cena := load("res://scenes/inimigos/gorath.tscn") as PackedScene
	chefe = cena.instantiate() as Inimigo
	chefe.especie = "gorath"
	var p := PRACA + Vector2(0, -18)
	chefe.position = Vector3(p.x, _y(p) + 0.1, p.y)
	add_child(chefe)
	chefe.vida_mudou.connect(func(a: int, m: int) -> void: chefe_vida.emit(chefe.nome, a, m))
	chefe.morreu.connect(func(_i: Inimigo) -> void: chefe_morreu.emit("gorath"))
	GerenciadorMissoes.instancia.aviso.emit("O capataz Gorath surge da mina, furioso!", 4.0)


func _process(_delta: float) -> void:
	if chefe == null or chefe.estado == Inimigo.Estado.MORTO or engajado:
		return
	var js := get_tree().get_nodes_in_group("jogador")
	if js.size() > 0 and (js[0] as Node3D).global_position.distance_to(chefe.global_position) < 34.0:
		engajado = true
		chefe_vida.emit(chefe.nome, chefe.vida, chefe.vida_max)


func _ao_missao_concluida(id: String) -> void:
	if id == "C2-M3":
		_spawn_gorath()


## O obelisco cai: a névoa recua, parte da caça foge e os filhotes que ainda estavam presos voam para longe.
func _ao_obelisco_cair() -> void:
	create_tween().tween_property(_ambiente_env, "fog_density", 0.004, 6.0)
	for a in _fauna:
		if is_instance_valid(a) and not a.morto:
			a._dir_fuga = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)).normalized()
			a._fuga = 6.0
	for j in _jaulas:
		if is_instance_valid(j) and j.disponivel():
			j.abrir()


# ---------------------------------------------------------------- jaulas, guardas, animais, NPCs

func _guarda(pos: Vector2, com_chave: bool) -> void:
	var g := (load("res://scenes/inimigos/guarda_imperial.tscn") as PackedScene).instantiate() as Inimigo
	g.nome = "Guarda da Mina"
	g.especie = "guarda_mina"
	if com_chave:
		g.drops = {"chave": [1, 1]}
	g.position = Vector3(pos.x, _y(pos) + 0.2, pos.y)
	add_child(g)


func _jaulas_e_guardas() -> void:
	for it in [[Vector2(-18, -12), Vector2(-14, -7)], [Vector2(-9, -72), Vector2(-4, -66)], [Vector2(11, -90), Vector2(7, -85)]]:   # jaula + guarda com a chave
		var j := JaulaDeFilhote.new()
		j.position = Vector3(it[0].x, _y(it[0]), it[0].y)
		add_child(j)
		_jaulas.append(j)
		_guarda(it[1], true)
	for p in [Vector2(-8, -100), Vector2(8, -100), Vector2(-12, -118), Vector2(12, -118)]:   # guardas da praça
		_guarda(p, false)


func _inimigo(caminho: String, pos: Vector2) -> void:
	var ini := (load(caminho) as PackedScene).instantiate() as Inimigo
	ini.position = Vector3(pos.x, _y(pos) + 0.3, pos.y)
	add_child(ini)


func _caca(modelo: String, pos: Vector2, esc: float, nome_animal: String, especie_animal: String, acess: String, vida: int, vel: float, drops_animal: Dictionary) -> void:
	var a := AnimalVila.new()
	a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [modelo, modelo])
	a.nome = nome_animal
	a.especie = especie_animal
	a.acessorio = acess
	a.escala = esc
	a.fugitivo = true
	a.raio_vagar = 6.0
	a.velocidade = vel
	a.vida_max = vida
	a.raio_colisao = 0.5
	a.drops = drops_animal
	a.altura_em = altura_em
	a.position = Vector3(pos.x, _y(pos), pos.y)
	add_child(a)
	_fauna.append(a)


func _animais() -> void:
	for p in [Vector2(24, 54), Vector2(-26, 30), Vector2(34, 22)]:
		_inimigo("res://scenes/inimigos/lobo.tscn", p)
	for p in [Vector2(-32, 56), Vector2(30, 28)]:
		_inimigo("res://scenes/inimigos/javali.tscn", p)
	_inimigo("res://scenes/inimigos/urso.tscn", Vector2(16, 30))   # urso defende a margem norte do riacho
	for p in [Vector2(-36, 74), Vector2(40, 72), Vector2(-12, 78), Vector2(14, 66)]:
		_caca("cavalo", p, 0.62, "Cervo", "cervo", "chifres", 30, 1.4, {"carne": [2, 3], "couro": [1, 1]})
	for p in [Vector2(-5, 118), Vector2(10, 122), Vector2(-18, 96), Vector2(22, 100), Vector2(-24, 50), Vector2(26, 46)]:
		_caca("cao", p, 0.5, "Coelho", "coelho", "orelhas_longas", 6, 1.8, {"carne": [1, 1]})
	for p in [Vector3(3.5, 2.7, 128.0), Vector3(15.0, 2.4, 105.0), Vector3(-13.0, 7.3, -22.0), Vector3(16.0, 7.3, -28.0)]:   # corvos pousados
		var corvo := Corvo.new()
		corvo.position = Vector3(p.x, altura_em(p.x, p.z) + p.y, p.z)
		add_child(corvo)


func _npc(nome_npc: String, papel: String, cena: String, pos: Vector2, falas: PackedStringArray, rotina: Array, oferece := "") -> void:
	var n := Npc.new()
	n.nome = nome_npc
	n.papel = papel
	n.falas = falas
	n.cena = load(cena)
	n.oferece_missao = oferece
	for passo in rotina:   # as rotinas pedem pontos 3D; aqui escrevemos em (x, z)
		for chave in ["ir", "olhar"]:
			if passo.has(chave) and passo[chave] is Vector2:
				var v: Vector2 = passo[chave]
				passo[chave] = Vector3(v.x, _y(v), v.y)
	n.rotina = rotina
	n.altura_em = altura_em
	n.position = Vector3(pos.x, _y(pos), pos.y)
	add_child(n)
	npcs.append(n)


func _npcs() -> void:
	var c := ACAMPAMENTO
	_npc("Elda", "Caçadora", "res://scenes/personagens/elda.tscn", c + Vector2(4, 4),
		PackedStringArray(["Sou a Elda. Caço neste bosque há vinte anos e conheço cada trilha.", "Vejo que você sabe andar. Quer aprender a seguir rastro de verdade? Fale comigo de novo."]),
		[{"esperar": 7.0, "anim": "Idle_Talking", "olhar": c}, {"ir": c + Vector2(4, 10), "vel": 1.3}, {"fazer": "Interact", "seg": 6.0, "olhar": c + Vector2(0, 9)}, {"ir": c + Vector2(4, 4), "vel": 1.3}],
		"C2-M1")
	_npc("Borin", "Mineiro fugitivo", "res://scenes/personagens/borin.tscn", Vector2(-49, 30),
		PackedStringArray(["Fale baixo. Os guardas do Império vasculham a mata atrás de mim.", "Fugi da mina. Foi ali que vi o que o Império faz."]),
		[{"esperar": 8.0, "anim": "Crouch_Idle", "olhar": Vector2(0, 60)}, {"esperar": 5.0, "anim": "Idle", "olhar": Vector2(-70, 30)}])
	_npc("Sava", "Prisioneira", "res://scenes/personagens/sava.tscn", Vector2(-6, -74),
		PackedStringArray(["Eu cuido dos filhotes que o Império prende. Cada jaula tem um guarda com a chave.", "Se você puder libertá-los, fale comigo de novo."]),
		[{"fazer": "Interact", "seg": 6.0, "olhar": Vector2(-9, -72)}, {"esperar": 4.0, "anim": "Idle_Talking", "olhar": Vector2(-9, -72)}],
		"C2-M2")
