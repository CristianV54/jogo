class_name MundoDados
extends RefCounted
## Planta do mundo contínuo (coordenadas do MUNDO, em metros; norte = -Z; o centro do reino fica perto de 0, 0). Cada região é
## uma das áreas já construídas, posta num lugar fixo; entre elas há estradas, rios, florestas, pontes, povoados e fazendas.

## MAPA NOVO (24/11/2026): uma ilha de ~3 x 3 km cercada de mar, com o reino (Valdoria e o Castelo) no centro e as vilas em
## volta. Mundo aberto: não há mais serras nem barreiras de história fechando o caminho. Planta: docs/mapa-novo/PLANTA_v1.md.
## id -> {cena, centro (Vector2), meia (metade do lado da área), nome}
const REGIOES := {
	"refugio_do_pinhal": {"cena": "res://scenes/areas/refugio_do_pinhal.tscn", "centro": Vector2(-364.5, 1825.5), "meia": 160.0, "nome": "Refúgio do Pinhal"},
	"pomar_alto": {"cena": "res://scenes/areas/pomar_alto.tscn", "centro": Vector2(-2138.4, 1277.9), "meia": 120.0, "nome": "Pomar Alto das Macieiras"},
	"bosque_velado": {"cena": "res://scenes/areas/bosque_velado.tscn", "centro": Vector2(-1555.2, -1095.3), "meia": 160.0, "nome": "Bosque Velado"},
	"acampamento_ruptura": {"cena": "res://scenes/areas/acampamento_ruptura.tscn", "centro": Vector2(972, 1825.5), "meia": 130.0, "nome": "Acampamento da Ruptura"},
	"fronteira_ferrogris": {"cena": "res://scenes/areas/fronteira_ferrogris.tscn", "centro": Vector2(2673, 36.5), "meia": 150.0, "nome": "Fortaleza de Ferrogris"},
	"cratera_ignis": {"cena": "res://scenes/areas/cratera_ignis.tscn", "centro": Vector2(1798.2, -1314.4), "meia": 150.0, "nome": "Cratera de Ignis"},
	"valdoria": {"cena": "res://scenes/areas/valdoria.tscn", "centro": Vector2(0, 150), "meia": 150.0, "nome": "Valdoria"},
	"castelo_imperial": {"cena": "res://scenes/areas/castelo_imperial.tscn", "centro": Vector2(0, -270), "meia": 150.0, "nome": "Castelo Imperial"},   # 420 m ao norte de Valdoria: o viaduto liga as duas
}

## Limites do chão do mundo (a ilha fica dentro; o resto é mar).
const LIMITES := Rect2(-4000.0, -3050.0, 8000.0, 6100.0)
## Meio-eixos da ilha, que é oval: 7,45 km de leste a oeste e 5,6 km de norte a sul (a medida do mapa de Red Dead
## Redemption 2, pedida pelo Cristian). A costa é recortada em volta desse oval, ver Costa.
const EIXOS_DA_ILHA := Vector2(3725.0, 2800.0)

