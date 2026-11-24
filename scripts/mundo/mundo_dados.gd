class_name MundoDados
extends RefCounted
## Planta do mundo contínuo (coordenadas do MUNDO, em metros; norte = -Z; o centro do reino fica perto de 0, 0). Cada região é
## uma das áreas já construídas, posta num lugar fixo; entre elas há estradas, rios, florestas, pontes, povoados e fazendas.

## MAPA NOVO (24/11/2026): uma ilha de ~3 x 3 km cercada de mar, com o reino (Valdoria e o Castelo) no centro e as vilas em
## volta. Mundo aberto: não há mais serras nem barreiras de história fechando o caminho. Planta: docs/mapa-novo/PLANTA_v1.md.
## id -> {cena, centro (Vector2), meia (metade do lado da área), nome}
const REGIOES := {
	"refugio_do_pinhal": {"cena": "res://scenes/areas/refugio_do_pinhal.tscn", "centro": Vector2(-225, 1500), "meia": 160.0, "nome": "Refúgio do Pinhal"},
	"pomar_alto": {"cena": "res://scenes/areas/pomar_alto.tscn", "centro": Vector2(-1320, 1050), "meia": 120.0, "nome": "Pomar Alto das Macieiras"},
	"bosque_velado": {"cena": "res://scenes/areas/bosque_velado.tscn", "centro": Vector2(-960, -900), "meia": 160.0, "nome": "Bosque Velado"},
	"acampamento_ruptura": {"cena": "res://scenes/areas/acampamento_ruptura.tscn", "centro": Vector2(600, 1500), "meia": 130.0, "nome": "Acampamento da Ruptura"},
	"fronteira_ferrogris": {"cena": "res://scenes/areas/fronteira_ferrogris.tscn", "centro": Vector2(1650, 30), "meia": 150.0, "nome": "Fortaleza de Ferrogris"},
	"cratera_ignis": {"cena": "res://scenes/areas/cratera_ignis.tscn", "centro": Vector2(1110, -1080), "meia": 150.0, "nome": "Cratera de Ignis"},
	"valdoria": {"cena": "res://scenes/areas/valdoria.tscn", "centro": Vector2(0, 150), "meia": 150.0, "nome": "Valdoria"},
	"castelo_imperial": {"cena": "res://scenes/areas/castelo_imperial.tscn", "centro": Vector2(0, -270), "meia": 150.0, "nome": "Castelo Imperial"},   # 420 m ao norte de Valdoria: o viaduto liga as duas
}

## Limites do chão do mundo (a ilha fica dentro; o resto é mar).
const LIMITES := Rect2(-2550.0, -2550.0, 5100.0, 5100.0)
## Raio médio da ilha (a costa é recortada em volta dele, ver Costa).
const RAIO_DA_ILHA := 2300.0

