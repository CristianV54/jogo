class_name VidaDasRuas
extends Node3D
## O que dá vida às ruas de Valdoria (tirado do Reino de Aethelgard de blocos do Cristian):
##   - a FONTE da praça do mercado: tanque redondo, coluna, taça e água;
##   - LAMPIÕES dos dois lados da avenida do portão sul (o vidro brilha sem gastar luz de verdade);
##   - caixotes, barris e sacos encostados nas casas da avenida, e carroças paradas;
##   - os JARDINS ao pé do penhasco: arvoredo entre a rocha e a rua em anel.

var mundo: Mundo
var lampioes := 0
var arvores := 0
var rochas := 0
var npcs: Array[Npc] = []
var _solidos: StaticBody3D


func montar() -> void:
	name = "VidaDasRuas"
	_solidos = StaticBody3D.new()
	_solidos.name = "Solidos"
	add_child(_solidos)
	VilaRefugio.preparar(self, mundo.terreno.altura_em, _solidos)
	_fonte(MundoDados.PRACA.get_center())
	_avenida()
	_jardins()
	_rochas_do_penhasco()
	_gente()
	print("VidaDasRuas: fonte, ", lampioes, " lampiões e ", arvores, " árvores nos jardins, ", rochas, " rochas no paredão e ", npcs.size(), " pessoas circulando")


func _fonte(p: Vector2) -> void:
	var y := mundo.terreno.altura_em(p.x, p.y)
	var pedra := Pedra.material(Color(0.72, 0.7, 0.66))
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.25, 0.5, 0.62)
	agua.roughness = 0.15
	VilaRefugio._cilindro(Vector3(p.x, y + 0.45, p.y), 3.6, 0.9, pedra, true, 18)      # tanque
	VilaRefugio._cilindro(Vector3(p.x, y + 0.86, p.y), 3.2, 0.12, agua, false, 18)     # água
	VilaRefugio._cilindro(Vector3(p.x, y + 1.6, p.y), 0.45, 2.4, pedra, false, 10)     # coluna
	VilaRefugio._cilindro(Vector3(p.x, y + 2.9, p.y), 1.5, 0.3, pedra, false, 14)      # taça
	VilaRefugio._cilindro(Vector3(p.x, y + 3.08, p.y), 1.3, 0.08, agua, false, 14)
	VilaRefugio._cilindro(Vector3(p.x, y + 3.7, p.y), 0.25, 1.2, pedra, false, 8)      # pináculo


## Lampiões, caixotes, barris e carroças ao longo da avenida do portão sul.
func _avenida() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var ferro := VilaRefugio._mat(Color(0.16, 0.15, 0.15))
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(1.0, 0.82, 0.45)
	vidro.emission_enabled = true
	vidro.emission = Color(1.0, 0.75, 0.35)
	vidro.emission_energy_multiplier = 1.6
	var z := MundoDados.PRACA.end.y + 6.0
	var n := 0
	while z < 212.0:
		for s in [-1.0, 1.0]:
			var x: float = s * 7.4
			var y := mundo.terreno.altura_em(x, z)
			if true:   # um lampião a cada 15 m, dos dois lados
				VilaRefugio._caixa(Vector3(x, y + 1.8, z), Vector3(0.22, 3.6, 0.22), ferro, true)
				VilaRefugio._caixa(Vector3(x, y + 3.85, z), Vector3(0.55, 0.55, 0.55), vidro)
				lampioes += 1
			if n % 2 == 1 and rng.randf() < 0.7:
				ConstrutorCasa._movel(self, _solidos, ["Barrel", "Bag", "Barrel"][rng.randi() % 3], x, z + rng.randf_range(3.0, 6.0), rng.randf() * 90.0, y)
		z += 15.0
		n += 1
	for av in [[-150.0, -262.0, MundoDados.PORTAO_OESTE_Z], [150.0, 276.0, MundoDados.PORTAO_LESTE_Z]]:   # avenidas dos portões oeste e leste
		var passos := int(absf(float(av[1]) - float(av[0])) / 18.0)
		for k in passos:
			var x := lerpf(float(av[0]), float(av[1]), (k + 0.5) / passos)
			var zz: float = float(av[2]) + (6.4 if k % 2 == 0 else -6.4)
			var y := mundo.terreno.altura_em(x, zz)
			VilaRefugio._caixa(Vector3(x, y + 1.8, zz), Vector3(0.22, 3.6, 0.22), ferro, true)
			VilaRefugio._caixa(Vector3(x, y + 3.85, zz), Vector3(0.55, 0.55, 0.55), vidro)
			lampioes += 1
	for p in [Vector2(-4.0, 196.0), Vector2(3.8, 182.0)]:   # carroças paradas
		var y := mundo.terreno.altura_em(p.x, p.y)
		var madeira := VilaRefugio._mat(Color(0.4, 0.28, 0.16))
		VilaRefugio._caixa(Vector3(p.x, y + 0.9, p.y), Vector3(2.2, 0.8, 3.6), madeira, true)
		VilaRefugio._caixa(Vector3(p.x, y + 1.6, p.y), Vector3(1.4, 0.9, 1.6), VilaRefugio._mat(Color(0.7, 0.62, 0.36)))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var roda := VilaRefugio._cilindro(Vector3(p.x + sx * 1.2, y + 0.5, p.y + sz * 1.1), 0.5, 0.18, VilaRefugio._mat(Color(0.26, 0.18, 0.1)), false, 10)
				roda.rotation.z = PI / 2.0


