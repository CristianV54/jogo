class_name DadosMissoes
extends RefCounted
## Catálogo das missões da campanha (Bíblia de Reino de Cinzas). Só entram aqui missões que o jogo já consegue cumprir.
## Tipos de objetivo: "falar" (alvo = nome do NPC em minúsculas), "golpear", "interagir" e "coletar" (alvo = id do objeto/item).
## Nenhuma missão conclui por proximidade: só por contagem real de eventos.

const CAPITULOS := {1: "Capítulo I: Refúgio do Pinhal"}

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
}
