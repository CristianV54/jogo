class_name MundoDados
extends RefCounted
## Planta do mundo contínuo (coordenadas do MUNDO, em metros; norte = -Z). Cada região é uma das áreas já construídas,
## posta num lugar fixo; entre elas há estradas, rios, florestas, pontes, povoados e fazendas.

## id -> {cena, centro (Vector2), meia (metade do lado da área), nome}
const REGIOES := {
	"refugio_do_pinhal": {"cena": "res://scenes/areas/refugio_do_pinhal.tscn", "centro": Vector2(0, 0), "meia": 160.0, "nome": "Refúgio do Pinhal"},
	"pomar_alto": {"cena": "res://scenes/areas/pomar_alto.tscn", "centro": Vector2(-420, -250), "meia": 120.0, "nome": "Pomar Alto das Macieiras"},
	"bosque_velado": {"cena": "res://scenes/areas/bosque_velado.tscn", "centro": Vector2(0, -550), "meia": 160.0, "nome": "Bosque Velado"},
	"acampamento_ruptura": {"cena": "res://scenes/areas/acampamento_ruptura.tscn", "centro": Vector2(560, -330), "meia": 130.0, "nome": "Acampamento da Ruptura"},
	"fronteira_ferrogris": {"cena": "res://scenes/areas/fronteira_ferrogris.tscn", "centro": Vector2(584, -840), "meia": 150.0, "nome": "Fortaleza de Ferrogris"},
	"cratera_ignis": {"cena": "res://scenes/areas/cratera_ignis.tscn", "centro": Vector2(584, -1360), "meia": 150.0, "nome": "Cratera de Ignis"},
	"valdoria": {"cena": "res://scenes/areas/valdoria.tscn", "centro": Vector2(584, -1880), "meia": 150.0, "nome": "Valdoria"},
	"castelo_imperial": {"cena": "res://scenes/areas/castelo_imperial.tscn", "centro": Vector2(584, -2300), "meia": 150.0, "nome": "Castelo Imperial"},
}

## Limites do chão do mundo.
const LIMITES := Rect2(-760.0, -2650.0, 1640.0, 3010.0)

## Estradas entre as regiões: id, de, para, pontos de controle (suavizados) e largura da faixa de passagem (meia largura).
## Cada ponta casa com a estrada que já existe dentro da área, na borda dela.
const ESTRADAS := [
	{"id": "pomar", "nome": "Estrada do Pomar", "a": "refugio_do_pinhal", "b": "pomar_alto", "meia": 22.0,
		"pontos": [Vector2(-160, 0), Vector2(-250, 15), Vector2(-330, -20), Vector2(-390, -70), Vector2(-420, -125)]},
	{"id": "bosque", "nome": "Trilha do Bosque", "a": "refugio_do_pinhal", "b": "bosque_velado", "meia": 20.0,
		"pontos": [Vector2(0, -160), Vector2(-5, -230), Vector2(6, -300), Vector2(0, -390)]},
	{"id": "campos", "nome": "Estrada dos Campos Altos", "a": "refugio_do_pinhal", "b": "acampamento_ruptura", "meia": 24.0,
		"pontos": [Vector2(160, 0), Vector2(300, 12), Vector2(420, -40), Vector2(500, -110), Vector2(560, -195)]},
	{"id": "ruptura", "nome": "Caminho da Ruptura", "a": "acampamento_ruptura", "b": "fronteira_ferrogris", "meia": 20.0,
		"pontos": [Vector2(584, -465), Vector2(592, -520), Vector2(578, -600), Vector2(584, -685)]},
	{"id": "ferrogris", "nome": "Estrada Queimada", "a": "fronteira_ferrogris", "b": "cratera_ignis", "meia": 20.0,
		"pontos": [Vector2(584, -995), Vector2(570, -1060), Vector2(598, -1130), Vector2(584, -1205)]},
	{"id": "imperial", "nome": "Estrada Imperial", "a": "cratera_ignis", "b": "valdoria", "meia": 24.0,
		"pontos": [Vector2(584, -1515), Vector2(600, -1590), Vector2(570, -1660), Vector2(584, -1725)]},
]

