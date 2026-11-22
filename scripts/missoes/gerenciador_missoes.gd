class_name GerenciadorMissoes
extends Node
## Rastreia as missões: quais estão ativas, o progresso de cada objetivo e as recompensas. Qualquer parte do jogo avisa
## o que aconteceu com `GerenciadorMissoes.evento("golpear", "boneco_treino")`; quando todos os objetivos chegam à
## quantidade pedida, a missão conclui, entrega a recompensa e avisa a interface por sinal.

signal missao_iniciada(id: String)
signal objetivo_atualizado(id: String)
signal missao_concluida(id: String)
signal aviso(texto: String, segundos: float)

static var instancia: GerenciadorMissoes

var ativas: Array[String] = []
var concluidas: Array[String] = []
var progresso := {}                 # "missao|objetivo" -> quantidade feita
var jogador: Jogador                # recebe as recompensas
var quadro_liberado := false


func _ready() -> void:
	instancia = self


static func evento(tipo: String, alvo: String, quantidade := 1) -> void:
	if instancia:
		instancia._registrar(tipo, alvo, quantidade)


func iniciar(id: String) -> void:
	if ativas.has(id) or concluidas.has(id) or not DadosMissoes.MISSOES.has(id):
		return
	ativas.append(id)
	missao_iniciada.emit(id)
	aviso.emit("Missão: %s" % DadosMissoes.MISSOES[id]["titulo"], 3.0)


func _registrar(tipo: String, alvo: String, quantidade: int) -> void:
	for id in ativas.duplicate():
		for obj in DadosMissoes.MISSOES[id]["objetivos"]:
			if obj["tipo"] != tipo or not _combina(obj["alvo"], alvo):
				continue
			var chave := "%s|%s" % [id, obj["id"]]
			var antes := int(progresso.get(chave, 0))
			progresso[chave] = mini(int(obj["qtd"]), antes + quantidade)
			if int(progresso[chave]) != antes:
				objetivo_atualizado.emit(id)
		if _completa(id):
			_concluir(id)


## O alvo do objetivo pode ser um texto ou uma lista de textos ("couro" ou "presa").
func _combina(esperado: Variant, alvo: String) -> bool:
	return alvo in esperado if esperado is Array else esperado == alvo


## A missão pode começar agora? (sem outra ativa e com a anterior concluída)
func pode_iniciar(id: String) -> bool:
	if not DadosMissoes.MISSOES.has(id) or ativas.has(id) or concluidas.has(id) or not ativas.is_empty():
		return false
	var requer: String = DadosMissoes.MISSOES[id].get("requer", "")
	return requer == "" or concluidas.has(requer)


func feito(id: String, objetivo: String) -> int:
	return int(progresso.get("%s|%s" % [id, objetivo], 0))


func _completa(id: String) -> bool:
	for obj in DadosMissoes.MISSOES[id]["objetivos"]:
		if feito(id, obj["id"]) < int(obj["qtd"]):
			return false
	return true


func _concluir(id: String) -> void:
	var dados: Dictionary = DadosMissoes.MISSOES[id]
	ativas.erase(id)
	concluidas.append(id)
	var recompensa: Dictionary = dados["recompensa"]
	for item in recompensa.get("itens", {}):
		if jogador:
			jogador.coletar(item, int(recompensa["itens"][item]))
	if id == "C1-M1":
		quadro_liberado = true
	missao_concluida.emit(id)
	aviso.emit("Missão concluída: %s\n%s" % [dados["titulo"], dados["encerramento"]], 7.0)
	for outra in DadosMissoes.MISSOES:   # missões que começam sozinhas depois desta
		if DadosMissoes.MISSOES[outra].get("auto_apos", "") == id:
			get_tree().create_timer(6.0).timeout.connect(iniciar.bind(outra))   # deixa ler o encerramento antes


## Texto do rastreador na tela: a primeira missão ativa, com contadores.
func rastreador() -> String:
	if ativas.is_empty():
		return ""
	var id := ativas[0]
	var dados: Dictionary = DadosMissoes.MISSOES[id]
	var linhas: Array[String] = [String(dados["titulo"])]
	for obj in dados["objetivos"]:
		var f := feito(id, obj["id"])
		var q := int(obj["qtd"])
		var marca := "[x]" if f >= q else "[ ]"
		linhas.append("%s %s%s" % [marca, obj["texto"], " (%d/%d)" % [f, q] if q > 1 else ""])
	return "\n".join(linhas)


## Falas do NPC que dependem da missão ativa (vazio = usa as falas normais).
func dialogo_de(npc: String) -> PackedStringArray:
	for id in ativas:
		var d: Dictionary = DadosMissoes.MISSOES[id].get("dialogos", {})
		if d.has(npc):
			return PackedStringArray(d[npc])
	return PackedStringArray()


## Ler o quadro de avisos da praça: oferece o próximo serviço do capítulo, na ordem.
func ler_quadro() -> void:
	if not quadro_liberado:
		aviso.emit("O quadro está cheio de avisos que você ainda não pode atender. Termine a Rotina do Exílio.", 4.0)
		return
	if not ativas.is_empty():
		aviso.emit("Você já tem um serviço em andamento: %s." % DadosMissoes.MISSOES[ativas[0]]["titulo"], 3.0)
		return
	for id in DadosMissoes.ORDEM_CAP1:
		if not concluidas.has(id):
			iniciar(id)
			return
	aviso.emit("Nenhum aviso novo por enquanto.", 3.0)


## O jogador tenta entregar ao NPC `alvo` o que alguma missão ativa pede (maçãs à Mara, carne à Fagulha).
## Gasta o item do inventário e conta para o objetivo. Devolve true se algo foi entregue.
func tentar_entrega(alvo: String) -> bool:
	for id in ativas.duplicate():
		for obj in DadosMissoes.MISSOES[id]["objetivos"]:
			if obj["tipo"] != "entregar" or obj["alvo"] != alvo:
				continue
			var faltam := int(obj["qtd"]) - feito(id, obj["id"])
			if faltam <= 0 or jogador == null:
				continue
			var item: String = obj["item"]
			var tenho := int(jogador.inventario.get(item, 0))
			if tenho <= 0:
				aviso.emit("Você precisa de %s para isso." % Itens.nome(item), 2.5)
				return false
			var dar := mini(tenho, faltam)
			jogador.gastar_item(item, dar)
			aviso.emit("Entregou %d %s." % [dar, Itens.nome(item)], 2.0)
			_registrar("entregar", alvo, dar)
			return true
	return false
