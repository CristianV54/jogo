class_name MundoDados
extends RefCounted
## Planta do mundo contínuo (coordenadas do MUNDO, em metros; norte = -Z; o centro do reino fica perto de 0, 0). Cada região é
## uma das áreas já construídas, posta num lugar fixo; entre elas há estradas, rios, florestas, pontes, povoados e fazendas.

## MAPA NOVO (24/11/2026): uma ilha de ~3 x 3 km cercada de mar, com o reino (Valdoria e o Castelo) no centro e as vilas em
## volta. Mundo aberto: não há mais serras nem barreiras de história fechando o caminho. Planta: docs/mapa-novo/PLANTA_v1.md.
## id -> {cena, centro (Vector2), meia (metade do lado da área), nome}
const REGIOES := {
	"refugio_do_pinhal": {"cena": "res://scenes/areas/refugio_do_pinhal.tscn", "centro": Vector2(-150, 1000), "meia": 160.0, "nome": "Refúgio do Pinhal"},
	"pomar_alto": {"cena": "res://scenes/areas/pomar_alto.tscn", "centro": Vector2(-880, 700), "meia": 120.0, "nome": "Pomar Alto das Macieiras"},
	"bosque_velado": {"cena": "res://scenes/areas/bosque_velado.tscn", "centro": Vector2(-640, -600), "meia": 160.0, "nome": "Bosque Velado"},
	"acampamento_ruptura": {"cena": "res://scenes/areas/acampamento_ruptura.tscn", "centro": Vector2(400, 1000), "meia": 130.0, "nome": "Acampamento da Ruptura"},
	"fronteira_ferrogris": {"cena": "res://scenes/areas/fronteira_ferrogris.tscn", "centro": Vector2(1100, 20), "meia": 150.0, "nome": "Fortaleza de Ferrogris"},
	"cratera_ignis": {"cena": "res://scenes/areas/cratera_ignis.tscn", "centro": Vector2(740, -720), "meia": 150.0, "nome": "Cratera de Ignis"},
	"valdoria": {"cena": "res://scenes/areas/valdoria.tscn", "centro": Vector2(0, 150), "meia": 150.0, "nome": "Valdoria"},
	"castelo_imperial": {"cena": "res://scenes/areas/castelo_imperial.tscn", "centro": Vector2(0, -270), "meia": 150.0, "nome": "Castelo Imperial"},   # 420 m ao norte de Valdoria: o viaduto liga as duas
}

## Limites do chão do mundo (a ilha fica dentro; o resto é mar).
const LIMITES := Rect2(-1650.0, -1650.0, 3300.0, 3300.0)
## Raio médio da ilha (a costa é recortada em volta dele, ver Costa).
const RAIO_DA_ILHA := 1450.0

