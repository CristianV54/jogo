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
}

## Limites do chão do mundo (a ilha fica dentro; o resto é mar).
const LIMITES := Rect2(-4000.0, -3050.0, 8000.0, 6100.0)
## Meio-eixos da ilha, que é oval: 7,45 km de leste a oeste e 5,6 km de norte a sul (a medida do mapa de Red Dead
## Redemption 2, pedida pelo Cristian). A costa é recortada em volta desse oval, ver Costa.
const EIXOS_DA_ILHA := Vector2(3725.0, 2800.0)

## O REINO DE VALDORIA: o Castelo num rochedo no centro e, em volta dele, a cidade apertada dentro da muralha (ver
## MuralhaDoReino e CasarioDoReino). Onde uma estrada cruza o círculo da muralha abre-se um portão.
const REINO := {"centro": Vector2(0.0, 0.0), "raio": 300.0}   # círculo que envolve a cidade (para contas grossas; a muralha de verdade é oval, ver ate_a_muralha)

## Estradas: id, nome, pontos de controle (suavizados). Cada ponta casa com a entrada que a região já tem na borda dela
## (quase todas as regiões se entram pelo lado sul; o Refúgio tem portões a oeste, norte e leste).
const ESTRADAS := [
	{"id": "reino_sul", "nome": "Estrada do Reino", "a": "refugio_do_pinhal", "b": "valdoria", "meia": 24.0,
		"pontos": [Vector2(-364.5, 1665.5), Vector2(-291.6, 1277.9), Vector2(-97.2, 949.3), Vector2(0, 730.2), Vector2(0, 227), Vector2(0, 173)]},
	{"id": "norte", "nome": "Estrada do Norte", "a": "valdoria", "b": "", "meia": 22.0,   # sai pelo portão norte, atrás do Castelo, rumo à Vila Ocre
		"pontos": [Vector2(430, -40), Vector2(400, -220), Vector2(220, -420), Vector2(60, -900), Vector2(250, -1250), Vector2(420, -1500), Vector2(560, -1640), Vector2(735, -1643)]},
	{"id": "rua_do_penhasco", "nome": "Rua do Penhasco", "a": "", "b": "", "meia": 14.0,   # dá a volta ao pé do penhasco
		"pontos": [Vector2(0, 118), Vector2(-24, 116), Vector2(-48, 111), Vector2(-70, 102), Vector2(-90, 90), Vector2(-107, 76), Vector2(-121, 59), Vector2(-132, 40), Vector2(-138, 20), Vector2(-140, 0), Vector2(-138, -20), Vector2(-132, -40), Vector2(-121, -59), Vector2(-107, -76), Vector2(-90, -90), Vector2(-70, -102), Vector2(-48, -111), Vector2(-24, -116), Vector2(0, -118), Vector2(24, -116), Vector2(48, -111), Vector2(70, -102), Vector2(90, -90), Vector2(107, -76), Vector2(121, -59), Vector2(132, -40), Vector2(138, -20), Vector2(140, 0), Vector2(138, 20), Vector2(132, 40), Vector2(121, 59), Vector2(107, 76), Vector2(90, 90), Vector2(70, 102), Vector2(48, 111), Vector2(24, 116), Vector2(0, 118)]},
	{"id": "pomar", "nome": "Estrada do Pomar", "a": "refugio_do_pinhal", "b": "pomar_alto", "meia": 22.0,
		"pontos": [Vector2(-524.5, 1825.5), Vector2(-1093.5, 1843.8), Vector2(-1579.5, 1752.5), Vector2(-1944, 1643), Vector2(-2138.4, 1402.9)]},
	{"id": "ruptura", "nome": "Caminho da Ruptura", "a": "refugio_do_pinhal", "b": "acampamento_ruptura", "meia": 20.0,
		"pontos": [Vector2(-204.5, 1825.5), Vector2(291.6, 1916.8), Vector2(631.8, 2135.8), Vector2(972, 1960.5)]},
	{"id": "campos", "nome": "Estrada dos Campos Altos", "a": "valdoria", "b": "", "meia": 24.0,
		"pontos": [Vector2(-134, 35), Vector2(-276, 35), Vector2(-520, 70), Vector2(-800, 200), Vector2(-1020.6, 365.1), Vector2(-1701, 109.5), Vector2(-2308.5, -36.5), Vector2(-2527.2, -91.3)]},
	{"id": "bosque", "nome": "Trilha do Bosque", "a": "valdoria", "b": "bosque_velado", "meia": 20.0,
		"pontos": [Vector2(-1020.6, 365.1), Vector2(-1263.6, 0), Vector2(-1458, -456.4), Vector2(-1555.2, -935.3)]},
	{"id": "nevoa", "nome": "Trilha da Névoa", "a": "bosque_velado", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1555.2, -1255.3), Vector2(-1846.8, -1533.4), Vector2(-2187, -1606.4), Vector2(-2332.8, -1633.8)]},
	{"id": "pedras", "nome": "Estrada da Serra", "a": "valdoria", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1020.6, 365.1), Vector2(-1044.9, -109.5), Vector2(-1020.6, -730.2), Vector2(-729, -1460.4), Vector2(-437.4, -1989.8)]},
	{"id": "trilha_do_gelo", "nome": "Trilha do Gelo", "a": "", "b": "", "meia": 12.0,
		"pontos": [Vector2(-437.4, -1989.8), Vector2(-150, -2200), Vector2(250, -2330)]},
	{"id": "trilha_dos_dragoes", "nome": "Trilha dos Dragões", "a": "", "b": "", "meia": 12.0,
		"pontos": [Vector2(-729, -1460.4), Vector2(-660, -1490), Vector2(-590, -1500)]},
	{"id": "ferrogris", "nome": "Estrada de Ferrogris", "a": "valdoria", "b": "fronteira_ferrogris", "meia": 24.0,
		"pontos": [Vector2(129, -45), Vector2(294, -45), Vector2(520, -10), Vector2(820, 300), Vector2(1093.5, 547.7), Vector2(1822.5, 419.9), Vector2(2430, 383.4), Vector2(2673, 191.5)]},
	{"id": "cratera", "nome": "Estrada Queimada", "a": "valdoria", "b": "cratera_ignis", "meia": 20.0,
		"pontos": [Vector2(1822.5, 419.9), Vector2(1871.1, -182.6), Vector2(1846.8, -730.2), Vector2(1798.2, -1159.4)]},
	{"id": "beira_rio", "nome": "Estrada da Foz", "a": "valdoria", "b": "", "meia": 22.0,
		"pontos": [Vector2(0, 620), Vector2(486, 602.4), Vector2(1020.6, 785), Vector2(1506.6, 1095.3), Vector2(1749.6, 1460.4), Vector2(1798.2, 1734.2)]},
	{"id": "vau", "nome": "Caminho do Vau", "a": "acampamento_ruptura", "b": "valdoria", "meia": 20.0,
		"pontos": [Vector2(996, 1690.5), Vector2(1069.2, 1277.9), Vector2(1044.9, 985.8), Vector2(1020.6, 785)]},
	# >>> GERADO por tools/mundo/encher_o_mundo.py: a Estrada da Costa, em trechos de vila a vila
	{"id": "costa_01", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2681, -147), Vector2(-2912, -273), Vector2(-3109, -430)]},
	{"id": "costa_02", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-3114, -502), Vector2(-2832, -724), Vector2(-2615, -943)]},
	{"id": "costa_03", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2558, -1041), Vector2(-2481, -1309), Vector2(-2442, -1585)]},
	{"id": "costa_04", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2376, -1667), Vector2(-1960, -1863), Vector2(-1512, -2045)]},
	{"id": "costa_05", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1399, -2070), Vector2(-874, -2049), Vector2(-351, -2098)]},
	{"id": "costa_06", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-233, -2110), Vector2(300, -2089), Vector2(784, -2301)]},
	{"id": "costa_07", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(839, -2253), Vector2(872, -1975), Vector2(805, -1702)]},
	{"id": "costa_08", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(856, -1669), Vector2(1223, -1803), Vector2(1589, -2019)]},
	{"id": "costa_09", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(3257, -779), Vector2(3292, -440), Vector2(3344, -104)]},
	{"id": "costa_10", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(3324, 7), Vector2(3072, 187), Vector2(3025, 556)]},
	{"id": "costa_11", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(2956, 651), Vector2(2784, 853), Vector2(2569, 1052)]},
	{"id": "costa_12", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(2517, 1154), Vector2(2445, 1361), Vector2(2440, 1584)]},
	{"id": "costa_13", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(2374, 1662), Vector2(2132, 1781), Vector2(1903, 1824)]},
	{"id": "costa_14", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-1322, 2088), Vector2(-2074, 1980), Vector2(-2842, 1785)]},
	{"id": "costa_15", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2896, 1715), Vector2(-2878, 1347), Vector2(-2839, 972)]},
	{"id": "costa_16", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-2859, 858), Vector2(-2928, 655), Vector2(-3054, 419)]},
	{"id": "costa_17", "nome": "Estrada da Costa", "a": "", "b": "", "meia": 20.0,
		"pontos": [Vector2(-3037, 322), Vector2(-2854, 151), Vector2(-2671, -60)]},
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
	{"id": "vila_geada", "nome": "Vila Geada", "tipo": "vila", "centro": Vector2(250, -2380), "dir": Vector2(1, 0), "lado": -1.0, "raio": 70.0, "liga": "trilha_do_gelo"},   # a vila das Terras do Gelo (nome criado, a aprovar)
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
	{"id": "mercado_central", "nome": "Praça do Mercado", "tipo": "mercado", "centro": Vector2(0, 129), "dir": Vector2(1, 0), "lado": 1.0, "raio": 30.0, "liga": ""},
	{"id": "quartel_da_guarda", "nome": "Quartel da Guarda", "tipo": "quartel", "centro": Vector2(-180, -125), "dir": Vector2(1, 0), "lado": 1.0, "raio": 46.0, "liga": ""},
	{"id": "estabulos_do_reino", "nome": "Estábulos do Reino", "tipo": "estabulo", "centro": Vector2(-212, 52), "dir": Vector2(1, 0), "lado": 1.0, "raio": 44.0, "liga": ""},
	{"id": "catedral_de_valdoria", "nome": "Catedral de Valdoria", "tipo": "catedral", "centro": Vector2(150, 40), "dir": Vector2(0, 1), "lado": -1.0, "raio": 44.0, "liga": ""},
	{"id": "lavoura_do_carvalho", "nome": "Lavoura do Carvalho", "tipo": "lavoura", "centro": Vector2(407, 343), "dir": Vector2(-0.707, 0.707), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_da_ponte", "nome": "Lavoura da Ponte", "tipo": "lavoura", "centro": Vector2(149, 468), "dir": Vector2(-0.966, 0.259), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_vale", "nome": "Lavoura do Vale", "tipo": "lavoura", "centro": Vector2(-149, 468), "dir": Vector2(-0.966, -0.259), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_das_abelhas", "nome": "Lavoura das Abelhas", "tipo": "lavoura", "centro": Vector2(-407, 343), "dir": Vector2(-0.707, -0.707), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_trigal", "nome": "Lavoura do Trigal", "tipo": "lavoura", "centro": Vector2(-407, -343), "dir": Vector2(0.707, -0.707), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_da_fonte", "nome": "Lavoura da Fonte", "tipo": "lavoura", "centro": Vector2(-149, -468), "dir": Vector2(0.966, -0.259), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_outeiro", "nome": "Lavoura do Outeiro", "tipo": "lavoura", "centro": Vector2(149, -468), "dir": Vector2(0.966, 0.259), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_da_varzea", "nome": "Lavoura da Várzea", "tipo": "lavoura", "centro": Vector2(407, -343), "dir": Vector2(0.707, 0.707), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "guarita_sul", "nome": "Guarita do Portão Sul", "tipo": "guarita", "centro": Vector2(0, 211), "dir": Vector2(1, 0), "lado": -1.0, "raio": 9.0, "liga": ""},
	{"id": "guarita_oeste", "nome": "Guarita do Portão Oeste", "tipo": "guarita", "centro": Vector2(-260, 35), "dir": Vector2(0, 1), "lado": -1.0, "raio": 9.0, "liga": ""},
	{"id": "guarita_leste", "nome": "Guarita do Portão Leste", "tipo": "guarita", "centro": Vector2(278, -45), "dir": Vector2(0, 1), "lado": 1.0, "raio": 9.0, "liga": ""},
	{"id": "feira_sul", "nome": "Feira do Portão Sul", "tipo": "mercado", "centro": Vector2(70, 297), "dir": Vector2(0, 1), "lado": -1.0, "raio": 40.0, "liga": "reino_sul"},
	{"id": "feira_poente", "nome": "Feira do Poente", "tipo": "mercado", "centro": Vector2(-366, 120), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "campos"},
	{"id": "feira_nascente", "nome": "Feira do Nascente", "tipo": "mercado", "centro": Vector2(374, -130), "dir": Vector2(1, 0), "lado": -1.0, "raio": 40.0, "liga": "ferrogris"},
	{"id": "lavoura_do_sul", "nome": "Lavoura do Sul", "tipo": "lavoura", "centro": Vector2(204, 327), "dir": Vector2(-0.883, 0.469), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_poente", "nome": "Lavoura do Poente", "tipo": "lavoura", "centro": Vector2(-204, 327), "dir": Vector2(-0.883, -0.469), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_nascente", "nome": "Lavoura do Nascente", "tipo": "lavoura", "centro": Vector2(-394, 156), "dir": Vector2(-0.423, -0.906), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_norte", "nome": "Lavoura do Norte", "tipo": "lavoura", "centro": Vector2(-394, -156), "dir": Vector2(0.423, -0.906), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_das_sete_leiras", "nome": "Lavoura das Sete Leiras", "tipo": "lavoura", "centro": Vector2(-218, -320), "dir": Vector2(0.866, -0.500), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_moleiro", "nome": "Lavoura do Moleiro", "tipo": "lavoura", "centro": Vector2(0, -370), "dir": Vector2(1.000, -0.000), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_da_colina", "nome": "Lavoura da Colina", "tipo": "lavoura", "centro": Vector2(218, -320), "dir": Vector2(0.866, 0.500), "lado": -1.0, "raio": 52.0, "liga": ""},
	{"id": "lavoura_do_ribeiro", "nome": "Lavoura do Ribeiro", "tipo": "lavoura", "centro": Vector2(377, -185), "dir": Vector2(0.500, 0.866), "lado": -1.0, "raio": 52.0, "liga": ""},
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
	{"id": "vila_carvalhal", "nome": "Vila Carvalhal", "tipo": "vila", "centro": Vector2(911, -168), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": ""},
	{"id": "vila_monte_claro", "nome": "Vila Monte Claro", "tipo": "vila", "centro": Vector2(-499, -1152), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pedras"},
	{"id": "vila_serra_baixa", "nome": "Vila Serra Baixa", "tipo": "vila", "centro": Vector2(-1787, -81), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "vila_lagoa_seca", "nome": "Vila Lagoa Seca", "tipo": "vila", "centro": Vector2(3352, -45), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_09"},
	{"id": "vila_pedra_lisa", "nome": "Vila Pedra Lisa", "tipo": "vila", "centro": Vector2(1643, -2045), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_08"},
	{"id": "vila_vento_sul", "nome": "Vila Vento Sul", "tipo": "vila", "centro": Vector2(3249, -838), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_09"},
	{"id": "vila_ribeira", "nome": "Vila Ribeira", "tipo": "vila", "centro": Vector2(-1070, 1318), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "vila_bom_retiro", "nome": "Vila Bom Retiro", "tipo": "vila", "centro": Vector2(314, -882), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "norte"},
	{"id": "vila_areal", "nome": "Vila Areal", "tipo": "vila", "centro": Vector2(395, 841), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},
	{"id": "vila_morro_verde", "nome": "Vila Morro Verde", "tipo": "vila", "centro": Vector2(1099, -852), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "cratera"},
	{"id": "vila_sete_pontes", "nome": "Vila Sete Pontes", "tipo": "vila", "centro": Vector2(-1662, 729), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "campos"},
	{"id": "vila_corrego_frio", "nome": "Vila Córrego Frio", "tipo": "vila", "centro": Vector2(1654, 902), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "beira_rio"},
	{"id": "vila_cruz_das_almas", "nome": "Vila Cruz das Almas", "tipo": "vila", "centro": Vector2(-2570, -983), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "costa_03"},
	{"id": "estalagem_do_viajante", "nome": "Estalagem do Viajante", "tipo": "posto_imperial", "centro": Vector2(2335, -1360), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "cratera"},
	{"id": "estalagem_da_encosta", "nome": "Estalagem da Encosta", "tipo": "posto_imperial", "centro": Vector2(1913, -1883), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "costa_08"},
	{"id": "estalagem_das_tres_estradas", "nome": "Estalagem das Três Estradas", "tipo": "posto_imperial", "centro": Vector2(-2140, -1912), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "costa_04"},
	{"id": "estalagem_do_rio", "nome": "Estalagem do Rio", "tipo": "posto_imperial", "centro": Vector2(3337, 597), "dir": Vector2(1, 0), "lado": 1.0, "raio": 50.0, "liga": "costa_10"},
	{"id": "fazenda_boa_vista", "nome": "Fazenda Boa Vista", "tipo": "fazenda", "centro": Vector2(-3138, 1203), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_15"},
	{"id": "fazenda_do_vale", "nome": "Fazenda do Vale", "tipo": "fazenda", "centro": Vector2(-2443, 790), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_16"},
	{"id": "fazenda_capim_dourado", "nome": "Fazenda Capim Dourado", "tipo": "fazenda", "centro": Vector2(3209, 952), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_11"},
	{"id": "fazenda_olho_d_agua", "nome": "Fazenda Olho d'Água", "tipo": "fazenda", "centro": Vector2(-218, -995), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "norte"},
	{"id": "fazenda_pedregal", "nome": "Fazenda Pedregal", "tipo": "fazenda", "centro": Vector2(2596, -454), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ferrogris"},
	{"id": "fazenda_rio_manso", "nome": "Fazenda Rio Manso", "tipo": "fazenda", "centro": Vector2(-2680, -1450), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_03"},
	{"id": "fazenda_cerca_velha", "nome": "Fazenda Cerca Velha", "tipo": "fazenda", "centro": Vector2(159, -1303), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "norte"},
	{"id": "fazenda_girassol", "nome": "Fazenda Girassol", "tipo": "fazenda", "centro": Vector2(-2458, -530), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_02"},
	{"id": "fazenda_arado", "nome": "Fazenda Arado", "tipo": "fazenda", "centro": Vector2(370, -2601), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_06"},
	{"id": "fazenda_colmeia", "nome": "Fazenda Colmeia", "tipo": "fazenda", "centro": Vector2(1495, 261), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "ferrogris"},
	{"id": "fazenda_remanso", "nome": "Fazenda Remanso", "tipo": "fazenda", "centro": Vector2(-851, -2300), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_05"},
	{"id": "fazenda_espiga", "nome": "Fazenda Espiga", "tipo": "fazenda", "centro": Vector2(842, -1058), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "norte"},
	{"id": "fazenda_curral_novo", "nome": "Fazenda Curral Novo", "tipo": "fazenda", "centro": Vector2(-418, -2418), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "costa_05"},
	{"id": "fazenda_acude", "nome": "Fazenda Açude", "tipo": "fazenda", "centro": Vector2(2006, 1276), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "beira_rio"},
	{"id": "fazenda_horizonte", "nome": "Fazenda Horizonte", "tipo": "fazenda", "centro": Vector2(1442, -853), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "cratera"},
	{"id": "fazenda_sombra_boa", "nome": "Fazenda Sombra Boa", "tipo": "fazenda", "centro": Vector2(-930, -17), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "pedras"},
	{"id": "posto_da_encruzilhada", "nome": "Posto da Encruzilhada", "tipo": "posto", "centro": Vector2(964, 195), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "ferrogris"},
	{"id": "posto_do_desfiladeiro", "nome": "Posto do Desfiladeiro", "tipo": "posto", "centro": Vector2(915, 2293), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "ruptura"},
	{"id": "posto_da_mata", "nome": "Posto da Mata", "tipo": "posto", "centro": Vector2(-2808, 568), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_16"},
	{"id": "posto_do_morro", "nome": "Posto do Morro", "tipo": "posto", "centro": Vector2(941, -468), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "posto_da_ponte", "nome": "Posto da Ponte", "tipo": "posto", "centro": Vector2(-1179, -1956), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_05"},
	{"id": "cabana_do_ermitao", "nome": "Cabana do Ermitão", "tipo": "cabana", "centro": Vector2(-182, 1384), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "reino_sul"},
	{"id": "cabana_do_cacador", "nome": "Cabana do Caçador", "tipo": "cabana", "centro": Vector2(-562, -840), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pedras"},
	{"id": "cabana_da_clareira", "nome": "Cabana da Clareira", "tipo": "cabana", "centro": Vector2(-2467, 1997), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_14"},
	{"id": "cabana_do_barqueiro", "nome": "Cabana do Barqueiro", "tipo": "cabana", "centro": Vector2(-667, 749), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "reino_sul"},
	{"id": "cabana_do_mateiro", "nome": "Cabana do Mateiro", "tipo": "cabana", "centro": Vector2(2732, -1060), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_09"},
	{"id": "cabana_da_colina", "nome": "Cabana da Colina", "tipo": "cabana", "centro": Vector2(296, -2222), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_06"},
	{"id": "cabana_do_ferreiro_velho", "nome": "Cabana do Ferreiro Velho", "tipo": "cabana", "centro": Vector2(1751, -626), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "cratera"},
	{"id": "cabana_do_vigia", "nome": "Cabana do Vigia", "tipo": "cabana", "centro": Vector2(3146, 318), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "costa_10"},
	{"id": "cabana_do_pescador_do_oeste", "nome": "Cabana do Pescador do Oeste", "tipo": "pescador", "centro": Vector2(-3190, -1029), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_02"},
	{"id": "cabana_do_pescador_do_leste", "nome": "Cabana do Pescador do Leste", "tipo": "pescador", "centro": Vector2(1415, -2451), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_08"},
	{"id": "cabana_do_pescador_do_sul", "nome": "Cabana do Pescador do Sul", "tipo": "pescador", "centro": Vector2(-3335, 551), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_16"},
	{"id": "cabana_do_pescador_da_baia", "nome": "Cabana do Pescador da Baía", "tipo": "pescador", "centro": Vector2(-3436, -263), "dir": Vector2(1, 0), "lado": 1.0, "raio": 22.0, "liga": "costa_01"},
	# <<< GERADO
]


## ------------------------------------------------------------------------------------------------------------------
## A PLANTA DE VALDORIA segue o Reino de Aethelgard que o Cristian tinha feito em blocos (mesma composição e mesmas
## proporções, uma unidade de lá = 10 cm daqui): penhasco de rocha no centro com a cidadela branca em cima; rampa que
## sobe do leste, passa pela face sul e chega ao portão da cidadela, a oeste; rua em anel no pé do penhasco; avenida do
## portão sul até a praça do mercado; cidade densa em faixas; muralha de contorno irregular com três portões (os do
## oeste e do leste não ficam frente a frente). Origem no centro do penhasco; sul = z positivo.
const MURALHA_EIXOS := Vector2(290.0, 240.0)   # meia largura e meia profundidade da muralha, antes da ondulação
const PENHASCO_EIXOS := Vector2(66.0, 55.0)    # o topo do penhasco (platô da cidadela)
const PENHASCO_ALTURA := 64.0
const PENHASCO_BASE := 1.7                     # o pé do penhasco fica, em média, a 1,7 vezes o topo
const RAMPA_R0 := 1.08                         # faixa da rampa, em múltiplos do topo
const RAMPA_R1 := 1.34
const RAMPA_TS := 3.054326                     # 175 graus: o pé da rampa, a leste
const RAMPA_TE := 0.174533                     # 10 graus: o alto da rampa, a oeste
const RAMPA_TFIM := -0.314159                  # -18 graus: fim do patamar diante do portão da cidadela
const ANEL_EIXOS := Vector2(140.0, 118.0)      # penhasco + rua em anel: dali para dentro não há casa
const PORTAO_OESTE_Z := 35.0
const PORTAO_LESTE_Z := -45.0
const PRACA := Rect2(-27.0, 129.0, 54.0, 44.0) # praça do mercado, onde a avenida do sul encontra a rua em anel

static var _ruido_do_penhasco: FastNoiseLite


## Distância até a muralha do reino: NEGATIVA dentro da cidade, positiva fora.
static func ate_a_muralha(x: float, z: float) -> float:
	var e := MURALHA_EIXOS
	var a := atan2(z / e.y, x / e.x)
	var raio_aqui := 1.0 / Vector2(cos(a) / e.x, sin(a) / e.y).length()
	return (Vector2(x / e.x, z / e.y).length() - 1.0) * raio_aqui - (12.0 * sin(3.0 * a + 0.7) + 8.0 * sin(5.0 * a + 2.0))


## Ponto da muralha na direção `a` (ângulo no oval): onde a distância até a muralha é zero.
static func ponto_da_muralha(a: float) -> Vector2:
	var dentro := 0.6
	var fora := 1.4
	for passo in 30:
		var m := (dentro + fora) / 2.0
		if ate_a_muralha(m * cos(a) * MURALHA_EIXOS.x, m * sin(a) * MURALHA_EIXOS.y) < 0.0:
			dentro = m
		else:
			fora = m
	return Vector2(dentro * cos(a) * MURALHA_EIXOS.x, dentro * sin(a) * MURALHA_EIXOS.y)


## Ângulo no penhasco: 0 a oeste, 90 graus ao sul, 180 a leste (o sentido em que a rampa desce).
static func angulo_no_penhasco(x: float, z: float) -> float:
	return atan2(z / PENHASCO_EIXOS.y, -x / PENHASCO_EIXOS.x)


## Altura do piso da rampa no ângulo `t`: 0 no pé (leste), a altura do penhasco no alto (oeste).
static func altura_da_rampa(t: float) -> float:
	return PENHASCO_ALTURA * clampf((RAMPA_TS - t) / (RAMPA_TS - RAMPA_TE), 0.0, 1.0)


## O penhasco: devolve [altura do chão acima da cidade, é piso da rampa?, raio em múltiplos do topo].
static func penhasco(x: float, z: float) -> Array:
	if _ruido_do_penhasco == null:
		_ruido_do_penhasco = FastNoiseLite.new()
		_ruido_do_penhasco.seed = 22
		_ruido_do_penhasco.frequency = 0.045
	var r := Vector2(x / PENHASCO_EIXOS.x, z / PENHASCO_EIXOS.y).length()
	if r > PENHASCO_BASE + 0.4:
		return [0.0, false, r]
	var t := angulo_no_penhasco(x, z)
	var ru := _ruido_do_penhasco.get_noise_2d(x, z) * 0.5 + 0.5
	var base := PENHASCO_BASE + 0.5 * (_ruido_do_penhasco.get_noise_2d(x * 0.5 + 90.0, z * 0.5 + 40.0) * 0.5)   # pé irregular
	var h := PENHASCO_ALTURA
	if r > 1.0:
		h = 0.0 if r >= base else PENHASCO_ALTURA * pow((base - r) / (base - 1.0), 0.62) * (0.7 + 0.5 * ru)
	h = minf(PENHASCO_ALTURA, roundf(h / 2.0) * 2.0)   # a rocha sobe em bancadas de 2 m
	var via := false
	if t <= RAMPA_TS and t >= RAMPA_TFIM:
		if r >= RAMPA_R0:
			var hr := altura_da_rampa(t)
			if r <= RAMPA_R1:
				h = hr
				via = true
			else:
				h = minf(h, hr)
		elif r > 1.0 and t <= deg_to_rad(14.0):
			h = PENHASCO_ALTURA   # patamar diante do portão da cidadela
	return [h, via, r]


## AS TERRAS DO GELO (pedido do Cristian): o extremo norte da ilha, atrás da Montanha dos Dragões. O bioma "gelo" (ver
## Biomas) cobre a faixa; aqui ficam o Lago Congelado e a Vila Geada.
const LAGO_CONGELADO := Vector2(-420.0, -2420.0)
const LAGO_RAIO := 70.0


## A MONTANHA DOS DRAGÕES (pedido do Cristian): um cone de rocha de 240 m ao norte de Valdoria, com uma trilha em
## espiral (volta e meia, ~12% de subida) do pé, a oeste, até o platô do ninho no topo. É onde se doma o primeiro dragão.
const MONTANHA_CENTRO := Vector2(-200.0, -1500.0)
const MONTANHA_RAIO := 380.0
const MONTANHA_TOPO := 42.0      # raio do platô do ninho
const MONTANHA_ALTURA := 240.0
const MONTANHA_VOLTAS := 1.5
static var _ruido_da_montanha: FastNoiseLite


## Fração da subida (0 no pé, 1 no topo) -> altura da encosta ali.
static func _perfil_da_montanha(t: float) -> float:
	return MONTANHA_ALTURA * pow(clampf(t, 0.0, 1.0), 1.15)


## Ponto do eixo da trilha: `t` de 0 (pé, a oeste) a 1 (borda do platô).
static func ponto_da_trilha(t: float) -> Vector2:
	var a := TAU * MONTANHA_VOLTAS * t
	var r := MONTANHA_RAIO - t * (MONTANHA_RAIO - MONTANHA_TOPO)
	return MONTANHA_CENTRO + Vector2(-cos(a), sin(a)) * r


## A montanha: devolve [altura do chão acima do terreno, é piso da trilha?, distância ao centro].
static func montanha(x: float, z: float) -> Array:
	var v := Vector2(x, z) - MONTANHA_CENTRO
	var d := v.length()
	if d > MONTANHA_RAIO + 14.0:
		return [0.0, false, d]
	if _ruido_da_montanha == null:
		_ruido_da_montanha = FastNoiseLite.new()
		_ruido_da_montanha.seed = 77
		_ruido_da_montanha.frequency = 0.02
	var t := clampf((MONTANHA_RAIO - d) / (MONTANHA_RAIO - MONTANHA_TOPO), 0.0, 1.0)
	var h := _perfil_da_montanha(t)
	h += _ruido_da_montanha.get_noise_2d(x, z) * 22.0 * t * (1.0 - t) * 4.0   # cristas e grotas na encosta (nada no pé nem no platô)
	h = maxf(h, 0.0)
	var volta := fposmod(atan2(v.y, -v.x), TAU) / TAU   # 0 a oeste, crescendo no sentido da trilha
	var k := roundf(MONTANHA_VOLTAS * t - volta)
	var tp := (k + volta) / MONTANHA_VOLTAS
	var trilha := false
	if tp >= -0.02 and tp <= 1.0:
		var rp := MONTANHA_RAIO - tp * (MONTANHA_RAIO - MONTANHA_TOPO)
		var fora := absf(d - rp)
		if fora < 13.0:
			h = lerpf(h, _perfil_da_montanha(tp), 1.0 - smoothstep(5.5, 13.0, fora))
			trilha = fora < 5.5
	return [h, trilha, d]


## Altura do chão da região acima do nível do reino (só o Castelo fica no alto de um morro).
static func altura(id: String) -> float:
	return float(REGIOES[id].get("altura", 0.0))


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
