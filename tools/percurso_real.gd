extends SceneTree
## Agente de percurso real: anda de verdade (W + Shift, sem teleporte entre regiões) do Refúgio ao Castelo, com idas ao Pomar Alto e ao Bosque
## Velado (a Mina é parte do Bosque Velado). Tem watchdog: tempo por trecho, tempo total e detecção de preso (sem avançar 3 m em 6 s, mesmo
## desviando). Grava progresso a cada 15 s e a cada trecho em docs/auditoria/PERCURSO_REAL_PROGRESSO.md e SEMPRE escreve PERCURSO_REAL.md,
## mesmo em falha (REPROVADO, com a coordenada onde parou e uma foto). Checkpoint em tools/capturas/percurso_checkpoint.txt: com
## `-- retomar` o agente recomeça do último trecho concluído (único teleporte permitido, só para retomar).
##   godot --path . --resolution 1280x720 --script res://tools/percurso_real.gd [-- retomar]
const TEMPO_TOTAL := 1500.0     # 25 min
const TEMPO_TRECHO := 90.0
const PROGRESSO := "res://docs/auditoria/PERCURSO_REAL_PROGRESSO.md"
const RELATORIO := "res://docs/auditoria/PERCURSO_REAL.md"
const CHECK := "res://tools/capturas/percurso_checkpoint.txt"

var jogo: Jogo
var jog: Jogador
var problemas: Array = []
var trechos := ""
var regioes := {}          # nome -> {entrada, saida, p0, p1, dist, fps_min, t0, t1, quedas, desvios}
var ordem_regioes: Array = []
var dano_total := 0
var inicio_ms := 0
var reprovado := false
var ultimo_progresso := 0.0
var etapa_atual := ""