## Estradas: id, nome, pontos de controle (suavizados). Cada ponta casa com a entrada que a região já tem na borda dela
## (quase todas as regiões se entram pelo lado sul; o Refúgio tem portões a oeste, norte e leste).
const ESTRADAS := [
	{"id": "reino_sul", "nome": "Estrada do Reino", "a": "refugio_do_pinhal", "b": "valdoria", "meia": 24.0,
		"pontos": [Vector2(-150, 840), Vector2(-120, 700), Vector2(-40, 520), Vector2(0, 400), Vector2(0, 305)]},
	{"id": "pomar", "nome": "Estrada do Pomar", "a": "refugio_do_pinhal", "b": "pomar_alto", "meia": 22.0,
		"pontos": [Vector2(-310, 1000), Vector2(-450, 1010), Vector2(-650, 960), Vector2(-800, 900), Vector2(-880, 825)]},
	{"id": "ruptura", "nome": "Caminho da Ruptura", "a": "refugio_do_pinhal", "b": "acampamento_ruptura", "meia": 20.0,
		"pontos": [Vector2(10, 1000), Vector2(120, 1050), Vector2(260, 1170), Vector2(400, 1135)]},
	{"id": "campos", "nome": "Estrada dos Campos Altos", "a": "valdoria", "b": "", "meia": 24.0,
		"pontos": [Vector2(0, 305), Vector2(-200, 330), Vector2(-420, 200), Vector2(-700, 60), Vector2(-950, -20), Vector2(-1040, -50)]},
	{"id": "bosque", "nome": "Trilha do Bosque", "a": "valdoria", "b": "bosque_velado", "meia": 20.0,
		"pontos": [Vector2(-420, 200), Vector2(-520, 0), Vector2(-600, -250), Vector2(-640, -440)]},
	{"id": "nevoa", "nome": "Trilha da Névoa", "a": "bosque_velado", "b": "", "meia": 20.0,
		"pontos": [Vector2(-640, -760), Vector2(-760, -840), Vector2(-900, -880), Vector2(-960, -895)]},
	{"id": "pedras", "nome": "Estrada da Serra", "a": "valdoria", "b": "", "meia": 20.0,
		"pontos": [Vector2(-420, 200), Vector2(-430, -60), Vector2(-420, -400), Vector2(-300, -800), Vector2(-180, -1090)]},
	{"id": "ferrogris", "nome": "Estrada de Ferrogris", "a": "valdoria", "b": "fronteira_ferrogris", "meia": 24.0,
		"pontos": [Vector2(0, 305), Vector2(200, 330), Vector2(450, 300), Vector2(750, 230), Vector2(1000, 210), Vector2(1100, 175)]},
	{"id": "cratera", "nome": "Estrada Queimada", "a": "valdoria", "b": "cratera_ignis", "meia": 20.0,
		"pontos": [Vector2(750, 230), Vector2(770, -100), Vector2(760, -400), Vector2(740, -565)]},
	{"id": "beira_rio", "nome": "Estrada da Foz", "a": "valdoria", "b": "", "meia": 22.0,
		"pontos": [Vector2(200, 330), Vector2(420, 430), Vector2(620, 600), Vector2(720, 800), Vector2(740, 950)]},
	{"id": "vau", "nome": "Caminho do Vau", "a": "acampamento_ruptura", "b": "valdoria", "meia": 20.0,
		"pontos": [Vector2(424, 865), Vector2(440, 700), Vector2(430, 540), Vector2(420, 430)]},
]

## Rios do mundo (largura do leito, margem, fundo). Cada um começa numa nascente, na borda de uma região (onde o rio de dentro
## dela continua) ou num rio maior, e termina noutro rio, na borda de uma região ou no mar. Nenhum acaba no seco.
const RIOS := [
	{"id": "nevoa_nascente", "nome": "Riacho da Névoa", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-980, -640), Vector2(-900, -590), Vector2(-796, -559.4)]},
	{"id": "cinzento", "nome": "Rio Cinzento", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(-484, -560.6), Vector2(-400, -480), Vector2(-340, -250), Vector2(-310, 0), Vector2(-330, 300), Vector2(-420, 560), Vector2(-560, 800), Vector2(-640, 1050), Vector2(-700, 1303)]},
	{"id": "moinho_nascente", "nome": "Riacho do Moinho", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-860, 430), Vector2(-840, 510), Vector2(-831, 580)]},
	{"id": "moinho", "nome": "Riacho do Moinho", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-810, 818), Vector2(-760, 950), Vector2(-670, 1100)]},
	{"id": "pinhal_oeste", "nome": "Riacho do Pinhal", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-226, 1150), Vector2(-250, 1280), Vector2(-258, 1388)]},
	{"id": "pinhal_leste", "nome": "Riacho do Pinhal", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-72, 1150), Vector2(-50, 1280), Vector2(-47, 1372)]},
	{"id": "leste", "nome": "Rio do Leste", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(150, -1150), Vector2(260, -800), Vector2(330, -400), Vector2(300, 0), Vector2(300, 300), Vector2(280, 600), Vector2(250, 850), Vector2(244, 993.5)]},
	{"id": "leste_foz", "nome": "Rio do Leste", "largura": 6.0, "margem": 8.0, "fundo": 1.2,
		"pontos": [Vector2(530, 993), Vector2(650, 1060), Vector2(760, 1160), Vector2(850, 1320)]},
]

## Povoados presos a uma estrada (formato antigo): hoje todos têm centro explícito em POVOADOS_LIVRES.
const POVOADOS := []

## Sem serras nem barreiras: o mundo é aberto. As listas ficam vazias porque o Mundo e o mapa (tecla M) as percorrem.
const CRISTAS := []
const BARREIRAS := []