## Estradas: id, nome, pontos de controle (suavizados). Cada ponta casa com a entrada que a região já tem na borda dela
## (quase todas as regiões se entram pelo lado sul; o Refúgio tem portões a oeste, norte e leste).
const ESTRADAS := [
	{"id": "reino_sul", "nome": "Estrada do Reino", "a": "refugio_do_pinhal", "b": "valdoria", "meia": 24.0,
		"pontos": [Vector2(-364.5, 1665.5), Vector2(-291.6, 1277.9), Vector2(-97.2, 949.3), Vector2(0, 730.2), Vector2(0, 305)]},
	{"id": "pomar", "nome": "Estrada do Pomar", "a": "refugio_do_pinhal", "b": "pomar_alto", "meia": 22.0,
		"pontos": [Vector2(-524.5, 1825.5), Vector2(-1093.5, 1843.8), Vector2(-1579.5, 1752.5), Vector2(-1944, 1643), Vector2(-2138.4, 1402.9)]},
	{"id": "ruptura", "nome": "Caminho da Ruptura", "a": "refugio_do_pinhal", "b": "acampamento_ruptura", "meia": 20.0,
		"pontos": [Vector2(-204.5, 1825.5), Vector2(291.6, 1916.8), Vector2(631.8, 2135.8), Vector2(972, 1960.5)]},
	{"id": "campos", "nome": "Estrada dos Campos Altos", "a": "valdoria", "b": "", "meia": 24.0,
		"pontos": [Vector2(0, 305), Vector2(-486, 602.4), Vector2(-1020.6, 365.1), Vector2(-1701, 109.5), Vector2(-2308.5, -36.5), Vector2(-2527.2, -91.3)]},
	{"id": "bosque", "nome": "Trilha do Bosque", "a": "valdoria", "b": "bosque_velado", "meia": 20.0,
		"pontos": [Vector2(-1020.6, 365.1), Vector2(-1263.6, 0), Vector2(-1458, -456.4), Vector2(-1555.2, -935.3)]},
	{"id": "nevoa", "nome": "Trilha da Névoa", "a": "bosque_velado", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1555.2, -1255.3), Vector2(-1846.8, -1533.4), Vector2(-2187, -1606.4), Vector2(-2332.8, -1633.8)]},
	{"id": "pedras", "nome": "Estrada da Serra", "a": "valdoria", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1020.6, 365.1), Vector2(-1044.9, -109.5), Vector2(-1020.6, -730.2), Vector2(-729, -1460.4), Vector2(-437.4, -1989.8)]},
	{"id": "ferrogris", "nome": "Estrada de Ferrogris", "a": "valdoria", "b": "fronteira_ferrogris", "meia": 24.0,
		"pontos": [Vector2(0, 305), Vector2(486, 602.4), Vector2(1093.5, 547.7), Vector2(1822.5, 419.9), Vector2(2430, 383.4), Vector2(2673, 191.5)]},
	{"id": "cratera", "nome": "Estrada Queimada", "a": "valdoria", "b": "cratera_ignis", "meia": 20.0,
		"pontos": [Vector2(1822.5, 419.9), Vector2(1871.1, -182.6), Vector2(1846.8, -730.2), Vector2(1798.2, -1159.4)]},
	{"id": "beira_rio", "nome": "Estrada da Foz", "a": "valdoria", "b": "", "meia": 22.0,
		"pontos": [Vector2(486, 602.4), Vector2(1020.6, 785), Vector2(1506.6, 1095.3), Vector2(1749.6, 1460.4), Vector2(1798.2, 1734.2)]},
	{"id": "vau", "nome": "Caminho do Vau", "a": "acampamento_ruptura", "b": "valdoria", "meia": 20.0,
		"pontos": [Vector2(996, 1690.5), Vector2(1069.2, 1277.9), Vector2(1044.9, 985.8), Vector2(1020.6, 785)]},
]

## Rios do mundo (largura do leito, margem, fundo). Cada um começa numa nascente, na borda de uma região (onde o rio de dentro
## dela continua) ou num rio maior, e termina noutro rio, na borda de uma região ou no mar. Nenhum acaba no seco.
const RIOS := [
	{"id": "nevoa_nascente", "nome": "Riacho da Névoa", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-2381.4, -1168.3), Vector2(-2187, -1077), Vector2(-1711.2, -1054.7)]},
	{"id": "cinzento", "nome": "Rio Cinzento", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(-1399.2, -1055.9), Vector2(-972, -876.2), Vector2(-826.2, -456.4), Vector2(-753.3, 0), Vector2(-801.9, 547.7), Vector2(-1020.6, 1022.3), Vector2(-1360.8, 1460.4), Vector2(-1555.2, 1916.8), Vector2(-1701, 2378.6)]},
	{"id": "moinho_nascente", "nome": "Riacho do Moinho", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-2089.8, 785), Vector2(-2041.2, 931), Vector2(-2089.4, 1157.9)]},
	{"id": "moinho", "nome": "Riacho do Moinho", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-2068.4, 1395.9), Vector2(-1846.8, 1734.2), Vector2(-1628.1, 2008.1)]},
	{"id": "pinhal_oeste", "nome": "Riacho do Pinhal", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-440.5, 1975.5), Vector2(-607.5, 2336.6), Vector2(-626.9, 2533.8)]},
	{"id": "pinhal_leste", "nome": "Riacho do Pinhal", "largura": 4.6, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-286.5, 1975.5), Vector2(-121.5, 2336.6), Vector2(-114.2, 2504.6)]},
	{"id": "leste", "nome": "Rio do Leste", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(364.5, -2099.3), Vector2(631.8, -1460.4), Vector2(801.9, -730.2), Vector2(729, 0), Vector2(729, 547.7), Vector2(680.4, 1095.3), Vector2(822, 1675.5), Vector2(816, 1819)]},
	{"id": "leste_foz", "nome": "Rio do Leste", "largura": 6.0, "margem": 8.0, "fundo": 1.2,
		"pontos": [Vector2(1102, 1818.5), Vector2(1579.5, 1935), Vector2(1846.8, 2117.6), Vector2(2065.5, 2409.7)]},
]

