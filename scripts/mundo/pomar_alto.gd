extends AreaBase
## Pomar Alto das Macieiras: encosta suave a oeste do Refúgio com cinco fileiras de macieiras colhíveis, cerca baixa, cestos,
## escada de colheita, barracão de ferramentas, pedras com musgo e um moinho de pedra com roda d'água e porta trancada.
## Cenário da missão C1-M2 (colheita). Entrada pelo sul; a saída leva de volta ao Refúgio.

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const TAM := 240.0

var terreno: Terreno
var _rng := RandomNumberGenerator.new()
var _solidos: StaticBody3D
var _rastros_postos := false


func _ready() -> void:
	nome_area = "Pomar Alto das Macieiras"
	_rng.seed = 77
	_ambiente_padrao()
	_terreno()
	_solidos = StaticBody3D.new()
	_solidos.name = "SolidosDoPomar"
	add_child(_solidos)
	VilaRefugio.preparar(self, altura_em, _solidos)
	_floresta()
	_pomar()
	_galpao()
	_moinho()
	_detalhes()
	_saidas()
	if GerenciadorMissoes.instancia:
		GerenciadorMissoes.instancia.objetivo_atualizado.connect(_ao_progresso)


func altura_em(x: float, z: float) -> float:
	return terreno.altura_em(x, z)


func _terreno() -> void:
	terreno = Terreno.new()
	terreno.name = "Terreno"
	terreno.tamanho = TAM
	terreno.clareira_raio = 85.0
	terreno.amplitude = 9.0
	terreno.inclinacao = Vector2(0.0, -0.04)   # sobe para o norte: a encosta do pomar
	terreno.caminhos = [
		PackedVector2Array([Vector2(0, 110), Vector2(0, 40), Vector2(0, 6), Vector2(0, -10)]),
		PackedVector2Array([Vector2(0, 18), Vector2(30, -18), Vector2(40, -34)]),   # até o moinho
	]
	add_child(terreno)
	terreno.gerar()


func _livre_de_arvore(x: float, z: float) -> bool:
	if Vector2(x, z).length() < 88.0:
		return false
	return terreno.normal_em(x, z).y >= 0.74


func _floresta() -> void:
	var pinheiros: Array[Transform3D] = []
	var colisoes := 0
	for k in 1500:
		var x := _rng.randf_range(-TAM / 2.0 * 0.97, TAM / 2.0 * 0.97)
		var z := _rng.randf_range(-TAM / 2.0 * 0.97, TAM / 2.0 * 0.97)
		if not _livre_de_arvore(x, z):
			continue
		var s := _rng.randf_range(0.8, 1.6)
		var h := altura_em(x, z)
		pinheiros.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s)), Vector3(x, h - 0.15, z)))
		if colisoes < 300:
			colisoes += 1
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
	for lado in [[Vector3(0, 6, -119), Vector3(TAM, 12, 2)], [Vector3(0, 6, 119), Vector3(TAM, 12, 2)], [Vector3(-119, 6, 0), Vector3(2, 12, TAM)], [Vector3(119, 6, 0), Vector3(2, 12, TAM)]]:
		var cs := CollisionShape3D.new()   # paredes invisíveis na borda do mapa
		var caixa := BoxShape3D.new()
		caixa.size = lado[1]
		cs.shape = caixa
		cs.position = lado[0]
		_solidos.add_child(cs)


func _pomar() -> void:
	for j in 5:
		for i in 7:
			var x := -18.0 + i * 6.0
			var z := -50.0 + j * 12.0
			var arvore := MacieiraColhivel.new()
			arvore.name = "Macieira"
			arvore.position = Vector3(x + _rng.randf_range(-0.4, 0.4), altura_em(x, z), z + _rng.randf_range(-0.4, 0.4))
			add_child(arvore)
	VilaRefugio._cerca_retangular(Vector3(0.0, 0.0, -26.0), 52.0, 64.0, "s", 5.0)   # cerca baixa em volta do pomar
	var cesto_virado := CestoVirado.new()
	cesto_virado.position = Vector3(9.0, altura_em(9.0, -8.0), -8.0)
	add_child(cesto_virado)


