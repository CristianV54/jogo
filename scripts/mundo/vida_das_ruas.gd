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
	print("VidaDasRuas: fonte, ", lampioes, " lampiões e ", arvores, " árvores nos jardins do penhasco")


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
			if n % 2 == 0:   # um lampião a cada 30 m
				VilaRefugio._caixa(Vector3(x, y + 1.8, z), Vector3(0.22, 3.6, 0.22), ferro, true)
				VilaRefugio._caixa(Vector3(x, y + 3.85, z), Vector3(0.55, 0.55, 0.55), vidro)
				lampioes += 1
			elif rng.randf() < 0.7:
				ConstrutorCasa._movel(self, _solidos, ["Barrel", "Bag", "Barrel"][rng.randi() % 3], x, z + rng.randf_range(-3.0, 3.0), rng.randf() * 90.0, y)
		z += 15.0
		n += 1
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