## Estradas: id, nome, pontos de controle (suavizados). Cada ponta casa com a entrada que a região já tem na borda dela
## (quase todas as regiões se entram pelo lado sul; o Refúgio tem portões a oeste, norte e leste).
const ESTRADAS := [
	{"id": "reino_sul", "nome": "Estrada do Reino", "a": "refugio_do_pinhal", "b": "valdoria", "meia": 24.0,
		"pontos": [Vector2(-225, 1340), Vector2(-180, 1050), Vector2(-60, 780), Vector2(0, 600), Vector2(0, 305)]},
	{"id": "pomar", "nome": "Estrada do Pomar", "a": "refugio_do_pinhal", "b": "pomar_alto", "meia": 22.0,
		"pontos": [Vector2(-385, 1500), Vector2(-675, 1515), Vector2(-975, 1440), Vector2(-1200, 1350), Vector2(-1320, 1175)]},
	{"id": "ruptura", "nome": "Caminho da Ruptura", "a": "refugio_do_pinhal", "b": "acampamento_ruptura", "meia": 20.0,
		"pontos": [Vector2(-65, 1500), Vector2(180, 1575), Vector2(390, 1755), Vector2(600, 1635)]},
	{"id": "campos", "nome": "Estrada dos Campos Altos", "a": "valdoria", "b": "", "meia": 24.0,
		"pontos": [Vector2(0, 305), Vector2(-300, 495), Vector2(-630, 300), Vector2(-1050, 90), Vector2(-1425, -30), Vector2(-1560, -75)]},
	{"id": "bosque", "nome": "Trilha do Bosque", "a": "valdoria", "b": "bosque_velado", "meia": 20.0,
		"pontos": [Vector2(-630, 300), Vector2(-780, 0), Vector2(-900, -375), Vector2(-960, -740)]},
	{"id": "nevoa", "nome": "Trilha da Névoa", "a": "bosque_velado", "b": "", "meia": 20.0,
		"pontos": [Vector2(-960, -1060), Vector2(-1140, -1260), Vector2(-1350, -1320), Vector2(-1440, -1342.5)]},
	{"id": "pedras", "nome": "Estrada da Serra", "a": "valdoria", "b": "", "meia": 20.0,
		"pontos": [Vector2(-630, 300), Vector2(-645, -90), Vector2(-630, -600), Vector2(-450, -1200), Vector2(-270, -1635)]},
	{"id": "ferrogris", "nome": "Estrada de Ferrogris", "a": "valdoria", "b": "fronteira_ferrogris", "meia": 24.0,
		"pontos": [Vector2(0, 305), Vector2(300, 495), Vector2(675, 450), Vector2(1125, 345), Vector2(1500, 315), Vector2(1650, 185)]},
	{"id": "cratera", "nome": "Estrada Queimada", "a": "valdoria", "b": "cratera_ignis", "meia": 20.0,
		"pontos": [Vector2(1125, 345), Vector2(1155, -150), Vector2(1140, -600), Vector2(1110, -925)]},
	{"id": "beira_rio", "nome": "Estrada da Foz", "a": "valdoria", "b": "", "meia": 22.0,
		"pontos": [Vector2(300, 495), Vector2(630, 645), Vector2(930, 900), Vector2(1080, 1200), Vector2(1110, 1425)]},
	{"id": "vau", "nome": "Caminho do Vau", "a": "acampamento_ruptura", "b": "valdoria", "meia": 20.0,
		"pontos": [Vector2(624, 1365), Vector2(660, 1050), Vector2(645, 810), Vector2(630, 645)]},
]

## Rios do mundo (largura do leito, margem, fundo). Cada um começa numa nascente, na borda de uma região (onde o rio de dentro
## dela continua) ou num rio maior, e termina noutro rio, na borda de uma região ou no mar. Nenhum acaba no seco.
const RIOS := [
	{"id": "nevoa_nascente", "nome": "Riacho da Névoa", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-1470, -960), Vector2(-1350, -885), Vector2(-1116, -859.4)]},
	{"id": "cinzento", "nome": "Rio Cinzento", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(-804, -860.6), Vector2(-600, -720), Vector2(-510, -375), Vector2(-465, 0), Vector2(-495, 450), Vector2(-630, 840), Vector2(-840, 1200), Vector2(-960, 1575), Vector2(-1050, 1954.5)]},
	{"id": "moinho_nascente", "nome": "Riacho do Moinho", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-1290, 645), Vector2(-1260, 765), Vector2(-1271, 930)]},
	{"id": "moinho", "nome": "Riacho do Moinho", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-1250, 1168), Vector2(-1140, 1425), Vector2(-1005, 1650)]},
	{"id": "pinhal_oeste", "nome": "Riacho do Pinhal", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-301, 1650), Vector2(-375, 1920), Vector2(-387, 2082)]},
	{"id": "pinhal_leste", "nome": "Riacho do Pinhal", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-147, 1650), Vector2(-75, 1920), Vector2(-70.5, 2058)]},
	{"id": "leste", "nome": "Rio do Leste", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(225, -1725), Vector2(390, -1200), Vector2(495, -600), Vector2(450, 0), Vector2(450, 450), Vector2(420, 900), Vector2(450, 1350), Vector2(444, 1493.5)]},
	{"id": "leste_foz", "nome": "Rio do Leste", "largura": 6.0, "margem": 8.0, "fundo": 1.2,
		"pontos": [Vector2(730, 1493), Vector2(975, 1590), Vector2(1140, 1740), Vector2(1275, 1980)]},
]

## Povoados presos a uma estrada (formato antigo): hoje todos têm centro explícito em POVOADOS_LIVRES.
const POVOADOS := []