## Cestos em pé, escada encostada numa macieira e pedras com musgo.
func _detalhes() -> void:
	var palha := StandardMaterial3D.new()
	palha.albedo_color = Color(0.62, 0.45, 0.22)
	for p in [Vector2(-9.0, -20.0), Vector2(3.0, -32.0), Vector2(14.0, -44.0), Vector2(-3.0, 1.5)]:
		var cesto := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.42
		cil.bottom_radius = 0.3
		cil.height = 0.55
		cil.radial_segments = 8
		cil.material = palha
		cesto.mesh = cil
		cesto.position = Vector3(p.x, altura_em(p.x, p.y) + 0.28, p.y)
		add_child(cesto)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.34, 0.22, 0.12)
	var base := Vector3(-6.4, altura_em(-6.4, -26.0), -26.0)   # escada de colheita encostada na macieira da terceira fileira
	for lado in [-0.28, 0.28]:
		var trilho := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.07, 3.4, 0.07)
		b.material = madeira
		trilho.mesh = b
		trilho.position = base + Vector3(0.0, 1.6, lado)
		trilho.rotation_degrees.z = -14.0
		add_child(trilho)
	for degrau in 7:
		var d := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.06, 0.06, 0.6)
		b.material = madeira
		d.mesh = b
		d.position = base + Vector3(-0.12 * degrau * 0.4, 0.4 + degrau * 0.46, 0.0)
		add_child(d)
	var musgo := StandardMaterial3D.new()
	musgo.albedo_color = Color(0.35, 0.48, 0.3)
	musgo.roughness = 1.0
	for k in 10:   # pedras cobertas de musgo
		var x := _rng.randf_range(-40.0, 40.0)
		var z := _rng.randf_range(-62.0, 40.0)
		if absf(x) < 27.0 and z > -60.0 and z < 8.0:
			continue
		var pedra := MeshInstance3D.new()
		pedra.mesh = FabricaNatureza.pedra(3.0 + k)
		pedra.material_override = musgo
		pedra.scale = Vector3.ONE * _rng.randf_range(0.9, 1.8)
		pedra.position = Vector3(x, altura_em(x, z) - 0.1, z)
		add_child(pedra)


func _casa(nome_casa: String, pos: Vector3, colunas: int, linhas: int, estilo: Dictionary, interior: String, placa: String) -> Node3D:
	var casa := ConstrutorCasa.montar(colunas, linhas, estilo, true, interior)
	casa.name = nome_casa
	casa.position = Vector3(pos.x, altura_em(pos.x, pos.z), pos.z)
	casa.rotation.y = atan2(-pos.x, -pos.z)
	add_child(casa)
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
	rotulo.text = placa
	rotulo.font_size = 40
	rotulo.pixel_size = 0.0045
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.position = Vector3(x_porta, 2.62, meia_z + 0.35)
	casa.add_child(rotulo)
	return casa


func _galpao() -> void:
	_casa("BarracaoDeFerramentas", Vector3(-38.0, 0.0, -30.0), 2, 2, REF.ESTILO_MADEIRA, "deposito", "Barracão de Ferramentas")


func _moinho() -> void:
	var casa := _casa("Moinho", Vector3(44.0, 0.0, -40.0), 3, 3, REF.ESTILO_PEDRA, "deposito", "Moinho do Pomar")
	var porta := casa.get_node("Porta") as PortaCasa
	porta.trancada = true   # o moleiro sumiu com a chave: abre numa missão secundária futura
	var aviso := InteragivelAviso.new()
	aviso.texto = "Porta trancada"
	aviso.mensagem = "Trancada. Dizem que o moleiro levou a chave quando os soldados chegaram."
	aviso.raio = 2.6
	aviso.position = Vector3(float(casa.get_meta("x_porta")), 0.0, 3.4)
	casa.add_child(aviso)
	var roda := RodaDagua.new()   # roda d'água na lateral direita, sobre o riacho
	roda.position = Vector3(3.6, 1.7, 0.0)
	casa.add_child(roda)
	var agua := MeshInstance3D.new()
	var rio := BoxMesh.new()
	rio.size = Vector3(2.6, 0.06, 26.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.24, 0.4, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.7
	rio.material = m
	agua.mesh = rio
	agua.position = Vector3(3.6, 0.12, 6.0)
	casa.add_child(agua)


func _saidas() -> void:
	_novo_spawn("Principal", Vector3(0, altura_em(0, 62), 62), Vector3(0, 0, 0))
	_portal(Vector3(0, altura_em(0, 105), 105), "refugio_do_pinhal", "DoPomar", 14.0)


## Rastros de botas imperiais aparecem junto à cerca quando a colheita passa da metade (evento da C1-M2).
func _ao_progresso(id: String) -> void:
	var m := GerenciadorMissoes.instancia
	if id != "C1-M2" or _rastros_postos or m.feito("C1-M2", "macas") < 3:
		return
	_rastros_postos = true
	var bota := StandardMaterial3D.new()
	bota.albedo_color = Color(0.1, 0.08, 0.06)
	for k in 10:
		var x := -27.5 - k * 0.9
		var z := -30.0 + (k % 2) * 0.5
		var marca := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.28, 0.02, 0.12)
		b.material = bota
		marca.mesh = b
		marca.position = Vector3(x, altura_em(x, z) + 0.04, z)
		marca.rotation.y = 0.15
		add_child(marca)
	m.aviso.emit("Rastros de botas imperiais junto à cerca. Alguém andou espiando o pomar.", 4.5)
