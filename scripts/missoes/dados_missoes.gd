class_name DadosMissoes
extends RefCounted
## Catálogo das missões da campanha (Bíblia de Reino de Cinzas). Só entram aqui missões que o jogo já consegue cumprir.
## Tipos de objetivo: "falar" (alvo = nome do NPC em minúsculas), "golpear", "interagir", "derrotar" (alvo = espécie),
## "visitar" (alvo = id de uma ZonaDeEvento) e "entregar" (alvo = NPC; "item" = o que gastar do inventário).
## Nenhuma missão conclui por proximidade: só por contagem real de eventos.

const CAPITULOS := {1: "Capítulo I: Refúgio do Pinhal", 2: "Capítulo II: Bosque Velado e Mina das Correntes"}
## Ordem em que o quadro de avisos oferece as missões do capítulo.
const ORDEM_CAP1 := ["C1-M1", "C1-M2", "C1-M3", "C1-M4"]
## No capítulo II as missões são oferecidas pelos NPCs (Elda e Sava) ou começam em cadeia.

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
	"C2-M1": {
		"capitulo": 2,
		"titulo": "Caçada e Rastreamento",
		"requer": "C1-M4",
		"objetivos": [
			{"id": "pegadas", "texto": "Seguir as pegadas de lobo até a toca (não as botas)", "tipo": "visitar", "alvo": "toca_do_lobo", "qtd": 1},
			{"id": "couros", "texto": "Coletar couros ou presas da caça", "tipo": "coletar", "alvo": ["couro", "presa"], "qtd": 4},
			{"id": "raizes", "texto": "Colher raízes medicinais no Riacho da Névoa", "tipo": "coletar", "alvo": "raiz", "qtd": 4},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "Elda confia em você"},
		"encerramento": "Elda: \"Você lê rastro melhor que muito veterano. Fale com a Sava, na mina: ela cuida dos filhotes de dragão que o Império prendeu.\"",
		"dialogos": {
			"elda": ["Rastro bom a gente segue com calma. Há dois conjuntos de pegadas saindo do acampamento: as de lobo levam à toca, as de bota levam a um beco sem saída.", "Traga quatro couros ou presas da caça e quatro raízes do riacho. Evite o urso da margem norte."],
		},
	},
	"C2-M2": {
		"capitulo": 2,
		"titulo": "Asas nas Gaiolas",
		"requer": "C2-M1",
		"objetivos": [
			{"id": "chaves", "texto": "Tirar as chaves dos guardas da mina", "tipo": "coletar", "alvo": "chave", "qtd": 3},
			{"id": "jaulas", "texto": "Libertar os Filhotes de Asa nas jaulas", "tipo": "interagir", "alvo": "jaula", "qtd": 3},
		],
		"recompensa": {"itens": {"maca": 2}, "texto": "Os filhotes voltam ao céu"},
		"encerramento": "Sava: \"Olha eles voando! Procure o Borin, o mineiro fugido, perto do riacho. Ele sabe o que prende os dragões.\"",
		"dialogos": {
			"sava": ["Eles não comem, não dormem: o Ferro Negro os deixa tontos. Há três jaulas na encosta, na triagem e no depósito.", "Cada jaula tem um guarda com a chave. Tire a chave dele e abra."],
		},
	},
	"C2-M3": {
		"capitulo": 2,
		"titulo": "Queda do Primeiro Obelisco",
		"requer": "C2-M2",
		"auto_apos": "C2-M2",
		"objetivos": [
			{"id": "borin", "texto": "Ouvir o mineiro Borin, perto do riacho", "tipo": "falar", "alvo": "borin", "qtd": 1},
			{"id": "ancoras", "texto": "Destruir as âncoras do obelisco", "tipo": "destruir", "alvo": "ancora", "qtd": 3},
			{"id": "minerio", "texto": "Coletar o Ferro Negro bruto que sobra", "tipo": "coletar", "alvo": "minerio_bruto", "qtd": 3},
		],
		"recompensa": {"itens": {"maca": 2}, "texto": "A névoa do bosque recua"},
		"encerramento": "O obelisco desaba. A névoa recua, os animais correm para longe e os filhotes que restavam se vão. Mas o capataz da mina ouviu o estrondo.",
		"dialogos": {
			"borin": ["Eu cavei sete meses naquele buraco. O obelisco no meio da mina é o que deixa os dragões loucos: ele os prende por correntes invisíveis.", "Não adianta bater no corpo dele. Quebre as três âncoras ao redor, e a pedra cai sozinha. Os guardas vão tentar impedir."],
		},
	},
	"C2-M4": {
		"capitulo": 2,
		"titulo": "O Capataz da Mina",
		"requer": "C2-M3",
		"auto_apos": "C2-M3",
		"objetivos": [
			{"id": "gorath", "texto": "Derrotar o capataz Gorath na praça da mina", "tipo": "derrotar", "alvo": "gorath", "qtd": 1},
		],
		"recompensa": {"itens": {"couro": 2}, "texto": "A estrada para Ferrogris se abre"},
		"encerramento": "Gorath tomba. A estrada leste para a Fortaleza de Ferrogris está livre.",
	},
}
