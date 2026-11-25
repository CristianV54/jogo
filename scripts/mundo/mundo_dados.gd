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

## O REINO: a muralha grande que cerca Valdoria, o Castelo e os bairros (ver MuralhaDoReino). Onde uma estrada cruza o
## círculo abre-se um portão.
const REINO := {"centro": Vector2(0.0, -60.0), "raio": 560.0}

## Estradas: id, nome, pontos de controle (suavizados). Cada ponta casa com a entrada que a região já tem na borda dela
## (quase todas as regiões se entram pelo lado sul; o Refúgio tem portões a oeste, norte e leste).
const ESTRADAS := [
	{"id": "reino_sul", "nome": "Estrada do Reino", "a": "refugio_do_pinhal", "b": "valdoria", "meia": 24.0,
		"pontos": [Vector2(-364.5, 1665.5), Vector2(-291.6, 1277.9), Vector2(-97.2, 949.3), Vector2(0, 730.2), Vector2(0, 305)]},
	{"id": "anel_do_reino", "nome": "Rua do Anel", "a": "valdoria", "b": "valdoria", "meia": 20.0,   # dá a volta em Valdoria e no Castelo, por dentro da muralha
		"pontos": [Vector2(0, 350), Vector2(-71, 344), Vector2(-140, 325), Vector2(-205, 295), Vector2(-264, 254), Vector2(-314, 204), Vector2(-355, 145), Vector2(-385, 80), Vector2(-404, 11), Vector2(-410, -60), Vector2(-404, -131), Vector2(-385, -200), Vector2(-355, -265), Vector2(-314, -324), Vector2(-264, -374), Vector2(-205, -415), Vector2(-140, -445), Vector2(-71, -464), Vector2(0, -470), Vector2(71, -464), Vector2(140, -445), Vector2(205, -415), Vector2(264, -374), Vector2(314, -324), Vector2(355, -265), Vector2(385, -200), Vector2(404, -131), Vector2(410, -60), Vector2(404, 11), Vector2(385, 80), Vector2(355, 145), Vector2(314, 204), Vector2(264, 254), Vector2(205, 295), Vector2(140, 325), Vector2(71, 344), Vector2(0, 350)]},
	{"id": "rua_do_meio_oeste", "nome": "Rua do Meio", "a": "valdoria", "b": "valdoria", "meia": 20.0,   # corta o reino de oeste a leste, entre a cidade velha e o Castelo
		"pontos": [Vector2(-410, -60), Vector2(-300, -58), Vector2(-175, -60)]},
	{"id": "rua_do_meio_leste", "nome": "Rua do Meio", "a": "valdoria", "b": "valdoria", "meia": 20.0,
		"pontos": [Vector2(175, -60), Vector2(300, -58), Vector2(410, -60)]},
	{"id": "pomar", "nome": "Estrada do Pomar", "a": "refugio_do_pinhal", "b": "pomar_alto", "meia": 22.0,
		"pontos": [Vector2(-524.5, 1825.5), Vector2(-1093.5, 1843.8), Vector2(-1579.5, 1752.5), Vector2(-1944, 1643), Vector2(-2138.4, 1402.9)]},
	{"id": "ruptura", "nome": "Caminho da Ruptura", "a": "refugio_do_pinhal", "b": "acampamento_ruptura", "meia": 20.0,
		"pontos": [Vector2(-204.5, 1825.5), Vector2(291.6, 1916.8), Vector2(631.8, 2135.8), Vector2(972, 1960.5)]},
	{"id": "campos", "nome": "Estrada dos Campos Altos", "a": "valdoria", "b": "", "meia": 24.0,
		"pontos": [Vector2(-410, -60), Vector2(-560, -60), Vector2(-800, 200), Vector2(-1020.6, 365.1), Vector2(-1701, 109.5), Vector2(-2308.5, -36.5), Vector2(-2527.2, -91.3)]},
	{"id": "bosque", "nome": "Trilha do Bosque", "a": "valdoria", "b": "bosque_velado", "meia": 20.0,
		"pontos": [Vector2(-1020.6, 365.1), Vector2(-1263.6, 0), Vector2(-1458, -456.4), Vector2(-1555.2, -935.3)]},
	{"id": "nevoa", "nome": "Trilha da Névoa", "a": "bosque_velado", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1555.2, -1255.3), Vector2(-1846.8, -1533.4), Vector2(-2187, -1606.4), Vector2(-2332.8, -1633.8)]},
	{"id": "pedras", "nome": "Estrada da Serra", "a": "valdoria", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1020.6, 365.1), Vector2(-1044.9, -109.5), Vector2(-1020.6, -730.2), Vector2(-729, -1460.4), Vector2(-437.4, -1989.8)]},
	{"id": "ferrogris", "nome": "Estrada de Ferrogris", "a": "valdoria", "b": "fronteira_ferrogris", "meia": 24.0,
		"pontos": [Vector2(410, -60), Vector2(560, -60), Vector2(820, 300), Vector2(1093.5, 547.7), Vector2(1822.5, 419.9), Vector2(2430, 383.4), Vector2(2673, 191.5)]},
	{"id": "cratera", "nome": "Estrada Queimada", "a": "valdoria", "b": "cratera_ignis", "meia": 20.0,
		"pontos": [Vector2(1822.5, 419.9), Vector2(1871.1, -182.6), Vector2(1846.8, -730.2), Vector2(1798.2, -1159.4)]},
	{"id": "beira_rio", "nome": "Estrada da Foz", "a": "valdoria", "b": "", "meia": 22.0,
		"pontos": [Vector2(0, 620), Vector2(486, 602.4), Vector2(1020.6, 785), Vector2(1506.6, 1095.3), Vector2(1749.6, 1460.4), Vector2(1798.2, 1734.2)]},
	{"id": "vau", "nome": "Caminho do Vau", "a": "acampamento_ruptura", "b": "valdoria", "meia": 20.0,
		"pontos": [Vector2(996, 1690.5), Vector2(1069.2, 1277.9), Vector2(1044.9, 985.8), Vector2(1020.6, 785)]},
	# >>> GERADO por tools/mundo/encher_o_mundo.py: a Estrada da Costa, em trechos de vila a vila
	{"id": "costa_01", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2681, -147), Vector2(-2868, -286), Vector2(-3109, -430)]},
	{"id": "costa_02", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-3114, -502), Vector2(-2835, -700), Vector2(-2615, -943)]},
	{"id": "costa_03", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2558, -1041), Vector2(-2459, -1315), Vector2(-2442, -1585)]},
	{"id": "costa_04", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2376, -1667), Vector2(-1963, -1855), Vector2(-1512, -2045)]},
	{"id": "costa_05", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1399, -2070), Vector2(-876, -2049), Vector2(-351, -2098)]},
	{"id": "costa_06", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-233, -2110), Vector2(297, -2046), Vector2(784, -2301)]},
	{"id": "costa_07", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(839, -2253), Vector2(838, -1975), Vector2(805, -1702)]},
	{"id": "costa_08", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(856, -1669), Vector2(1202, -1874), Vector2(1589, -2019)]},
	{"id": "costa_09", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(3257, -779), Vector2(3274, -437), Vector2(3344, -104)]},
	{"id": "costa_10", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(3324, 7), Vector2(3071, 213), Vector2(3025, 556)]},
	{"id": "costa_11", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(2956, 651), Vector2(2772, 845), Vector2(2569, 1052)]},
	{"id": "costa_12", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(2517, 1154), Vector2(2473, 1371), Vector2(2440, 1584)]},
	{"id": "costa_13", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(2374, 1662), Vector2(2137, 1718), Vector2(1903, 1824)]},
	{"id": "costa_14", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1322, 2088), Vector2(-2081, 1972), Vector2(-2842, 1785)]},
	{"id": "costa_15", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2896, 1715), Vector2(-2677, 1359), Vector2(-2839, 972)]},
	{"id": "costa_16", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2859, 858), Vector2(-2976, 636), Vector2(-3054, 419)]},
	{"id": "costa_17", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-3037, 322), Vector2(-2828, 106), Vector2(-2671, -60)]},
	# <<< GERADO
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
	# --- o reino: bairros e mercados dentro da muralha, feiras do lado de fora de cada portão (NOMES PROVISÓRIOS, a aprovar) ---
	{"id": "bairro_do_nascente", "nome": "Bairro do Nascente", "tipo": "bairro", "centro": Vector2(445, 124), "dir": Vector2(-0.383, 0.924), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_dos_teceloes", "nome": "Bairro dos Tecelões", "tipo": "bairro", "centro": Vector2(341, 281), "dir": Vector2(-0.707, 0.707), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_dos_oleiros", "nome": "Bairro dos Oleiros", "tipo": "bairro", "centro": Vector2(184, 385), "dir": Vector2(-0.924, 0.383), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "estabulos_do_reino", "nome": "Estábulos do Reino", "tipo": "estabulo", "centro": Vector2(-184, 385), "dir": Vector2(-0.924, -0.383), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_do_moinho", "nome": "Bairro do Moinho", "tipo": "bairro", "centro": Vector2(-341, 281), "dir": Vector2(-0.707, -0.707), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_do_poente", "nome": "Bairro do Poente", "tipo": "bairro", "centro": Vector2(-445, 124), "dir": Vector2(-0.383, -0.924), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_da_muralha", "nome": "Bairro da Muralha", "tipo": "bairro", "centro": Vector2(-445, -244), "dir": Vector2(0.383, -0.924), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_dos_ferreiros", "nome": "Bairro dos Ferreiros", "tipo": "bairro", "centro": Vector2(-341, -401), "dir": Vector2(0.707, -0.707), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_da_torre", "nome": "Bairro da Torre", "tipo": "bairro", "centro": Vector2(-184, -505), "dir": Vector2(0.924, -0.383), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_alto", "nome": "Bairro Alto", "tipo": "bairro", "centro": Vector2(0, -542), "dir": Vector2(1.000, -0.000), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_do_sino", "nome": "Bairro do Sino", "tipo": "bairro", "centro": Vector2(184, -505), "dir": Vector2(0.924, 0.383), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_das_flores", "nome": "Bairro das Flores", "tipo": "bairro", "centro": Vector2(341, -401), "dir": Vector2(0.707, 0.707), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_da_fonte", "nome": "Bairro da Fonte", "tipo": "bairro", "centro": Vector2(445, -244), "dir": Vector2(0.383, 0.924), "lado": -1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_do_mercado_velho", "nome": "Bairro do Mercado Velho", "tipo": "bairro", "centro": Vector2(286, 105), "dir": Vector2(-0.500, 0.866), "lado": 1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_da_ponte_velha", "nome": "Bairro da Ponte Velha", "tipo": "bairro", "centro": Vector2(-286, 105), "dir": Vector2(-0.500, -0.866), "lado": 1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "bairro_do_castelo", "nome": "Bairro do Castelo", "tipo": "bairro", "centro": Vector2(-286, -225), "dir": Vector2(0.500, -0.866), "lado": 1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "quartel_da_guarda", "nome": "Quartel da Guarda", "tipo": "quartel", "centro": Vector2(286, -225), "dir": Vector2(0.500, 0.866), "lado": 1.0, "raio": 58.0, "liga": "anel_do_reino"},
	{"id": "mercado_do_poente", "nome": "Mercado do Poente", "tipo": "mercado", "centro": Vector2(-285, -78), "dir": Vector2(1, 0), "lado": -1.0, "raio": 50.0, "liga": "rua_do_meio_oeste"},
	{"id": "mercado_do_nascente", "nome": "Mercado do Nascente", "tipo": "mercado", "centro": Vector2(285, -78), "dir": Vector2(1, 0), "lado": -1.0, "raio": 50.0, "liga": "rua_do_meio_leste"},
	{"id": "guarita_sul", "nome": "Guarita do Portão Sul", "tipo": "guarita", "centro": Vector2(0, 478), "dir": Vector2(1, 0), "lado": -1.0, "raio": 9.0, "liga": ""},
	{"id": "guarita_oeste", "nome": "Guarita do Portão Oeste", "tipo": "guarita", "centro": Vector2(-538, -60), "dir": Vector2(0, 1), "lado": -1.0, "raio": 9.0, "liga": ""},
	{"id": "guarita_leste", "nome": "Guarita do Portão Leste", "tipo": "guarita", "centro": Vector2(538, -60), "dir": Vector2(0, 1), "lado": 1.0, "raio": 9.0, "liga": ""},
	{"id": "feira_sul", "nome": "Feira do Portão Sul", "tipo": "mercado", "centro": Vector2(95, 590), "dir": Vector2(0, 1), "lado": -1.0, "raio": 50.0, "liga": "reino_sul"},
	{"id": "feira_poente", "nome": "Feira do Poente", "tipo": "posto_imperial", "centro": Vector2(-660, -150), "dir": Vector2(1, 0), "lado": -1.0, "raio": 50.0, "liga": "campos"},
	{"id": "feira_nascente", "nome": "Feira do Nascente", "tipo": "posto_imperial", "centro": Vector2(660, -150), "dir": Vector2(1, 0), "lado": -1.0, "raio": 50.0, "liga": "ferrogris"},
	# --- povoados novos da ilha grande (NOMES PROVISÓRIOS, propostos e ainda não aprovados pelo Cristian) ---
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
	# >>> GERADO por tools/mundo/encher_o_mundo.py (NOMES PROVISÓRIOS, a aprovar): não editar à mão
	{"id": "vila_riacho_fundo", "nome": "Vila Riacho Fundo", "tipo": "vila", "centro": Vector2(-2900, 1774), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_14"},
	{"id": "vila_carvalhal", "nome": "Vila Carvalhal", "tipo": "vila", "centro": Vector2(-499, -1152), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "vila_monte_claro", "nome": "Vila Monte Claro", "tipo": "vila", "centro": Vector2(-1787, -81), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "vila_serra_baixa", "nome": "Vila Serra Baixa", "tipo": "vila", "centro": Vector2(3352, -45), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_09"},
	{"id": "vila_lagoa_seca", "nome": "Vila Lagoa Seca", "tipo": "vila", "centro": Vector2(1643, -2045), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_08"},
	{"id": "vila_pedra_lisa", "nome": "Vila Pedra Lisa", "tipo": "vila", "centro": Vector2(969, 37), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "ferrogris"},
	{"id": "vila_vento_sul", "nome": "Vila Vento Sul", "tipo": "vila", "centro": Vector2(3249, -838), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_09"},
	{"id": "vila_ribeira", "nome": "Vila Ribeira", "tipo": "vila", "centro": Vector2(-1070, 1318), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "vila_bom_retiro", "nome": "Vila Bom Retiro", "tipo": "vila", "centro": Vector2(582, -807), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "anel_do_reino"},
	{"id": "vila_areal", "nome": "Vila Areal", "tipo": "vila", "centro": Vector2(395, 841), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},
	{"id": "vila_morro_verde", "nome": "Vila Morro Verde", "tipo": "vila", "centro": Vector2(-1662, 729), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "vila_sete_pontes", "nome": "Vila Sete Pontes", "tipo": "vila", "centro": Vector2(1654, 902), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},
	{"id": "vila_corrego_frio", "nome": "Vila Córrego Frio", "tipo": "vila", "centro": Vector2(-2570, -983), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_03"},
	{"id": "vila_cruz_das_almas", "nome": "Vila Cruz das Almas", "tipo": "vila", "centro": Vector2(159, -1303), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_06"},
	{"id": "estalagem_do_viajante", "nome": "Estalagem do Viajante", "tipo": "posto_imperial", "centro": Vector2(-2458, -530), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "costa_02"},
	{"id": "estalagem_da_encosta", "nome": "Estalagem da Encosta", "tipo": "posto_imperial", "centro": Vector2(370, -2601), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "costa_06"},
	{"id": "estalagem_das_tres_estradas", "nome": "Estalagem das Três Estradas", "tipo": "posto_imperial", "centro": Vector2(1495, 261), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "ferrogris"},
	{"id": "estalagem_do_rio", "nome": "Estalagem do Rio", "tipo": "posto_imperial", "centro": Vector2(-851, -2300), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "costa_05"},
	{"id": "fazenda_boa_vista", "nome": "Fazenda Boa Vista", "tipo": "fazenda", "centro": Vector2(36, -912), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "anel_do_reino"},
	{"id": "fazenda_do_vale", "nome": "Fazenda do Vale", "tipo": "fazenda", "centro": Vector2(842, -1058), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_08"},
	{"id": "fazenda_capim_dourado", "nome": "Fazenda Capim Dourado", "tipo": "fazenda", "centro": Vector2(-418, -2418), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_05"},
	{"id": "fazenda_olho_d_agua", "nome": "Fazenda Olho d'Água", "tipo": "fazenda", "centro": Vector2(2006, 1276), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "beira_rio"},
	{"id": "fazenda_pedregal", "nome": "Fazenda Pedregal", "tipo": "fazenda", "centro": Vector2(1077, -590), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "fazenda_rio_manso", "nome": "Fazenda Rio Manso", "tipo": "fazenda", "centro": Vector2(1442, -853), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "fazenda_cerca_velha", "nome": "Fazenda Cerca Velha", "tipo": "fazenda", "centro": Vector2(-930, -17), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "pedras"},
	{"id": "fazenda_girassol", "nome": "Fazenda Girassol", "tipo": "fazenda", "centro": Vector2(915, 2293), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ruptura"},
	{"id": "fazenda_arado", "nome": "Fazenda Arado", "tipo": "fazenda", "centro": Vector2(-2808, 568), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_16"},
	{"id": "fazenda_colmeia", "nome": "Fazenda Colmeia", "tipo": "fazenda", "centro": Vector2(-1179, -1956), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_05"},
	{"id": "fazenda_remanso", "nome": "Fazenda Remanso", "tipo": "fazenda", "centro": Vector2(-182, 1384), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "reino_sul"},
	{"id": "fazenda_espiga", "nome": "Fazenda Espiga", "tipo": "fazenda", "centro": Vector2(-562, -840), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "pedras"},
	{"id": "fazenda_curral_novo", "nome": "Fazenda Curral Novo", "tipo": "fazenda", "centro": Vector2(-2467, 1997), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_14"},
	{"id": "fazenda_acude", "nome": "Fazenda Açude", "tipo": "fazenda", "centro": Vector2(-667, 749), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "reino_sul"},
	{"id": "fazenda_horizonte", "nome": "Fazenda Horizonte", "tipo": "fazenda", "centro": Vector2(2732, -1060), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_09"},
	{"id": "fazenda_sombra_boa", "nome": "Fazenda Sombra Boa", "tipo": "fazenda", "centro": Vector2(296, -2222), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_06"},
	{"id": "posto_da_encruzilhada", "nome": "Posto da Encruzilhada", "tipo": "posto", "centro": Vector2(1751, -626), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "posto_do_desfiladeiro", "nome": "Posto do Desfiladeiro", "tipo": "posto", "centro": Vector2(3146, 318), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_10"},
	{"id": "posto_da_mata", "nome": "Posto da Mata", "tipo": "posto", "centro": Vector2(-1584, 1573), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pomar"},
	{"id": "posto_do_morro", "nome": "Posto do Morro", "tipo": "posto", "centro": Vector2(-2957, -189), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_01"},
	{"id": "posto_da_ponte", "nome": "Posto da Ponte", "tipo": "posto", "centro": Vector2(-1665, -1574), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "nevoa"},
	{"id": "cabana_do_ermitao", "nome": "Cabana do Ermitão", "tipo": "cabana", "centro": Vector2(-1191, -2280), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_05"},
	{"id": "cabana_do_cacador", "nome": "Cabana do Caçador", "tipo": "cabana", "centro": Vector2(-2610, 293), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_17"},
	{"id": "cabana_da_clareira", "nome": "Cabana da Clareira", "tipo": "cabana", "centro": Vector2(2217, 209), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "ferrogris"},
	{"id": "cabana_do_barqueiro", "nome": "Cabana do Barqueiro", "tipo": "cabana", "centro": Vector2(-2822, 1344), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_15"},
	{"id": "cabana_do_mateiro", "nome": "Cabana do Mateiro", "tipo": "cabana", "centro": Vector2(-791, 1695), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pomar"},
	{"id": "cabana_da_colina", "nome": "Cabana da Colina", "tipo": "cabana", "centro": Vector2(-2122, 244), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "cabana_do_ferreiro_velho", "nome": "Cabana do Ferreiro Velho", "tipo": "cabana", "centro": Vector2(-1361, 1199), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "cabana_do_vigia", "nome": "Cabana do Vigia", "tipo": "cabana", "centro": Vector2(2070, -918), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "cabana_do_pescador_do_oeste", "nome": "Cabana do Pescador do Oeste", "tipo": "pescador", "centro": Vector2(-3436, -263), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_01"},
	{"id": "cabana_do_pescador_do_leste", "nome": "Cabana do Pescador do Leste", "tipo": "pescador", "centro": Vector2(3712, -455), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_09"},
	{"id": "cabana_do_pescador_do_sul", "nome": "Cabana do Pescador do Sul", "tipo": "pescador", "centro": Vector2(-3046, -1309), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_03"},
	{"id": "cabana_do_pescador_da_baia", "nome": "Cabana do Pescador da Baía", "tipo": "pescador", "centro": Vector2(-469, 2496), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "reino_sul"},
	# <<< GERADO
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