## Rios do mundo (largura do leito, margem, fundo). Ligam-se aos rios que já existem dentro das áreas.
const RIOS := [
	{"id": "cinzento", "nome": "Rio Cinzento", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(-700, 150), Vector2(-560, 140), Vector2(-400, 120), Vector2(-300, 95), Vector2(-180, 130), Vector2(-76, 150)]},
	{"id": "cinzento_leste", "nome": "Rio Cinzento", "largura": 7.0, "margem": 8.0, "fundo": 1.5,
		"pontos": [Vector2(78, 150), Vector2(180, 150), Vector2(280, 110), Vector2(360, 40), Vector2(400, -80), Vector2(404, -200), Vector2(404, -336.5)]},
	{"id": "cinzento_fim", "nome": "Rio Cinzento", "largura": 6.0, "margem": 8.0, "fundo": 1.2,
		"pontos": [Vector2(716, -337), Vector2(790, -400), Vector2(840, -520), Vector2(860, -640)]},
	{"id": "pomar", "nome": "Riacho do Moinho", "largura": 3.0, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-371, -420), Vector2(-371, -362), Vector2(-350, -132), Vector2(-340, -40), Vector2(-325, 40), Vector2(-305, 96)]},
	{"id": "nevoa_oeste", "nome": "Riacho da Névoa", "largura": 3.8, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(-156, -509.4), Vector2(-230, -480), Vector2(-290, -410), Vector2(-292, -300), Vector2(-296, -200), Vector2(-322, -130), Vector2(-340, -40)]},
	{"id": "nevoa_leste", "nome": "Riacho da Névoa", "largura": 3.8, "margem": 6.0, "fundo": 0.7,
		"pontos": [Vector2(156, -510.6), Vector2(250, -470), Vector2(330, -400), Vector2(404, -338)]},
]

## Povoados e fazendas: id, nome, tipo, centro (mundo), estrada e posição na estrada (0 a 1) onde o corredor se alarga.
const POVOADOS := [
	{"id": "campina", "nome": "Fazenda Campina", "tipo": "fazenda", "estrada": "pomar", "t": 0.3, "lado": 1.0, "raio": 60.0},
	{"id": "lenhador", "nome": "Cabana do Lenhador", "tipo": "cabana", "estrada": "bosque", "t": 0.5, "lado": -1.0, "raio": 45.0},
	{"id": "campos_altos", "nome": "Vila Campos Altos", "tipo": "vila", "estrada": "campos", "t": 0.5, "lado": 1.0, "raio": 80.0},
	{"id": "posto_rebelde", "nome": "Posto Rebelde", "tipo": "posto", "estrada": "ruptura", "t": 0.45, "lado": -1.0, "raio": 45.0},
	{"id": "posto_imperial", "nome": "Posto da Estrada Imperial", "tipo": "posto_imperial", "estrada": "imperial", "t": 0.35, "lado": 1.0, "raio": 50.0},
	{"id": "fazenda_imperial", "nome": "Fazenda Imperial", "tipo": "fazenda", "estrada": "imperial", "t": 0.55, "lado": -1.0, "raio": 60.0},
]

## Cristas de rocha: muralhas naturais que fecham o mundo por trás de cada passagem de história. Só passa quem usa o vão,
## e em cada vão há uma barreira (ver BARREIRAS). Fora delas o mundo é aberto. `altura` limita a colisão (o viaduto passa por cima).
const CRISTAS := [
	{"id": "oeste_leste", "de": Vector2(330, 360), "para": Vector2(330, -2650), "altura": 40.0, "vaos": [Vector2(330, -1.0)]},
	{"id": "bosque", "de": Vector2(-760, -385), "para": Vector2(330, -385), "altura": 40.0, "vaos": [Vector2(0.5, -385)]},
	{"id": "ruptura", "de": Vector2(330, -640), "para": Vector2(880, -640), "altura": 40.0, "vaos": [Vector2(581, -640)]},
	{"id": "fortaleza_norte_oeste", "de": Vector2(330, -940), "para": Vector2(514, -940), "altura": 40.0, "vaos": []},
	{"id": "fortaleza_norte_leste", "de": Vector2(654, -940), "para": Vector2(880, -940), "altura": 40.0, "vaos": []},
	{"id": "imperial", "de": Vector2(330, -1700), "para": Vector2(880, -1700), "altura": 40.0, "vaos": [Vector2(578, -1700)]},
	{"id": "castelo", "de": Vector2(330, -2035), "para": Vector2(880, -2035), "altura": 5.5, "vaos": []},
]

