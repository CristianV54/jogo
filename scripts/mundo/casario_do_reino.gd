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
	for chave in _moldes:
		(_moldes[chave] as Node3D).free()
	_moldes.clear()
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
	return eixo.distance_to(p) > RECUO - 1.0


func _perto_da_linha(p: Vector2, pts: PackedVector2Array, folga: float) -> bool:
	for i in range(0, pts.size(), 2):
		if pts[i].distance_to(p) < folga:
			return true
	return false


func _casa(p: Vector2, para_a_rua: Vector2, rng: RandomNumberGenerator) -> void:
	var n := casas.size()
	# Uma casa de cada jeito é montada uma vez e as outras são cópias dela (copiar é dezenas de vezes mais rápido que montar).
	var chave := "%d_%d_%d" % [n % 2, 0 if n % 3 != 0 else 1, rng.randi() % PALETAS.size()]
	if not _moldes.has(chave):
		var partes := chave.split("_")
		var molde := ConstrutorCasa.montar(3, 2 + int(partes[0]), REF.ESTILO_PEDRA if partes[1] == "0" else REF.ESTILO_MADEIRA, true, "moradia", PALETAS[int(partes[2])])
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
