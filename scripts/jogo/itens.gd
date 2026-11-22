class_name Itens
extends RefCounted
## Catálogo dos itens do jogo: nome, descrição, modelo 3D (usado no chão e no ícone do inventário) e efeito.
## `cura` > 0: o item é comestível e recupera essa vida ao ser usado.

const ORDEM := ["carne", "couro", "la", "presa"]

const DADOS := {
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
