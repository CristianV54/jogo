class_name Costa
extends RefCounted
## Costa recortada do mundo: o contorno não é mais um retângulo. `distancia(x, z)` é positiva em terra firme e negativa no
## mar; perto das regiões e dos povoados (`protegidos`) a costa recua para não os engolir. O chão desce até o mar (ver
## `TerrenoMundo`), há praia de areia e uma fileira de paredes invisíveis impede o Torin de entrar na água funda.

const NIVEL_MAR := -1.0

static var protegidos: Array = []   # [centro Vector2, raio]
static var _ruido: FastNoiseLite


static func distancia(x: float, z: float) -> float:
	if _ruido == null:
		_ruido = FastNoiseLite.new()
		_ruido.seed = 31
		_ruido.frequency = 0.0035
		_ruido.fractal_octaves = 3
	var lim := MundoDados.LIMITES
	var borda := minf(minf(x - lim.position.x, lim.end.x - x), minf(z - lim.position.y, lim.end.y - z))
	var recuo := 18.0 + 80.0 * (_ruido.get_noise_2d(x, z) * 0.5 + 0.5)
	var p := Vector2(x, z)
	var prot := 1e9
	for q in protegidos:
		prot = minf(prot, p.distance_to(q[0]) - float(q[1]))
	recuo *= smoothstep(0.0, 70.0, prot)
	return borda - recuo
