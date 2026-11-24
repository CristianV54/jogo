class_name Biomas
extends RefCounted
## Biomas do mundo: cada trecho tem a sua mata, as suas pedras e a cor do chão. Decide a mistura de árvores
## (pinheiro, folhosa, morta, arbusto), a densidade da mata, quantas pedras soltas e cogumelos há, e se o chão é seco.
##   pinhal    sul da ilha (Refúgio, Pomar): pinheiros densos, grama verde escura
##   bosque    noroeste: mata úmida, pinheiros e folhosas, cogumelos
##   ruptura   campos do oeste, do sudeste e do leste: campos e matas ralas
##   ferrogris leste e serra do norte: frio, árvores mortas, pedra
##   cratera   nordeste: cinza e basalto, árvores queimadas, quase sem mata
##   imperio   centro, em volta do reino: campos cuidados, folhosas isoladas
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
const DENSIDADE := {"pinhal": 1.0, "bosque": 1.0, "ruptura": 0.8, "ferrogris": 0.55, "cratera": 0.25, "imperio": 0.5, "costa": 0.3}
const PEDRAS := {"pinhal": 0.03, "bosque": 0.05, "ruptura": 0.05, "ferrogris": 0.18, "cratera": 0.25, "imperio": 0.04, "costa": 0.1}   # chance de uma pedra solta por célula de 7,5 m
const COGUMELOS := {"bosque": 0.07, "pinhal": 0.012}   # chance de um grupo de cogumelos por célula
const TOM_PEDRA := {"pinhal": Color(1, 1, 1), "bosque": Color(0.85, 0.95, 0.85), "ruptura": Color(1, 0.97, 0.9), "ferrogris": Color(0.7, 0.72, 0.8), "cratera": Color(0.42, 0.38, 0.38), "imperio": Color(1.0, 0.97, 0.92), "costa": Color(1.1, 1.05, 0.95)}


## Sementes dos biomas na ilha: [bioma, x, z]. Cada ponto do mundo pertence à semente mais próxima (ver docs/mapa-novo).
const SEMENTES := [
	["imperio", 0, 0], ["imperio", 450, 525], ["imperio", -450, 450],
	["pinhal", -225, 1500], ["pinhal", -900, 1575], ["pinhal", 150, 1125], ["pinhal", -1275, 975],
	["bosque", -960, -900], ["bosque", -1425, -1275], ["bosque", -1500, -525],
	["ruptura", -1500, 0], ["ruptura", -900, 225], ["ruptura", 675, 1425], ["ruptura", 1200, 1200], ["ruptura", 900, 600], ["ruptura", 675, -525],
	["ferrogris", 1650, 30], ["ferrogris", -180, -1650], ["ferrogris", 450, -1575], ["ferrogris", -525, -1350],
	["cratera", 1110, -1080], ["cratera", 1500, -750],
]


static func em(x: float, z: float) -> String:
	if Costa.distancia(x, z) < 45.0:
		return "costa"
	var p := Vector2(x, z)
	var melhor := 1e18
	var nome := "imperio"
	for s in SEMENTES:
		var d := p.distance_squared_to(Vector2(s[1], s[2]))
		if d < melhor:
			melhor = d
			nome = s[0]
	return nome


## Escolhe um tipo de árvore de acordo com a mistura do bioma.
static func tipo(bioma: String, r: float) -> int:
	var m: Array = MISTURA[bioma]
	var acum := 0.0
	for i in m.size():
		acum += float(m[i])
		if r <= acum:
			return i
	return 0


const COR_CHAO := {"imperio": Color(0.3, 0.45, 0.22), "pinhal": Color(0.26, 0.38, 0.19), "bosque": Color(0.2, 0.34, 0.17),
	"ruptura": Color(0.36, 0.42, 0.21), "ferrogris": Color(0.3, 0.29, 0.28), "cratera": Color(0.27, 0.18, 0.16)}


## Cor do chão no ponto: mistura das cores dos biomas vizinhos (quanto mais perto da semente, mais pesa), para a troca ser suave.
static func cor_do_chao(x: float, z: float, ruido: float) -> Color:
	var p := Vector2(x, z)
	var soma := Color(0, 0, 0)
	var total := 0.0
	for s in SEMENTES:
		var w := 1.0 / pow(p.distance_to(Vector2(s[1], s[2])) + 60.0, 4.0)
		soma += (COR_CHAO[s[0]] as Color) * w
		total += w
	return (soma / total) * (0.9 + 0.2 * ruido)
