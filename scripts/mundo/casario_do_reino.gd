class_name CasarioDoReino
extends Node3D
## As casas de rua do reino: fileiras de casas dos dois lados da Rua do Anel, da Rua do Meio e das estradas que entram
## pelos portões, enchendo o espaço entre os bairros. Cada casa olha para a rua. Nenhuma nasce em cima de outra rua ou
## trilha, dentro de bairro ou mercado, dentro de Valdoria ou do Castelo, nem colada na muralha.
## Para não pesar, cada casa só é desenhada até 300 m (de longe quem aparece são a muralha, as torres e os bairros).

const REF := preload("res://scripts/mundo/refugio_do_pinhal.gd")
const RUAS := ["anel_do_reino", "rua_do_meio_oeste", "rua_do_meio_leste", "reino_sul", "campos", "ferrogris"]   # mais todas as "travessa_NN"
const PASSO := 18.0        # de uma casa à seguinte, ao longo da rua
const RECUO := 13.0        # do eixo da rua até o meio da casa
const VISIVEL_ATE := 300.0
const PALETAS := [{"parede": Color(1.0, 0.9, 0.75), "telhado": Color(0.85, 0.5, 0.38)}, {"parede": Color(0.9, 0.86, 0.8), "telhado": Color(0.55, 0.5, 0.58)},
	{"parede": Color(0.95, 0.8, 0.62), "telhado": Color(0.6, 0.38, 0.32)}, {"parede": Color(0.82, 0.84, 0.9), "telhado": Color(0.45, 0.5, 0.62)}, {"parede": Color(0.86, 0.74, 0.6), "telhado": Color(0.5, 0.32, 0.26)}]

var mundo: Mundo
var casas: Array[Vector2] = []
var hortas := 0
var arvores_de_quintal := 0
var pocos := 0
var _moldes: Dictionary = {}   # "tamanho_estilo_paleta" -> casa montada (fora da cena), de onde saem as cópias


func montar() -> void:
	name = "CasarioDoReino"
	var c: Vector2 = MundoDados.REINO["centro"]
	var r: float = MundoDados.REINO["raio"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var ruas: Array = RUAS.duplicate()
	for id in mundo.estradas:
		if String(id).begins_with("travessa_"):
			ruas.append(id)
	for id in ruas:
		var comp := mundo.comprimento_da_estrada(id)
		var s := PASSO / 2.0
		while s < comp:
			var par := mundo.ponto_na_estrada(id, s)
			var eixo: Vector2 = par[0]
			var dir: Vector2 = par[1]
			for lado in [-1.0, 1.0]:
				var p: Vector2 = eixo + Vector2(-dir.y, dir.x) * lado * RECUO
				if _livre(p, c, r, id, eixo):
					_casa(p, eixo - p, rng)
			s += PASSO
	var de_rua := casas.size()
	_encher_os_quarteiroes(c, r, rng)
	for chave in _moldes:
		(_moldes[chave] as Node3D).free()
	_moldes.clear()
	print("CasarioDoReino: quarteirões com ", casas.size() - de_rua, " casas de fundo, ", hortas, " hortas, ", arvores_de_quintal, " árvores de quintal e ", pocos, " poços")
	print("CasarioDoReino: ", casas.size(), " casas de rua")


func _livre(p: Vector2, c: Vector2, r: float, rua: String, eixo: Vector2) -> bool:
	if p.distance_to(c) > r - 26.0 or mundo._em_alguma_area(p):
		return false
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id, 22.0).has_point(p):
			return false
	for pid in mundo.povoados:
		if p.distance_to(mundo.povoados[pid]["centro"]) < float(mundo.povoados[pid]["raio"]) + 14.0:
			return false
	for outra in casas:
		if outra.distance_to(p) < 17.0:
			return false
	for id in mundo.estradas:   # nem em cima de outra rua (cruzamentos), nem de trilha
		if id != rua and _perto_da_linha(p, mundo.estradas[id], 12.0):
			return false
	for trilha in mundo.trilhas:
		if _perto_da_linha(p, trilha, 10.0):
			return false
	if _em_ladeira(p):
		return false
	return eixo.distance_to(p) > RECUO - 1.0


## Ladeira (o morro do Castelo): casa só em chão plano.
func _em_ladeira(p: Vector2) -> bool:
	var h0 := mundo.terreno.altura_em(p.x, p.y)
	for d in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
		if absf(mundo.terreno.altura_em(p.x + d.x, p.y + d.y) - h0) > 0.3:
			return true
	return false