func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	(jogo.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false
	root.add_child(jogo)
	_r.call_deferred()


func _tecla(k: Key, apertada: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = apertada
	Input.parse_input_event(ev)


func _toque(k: Key, espera := 0.15) -> void:
	_tecla(k, true)
	await create_timer(0.08).timeout
	_tecla(k, false)
	await create_timer(espera).timeout


func _fechar_dialogos() -> void:
	var g := 0
	while (jogo.hud.dialogo_aberto or not jogo._cena.is_empty()) and g < 80:
		await _toque(KEY_E, 0.2)
		g += 1


## Região onde o Torin está (pela posição; no mundo contínuo o jogo mantém area_nome fixo). Fora das 8 áreas = estrada ou campo.
func _regiao() -> String:
	var p := _pos2()
	for id in MundoDados.REGIOES:
		if MundoDados.retangulo(id).has_point(p):
			return id
	return "estrada_ou_campo"


var lutas := 0


## Bicho ou inimigo a menos de 5 m: para, vira para ele e golpeia (J) até morrer ou 10 s, como um jogador faria. Devolve se lutou.
func _lutar() -> bool:
	var alvo: Node3D = null
	var menor := 5.0
	for n in get_nodes_in_group("inimigos"):
		if is_instance_valid(n) and not n.get("morto") and (n as Node3D).global_position.distance_to(jog.global_position) < menor:
			menor = (n as Node3D).global_position.distance_to(jog.global_position)
			alvo = n
	if alvo == null:
		return false
	lutas += 1
	_tecla(KEY_W, false)
	_tecla(KEY_SHIFT, false)
	var t := 0.0
	while t < 10.0 and is_instance_valid(alvo) and not alvo.get("morto"):
		var d := Vector2(alvo.global_position.x - jog.global_position.x, alvo.global_position.z - jog.global_position.z)
		jogo.camera.yaw = atan2(-d.x, -d.y)
		if d.length() > 2.0:
			_tecla(KEY_W, true)
		else:
			_tecla(KEY_W, false)
		await _toque(KEY_J, 0.45)
		t += 0.55
		if jog.vida < jog.vida_max * 0.4:
			jog.vida = jog.vida_max
	_tecla(KEY_W, false)
	await create_timer(0.5).timeout
	return true


func _agora() -> float:
	return (Time.get_ticks_msec() - inicio_ms) / 1000.0


func _pos2() -> Vector2:
	return Vector2(jog.global_position.x, jog.global_position.z)


func _escrever(caminho: String, texto: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _progresso(estado: String) -> void:
	ultimo_progresso = _agora()
	var md := "# Percurso real: progresso (atualizado a cada 15 s)\n\nEstado: **%s**\nTempo: %.0f s. Etapa: %s. Região: %s. Posição: %s (y=%.1f). fps agora: %d.\n\n" % [estado, _agora(), etapa_atual, _regiao(), _pos2().snapped(Vector2(1, 1)), jog.global_position.y, Engine.get_frames_per_second()]
	md += "| Trecho | Resultado | Tempo | Desvios | Região ao fim | fps |\n|---|---|---|---|---|---|\n" + trechos
	_escrever(PROGRESSO, md)


func _ao_andar(nome_regiao: String, fps: float, dist: float, tempo: float) -> void:
	if not regioes.has(nome_regiao):
		regioes[nome_regiao] = {"entrada": _agora(), "p0": _pos2(), "dist": 0.0, "fps_min": 999.0, "quedas": 0, "desvios": 0, "t_andando": 0.0}
		ordem_regioes.append(nome_regiao)
	var r: Dictionary = regioes[nome_regiao]
	r["saida"] = _agora()
	r["p1"] = _pos2()
	r["dist"] += dist
	r["t_andando"] += tempo
	r["fps_min"] = minf(r["fps_min"], fps)


## Anda até (x,z). Falha se: passar de TEMPO_TRECHO, se ficar 6 s sem avançar 3 m (mesmo desviando), cair do mundo ou estourar o tempo total.
func _ir(alvo: Vector2, nome: String) -> bool:
	etapa_atual = nome
	var t := 0.0
	var desvios := 0
	var marca := jog.global_position
	var t_marca := 0.0
	var desvio_ate := 0.0
	var desvio_yaw := 0.0
	var marca_longa := _pos2()
	var t_longa := 0.0
	var vida_ant := jog.vida
	var motivo := ""
	var ult := _pos2()
	_tecla(KEY_W, true)
	_tecla(KEY_SHIFT, true)
	while true:
		await create_timer(0.1).timeout
		t += 0.1
		var p := _pos2()
		var fps := float(Engine.get_frames_per_second())
		_ao_andar(_regiao(), fps if t > 3.0 else 999.0, p.distance_to(ult), 0.1)
		ult = p
		if p.distance_to(alvo) < 6.0:
			break
		if jog.global_position.y < -20.0:
			motivo = "CAIU do mundo (y=%.1f)" % jog.global_position.y
			regioes[_regiao()]["quedas"] += 1
			break
		if t > TEMPO_TRECHO:
			motivo = "estourou %.0f s no trecho" % TEMPO_TRECHO
			break
		if _agora() > TEMPO_TOTAL:
			motivo = "estourou o tempo total"
			break
		if jog.vida < vida_ant:
			dano_total += vida_ant - jog.vida
		vida_ant = jog.vida
		if jog.vida < jog.vida_max * 0.4:
			jog.vida = jog.vida_max
		if jogo.hud.dialogo_aberto or not jogo._cena.is_empty():
			_tecla(KEY_W, false)
			await _fechar_dialogos()
			_tecla(KEY_W, true)
		if await _lutar():
			_tecla(KEY_W, true)
			_tecla(KEY_SHIFT, true)
			marca = jog.global_position
			t_marca = t
			marca_longa = _pos2()
			t_longa = t
			continue
		var d := alvo - p
		jogo.camera.yaw = desvio_yaw if t < desvio_ate else atan2(-d.x, -d.y)
		if t - t_marca >= 1.2:
			if jog.global_position.distance_to(marca) < 1.0 and t >= desvio_ate:
				desvios += 1
				regioes[_regiao()]["desvios"] += 1
				var lado := 1.0 if desvios % 2 == 1 else -1.0
				desvio_yaw = atan2(-d.x, -d.y) + lado * PI / 2.0
				desvio_ate = t + 1.6
			marca = jog.global_position
			t_marca = t
		if t - t_longa >= 6.0:
			if p.distance_to(marca_longa) < 3.0:
				motivo = "PRESO: menos de 3 m em 6 s (desviou %d vezes)" % desvios
				break
			marca_longa = p
			t_longa = t
		if _agora() - ultimo_progresso >= 15.0:
			_progresso("andando")
	_tecla(KEY_W, false)
	_tecla(KEY_SHIFT, false)
	var ok := motivo == ""
	trechos += "| %s | %s | %.0f s | %d | %s | %d |\n" % [nome, "chegou" if ok else "FALHOU: " + motivo, t, desvios, _regiao(), Engine.get_frames_per_second()]
	if not ok:
		problemas.append("[%s] PROBLEMA em '%s': %s. Parou em %s (alvo %s, a %.0f m dele)." % [_regiao(), nome, motivo, _pos2().snapped(Vector2(1, 1)), alvo, _pos2().distance_to(alvo)])
		RenderingServer.force_draw()
		root.get_viewport().get_texture().get_image().save_png("res://tools/capturas/percurso_falha.png")
	elif desvios >= 6:
		problemas.append("[%s] obs: %d desvios em '%s' (muito obstáculo na rota)" % [_regiao(), desvios, nome])
	_progresso("trecho concluído" if ok else "FALHA")
	return ok


func _fim(chegou_castelo: bool) -> void:
	var seg := _agora()
	var veredito := "PASS" if (not reprovado and chegou_castelo) else "REPROVADO"
	var md := "# Percurso real (agente andando, sem teleporte entre regiões)\n\n**Resultado: %s.** Chegou ao Castelo: **%s**. Duração: %.0f s (%.1f min). Posição final: %s (%s).\n" % [veredito, "SIM" if chegou_castelo else "NÃO", seg, seg / 60.0, _pos2().snapped(Vector2(1, 1)), _regiao()]
	md += "Teclas: W + Shift, E para fechar diálogos; câmera apontada ao próximo ponto; desvio de 90 graus quando fica 1,2 s parado. Dano recebido: %d (a vida era reposta abaixo de 40 %%). Lutas com bicho ou inimigo no caminho: %d.\n" % [dano_total, lutas]
	md += "Limites: %.0f s por trecho, %.0f s no total, reprova se ficar 6 s sem avançar 3 m.\n\n## Por região (a região é a que o jogo reporta no momento em que o Torin está)\n\n" % [TEMPO_TRECHO, TEMPO_TOTAL]
	md += "| Região | Entrada (s) | Saída (s) | Início | Fim | Distância andada | Vel. média | Menor fps | Quedas | Desvios (obstáculos) | Resultado |\n|---|---|---|---|---|---|---|---|---|---|---|\n"
	for nome in ordem_regioes:
		var r: Dictionary = regioes[nome]
		var vel: float = r["dist"] / maxf(r["t_andando"], 0.1)
		var ok_r: bool = r["quedas"] == 0
		md += "| %s | %.0f | %.0f | %s | %s | %.0f m | %.1f m/s | %.0f | %d | %d | %s |\n" % [nome, r["entrada"], r["saida"], (r["p0"] as Vector2).snapped(Vector2(1, 1)), (r["p1"] as Vector2).snapped(Vector2(1, 1)), r["dist"], vel, r["fps_min"], r["quedas"], r["desvios"], "PASS" if ok_r else "FAIL"]
	md += "\n## Trechos\n\n| Trecho | Resultado | Tempo | Desvios | Região ao fim | fps |\n|---|---|---|---|---|---|\n" + trechos
	md += "\n## Problemas e observações\n" + ("\n".join(problemas) if not problemas.is_empty() else "Nenhum.") + "\n"
	md += "\nNão medido por este agente: NPC ou animal preso e erros de console por região (os erros do console são conferidos no log da execução, ver o relatório de estabilização).\n"
	_escrever(RELATORIO, md)
	_progresso("TERMINADO: " + veredito)
	print("PERCURSO ", veredito, " castelo=", chegou_castelo, " problemas=", problemas.size(), " tempo=", seg)
	quit(0)


func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	jog = jogo.jogador
	inicio_ms = Time.get_ticks_msec()
	await create_timer(3.0).timeout
	await _fechar_dialogos()
	jogo.clima.congelado = true
	jogo.clima.definir_hora(10.0)
	var m: GerenciadorMissoes = jogo.missoes
	for id in ["C1-M1", "C1-M2", "C1-M3", "C1-M4", "C2-M1", "C2-M2", "C2-M3", "C2-M4", "C3-M1", "C3-M2", "C3-M3", "C3-M4", "C4-M1", "C4-M2", "C4-M3", "C4-M4", "C5-M1"]:   # C5-M1 abre o portão do Castelo
		if not m.concluidas.has(id):
			m.concluidas.append(id)
	m.ativas.clear()
	m.quadro_liberado = true
	jogo.liberar_fagulha()
	for k in ["gorath", "kaelor", "ignis"]:
		jogo.derrotados[k] = true
	# portões que só abrem quando um chefe cai (o agente não luta com chefes): abertos como estariam no fim da campanha
	jogo.mundo.regioes["fronteira_ferrogris"].portao_fundos.abrir()
	jogo.mundo.regioes["castelo_imperial"].portao_salao.abrir()
	var rota: Array = [
		["Refúgio -> saída oeste (desvia do curral)", Vector2(-22, -2)], ["Portão oeste da palicada", Vector2(-48, 0)], ["Estrada do Pomar (início)", Vector2(-160, 0)], ["Estrada do Pomar (meio)", Vector2(-330, -20)], ["Pomar Alto (centro)", Vector2(-420, -125)],
		["Pomar -> volta ao Refúgio", Vector2(-250, 15)], ["Portão oeste (volta)", Vector2(-48, 0)], ["Refúgio (centro) 1", Vector2(-10, 0)],
		["Contorna a casa do Vane pelo oeste", Vector2(-9, -20)], ["Atrás da casa do Vane", Vector2(-9, -35)], ["Portão norte da palicada", Vector2(0, -43)], ["Refúgio -> Trilha do Bosque", Vector2(0, -160)], ["Bosque Velado (entrada)", Vector2(0, -390)], ["Bosque Velado e Mina (centro)", Vector2(0, -550)],
		["Bosque -> volta ao Refúgio", Vector2(0, -160)], ["Portão norte (volta)", Vector2(0, -43)], ["Atrás da casa do Vane (volta)", Vector2(-9, -35)], ["Refúgio (centro) 2", Vector2(-9, -4)], ["Portão leste da palicada", Vector2(44, -3)],
		["Refúgio -> Campos Altos", Vector2(160, 0)], ["Barreira da Ruptura (antes do vão)", Vector2(316, 0)], ["Barreira da Ruptura (depois do vão)", Vector2(344, -2)], ["Campos Altos (meio)", Vector2(420, -40)], ["Ruptura (entrada)", Vector2(560, -195)], ["Acampamento da Ruptura (centro)", Vector2(560, -330)],
		["Ruptura -> Caminho da Ruptura", Vector2(584, -465)], ["Ferrogris (entrada)", Vector2(584, -685)], ["Ferrogris: antes da Brecha", Vector2(579, -734)], ["Ferrogris: depois da Brecha", Vector2(579, -752)], ["Fortaleza de Ferrogris (centro)", Vector2(584, -840)],
		["Ferrogris -> Estrada Queimada", Vector2(584, -995)], ["Cratera (entrada)", Vector2(584, -1205)], ["Cratera de Ignis (centro)", Vector2(584, -1360)],
		["Cratera: contorna o centro das forjas", Vector2(592, -1380)], ["Cratera: depois das forjas", Vector2(592, -1402)], ["Cratera -> Estrada Imperial", Vector2(584, -1515)], ["Valdoria (entrada)", Vector2(584, -1725)], ["Valdoria (centro)", Vector2(584, -1880)],
		["Valdoria: contorna a fonte", Vector2(593, -1880)], ["Valdoria: pé da escadaria", Vector2(584, -1960)], ["Escadaria de Valdoria (alto)", Vector2(584, -2012)], ["Viaduto (fim)", Vector2(584, -2160)],
		["Portão do Castelo", Vector2(584, -2194)], ["Castelo Imperial (centro)", Vector2(584, -2300)],
	]
	var inicio_idx := 0
	if OS.get_cmdline_user_args().has("retomar") and FileAccess.file_exists(CHECK):
		inicio_idx = int(FileAccess.get_file_as_string(CHECK).strip_edges()) + 1
		if inicio_idx > 0 and inicio_idx < rota.size():
			var ant: Vector2 = rota[inicio_idx - 1][1]
			# único teleporte: retomar do checkpoint. A região de destino pode estar desligada (longe do Torin ela fica sem chão sólido):
			# primeiro liga o que está em volta do ponto, espera a física enxergar o chão e só então pousa (como o Jogo.ir_para faz)
			jog.set_physics_process(false)
			jog.global_position = Vector3(ant.x, jogo.mundo.chao_em(ant.x, ant.y) + 0.5, ant.y)
			jogo.mundo.atualizar_atividade()
			await create_timer(1.0).timeout
			jog.global_position = Vector3(ant.x, jogo.mundo.chao_em(ant.x, ant.y) + 0.5, ant.y)
			jog.velocity = Vector3.ZERO
			jog.set_physics_process(true)
			await create_timer(5.0).timeout
			trechos += "| (retomada do checkpoint %d) | teleporte de retomada | 0 s | 0 | %s | 0 |\n" % [inicio_idx - 1, _regiao()]
	_progresso("começou")
	var chegou := false
	for i in range(inicio_idx, rota.size()):
		var ok: bool = await _ir(rota[i][1], rota[i][0])
		if not ok:
			reprovado = true
			break
		_escrever(CHECK, str(i))
		if i == rota.size() - 1:
			chegou = true
	_fim(chegou)