## Sem serras nem barreiras: o mundo é aberto. As listas ficam vazias porque o Mundo e o mapa (tecla M) as percorrem.
const CRISTAS := []
const BARREIRAS := []

## Vilas, fazendas e postos da ilha (centro explícito). `liga` é a estrada até onde sai uma trilha de terra.
## As 9 vilas da planta têm tema próprio; os postos e fazendas enchem o caminho entre o reino e elas.
const POVOADOS_LIVRES := [
	{"id": "campos_altos", "nome": "Vila Campos Altos", "tipo": "vila", "centro": Vector2(-1620, -90), "dir": Vector2(1, 0), "lado": 1.0, "raio": 80.0, "liga": "campos"},       # só plantação
	{"id": "nevoa_azul", "nome": "Aldeia Névoa Azul", "tipo": "vila", "centro": Vector2(-1500, -1350), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "nevoa"},          # atrás do Bosque Velado
	{"id": "pedras_altas", "nome": "Vila Pedras Altas", "tipo": "vila", "centro": Vector2(-180, -1725), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},       # mineiros, na serra
	{"id": "beira_rio", "nome": "Aldeia Beira-Rio", "tipo": "vila", "centro": Vector2(1140, 1515), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},          # pescadores, na foz
	{"id": "pescador", "nome": "Cabana do Pescador", "tipo": "pescador", "centro": Vector2(1290, 1590), "dir": Vector2(1, 0), "lado": -1.0, "raio": 22.0, "liga": "beira_rio"},
	{"id": "posto_de_caca", "nome": "Posto de Caça", "tipo": "posto", "centro": Vector2(-780, 495), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "lenhador", "nome": "Cabana do Lenhador", "tipo": "cabana", "centro": Vector2(210, 960), "dir": Vector2(1, 0), "lado": -1.0, "raio": 45.0, "liga": "reino_sul"},
	{"id": "campina", "nome": "Fazenda Campina", "tipo": "fazenda", "centro": Vector2(-840, -375), "dir": Vector2(1, 0), "lado": 1.0, "raio": 60.0, "liga": "bosque"},
	{"id": "rio_claro", "nome": "Fazenda Rio Claro", "tipo": "fazenda", "centro": Vector2(840, 570), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "beira_rio"},
	{"id": "posto_imperial", "nome": "Posto da Estrada Imperial", "tipo": "posto_imperial", "centro": Vector2(960, -300), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "cratera"},
	{"id": "fazenda_imperial", "nome": "Fazenda Imperial", "tipo": "fazenda", "centro": Vector2(-210, 840), "dir": Vector2(1, 0), "lado": -1.0, "raio": 60.0, "liga": "reino_sul"},
	{"id": "posto_rebelde", "nome": "Posto Rebelde", "tipo": "posto", "centro": Vector2(675, 1110), "dir": Vector2(0, -1), "lado": -1.0, "raio": 45.0, "liga": "vau"},
	{"id": "mineiros", "nome": "Acampamento dos Mineiros", "tipo": "posto", "centro": Vector2(90, -1470), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pedras"},
	{"id": "brumosa", "nome": "Fazenda Brumosa", "tipo": "fazenda", "centro": Vector2(-1350, 450), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "pinhal_escuro", "nome": "Vila Pinhal Escuro", "tipo": "vila", "centro": Vector2(-780, 1725), "dir": Vector2(1, 0), "lado": -1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "vale_oculto", "nome": "Fazenda do Vale Oculto", "tipo": "fazenda", "centro": Vector2(720, -1020), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "cabana_bruxa", "nome": "Cabana da Velha do Pinhal", "tipo": "cabana", "centro": Vector2(-1770, -720), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "ruptura_velha", "nome": "Aldeia Ruptura Velha", "tipo": "vila", "centro": Vector2(1560, 900), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "ferrogris"},
	{"id": "vigia", "nome": "Posto de Vigia Imperial", "tipo": "posto_imperial", "centro": Vector2(1320, -375), "dir": Vector2(0, -1), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "ocre", "nome": "Vila Ocre", "tipo": "vila", "centro": Vector2(495, -1350), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "cinzas", "nome": "Fazenda das Cinzas", "tipo": "fazenda", "centro": Vector2(1560, -630), "dir": Vector2(0, -1), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	# --- povoados novos da ilha grande (NOMES PROVISÓRIOS, propostos e ainda não aprovados pelo Cristian) ---
	{"id": "feira_sul", "nome": "Feira do Portão Sul", "tipo": "posto_imperial", "centro": Vector2(130, 470), "dir": Vector2(0, 1), "lado": 1.0, "raio": 50.0, "liga": "reino_sul"},        # mercadores em volta do reino
	{"id": "feira_poente", "nome": "Feira do Poente", "tipo": "posto_imperial", "centro": Vector2(-270, 360), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "campos"},
	{"id": "feira_nascente", "nome": "Feira do Nascente", "tipo": "posto_imperial", "centro": Vector2(280, 370), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "ferrogris"},
	{"id": "fazenda_castelo", "nome": "Fazenda do Castelo", "tipo": "fazenda", "centro": Vector2(-300, -80), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "fazenda_colinas", "nome": "Fazenda das Colinas", "tipo": "fazenda", "centro": Vector2(260, -120), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ferrogris"},
	{"id": "costa_brava", "nome": "Vila Costa Brava", "tipo": "vila", "centro": Vector2(-1900, 300), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "ponta_do_vento", "nome": "Vila Ponta do Vento", "tipo": "vila", "centro": Vector2(-1950, -380), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "trigal", "nome": "Fazenda Trigal", "tipo": "fazenda", "centro": Vector2(-1250, -450), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "tres_carvalhos", "nome": "Fazenda Três Carvalhos", "tipo": "fazenda", "centro": Vector2(-1050, 350), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "cabana_nevoeiro", "nome": "Cabana do Nevoeiro", "tipo": "cabana", "centro": Vector2(-1300, -1120), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "nevoa"},
	{"id": "pedra_fria", "nome": "Vila Pedra Fria", "tipo": "vila", "centro": Vector2(-900, -1700), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "posto_da_serra", "nome": "Posto da Serra", "tipo": "posto", "centro": Vector2(-640, -1280), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pedras"},
	{"id": "farol_do_norte", "nome": "Vila Farol do Norte", "tipo": "vila", "centro": Vector2(520, -1900), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "pescador_norte", "nome": "Cabana do Pescador do Norte", "tipo": "pescador", "centro": Vector2(0, -2060), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "pedras"},
	{"id": "cinza_fertil", "nome": "Fazenda Cinza Fértil", "tipo": "fazenda", "centro": Vector2(800, -1700), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "brasa_velha", "nome": "Vila Brasa Velha", "tipo": "vila", "centro": Vector2(1600, -1250), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "cratera"},
	{"id": "estalagem_leste", "nome": "Estalagem do Leste", "tipo": "posto_imperial", "centro": Vector2(1950, -300), "dir": Vector2(0, 1), "lado": 1.0, "raio": 50.0, "liga": "ferrogris"},
	{"id": "porto_do_leste", "nome": "Vila Porto do Leste", "tipo": "vila", "centro": Vector2(1850, 500), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "ferrogris"},
	{"id": "ferradura", "nome": "Fazenda Ferradura", "tipo": "fazenda", "centro": Vector2(1250, 560), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ferrogris"},
	{"id": "enseada", "nome": "Vila Enseada", "tipo": "vila", "centro": Vector2(1500, 1350), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},
	{"id": "fazenda_do_sul", "nome": "Fazenda do Sul", "tipo": "fazenda", "centro": Vector2(150, 1900), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ruptura"},
	{"id": "cabana_carvoeiro", "nome": "Cabana do Carvoeiro", "tipo": "cabana", "centro": Vector2(150, 1250), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "ruptura"},
	{"id": "fazenda_do_pinhal", "nome": "Fazenda do Pinhal", "tipo": "fazenda", "centro": Vector2(-380, 1150), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "reino_sul"},
	{"id": "cabana_poente", "nome": "Cabana do Poente", "tipo": "cabana", "centro": Vector2(-1400, 1450), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pomar"},
	{"id": "mare_baixa", "nome": "Vila Maré Baixa", "tipo": "vila", "centro": Vector2(-1750, 750), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pomar"},
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