## O MIOLO DOS QUARTEIRÕES: entre uma rua e outra o reino não é pasto. Cada lote de 24 m ganha uma casa de fundo, uma horta
## de canteiros, um quintal com árvores de fruta ou um poço. Só fica vazio o que é rua, bairro, mercado, ladeira ou muralha.
func _encher_os_quarteiroes(c: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var canteiros: Array[Transform3D] = []
	var verdes: Array[Transform3D] = []
	var copas: Array[Transform3D] = []
	var solidos := StaticBody3D.new()
	solidos.name = "SolidosDosQuintais"
	add_child(solidos)
	VilaRefugio.preparar(self, mundo.terreno.altura_em, solidos)
	var lote := 24.0
	var gx := c.x - r
	while gx < c.x + r:
		var gz := c.y - r
		while gz < c.y + r:
			var p := Vector2(gx + rng.randf_range(4.0, lote - 4.0), gz + rng.randf_range(4.0, lote - 4.0))
			gz += lote
			if not _lote_livre(p, c, r):
				continue
			var sorte := rng.randf()
			var y := mundo.terreno.altura_em(p.x, p.y)
			if sorte < 0.42:      # casa de fundo, virada para a rua mais próxima
				_casa(p, _rumo_da_rua(p), rng, "vazio")
			elif sorte < 0.66:    # horta: quatro canteiros de terra com verdura
				var giro := rng.randf() * PI
				for k in 4:
					var q := p + Vector2(cos(giro), sin(giro)).orthogonal() * (k - 1.5) * 2.2
					canteiros.append(Transform3D(Basis(Vector3.UP, -giro).scaled_local(Vector3(8.0, 0.3, 1.4)), Vector3(q.x, y + 0.12, q.y)))
					for v in 5:
						var w := q + Vector2(cos(giro), sin(giro)) * (v - 2.0) * 1.6
						verdes.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(0.7, rng.randf_range(0.5, 0.9), 0.7)), Vector3(w.x, y + 0.45, w.y)))
				hortas += 1
			elif sorte < 0.9:     # quintal de árvores de fruta
				for k in rng.randi_range(2, 4):
					var q := p + Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-7.0, 7.0))
					var e := rng.randf_range(0.7, 1.0)
					copas.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(e, e, e)), Vector3(q.x, mundo.terreno.altura_em(q.x, q.y), q.y)))
					mundo.arvores.adicionar(q.x, q.y, 0.35 * e)
					arvores_de_quintal += 1
			elif sorte < 0.95:    # poço de quintal
				VilaRefugio._poco(Vector3(p.x, 0.0, p.y))
				pocos += 1
		gx += lote
	var caixa := BoxMesh.new()
	caixa.material = VilaRefugio._mat(Color(0.3, 0.2, 0.12))
	_espalhar("Canteiros", caixa, canteiros, 220.0)
	var moita := FabricaNatureza.arbusto(3.0)
	_espalhar("Verduras", moita, verdes, 160.0, FabricaNatureza.material())
	_espalhar("ArvoresDeQuintal", FabricaNatureza.folhosa(), copas, 420.0, FabricaNatureza.material())


func _lote_livre(p: Vector2, c: Vector2, r: float) -> bool:
	if p.distance_to(c) > r - 24.0 or mundo.terreno.distancia_caminho(p.x, p.y) < 11.0 or _em_ladeira(p):
		return false
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id, 26.0).has_point(p):
			return false
	for pid in mundo.povoados:
		if p.distance_to(mundo.povoados[pid]["centro"]) < float(mundo.povoados[pid]["raio"]) + 12.0:
			return false
	for outra in casas:
		if outra.distance_to(p) < 15.0:
			return false
	return true


## Direção (não normalizada) do lote até a rua mais próxima: a casa de fundo vira a porta para lá.
func _rumo_da_rua(p: Vector2) -> Vector2:
	var melhor := Vector2(0, 1)
	var dmin := 1e9
	for id in mundo.estradas:
		var pts: PackedVector2Array = mundo.estradas[id]
		for i in range(0, pts.size(), 3):
			var d := pts[i].distance_squared_to(p)
			if d < dmin:
				dmin = d
				melhor = pts[i] - p
	return melhor


func _espalhar(nome: String, malha: Mesh, lista: Array[Transform3D], visivel_ate: float, mat: Material = null) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malha
	mm.instance_count = lista.size()
	for i in lista.size():
		mm.set_instance_transform(i, lista[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = nome
	inst.multimesh = mm
	if mat:
		inst.material_override = mat
	inst.visibility_range_end = visivel_ate
	add_child(inst)


func _perto_da_linha(p: Vector2, pts: PackedVector2Array, folga: float) -> bool:
	for i in range(0, pts.size(), 2):
		if pts[i].distance_to(p) < folga:
			return true
	return false


func _casa(p: Vector2, para_a_rua: Vector2, rng: RandomNumberGenerator, interior := "moradia") -> void:
	var n := casas.size()
	# Uma casa de cada jeito é montada uma vez e as outras são cópias dela (copiar é dezenas de vezes mais rápido que montar).
	var chave := "%d_%d_%d_%s" % [n % 2, 0 if n % 3 != 0 else 1, rng.randi() % PALETAS.size(), interior]
	if not _moldes.has(chave):
		var partes := chave.split("_")
		var molde := ConstrutorCasa.montar(3, 2 + int(partes[0]), REF.ESTILO_PEDRA if partes[1] == "0" else REF.ESTILO_MADEIRA, true, interior, PALETAS[int(partes[2])])
		for g in molde.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).visibility_range_end = VISIVEL_ATE
			(g as GeometryInstance3D).visibility_range_end_margin = 20.0
		_moldes[chave] = molde
	var casa := (_moldes[chave] as Node3D).duplicate() as Node3D
	casa.name = "CasaDeRua%d" % n
	casa.position = Vector3(p.x, mundo.terreno.altura_em(p.x, p.y), p.y)
	casa.rotation.y = atan2(para_a_rua.x, para_a_rua.y)   # a porta (+Z local) olha para a rua
	add_child(casa)
	casas.append(p)