## Barreiras de história: uma em cada vão. `dir` é o sentido da estrada ali.
const BARREIRAS := [
	{"id": "bosque", "pos": Vector2(0.5, -385), "dir": Vector2(0, -1), "largura": 20.0, "tipo": "portao", "texto": "O portão da trilha está fechado: Halk só deixa passar quem terminou os serviços do Refúgio (Resgate nas Sombras do Pinhal)."},
	{"id": "ruptura", "pos": Vector2(330, -1), "dir": Vector2(1, 0), "largura": 20.0, "tipo": "entulho", "texto": "A estrada para o leste está bloqueada por uma barricada do capataz. Derrote o Brutamontes Gorath na mina."},
	{"id": "ferrogris", "pos": Vector2(581, -640), "dir": Vector2(0, -1), "largura": 20.0, "tipo": "portao", "texto": "O vau é vigiado e a passagem está fechada. Resolva o que ficou pendente com o Vane e a Brenn (A Quebra do Juramento)."},
	{"id": "valdoria", "pos": Vector2(578, -1700), "dir": Vector2(0, -1), "largura": 20.0, "tipo": "carroca", "texto": "Uma barricada de carroças imperiais fecha a estrada. Só passa quem tiver a lâmina final (A Lâmina Forjada no Fogo)."},
	{"id": "castelo", "pos": Vector2(584, -2008), "dir": Vector2(0, -1), "largura": 34.0, "tipo": "portao", "altura_y": 6.7, "texto": "O portão do castelo está fechado: a elite imperial guarda a escadaria. Cumpra Portões e Ruas de Valdoria."},
]

## Mais povoados, espalhados pelo mundo (centro explícito; `dir` é para onde a porta da frente das casas olha ao contrário).
const POVOADOS_LIVRES := [
	{"id": "beira_rio", "nome": "Aldeia Beira-Rio", "tipo": "vila", "centro": Vector2(-200, 270), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "rio_claro", "nome": "Fazenda Rio Claro", "tipo": "fazenda", "centro": Vector2(210, 240), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": "campos"},
	{"id": "pescador", "nome": "Cabana do Pescador", "tipo": "cabana", "centro": Vector2(-490, 200), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "pomar"},
	{"id": "pedras_altas", "nome": "Vila Pedras Altas", "tipo": "vila", "centro": Vector2(-610, -40), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": "pomar"},
	{"id": "posto_de_caca", "nome": "Posto de Caça", "tipo": "posto", "centro": Vector2(160, -270), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": "bosque"},
	{"id": "nevoa_azul", "nome": "Aldeia Névoa Azul", "tipo": "vila", "centro": Vector2(-430, -820), "dir": Vector2(1, 0), "lado": 1.0, "raio": 70.0, "liga": ""},
	{"id": "brumosa", "nome": "Fazenda Brumosa", "tipo": "fazenda", "centro": Vector2(-190, -1010), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": ""},
	{"id": "mineiros", "nome": "Acampamento dos Mineiros", "tipo": "posto", "centro": Vector2(-560, -1300), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": ""},
	{"id": "pinhal_escuro", "nome": "Vila Pinhal Escuro", "tipo": "vila", "centro": Vector2(-300, -1700), "dir": Vector2(1, 0), "lado": -1.0, "raio": 70.0, "liga": ""},
	{"id": "vale_oculto", "nome": "Fazenda do Vale Oculto", "tipo": "fazenda", "centro": Vector2(150, -1500), "dir": Vector2(1, 0), "lado": 1.0, "raio": 55.0, "liga": ""},
	{"id": "cabana_bruxa", "nome": "Cabana da Velha do Pinhal", "tipo": "cabana", "centro": Vector2(-90, -2200), "dir": Vector2(1, 0), "lado": 1.0, "raio": 40.0, "liga": ""},
	{"id": "ruptura_velha", "nome": "Aldeia Ruptura Velha", "tipo": "vila", "centro": Vector2(800, -250), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": ""},
	{"id": "vigia", "nome": "Posto de Vigia Imperial", "tipo": "posto_imperial", "centro": Vector2(385, -790), "dir": Vector2(0, -1), "lado": 1.0, "raio": 40.0, "liga": ""},
	{"id": "ocre", "nome": "Vila Ocre", "tipo": "vila", "centro": Vector2(805, -1900), "dir": Vector2(0, 1), "lado": 1.0, "raio": 70.0, "liga": ""},
	{"id": "cinzas", "nome": "Fazenda das Cinzas", "tipo": "fazenda", "centro": Vector2(385, -1620), "dir": Vector2(0, -1), "lado": 1.0, "raio": 55.0, "liga": ""},
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
