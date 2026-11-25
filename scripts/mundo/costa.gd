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
	# Ilha oval (mais larga de leste a oeste): a costa fica a um raio do centro que muda com o ângulo (baías e pontas) e com
	# um ruído fino (recortes). `n` é a distância ao centro medida em "raios da ilha" (1 = na costa lisa).
	var eixos := MundoDados.EIXOS_DA_ILHA
	var rel := Vector2(x / eixos.x, z / eixos.y)
	var n := rel.length()
	var ang := atan2(rel.y, rel.x)
	var borda := 1.0 + 0.045 * sin(ang * 3.0 + 0.6) + 0.03 * sin(ang * 5.0 + 2.1) + 0.017 * sin(ang * 9.0 + 4.0)
	var raio_aqui := 1.0 / Vector2(cos(ang) / eixos.x, sin(ang) / eixos.y).length()   # quantos metros vale um "raio" nesta direção
	var d := (borda - n) * raio_aqui + 30.0 * _ruido.get_noise_2d(x, z)
	if d > 600.0 or d < -500.0:   # bem no interior ou bem no mar: nenhum lugar protegido muda a resposta
		return d
	var p := Vector2(x, z)
	for q in protegidos:   # regiões e povoados nunca ficam debaixo d'água: há pelo menos 60 m de terra em volta deles
		d = maxf(d, 60.0 - (p.distance_to(q[0]) - float(q[1])))
	return d
