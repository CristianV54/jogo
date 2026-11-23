class_name Biomas
extends RefCounted
## Biomas do mundo: cada trecho tem a sua mata, as suas pedras e a cor do chão. Decide a mistura de árvores
## (pinheiro, folhosa, morta, arbusto), a densidade da mata, quantas pedras soltas e cogumelos há, e se o chão é seco.
##   pinhal    sul e Refúgio: pinheiros densos, grama verde escura
##   bosque    oeste e norte: mata úmida, pinheiros e folhosas, cogumelos
##   ruptura   leste: campos e matas ralas
##   ferrogris frio e militar: árvores mortas, pedra
##   cratera   cinza e basalto: árvores queimadas, quase sem mata
##   imperio   campos cuidados em volta do castelo: folhosas isoladas
##   costa     faixa de praia: arbustos baixos e rochas

const TIPOS := ["pinheiro", "folhosa", "morta", "arbusto"]

const MISTURA := {
	"pinhal": [0.86, 0.10, 0.0, 0.04],
	"bosque": [0.62, 0.26, 0.04, 0.08],
	"ruptura": [0.40, 0.40, 0.0, 0.20],
	"ferrogris": [0.22, 0.0, 0.62, 0.16],
	"cratera": [0.0, 0.0, 0.88, 0.12],
	"imperio": [0.0, 0.82, 0.0, 0.18],
	"costa": [0.0, 0.05, 0.0, 0.95],
}
const DENSIDADE := {"pinhal": 1.0, "bosque": 1.0, "ruptura": 0.6, "ferrogris": 0.4, "cratera": 0.22, "imperio": 0.35, "costa": 0.3}
const PEDRAS := {"pinhal": 0.03, "bosque": 0.05, "ruptura": 0.05, "ferrogris": 0.18, "cratera": 0.25, "imperio": 0.04, "costa": 0.1}   # chance de uma pedra solta por célula de 7,5 m
const COGUMELOS := {"bosque": 0.07, "pinhal": 0.012}   # chance de um grupo de cogumelos por célula
const TOM_PEDRA := {"pinhal": Color(1, 1, 1), "bosque": Color(0.85, 0.95, 0.85), "ruptura": Color(1, 0.97, 0.9), "ferrogris": Color(0.7, 0.72, 0.8), "cratera": Color(0.42, 0.38, 0.38), "imperio": Color(1.0, 0.97, 0.92), "costa": Color(1.1, 1.05, 0.95)}


static func em(x: float, z: float) -> String:
	if Costa.distancia(x, z) < 45.0:
		return "costa"
	if x < 330.0:
		return "bosque" if z < -380.0 else "pinhal"
	if z > -640.0:
		return "ruptura"
	if z > -1100.0:
		return "ferrogris"
	if z > -1700.0:
		return "cratera"
	return "imperio"


## Escolhe um tipo de árvore de acordo com a mistura do bioma.
static func tipo(bioma: String, r: float) -> int:
	var m: Array = MISTURA[bioma]
	var acum := 0.0
	for i in m.size():
		acum += float(m[i])
		if r <= acum:
			return i
	return 0


## Cor do chão no ponto: o oeste fica verde e úmido ao norte; o leste e o norte do centro esfriam e queimam; o entorno do
## castelo é gramado (a transição leste/oeste é suave, em faixa de 150 m).
static func cor_do_chao(x: float, z: float, ruido: float) -> Color:
	var capim := Color(0.3, 0.42, 0.2)
	var umido := Color(0.2, 0.34, 0.17)
	var seco := Color(0.38, 0.36, 0.28)
	var cinza := Color(0.3, 0.29, 0.28)
	var vulcao := Color(0.27, 0.18, 0.16)
	var verde_cuidado := Color(0.3, 0.45, 0.22)
	var oeste := capim.lerp(umido, smoothstep(-300.0, -520.0, z))
	var leste := capim.lerp(seco, smoothstep(-500.0, -800.0, z))
	leste = leste.lerp(cinza, smoothstep(-800.0, -1000.0, z))
	leste = leste.lerp(vulcao, smoothstep(-1050.0, -1250.0, z))
	leste = leste.lerp(Color(0.44, 0.38, 0.27), smoothstep(-1550.0, -1750.0, z))
	leste = leste.lerp(verde_cuidado, smoothstep(-1950.0, -2100.0, z))
	var c := oeste.lerp(leste, smoothstep(250.0, 400.0, x))
	return c * (0.9 + 0.2 * ruido)
