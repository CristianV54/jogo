class_name Itens
extends RefCounted
## Catálogo dos itens do jogo: nome, descrição, modelo 3D (usado no chão e no ícone do inventário) e efeito.
## `cura` > 0: o item é comestível e recupera essa vida ao ser usado.

const ORDEM := ["maca", "raiz", "carne", "couro", "la", "presa", "minerio_bruto", "chave"]

const DADOS := {
	"raiz": {
		"nome": "Raiz medicinal",
		"descricao": "Raiz amarga do Riacho da Névoa. Mascada, recupera 12 de vida.",
		"modelo": "res://assets/models/itens/raiz/raiz.glb",
		"cura": 12,
	},
	"minerio_bruto": {
		"nome": "Ferro Negro bruto",
		"descricao": "Minério com veios azuis que pulsam de leve. A Brenn sabe o que fazer com ele (ainda sem uso).",
		"modelo": "res://assets/models/itens/minerio_bruto/minerio_bruto.glb",
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
		"cura": 8,
	},
	"carne": {
		"nome": "Carne",
		"descricao": "Carne fresca de caça ou de criação. Comer recupera 20 de vida.",
		"modelo": "res://assets/models/itens/carne/carne.glb",
		"cura": 20,
	},
	"couro": {
		"nome": "Couro",
		"descricao": "Pele curtida. Material para a forja da Brenn (ainda sem uso).",
		"modelo": "res://assets/models/itens/couro/couro.glb",
		"cura": 0,
	},
	"la": {
		"nome": "Lã",
		"descricao": "Lã de ovelha. Material de tecelagem (ainda sem uso).",
		"modelo": "res://assets/models/itens/la/la.glb",
		"cura": 0,
	},
	"presa": {
		"nome": "Presa",
		"descricao": "Presa de javali. Material de forja (ainda sem uso).",
		"modelo": "res://assets/models/itens/presa/presa.glb",
		"cura": 0,
	},
}


static func nome(id: String) -> String:
	return DADOS.get(id, {}).get("nome", id)
