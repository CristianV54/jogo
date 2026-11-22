class_name DadosMissoes
extends RefCounted
## Catálogo das missões da campanha (Bíblia de Reino de Cinzas). Só entram aqui missões que o jogo já consegue cumprir.
## Tipos de objetivo: "falar" (alvo = nome do NPC em minúsculas), "golpear", "interagir", "derrotar" (alvo = espécie),
## "visitar" (alvo = id de uma ZonaDeEvento) e "entregar" (alvo = NPC; "item" = o que gastar do inventário).
## Nenhuma missão conclui por proximidade: só por contagem real de eventos.

const CAPITULOS := {1: "Capítulo I: Refúgio do Pinhal", 2: "Capítulo II: Bosque Velado e Mina das Correntes", 3: "Capítulo III: Ruptura e Fortaleza de Ferrogris", 4: "Capítulo IV: Cratera de Ignis", 5: "Capítulo V: Valdoria e o Castelo Imperial"}
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
		"encerramento": "Vane: \"Você aguenta o básico. Veja o quadro de avisos na praça: sempre falta alguém para algum serviço. E obrigado por não perguntar por que eu preciso saber.\"",
		"dialogos": {
			"vane": ["Torin. Antes de qualquer trabalho, quero ver como você se vira.", "Eu prometi proteger este bando, e proteger dá trabalho. Preciso saber que você aguenta o básico antes que o Império apareça de novo.", "Fale com a Brenn, teste a espada no boneco do pátio e acenda as três tochas. Depois conversamos."],
			"brenn": ["Então o Vane mandou você testar a lâmina. Dê uma boa olhada nela: ferro bom aguenta, ferro ruim quebra no primeiro golpe.", "O pátio de treino fica ali, perto da casa dele. Bata no boneco sem dó. E nunca confie em arma que brilha demais."],
		},
	},
	"C1-M2": {
		"capitulo": 1,
		"titulo": "Colheita no Pomar Alto",
		"requer": "C1-M1",
		"auto_apos": "C1-M1",
		"objetivos": [
			{"id": "macas", "texto": "Colher maçãs nas macieiras do pomar", "tipo": "interagir", "alvo": "macieira", "qtd": 6},
			{"id": "cesto", "texto": "Endireitar o cesto virado", "tipo": "interagir", "alvo": "cesto_virado", "qtd": 1},
			{"id": "oren", "texto": "Conversar com Oren", "tipo": "falar", "alvo": "oren", "qtd": 1},
			{"id": "mara", "texto": "Levar 3 maçãs à Mara, no curral", "tipo": "entregar", "alvo": "mara", "item": "maca", "qtd": 3},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "O pomar volta a abastecer o Refúgio"},
		"encerramento": "Mara: \"Olha como eles comem! Obrigada, Torin. O pomar vai abastecer o Refúgio mais um inverno.\"",
		"dialogos": {
			"oren": ["O pomar é a nossa despensa e a nossa teimosia. Se o Império tomar isso, o Refúgio perde o direito de alimentar a própria gente.", "Colha seis maçãs, endireite o cesto que o vento derrubou e leve três à Mara. Os animais também precisam de ânimo."],
		},
	},
	"C1-M3": {
		"capitulo": 1,
		"titulo": "Guardião do Cercado e da Estrada",
		"requer": "C1-M2",
		"auto_apos": "C1-M2",
		"objetivos": [
			{"id": "lobos", "texto": "Afastar os lobos que rondam o cercado", "tipo": "derrotar", "alvo": "lobo", "qtd": 3},
			{"id": "cavalo", "texto": "Encontrar o cavalo fugido, na estrada leste", "tipo": "interagir", "alvo": "cavalo_perdido", "qtd": 1},
			{"id": "devolver", "texto": "Levar o cavalo de volta ao curral", "tipo": "visitar", "alvo": "curral_cavalo", "qtd": 1},
		],
		"recompensa": {"itens": {"couro": 2}, "texto": "Trilha do Pinhal revelada"},
		"encerramento": "Mara: \"Ele voltou inteiro! A Tessa viu pegadas estranhas no pinhal, a trilha escondida ao norte. Vá com cuidado.\"",
		"dialogos": {
			"mara": ["Lobos nas ovelhas e um cavalo fugido pela estrada leste! Eu cuido deles como família. Proteja o cercado e traga o cavalo de volta, por favor.", "Para trazê-lo, monte nele: ele só obedece a quem tem calma."],
		},
	},
	"C1-M4": {
		"capitulo": 1,
		"titulo": "Resgate nas Sombras do Pinhal",
		"requer": "C1-M3",
		"auto_apos": "C1-M3",
		"objetivos": [
			{"id": "clareira", "texto": "Encontrar a clareira no pinhal (trilha norte)", "tipo": "visitar", "alvo": "clareira_pinhal", "qtd": 1},
			{"id": "batedores", "texto": "Derrotar os batedores imperiais", "tipo": "derrotar", "alvo": "batedor", "qtd": 3},
			{"id": "estaca", "texto": "Arrancar a estaca de Ferro Negro", "tipo": "interagir", "alvo": "estaca_ferro", "qtd": 3},
			{"id": "fagulha", "texto": "Alimentar o dragão ferido com carne", "tipo": "entregar", "alvo": "fagulha", "item": "carne", "qtd": 1},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "Fagulha passa a acompanhar Torin; o portão norte abre"},
		"encerramento": "Um dragãozinho ferido ergue a cabeça e solta uma faísca. Ele não foge de você: confia, mesmo ferido. Fagulha agora acompanha você. Halk abrirá o portão norte.",
		"dialogos": {
			"tessa": ["Vi rastros de botas imperiais na trilha escondida do pinhal, ao norte. Eles prendem algo lá, e ouvi um som que não era de homem nem de lobo. Leve carne: pelo que ouvi, é um dragão.", "Batedores do Império costumam andar em três. E Torin: se for mesmo um dragão, não conte ao Vane antes de ver com os próprios olhos."],
		},
	},
	"C2-M1": {
		"capitulo": 2,
		"titulo": "Caçada e Rastreamento",
		"requer": "C1-M4",
		"auto_apos": "C1-M4",
		"objetivos": [
			{"id": "pegadas", "texto": "Seguir as pegadas de lobo até a toca (não as botas)", "tipo": "visitar", "alvo": "toca_do_lobo", "qtd": 1},
			{"id": "couros", "texto": "Coletar couros ou presas da caça", "tipo": "coletar", "alvo": ["couro", "presa"], "qtd": 4},
			{"id": "raizes", "texto": "Colher raízes medicinais no Riacho da Névoa", "tipo": "coletar", "alvo": "raiz", "qtd": 4},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "Elda confia em você"},
		"encerramento": "Elda: \"Você lê rastro melhor que muito veterano. Fale com a Sava, na mina: ela cuida dos filhotes de dragão que o Império prendeu.\"",
		"dialogos": {
			"elda": ["Rastro bom a gente segue com calma. Há dois conjuntos de pegadas saindo do acampamento: as de lobo levam à toca, as de bota levam a um beco sem saída.", "Não mate por diversão, Torin. O bosque já perdeu bicho demais para o Ferro Negro. Traga quatro couros ou presas e quatro raízes do riacho.", "E fique longe do urso da margem norte: ele não defende território. Está enlouquecido."],
		},
	},
	"C2-M2": {
		"capitulo": 2,
		"titulo": "Asas nas Gaiolas",
		"requer": "C2-M1",
		"auto_apos": "C2-M1",
		"objetivos": [
			{"id": "chaves", "texto": "Tirar as chaves dos guardas da mina", "tipo": "coletar", "alvo": "chave", "qtd": 3},
			{"id": "jaulas", "texto": "Libertar os Filhotes de Asa nas jaulas", "tipo": "interagir", "alvo": "jaula", "qtd": 3},
		],
		"recompensa": {"itens": {"maca": 2}, "texto": "Os filhotes voltam ao céu"},
		"encerramento": "Sava: \"Olha eles voando! Procure o Borin, o mineiro fugido, perto do riacho. Ele sabe o que prende os dragões.\"",
		"dialogos": {
			"sava": ["Eles não comem, não dormem: o Ferro Negro os deixa tontos. São filhotes, Torin. Perto do que os pais foram, são crianças.", "Há três jaulas: na encosta, na triagem e no depósito. Cada guarda tem a chave. Tire a chave dele e abra. E fale baixo: eles aprenderam a ter medo de voz de homem."],
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
		"encerramento": "O obelisco desaba. A névoa recua, os animais correm para longe e Fagulha estremece, sentindo as correntes do mundo afrouxarem. Mas o capataz da mina ouviu o estrondo.",
		"dialogos": {
			"borin": ["Eu cavei sete meses naquele buraco. O obelisco no meio da mina é o que deixa os dragões loucos: ele os prende por correntes que ninguém vê.", "Achei uma carta do Imperador Solon na mesa do capataz. Dizia que o medo é preferível ao caos. Passei a noite sem dormir, pensando em que tipo de gente escreve uma frase dessas.", "Não adianta bater no corpo dele. Quebre as três âncoras ao redor e a pedra cai sozinha. Os guardas vão tentar impedir."],
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
		"encerramento": "Gorath tomba, e entre os escombros ficam fragmentos do obelisco. A estrada leste para a Fortaleza de Ferrogris está livre.",
		"dialogos": {
			"borin": ["O Gorath não é louco: é obediente. Isso é pior. Ele tem filhos na vila do Império e vive apavorado de falhar com o Solon.", "Mesmo assim, ele vai tentar esmagar você. Não confunda explicação com perdão."],
		},
	},
	"C3-M1": {
		"capitulo": 3,
		"titulo": "A Quebra do Juramento",
		"requer": "C2-M4",
		"auto_apos": "C2-M4",
		"objetivos": [
			{"id": "confronto", "texto": "Chegar ao Acampamento da Ruptura e ouvir o Vane", "tipo": "interagir", "alvo": "confronto_visto", "qtd": 1},
			{"id": "forja", "texto": "Levar 3 Ferro Negro bruto à Brenn para o equipamento reforçado", "tipo": "entregar", "alvo": "brenn", "item": "minerio_bruto", "qtd": 3},
		],
		"recompensa": {"itens": {"maca": 2}, "texto": "Equipamento reforçado: golpe +8 e vida máxima +20"},
		"encerramento": "Brenn: \"Pronto. Ferro Negro bem batido não serve ao Império, serve contra ele. Mas é só um escudo, Torin: a lâmina de verdade vem depois. A ponte quebrada tem vau a norte, e Ferrogris é por ali.\"",
		"dialogos": {
			"brenn": ["Eu avisei que o Vane ia acabar assim. Ele não perdeu o juízo de uma vez: foi perdendo aos poucos, a cada vitória que o Ferro Negro lhe deu.", "Traga o Ferro Negro bruto que você tirou do obelisco. Se eu bater direito, serve para reforçar sua espada e sua armadura. Bruto, ele ainda obedece às runas: eu preciso de fogo para tirar isso dele."],
		},
	},
	"C3-M2": {
		"capitulo": 3,
		"titulo": "Brecha nas Muralhas",
		"requer": "C3-M1",
		"auto_apos": "C3-M1",
		"objetivos": [
			{"id": "guardas", "texto": "Derrotar os guardas de Ferrogris", "tipo": "derrotar", "alvo": "guarda_ferrogris", "qtd": 4},
			{"id": "caes", "texto": "Derrotar os cães de guerra do canil", "tipo": "derrotar", "alvo": "cao_guerra", "qtd": 2},
			{"id": "aco", "texto": "Pegar 3 Aços Imperiais no depósito", "tipo": "coletar", "alvo": "aco_imperial", "qtd": 3},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "Brecha aberta nas muralhas"},
		"encerramento": "As muralhas externas já não protegem o pátio. Os presos devem estar na prisão do lado oeste e nas jaulas do lado leste.",
	},
	"C3-M3": {
		"capitulo": 3,
		"titulo": "Libertação dos Cativos",
		"requer": "C3-M2",
		"auto_apos": "C3-M2",
		"objetivos": [
			{"id": "chaves", "texto": "Tirar as chaves dos guardas da prisão, das jaulas e da sala de comando", "tipo": "coletar", "alvo": "chave", "qtd": 3},
			{"id": "setores", "texto": "Abrir os 3 setores: cela dos civis, cela dos soldados e jaula do dragão", "tipo": "interagir", "alvo": "setor_prisao", "qtd": 3},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "Os cativos estão livres"},
		"encerramento": "Civis, soldados e um dragão jovem fogem pelo portão. Fagulha ruge baixo, reconhecendo um dos seus. Uma voz seca ordena das muralhas: o General Kaelor sai da sala de comando.",
	},
	"C3-M4": {
		"capitulo": 3,
		"titulo": "O Comandante de Ferrogris",
		"requer": "C3-M3",
		"auto_apos": "C3-M3",
		"objetivos": [
			{"id": "kaelor", "texto": "Derrotar o General Kaelor no pátio central", "tipo": "derrotar", "alvo": "kaelor", "qtd": 1},
		],
		"recompensa": {"itens": {"couro": 2}, "texto": "O portão dos fundos se abre para a Cratera de Ignis"},
		"encerramento": "Kaelor tomba sem gritar. O portão dos fundos da fortaleza se abre: o caminho segue para a Cratera de Ignis.",
	},
	"C4-M1": {
		"capitulo": 4,
		"titulo": "Travessia da Brasa",
		"requer": "C3-M4",
		"auto_apos": "C3-M4",
		"objetivos": [
			{"id": "minerios", "texto": "Coletar 4 minérios vulcânicos (calor e fumaça no caminho)", "tipo": "coletar", "alvo": "minerio_vulcanico", "qtd": 4},
			{"id": "alojamento", "texto": "Chegar ao alojamento dos trabalhadores", "tipo": "visitar", "alvo": "alojamento_ignis", "qtd": 1},
		],
		"recompensa": {"itens": {"maca": 2}, "texto": "Você atravessou a Cratera"},
		"encerramento": "O calor aperta, mas o alojamento está de pé. Os trabalhadores sabem como as forjas negras mantêm Ignis-Maw acorrentado.",
		"dialogos": {
			"tarn": ["Você veio pela ponte de basalto? Então já viu o que o Império construiu sobre o vulcão. Eu ajudei a levantar cada tijolo e me arrependo de cada um.", "Três forjas negras alimentam as correntes de Ignis-Maw. Desligue as três, uma de cada vez, e as correntes enfraquecem."],
		},
	},
	"C4-M2": {
		"capitulo": 4,
		"titulo": "Desativar as Forjas Negras",
		"requer": "C4-M1",
		"auto_apos": "C4-M1",
		"objetivos": [
			{"id": "fornalhas", "texto": "Desligar as 3 fornalhas (válvulas, canos, runas)", "tipo": "interagir", "alvo": "fornalha_apagada", "qtd": 3},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "As forjas negras se apagaram"},
		"encerramento": "As três forjas apagam e as correntes afrouxam. Algo enorme se mexe na caldeira ancestral, ao norte.",
		"dialogos": {
			"tarn": ["Cada fornalha tem o seu truque: válvulas de vapor, canos de lava e runas que pedem ordem.", "Quando as três apagarem, Ignis-Maw acorda de vez. Esteja pronto."],
		},
	},
	"C4-M3": {
		"capitulo": 4,
		"titulo": "O Colosso Acorrentado",
		"requer": "C4-M2",
		"auto_apos": "C4-M2",
		"objetivos": [
			{"id": "ancoras", "texto": "Quebrar as 4 âncoras do Ignis-Maw (cuidado com fogo, cauda e ondas de calor)", "tipo": "destruir", "alvo": "ancora", "qtd": 4},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "Ignis-Maw está livre"},
		"encerramento": "A última âncora cai. Ignis-Maw ruge, ergue-se e voa para longe, derrubando parte das forjas. Torin: \"Ele não era um monstro. Só tentava sobreviver à dor.\" Fagulha responde com um rugido baixo. Uma escama ancestral ficou na arena.",
	},
	"C4-M4": {
		"capitulo": 4,
		"titulo": "A Lâmina Forjada no Fogo",
		"requer": "C4-M3",
		"auto_apos": "C4-M3",
		"objetivos": [
			{"id": "minerios", "texto": "Entregar 4 minérios vulcânicos à Brenn", "tipo": "entregar", "alvo": "brenn", "item": "minerio_vulcanico", "qtd": 4},
			{"id": "escama", "texto": "Entregar a escama ancestral à Brenn", "tipo": "entregar", "alvo": "brenn", "item": "escama_ancestral", "qtd": 1},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "Lâmina final: golpe +14"},
		"encerramento": "Brenn: \"Ferro Negro, brasa do vulcão e escama de dragão livre. Essa liga não obedece mais a runa nenhuma. Essa lâmina não foi feita para o Império, Torin: foi feita para acabar com ele. Valdoria espera ao norte.\"",
		"dialogos": {
			"brenn": ["Trouxe tudo? Quatro minérios vulcânicos e a escama. Dá cá, vou acender a forja de campo.", "O Ferro Negro bruto obedece às runas do obelisco: ainda carrega a marca do Império. Mas misturado à brasa vulcânica e à escama de um dragão livre, ele perde a obediência. Não é o metal que resiste, Torin. É a liga."],
		},
	},
	"C5-M1": {
		"capitulo": 5,
		"titulo": "Portões e Ruas de Valdoria",
		"requer": "C4-M4",
		"auto_apos": "C4-M4",
		"objetivos": [
			{"id": "mercado", "texto": "Atravessar o Distrito do Comerciante", "tipo": "visitar", "alvo": "mercado_valdoria", "qtd": 1},
			{"id": "suprimento", "texto": "Obter suprimentos (fazer uma troca com um mercador)", "tipo": "interagir", "alvo": "suprimento", "qtd": 1},
			{"id": "elite", "texto": "Derrotar 4 guardas de elite", "tipo": "derrotar", "alvo": "guarda_elite", "qtd": 4},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "A escadaria do castelo está livre"},
		"encerramento": "A elite imperial cai. Os moradores espiam das janelas: a escadaria do castelo está livre.",
		"dialogos": {
			"suri": ["Psiu. Chaves e mapas, só para quem sabe perguntar. O castelo tem pátio, salão do trono e um obelisco enorme atrás do trono.", "Dizem que o Vane espera no pátio do duelo. E que ele já não é o mesmo: ri pouco, e quando ri, ninguém por perto ri junto."],
		},
	},
	"C5-M2": {
		"capitulo": 5,
		"titulo": "O Duelo de Vane",
		"requer": "C5-M1",
		"auto_apos": "C5-M1",
		"objetivos": [
			{"id": "vane", "texto": "Derrotar o Vane no pátio do duelo", "tipo": "derrotar", "alvo": "vane_duelo", "qtd": 1},
		],
		"recompensa": {"itens": {"carne": 2}, "texto": "O portão do salão do trono se abre"},
		"encerramento": "Vane cai de joelhos, o Ferro Negro apagando em suas mãos. O portão do salão do trono se abre.",
	},
	"C5-M3": {
		"capitulo": 5,
		"titulo": "Quebrar o Grande Obelisco",
		"requer": "C5-M2",
		"auto_apos": "C5-M2",
		"objetivos": [
			{"id": "focos", "texto": "Desativar os 4 focos de energia do salão", "tipo": "destruir", "alvo": "ancora", "qtd": 4},
		],
		"recompensa": {"itens": {"maca": 3}, "texto": "O obelisco se apagou"},
		"encerramento": "Os quatro focos caem e a luz negra do Grande Obelisco se apaga. No trono, o Imperador Solon se levanta.",
	},
	"C5-M4": {
		"capitulo": 5,
		"titulo": "A Queda do Imperador Solon",
		"requer": "C5-M3",
		"auto_apos": "C5-M3",
		"objetivos": [
			{"id": "solon", "texto": "Derrotar o Imperador Solon (com a ajuda do Fagulha)", "tipo": "derrotar", "alvo": "solon", "qtd": 1},
		],
		"recompensa": {"itens": {}, "texto": "O Império caiu"},
		"encerramento": "O Imperador Solon cai. O Império de Drakkar acabou.",
	},
}