## Arvoredo ao pé do penhasco, entre a rocha e a rua em anel (fora da avenida e do pé da rampa).
func _jardins() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	var a := MundoDados.ANEL_EIXOS
	var e := MundoDados.PENHASCO_EIXOS
	var pe := Vector2(-cos(MundoDados.RAMPA_TS) * e.x * 1.3, sin(MundoDados.RAMPA_TS) * e.y * 1.3)
	var copas: Array[Transform3D] = []
	for k in 700:
		var ang := rng.randf() * TAU
		var rr := rng.randf_range(0.72, 0.9)
		var p := Vector2(cos(ang) * a.x * rr, sin(ang) * a.y * rr)
		var livre := float(MundoDados.penhasco(p.x, p.y)[0]) < 0.1
		for d in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
			if float(MundoDados.penhasco(p.x + d.x, p.y + d.y)[0]) > 0.1:
				livre = false
		if not livre or (absf(p.x) < 14.0 and p.y > 0.0) or p.distance_to(pe) < 34.0 or mundo.terreno.distancia_caminho(p.x, p.y) < 5.0:
			continue
		var esc := rng.randf_range(0.6, 0.95)
		copas.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(esc, esc, esc)), Vector3(p.x, mundo.terreno.altura_em(p.x, p.y), p.y)))
		mundo.arvores.adicionar(p.x, p.y, 0.35 * esc)
		arvores += 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = FabricaNatureza.folhosa()
	mm.instance_count = copas.size()
	for i in copas.size():
		mm.set_instance_transform(i, copas[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "JardinsDoPenhasco"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)


## Relevo de rocha no paredão do penhasco: pedras grandes de tons diferentes cravadas na encosta (fora da rampa e do topo).
func _rochas_do_penhasco() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	var e := MundoDados.PENHASCO_EIXOS
	var lista: Array[Transform3D] = []
	var cores: Array[Color] = []
	for k in 2600:
		var p := Vector2(rng.randf_range(-e.x * 2.2, e.x * 2.2), rng.randf_range(-e.y * 2.2, e.y * 2.2))
		var pen := MundoDados.penhasco(p.x, p.y)
		var h: float = pen[0]
		if bool(pen[1]) or float(pen[2]) < 1.03 or h < 2.0 or h > MundoDados.PENHASCO_ALTURA - 1.0:
			continue
		var perto_da_rampa := false
		for d in [Vector2(5, 0), Vector2(-5, 0), Vector2(0, 5), Vector2(0, -5)]:
			if bool(MundoDados.penhasco(p.x + d.x, p.y + d.y)[1]):
				perto_da_rampa = true
		if perto_da_rampa:
			continue   # nada de pedra invadindo o caminho
		var esc := rng.randf_range(2.6, 6.5)
		lista.append(Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))).scaled_local(Vector3(esc, esc * rng.randf_range(0.8, 1.6), esc)), Vector3(p.x, mundo.terreno.altura_em(p.x, p.y) - esc * 0.25, p.y)))
		cores.append(Color(0.62, 0.6, 0.58) * rng.randf_range(0.6, 1.1))
		rochas += 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = FabricaNatureza.pedra(5.0)
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
		mm.set_instance_color(i, cores[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = "RochasDoPenhasco"
	inst.multimesh = mm
	inst.material_override = FabricaNatureza.material()
	add_child(inst)


## Gente circulando: moradores, mercadores ambulantes e guardas de ronda indo e vindo pela avenida do sul, pela praça,
## pelas avenidas dos portões e pela rua em anel. Andam só por rua (os dois pontos de cada trajeto ficam na mesma rua).
func _gente() -> void:
	var trajetos: Array = []
	for k in 4:
		var x := -3.0 + k * 2.0
		trajetos.append([Vector2(x, 180.0 + k * 6.0), Vector2(x, 214.0 - k * 4.0)])                        # avenida do sul
	trajetos.append([Vector2(-20.0, 136.0), Vector2(18.0, 168.0)])                                         # praça
	trajetos.append([Vector2(20.0, 134.0), Vector2(-16.0, 166.0)])
	trajetos.append([Vector2(-22.0, 150.0), Vector2(22.0, 152.0)])
	for k in 3:
		trajetos.append([Vector2(-155.0 - k * 22.0, 33.0 + k * 1.5), Vector2(-255.0 + k * 12.0, 36.5 - k)])    # avenida do oeste
		trajetos.append([Vector2(152.0 + k * 22.0, -47.0 + k * 1.5), Vector2(268.0 - k * 12.0, -43.5 - k)])    # avenida do leste
	for k in 3:   # viela junto da muralha do sul e mais gente na praça
		trajetos.append([Vector2(-60.0 + k * 50.0, 212.0 - absf(k - 1) * 4.0), Vector2(-90.0 + k * 50.0, 211.0 - absf(k - 1) * 4.0)])
	trajetos.append([Vector2(-24.0, 170.0), Vector2(24.0, 133.0)])
	trajetos.append([Vector2(6.0, 176.0), Vector2(-6.0, 131.0)])
	var a := MundoDados.ANEL_EIXOS
	for k in 9:   # rua em anel: trechos curtos, um depois do outro
		var ang := TAU * (k + 0.3) / 9.0
		trajetos.append([Vector2(cos(ang) * a.x, sin(ang) * a.y), Vector2(cos(ang + 0.22) * a.x, sin(ang + 0.22) * a.y)])
	var tipos := [["Moradora", "Moradora de Valdoria", "tessa", "Dia de feira na praça. Hoje o pão acaba cedo."], ["Morador", "Morador de Valdoria", "oren", "Quem sobe a rampa do penhasco a pé chega sem fôlego no portão. O rei devia mandar pôr bancos."],
		["Mercador ambulante", "Mercador", "dorn", "Sal, agulha e fita! Levo recado para qualquer vila da costa."], ["Guarda da ronda", "Guarda de Valdoria", "guarda_imperial", "Ronda da rua. Circulando, sem correria."],
		["Aprendiz de ferreiro", "Aprendiz", "orin", "Levo carvão para a forja do mestre. São três viagens por dia."], ["Lavadeira", "Lavadeira", "mira", "A água da fonte é fria até no verão. Bom para a roupa, ruim para as mãos."]]
	for i in trajetos.size():
		var t: Array = tipos[i % tipos.size()]
		var de: Vector2 = trajetos[i][0]
		var ate: Vector2 = trajetos[i][1]
		var n := Npc.new()
		n.nome = t[0]
		n.papel = t[1]
		n.falas = PackedStringArray([t[3]])
		n.cena = load("res://scenes/personagens/%s.tscn" % t[2])
		n.rotina = [{"ir": Vector3(ate.x, mundo.terreno.altura_em(ate.x, ate.y), ate.y), "vel": 1.2}, {"esperar": 4.0 + (i % 3) * 2.0, "anim": "Idle"},
			{"ir": Vector3(de.x, mundo.terreno.altura_em(de.x, de.y), de.y), "vel": 1.2}, {"esperar": 3.0 + (i % 4), "anim": "Idle_Talking" if i % 2 == 0 else "Idle"}]
		n.altura_em = mundo.terreno.altura_em
		n.position = Vector3(de.x, mundo.terreno.altura_em(de.x, de.y), de.y)
		add_child(n)
		npcs.append(n)
