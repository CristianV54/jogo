class_name Itens
extends RefCounted
## Catálogo dos itens do jogo: nome, descrição, modelo 3D (usado no chão e no ícone do inventário) e efeito.
## `cura` > 0 recupera vida ao comer; `fome` > 0 mata essa fome. `preco` é o valor de base em moedas (quem vende ao
## mercador recebe metade). `dano` faz do item uma ARMA que se equipa (com `arma`: como ela fica na mão); `defesa` faz
## dele uma ARMADURA (fração do dano que ela tira, com `veste`: as peças presas aos ossos). `ferramenta` diz para que serve.

const ORDEM := ["moeda", "maca", "pao", "raiz", "carne", "peixe_assado", "couro", "la", "presa", "madeira", "minerio_de_ferro", "lingote_de_ferro", "picareta", "machado", "espada_curta", "espada_longa", "katana", "armadura_de_couro", "armadura_de_ferro", "minerio_bruto", "chave", "aco_imperial", "minerio_vulcanico", "escama_ancestral"]

const DADOS := {
	"moeda": {"nome": "Moeda", "descricao": "Moeda de Valdoria. Compra-se e vende-se com os mercadores (E no balcão).", "modelo": "res://assets/models/itens/moeda/moeda.glb", "cura": 0, "preco": 1},
	"pao": {"nome": "Pão", "descricao": "Broa de trigo. Mata bastante fome.", "modelo": "res://assets/models/itens/pao/pao.glb", "cura": 6, "fome": 30, "preco": 4},
	"peixe_assado": {"nome": "Peixe assado", "descricao": "Peixe no espeto, dos pescadores. Mata a fome e recupera 14 de vida.", "modelo": "res://assets/models/itens/peixe_assado/peixe_assado.glb", "cura": 14, "fome": 28, "preco": 5},
	"madeira": {"nome": "Madeira", "descricao": "Toras amarradas. Serve para cabos e para a forja.", "modelo": "res://assets/models/itens/madeira/madeira.glb", "cura": 0, "preco": 2},
	"minerio_de_ferro": {"nome": "Minério de ferro", "descricao": "Pedra com veios de ferro, tirada com picareta. Na forja, dois viram um lingote.", "modelo": "res://assets/models/itens/minerio_de_ferro/minerio_de_ferro.glb", "cura": 0, "preco": 4},
	"lingote_de_ferro": {"nome": "Lingote de ferro", "descricao": "Ferro fundido em barra. É do que se fazem espadas, machados e armaduras.", "modelo": "res://assets/models/itens/lingote_de_ferro/lingote_de_ferro.glb", "cura": 0, "preco": 10},
	"picareta": {"nome": "Picareta", "descricao": "Com ela na bolsa dá para minerar os veios de ferro (E no veio).", "modelo": "res://assets/models/armas/picareta/picareta.glb", "cura": 0, "preco": 18, "ferramenta": "minerar"},
	"espada_curta": {"nome": "Espada curta", "descricao": "A espada com que o Torin começa. Dano 22.", "modelo": "res://assets/models/armas/shortsword.glb", "cura": 0, "preco": 12, "dano": 22,
		"arma": {"escala": 0.25, "giro": Vector3(180, 0, 0), "deslocamento": Vector3(-0.017, 0.098, 0.006), "empunhadura": Vector3(0, 0, 0.8)}},
	"machado": {"nome": "Machado", "descricao": "Machado de lenhador, pesado. Dano 27.", "modelo": "res://assets/models/armas/simpleaxe.glb", "cura": 0, "preco": 26, "dano": 27,
		"arma": {"escala": 0.28, "giro": Vector3(0, 0, -90), "deslocamento": Vector3(-0.017, 0.098, 0.006), "empunhadura": Vector3(0, -1.0, 0)}},
	"espada_longa": {"nome": "Espada longa", "descricao": "Lâmina de soldado, forjada com três lingotes. Dano 32.", "modelo": "res://assets/models/armas/longsword.glb", "cura": 0, "preco": 45, "dano": 32,
		"arma": {"escala": 0.2, "giro": Vector3(180, 0, 0), "deslocamento": Vector3(-0.017, 0.098, 0.006), "empunhadura": Vector3(0, 0, 0.78)}},
	"katana": {"nome": "Lâmina de Valdoria", "descricao": "A melhor lâmina que um ferreiro da ilha sabe fazer. Dano 44.", "modelo": "res://assets/models/armas/katana.glb", "cura": 0, "preco": 90, "dano": 44,
		"arma": {"escala": 0.2, "giro": Vector3(0, 0, 0), "deslocamento": Vector3(-0.017, 0.098, 0.006), "empunhadura": Vector3(0, 0, -0.65)}},
	"armadura_de_couro": {"nome": "Armadura de couro", "descricao": "Peitoral e ombreiras de couro curtido. Tira um quinto do dano.", "modelo": "res://assets/models/armaduras/peitoral_de_couro/peitoral_de_couro.glb", "cura": 0, "preco": 30, "defesa": 0.2,
		"veste": {"peito": "res://assets/models/armaduras/peitoral_de_couro/peitoral_de_couro.glb", "ombro": "res://assets/models/armaduras/ombreira_de_couro/ombreira_de_couro.glb"}},
	"armadura_de_ferro": {"nome": "Armadura de ferro", "descricao": "Peitoral e ombreiras de ferro batido. Tira quase metade do dano.", "modelo": "res://assets/models/armaduras/peitoral_de_ferro/peitoral_de_ferro.glb", "cura": 0, "preco": 85, "defesa": 0.45,
		"veste": {"peito": "res://assets/models/armaduras/peitoral_de_ferro/peitoral_de_ferro.glb", "ombro": "res://assets/models/armaduras/ombreira_de_ferro/ombreira_de_ferro.glb"}},
	"raiz": {
		"nome": "Raiz medicinal",
		"descricao": "Raiz amarga do Riacho da Névoa. Mascada, recupera 12 de vida.",
		"modelo": "res://assets/models/itens/raiz/raiz.glb",
		"cura": 12, "fome": 6, "preco": 3,
	},
	"minerio_bruto": {
		"nome": "Ferro Negro bruto",
		"descricao": "Minério com veios azuis que pulsam de leve. A Brenn sabe o que fazer com ele (ainda sem uso).",
		"modelo": "res://assets/models/itens/minerio_bruto/minerio_bruto.glb",
		"cura": 0,
	},
	"aco_imperial": {
		"nome": "Aço Imperial",
		"descricao": "Barras de aço do depósito de Ferrogris, marcadas com a listra do Império. Brenn dá valor a isso (ainda sem uso).",
		"modelo": "res://assets/models/itens/aco_imperial/aco_imperial.glb",
		"cura": 0,
	},
	"minerio_vulcanico": {
		"nome": "Minério vulcânico",
		"descricao": "Basalto com veios de brasa, tirado da Cratera de Ignis. A Brenn precisa de quatro para a lâmina final.",
		"modelo": "res://assets/models/itens/minerio_vulcanico/minerio_vulcanico.glb",
		"cura": 0,
	},
	"escama_ancestral": {
		"nome": "Escama ancestral",
		"descricao": "Escama que Ignis-Maw soltou ao se libertar. Ainda está morna. A Brenn sabe forjar com ela.",
		"modelo": "res://assets/models/itens/escama_ancestral/escama_ancestral.glb",
		"cura": 0,
	},
	"chave": {
		"nome": "Chave de jaula",
		"descricao": "Chave de ferro tirada de um guarda da mina. Abre uma jaula de Filhote de Asa.",
		"modelo": "res://assets/models/itens/chave/chave.glb",
		"cura": 0,
	},
	"maca": {
		"nome": "Maçã",
		"descricao": "Maçã do Pomar Alto, a despensa do Refúgio. Comer recupera 8 de vida.",
		"modelo": "res://assets/models/itens/maca/maca.glb",
		"cura": 8, "fome": 14, "preco": 2,
	},
	"carne": {
		"nome": "Carne",
		"descricao": "Carne fresca de caça ou de criação. Comer recupera 20 de vida.",
		"modelo": "res://assets/models/itens/carne/carne.glb",
		"cura": 20, "fome": 35, "preco": 6,
	},
	"couro": {
		"nome": "Couro",
		"descricao": "Pele curtida. Com três, um ferreiro faz uma armadura de couro.",
		"modelo": "res://assets/models/itens/couro/couro.glb",
		"cura": 0, "preco": 8,
	},
	"la": {
		"nome": "Lã",
		"descricao": "Lã de ovelha. Os mercadores compram.",
		"modelo": "res://assets/models/itens/la/la.glb",
		"cura": 0, "preco": 5,
	},
	"presa": {
		"nome": "Presa",
		"descricao": "Presa de javali. Entra na Lâmina de Valdoria; os mercadores também compram.",
		"modelo": "res://assets/models/itens/presa/presa.glb",
		"cura": 0, "preco": 9,
	},
}


static func nome(id: String) -> String:
	return DADOS.get(id, {}).get("nome", id)


## Receitas da forja: o que entra e o que sai. Qualquer ferreiro (bigorna) faz.
const RECEITAS := [
	{"sai": "lingote_de_ferro", "qtd": 1, "entra": {"minerio_de_ferro": 2}},
	{"sai": "picareta", "qtd": 1, "entra": {"lingote_de_ferro": 1, "madeira": 1}},
	{"sai": "machado", "qtd": 1, "entra": {"lingote_de_ferro": 2, "madeira": 1}},
	{"sai": "espada_longa", "qtd": 1, "entra": {"lingote_de_ferro": 3, "couro": 1}},
	{"sai": "katana", "qtd": 1, "entra": {"lingote_de_ferro": 6, "presa": 2, "couro": 1}},
	{"sai": "armadura_de_couro", "qtd": 1, "entra": {"couro": 3, "la": 1}},
	{"sai": "armadura_de_ferro", "qtd": 1, "entra": {"lingote_de_ferro": 5, "couro": 2}},
]


static func preco(id: String) -> int:
	return int(DADOS.get(id, {}).get("preco", 0))
