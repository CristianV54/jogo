class_name DadosMissoes
extends RefCounted
## Catálogo das missões da campanha (Bíblia de Reino de Cinzas). Só entram aqui missões que o jogo já consegue cumprir.
## Tipos de objetivo: "falar" (alvo = nome do NPC em minúsculas), "golpear", "interagir", "derrotar" (alvo = espécie),
## "visitar" (alvo = id de uma ZonaDeEvento) e "entregar" (alvo = NPC; "item" = o que gastar do inventário).
## Nenhuma missão conclui por proximidade: só por contagem real de eventos.

const CAPITULOS := {1: "Capítulo I: Refúgio do Pinhal"}
## Ordem em que o quadro de avisos oferece as missões do capítulo.
const ORDEM_CAP1 := ["C1-M1", "C1-M2", "C1-M3", "C1-M4"]

const MISSOES := {
	"C1-M1": {
		"capitulo": 1,
		"titulo": "Rotina do Exílio",
		"objetivos": [
			{"id": "vane", "texto": "Falar com Vane", "tipo": "falar", "alvo": "vane", "qtd": 1},
			{"id": "brenn", "texto": "Visitar Brenn na forja", "tipo": "falar", "alvo": "brenn", "qtd": 1},
			{"id": "espada", "texto": "Testar a espada no boneco de treino", "tipo": "golpear", "alvo": "boneco_treino", "qtd": 3},
			{"id": "tochas", "texto": "Acender as tochas de treinamento", "tipo": "interagir", "alvo": "tocha_treino", "qtd": 3},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "Quadro de avisos liberado"},
		"encerramento": "Vane: \"Você aguenta o básico. Veja o quadro de avisos na praça: sempre falta alguém para algum serviço.\"",
		"dialogos": {
			"vane": ["Torin. Antes de qualquer trabalho, quero ver como você se vira.", "Fale com a Brenn, teste a espada no boneco do pátio de treino e acenda as três tochas. Depois conversamos."],
			"brenn": ["Então o Vane mandou você testar a lâmina. Dê uma boa olhada nela: ferro bom aguenta, ferro ruim quebra no primeiro golpe.", "O pátio de treino fica ali, perto da casa dele. Bata no boneco sem dó."],
		},
	},
	"C1-M2": {
		"capitulo": 1,
		"titulo": "Colheita no Pomar Alto",
		"objetivos": [
			{"id": "macas", "texto": "Colher maçãs nas macieiras do pomar", "tipo": "interagir", "alvo": "macieira", "qtd": 6},
			{"id": "cesto", "texto": "Endireitar o cesto virado", "tipo": "interagir", "alvo": "cesto_virado", "qtd": 1},
			{"id": "oren", "texto": "Conversar com Oren", "tipo": "falar", "alvo": "oren", "qtd": 1},
			{"id": "mara", "texto": "Levar 3 maçãs à Mara, no curral", "tipo": "entregar", "alvo": "mara", "item": "maca", "qtd": 3},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "O pomar volta a abastecer o Refúgio"},
		"encerramento": "Mara: \"Olha como eles comem! Obrigada, Torin. O pomar vai abastecer o Refúgio mais um inverno.\"",
		"dialogos": {
			"oren": ["O pomar é a nossa despensa. Colha seis maçãs nas macieiras e endireite aquele cesto que o vento derrubou.", "Depois leve três maçãs à Mara. Os animais também precisam de ânimo."],
		},
	},
	"C1-M3": {
		"capitulo": 1,
		"titulo": "Guardião do Cercado e da Estrada",
		"objetivos": [
			{"id": "lobos", "texto": "Afastar os lobos que rondam o cercado", "tipo": "derrotar", "alvo": "lobo", "qtd": 3},
			{"id": "cavalo", "texto": "Encontrar o cavalo fugido, na estrada leste", "tipo": "interagir", "alvo": "cavalo_perdido", "qtd": 1},
			{"id": "devolver", "texto": "Levar o cavalo de volta ao curral", "tipo": "visitar", "alvo": "curral_cavalo", "qtd": 1},
		],
		"recompensa": {"itens": {"couro": 2}, "texto": "Trilha do Pinhal revelada"},
		"encerramento": "Mara: \"Ele voltou inteiro! A Tessa viu pegadas estranhas no pinhal, a trilha escondida ao norte. Vá com cuidado.\"",
		"dialogos": {
			"mara": ["Lobos nas ovelhas e um cavalo que fugiu pela estrada leste! Proteja o cercado e traga o cavalo de volta, por favor.", "Para trazê-lo, monte nele: ele só obedece a quem tem calma."],
		},
	},
	"C1-M4": {
		"capitulo": 1,
		"titulo": "Resgate nas Sombras do Pinhal",
		"objetivos": [
			{"id": "clareira", "texto": "Encontrar a clareira no pinhal (trilha norte)", "tipo": "visitar", "alvo": "clareira_pinhal", "qtd": 1},
			{"id": "batedores", "texto": "Derrotar os batedores imperiais", "tipo": "derrotar", "alvo": "batedor", "qtd": 3},
			{"id": "estaca", "texto": "Arrancar a estaca de Ferro Negro", "tipo": "interagir", "alvo": "estaca_ferro", "qtd": 3},
			{"id": "fagulha", "texto": "Alimentar o dragão ferido com carne", "tipo": "entregar", "alvo": "fagulha", "item": "carne", "qtd": 1},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "Fagulha passa a acompanhar Torin; o portão norte abre"},
		"encerramento": "Um dragãozinho ferido ergue a cabeça e solta uma faísca. Fagulha agora acompanha você. Halk abrirá o portão norte.",
		"dialogos": {
			"tessa": ["Vi rastros de botas imperiais na trilha escondida do pinhal, ao norte. Eles prendem algo lá. Vá ver, mas leve carne, pelo que ouvi é um dragão.", "Batedores do Império costumam andar em três. Cuidado."],
		},
	},
}
