class_name SalvarJogo
extends RefCounted
## SALVAR O JOGO: um arquivo só (user://jogo_salvo.json) com onde o Torin está, a vida, o inventário, a hora do dia e se
## o dragão Cinza já foi domado (e onde ficou). O Jogo grava sozinho a cada 20 s e ao fechar a janela, e lê ao abrir.
## As ferramentas de teste e de foto (rodadas com --script) não leem nem gravam, para um jogo salvo não mudar o teste.

const ARQUIVO := "user://jogo_salvo.json"


static func ativo() -> bool:
	return not OS.get_cmdline_args().has("--script") and not OS.get_cmdline_args().has("-s")


static func gravar(jogo: Jogo, arquivo := ARQUIVO) -> bool:
	if jogo.mundo == null or jogo.jogador.morto:
		return false
	var p: Vector3 = jogo.jogador.global_position
	var dados := {"versao": 1, "pos": [p.x, p.y, p.z], "vida": jogo.jogador.vida, "inventario": jogo.jogador.inventario, "hora": jogo.clima.hora, "cinza_domado": false}
	var cinza: DragaoSelvagem = jogo.mundo.montanha.domavel
	if cinza and cinza.domado:
		dados["cinza_domado"] = true
		dados["cinza_pos"] = [cinza.global_position.x, cinza.global_position.y, cinza.global_position.z]
	var f := FileAccess.open(arquivo, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(dados))
	return true


## Lê o jogo salvo e aplica. Devolve false se não há arquivo (jogo novo) ou se ele está estragado.
static func carregar(jogo: Jogo, arquivo := ARQUIVO) -> bool:
	if not FileAccess.file_exists(arquivo):
		return false
	var lido: Variant = JSON.parse_string(FileAccess.get_file_as_string(arquivo))
	if not (lido is Dictionary) or not (lido as Dictionary).has("pos"):
		return false
	var dados: Dictionary = lido
	var pos: Array = dados["pos"]
	var chao: float = jogo.mundo.chao_em(float(pos[0]), float(pos[2]))
	jogo.jogador.global_position = Vector3(float(pos[0]), maxf(float(pos[1]), chao) + 0.3, float(pos[2]))   # nunca abaixo do chão
	jogo.jogador.velocity = Vector3.ZERO
	jogo.jogador.vida = clampi(int(dados.get("vida", jogo.jogador.vida_max)), 1, jogo.jogador.vida_max)
	jogo.jogador.vida_mudou.emit(jogo.jogador.vida, jogo.jogador.vida_max)
	jogo.jogador.inventario = {}
	var inv: Dictionary = dados.get("inventario", {})
	for item in inv:
		jogo.jogador.inventario[String(item)] = int(inv[item])
	jogo.jogador.inventario_mudou.emit(jogo.jogador.inventario)
	jogo.clima.definir_hora(float(dados.get("hora", 9.0)))
	if bool(dados.get("cinza_domado", false)):
		var cinza: DragaoSelvagem = jogo.mundo.montanha.domavel
		cinza.domar(false)
		var cp: Array = dados.get("cinza_pos", [])
		if cp.size() == 3:
			cinza.global_position = Vector3(float(cp[0]), maxf(float(cp[1]), jogo.mundo.chao_em(float(cp[0]), float(cp[2]))), float(cp[2]))
	return true