## Povoados presos a uma estrada (formato antigo): hoje todos têm centro explícito em POVOADOS_LIVRES.
const POVOADOS := []

## Sem serras nem barreiras: o mundo é aberto. As listas ficam vazias porque o Mundo e o mapa (tecla M) as percorrem.
const CRISTAS := []
const BARREIRAS := []

## Vilas, fazendas e postos da ilha (centro explícito). `liga` é a estrada até onde sai uma trilha de terra.
## As 9 vilas da planta têm tema próprio; os postos e fazendas enchem o caminho entre o reino e elas.
const POVOADOS_LIVRES := [
	{"id": "campos_altos", "nome": "Vila Campos Altos", "tipo": "vila", "centro": Vector2(-2624.4, -109.5), "dir": Vector2(1, 0), "lado": 1.0, "raio": 80.0, "liga": "campos"},       # só plantação
	{"id": "nevoa_azul", "nome": "Aldeia Névoa Azul", "tipo": "vila", "centro": Vector2(-2430, -1643), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "nevoa"},          # atrás do Bosque Velado
	{"id": "pedras_altas", "nome": "Vila Pedras Altas", "tipo": "vila", "centro": Vector2(-291.6, -2099.3), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},       # mineiros, na serra
	{"id": "beira_rio", "nome": "Aldeia Beira-Rio", "tipo": "vila", "centro": Vector2(1846.8, 1843.8), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},          # pescadores, na foz
	{"id": "pescador", "nome": "Cabana do Pescador", "tipo": "pescador", "centro": Vector2(2089.8, 1935), "dir": Vector2(1, 0), "lado": -1.0, "raio": 22.0, "liga": "beira_rio"},
	{"id": "posto_de_caca", "nome": "Posto de Caça", "tipo": "posto", "centro": Vector2(-1263.6, 602.4), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "lenhador", "nome": "Cabana do Lenhador", "tipo": "cabana", "centro": Vector2(340.2, 1168.3), "dir": Vector2(1, 0), "lado": -1.0, "raio": 45.0, "liga": "reino_sul"},
	{"id": "campina", "nome": "Fazenda Campina", "tipo": "fazenda", "centro": Vector2(-1360.8, -456.4), "dir": Vector2(1, 0), "lado": 1.0, "raio": 60.0, "liga": "bosque"},
	{"id": "rio_claro", "nome": "Fazenda Rio Claro", "tipo": "fazenda", "centro": Vector2(1360.8, 693.7), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "beira_rio"},
	{"id": "posto_imperial", "nome": "Posto da Estrada Imperial", "tipo": "posto_imperial", "centro": Vector2(1555.2, -365.1), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "cratera"},
	{"id": "fazenda_imperial", "nome": "Fazenda Imperial", "tipo": "fazenda", "centro": Vector2(-340.2, 1022.3), "dir": Vector2(1, 0), "lado": -1.0, "raio": 60.0, "liga": "reino_sul"},
	{"id": "posto_rebelde", "nome": "Posto Rebelde", "tipo": "posto", "centro": Vector2(1093.5, 1350.9), "dir": Vector2(0, -1), "lado": -1.0, "raio": 45.0, "liga": "vau"},
	{"id": "mineiros", "nome": "Acampamento dos Mineiros", "tipo": "posto", "centro": Vector2(145.8, -1789), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pedras"},
	{"id": "brumosa", "nome": "Fazenda Brumosa", "tipo": "fazenda", "centro": Vector2(-2187, 547.7), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "pinhal_escuro", "nome": "Vila Pinhal Escuro", "tipo": "vila", "centro": Vector2(-1263.6, 2099.3), "dir": Vector2(1, 0), "lado": -1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "vale_oculto", "nome": "Fazenda do Vale Oculto", "tipo": "fazenda", "centro": Vector2(1166.4, -1241.3), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "cabana_bruxa", "nome": "Cabana da Velha do Pinhal", "tipo": "cabana", "centro": Vector2(-2867.4, -876.2), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "ruptura_velha", "nome": "Aldeia Ruptura Velha", "tipo": "vila", "centro": Vector2(2527.2, 1095.3), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "ferrogris"},
	{"id": "vigia", "nome": "Posto de Vigia Imperial", "tipo": "posto_imperial", "centro": Vector2(2138.4, -456.4), "dir": Vector2(0, -1), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "ocre", "nome": "Vila Ocre", "tipo": "vila", "centro": Vector2(801.9, -1643), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "cinzas", "nome": "Fazenda das Cinzas", "tipo": "fazenda", "centro": Vector2(2527.2, -766.7), "dir": Vector2(0, -1), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	# --- povoados novos da ilha grande (NOMES PROVISÓRIOS, propostos e ainda não aprovados pelo Cristian) ---
	{"id": "feira_sul", "nome": "Feira do Portão Sul", "tipo": "posto_imperial", "centro": Vector2(210.6, 572), "dir": Vector2(0, 1), "lado": 1.0, "raio": 50.0, "liga": "reino_sul"},        # mercadores em volta do reino
	{"id": "feira_poente", "nome": "Feira do Poente", "tipo": "posto_imperial", "centro": Vector2(-437.4, 438.1), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "campos"},
	{"id": "feira_nascente", "nome": "Feira do Nascente", "tipo": "posto_imperial", "centro": Vector2(453.6, 450.3), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "ferrogris"},
	{"id": "fazenda_castelo", "nome": "Fazenda do Castelo", "tipo": "fazenda", "centro": Vector2(-486, -97.4), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "fazenda_colinas", "nome": "Fazenda das Colinas", "tipo": "fazenda", "centro": Vector2(421.2, -146), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ferrogris"},
	{"id": "costa_brava", "nome": "Vila Costa Brava", "tipo": "vila", "centro": Vector2(-3078, 365.1), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "ponta_do_vento", "nome": "Vila Ponta do Vento", "tipo": "vila", "centro": Vector2(-3159, -462.5), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "trigal", "nome": "Fazenda Trigal", "tipo": "fazenda", "centro": Vector2(-2025, -547.7), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "tres_carvalhos", "nome": "Fazenda Três Carvalhos", "tipo": "fazenda", "centro": Vector2(-1701, 426), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "cabana_nevoeiro", "nome": "Cabana do Nevoeiro", "tipo": "cabana", "centro": Vector2(-2106, -1363), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "nevoa"},
	{"id": "pedra_fria", "nome": "Vila Pedra Fria", "tipo": "vila", "centro": Vector2(-1458, -2068.9), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "posto_da_serra", "nome": "Posto da Serra", "tipo": "posto", "centro": Vector2(-1036.8, -1557.8), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pedras"},
	{"id": "farol_do_norte", "nome": "Vila Farol do Norte", "tipo": "vila", "centro": Vector2(842.4, -2312.3), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "pescador_norte", "nome": "Cabana do Pescador do Norte", "tipo": "pescador", "centro": Vector2(0, -2507), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "pedras"},
	{"id": "cinza_fertil", "nome": "Fazenda Cinza Fértil", "tipo": "fazenda", "centro": Vector2(1296, -2068.9), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "brasa_velha", "nome": "Vila Brasa Velha", "tipo": "vila", "centro": Vector2(2592, -1521.2), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "cratera"},
	{"id": "estalagem_leste", "nome": "Estalagem do Leste", "tipo": "posto_imperial", "centro": Vector2(3159, -365.1), "dir": Vector2(0, 1), "lado": 1.0, "raio": 50.0, "liga": "ferrogris"},
	{"id": "porto_do_leste", "nome": "Vila Porto do Leste", "tipo": "vila", "centro": Vector2(2997, 608.5), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "ferrogris"},
	{"id": "ferradura", "nome": "Fazenda Ferradura", "tipo": "fazenda", "centro": Vector2(2025, 681.5), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ferrogris"},
	{"id": "enseada", "nome": "Vila Enseada", "tipo": "vila", "centro": Vector2(2430, 1643), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},
	{"id": "fazenda_do_sul", "nome": "Fazenda do Sul", "tipo": "fazenda", "centro": Vector2(243, 2312.3), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ruptura"},
	{"id": "cabana_carvoeiro", "nome": "Cabana do Carvoeiro", "tipo": "cabana", "centro": Vector2(243, 1521.2), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "ruptura"},
	{"id": "fazenda_do_pinhal", "nome": "Fazenda do Pinhal", "tipo": "fazenda", "centro": Vector2(-615.6, 1399.6), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "reino_sul"},
	{"id": "cabana_poente", "nome": "Cabana do Poente", "tipo": "cabana", "centro": Vector2(-2268, 1764.7), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pomar"},
	{"id": "mare_baixa", "nome": "Vila Maré Baixa", "tipo": "vila", "centro": Vector2(-2835, 912.8), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pomar"},
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