## Vilas, fazendas e postos da ilha (centro explícito). `liga` é a estrada até onde sai uma trilha de terra.
## As 9 vilas da planta têm tema próprio; os postos e fazendas enchem o caminho entre o reino e elas.
const POVOADOS_LIVRES := [
	{"id": "campos_altos", "nome": "Vila Campos Altos", "tipo": "vila", "centro": Vector2(-1080, -60), "dir": Vector2(1, 0), "lado": 1.0, "raio": 80.0, "liga": "campos"},       # só plantação
	{"id": "nevoa_azul", "nome": "Aldeia Névoa Azul", "tipo": "vila", "centro": Vector2(-1000, -900), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "nevoa"},          # atrás do Bosque Velado
	{"id": "pedras_altas", "nome": "Vila Pedras Altas", "tipo": "vila", "centro": Vector2(-120, -1150), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},       # mineiros, na serra
	{"id": "beira_rio", "nome": "Aldeia Beira-Rio", "tipo": "vila", "centro": Vector2(760, 1010), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},          # pescadores, na foz
	{"id": "pescador", "nome": "Cabana do Pescador", "tipo": "pescador", "centro": Vector2(860, 1060), "dir": Vector2(1, 0), "lado": -1.0, "raio": 22.0, "liga": "beira_rio"},
	{"id": "posto_de_caca", "nome": "Posto de Caça", "tipo": "posto", "centro": Vector2(-520, 330), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "lenhador", "nome": "Cabana do Lenhador", "tipo": "cabana", "centro": Vector2(140, 640), "dir": Vector2(1, 0), "lado": -1.0, "raio": 45.0, "liga": "reino_sul"},
	{"id": "campina", "nome": "Fazenda Campina", "tipo": "fazenda", "centro": Vector2(-560, -250), "dir": Vector2(1, 0), "lado": 1.0, "raio": 60.0, "liga": "bosque"},
	{"id": "rio_claro", "nome": "Fazenda Rio Claro", "tipo": "fazenda", "centro": Vector2(560, 380), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "beira_rio"},
	{"id": "posto_imperial", "nome": "Posto da Estrada Imperial", "tipo": "posto_imperial", "centro": Vector2(640, -200), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "cratera"},
	{"id": "fazenda_imperial", "nome": "Fazenda Imperial", "tipo": "fazenda", "centro": Vector2(-140, 560), "dir": Vector2(1, 0), "lado": -1.0, "raio": 60.0, "liga": "reino_sul"},
	{"id": "posto_rebelde", "nome": "Posto Rebelde", "tipo": "posto", "centro": Vector2(450, 740), "dir": Vector2(0, -1), "lado": -1.0, "raio": 45.0, "liga": "vau"},
	{"id": "mineiros", "nome": "Acampamento dos Mineiros", "tipo": "posto", "centro": Vector2(60, -980), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pedras"},
	{"id": "brumosa", "nome": "Fazenda Brumosa", "tipo": "fazenda", "centro": Vector2(-900, 300), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "pinhal_escuro", "nome": "Vila Pinhal Escuro", "tipo": "vila", "centro": Vector2(-520, 1150), "dir": Vector2(1, 0), "lado": -1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "vale_oculto", "nome": "Fazenda do Vale Oculto", "tipo": "fazenda", "centro": Vector2(480, -680), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "cabana_bruxa", "nome": "Cabana da Velha do Pinhal", "tipo": "cabana", "centro": Vector2(-1180, -480), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "ruptura_velha", "nome": "Aldeia Ruptura Velha", "tipo": "vila", "centro": Vector2(1040, 600), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "ferrogris"},
	{"id": "vigia", "nome": "Posto de Vigia Imperial", "tipo": "posto_imperial", "centro": Vector2(880, -250), "dir": Vector2(0, -1), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "ocre", "nome": "Vila Ocre", "tipo": "vila", "centro": Vector2(330, -900), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "cinzas", "nome": "Fazenda das Cinzas", "tipo": "fazenda", "centro": Vector2(1040, -420), "dir": Vector2(0, -1), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
]


static func centro(id: String) -> Vector2:
	return REGIOES[id]["centro"]


static func retangulo(id: String, folga := 0.0) -> Rect2:
	var c: Vector2 = REGIOES[id]["centro"]
	var m: float = REGIOES[id]["meia"] + folga
	return Rect2(c - Vector2(m, m), Vector2(m, m) * 2.0)


static func estrada(id: String) -> Dictionary:
	for e in ESTRADAS:
		if e["id"] == id:
			return e
	return {}
