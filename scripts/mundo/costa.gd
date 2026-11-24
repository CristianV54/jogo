class_name Costa
extends RefCounted
## Costa da ilha. `distancia(x, z)` é positiva em terra firme e negativa no mar; perto das regiões e dos povoados
## (`protegidos`) a costa recua para não os engolir. O chão desce até o mar (ver `TerrenoMundo`): praia, uma faixa de água
## rasa onde dá para entrar e, depois dela, a água funda (onde mora o tubarão, ver `Tubarao`).

const NIVEL_MAR := -1.0
const FUNDO_RASO := 0.6      # fundura da água na faixa rasa junto à praia
const LARGURA_RASO := 30.0   # até onde vai o raso, mar adentro (depois o fundo cai)
const PAREDE := 48.0         # distância mar adentro da parede invisível (o tubarão pega antes, ver Tubarao)

static var protegidos: Array = []   # [centro Vector2, raio]
static var _ruido: FastNoiseLite


static func distancia(x: float, z: float) -> float:
	if _ruido == null:
		_ruido = FastNoiseLite.new()
		_ruido.seed = 31
		_ruido.frequency = 0.0035
		_ruido.fractal_octaves = 3
	# Ilha: a costa fica a um raio do centro que muda com o ângulo (baías e pontas) e com um ruído fino (recortes).
	var ang := atan2(z, x)
	var raio := MundoDados.RAIO_DA_ILHA + 110.0 * sin(ang * 3.0 + 0.6) + 70.0 * sin(ang * 5.0 + 2.1) + 40.0 * sin(ang * 9.0 + 4.0)
	var d := raio - Vector2(x, z).length() + 30.0 * _ruido.get_noise_2d(x, z)
	var p := Vector2(x, z)
	for q in protegidos:   # regiões e povoados nunca ficam debaixo d'água: há pelo menos 60 m de terra em volta deles
		d = maxf(d, 60.0 - (p.distance_to(q[0]) - float(q[1])))
	return d
