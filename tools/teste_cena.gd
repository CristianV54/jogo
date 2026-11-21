extends SceneTree
# Roteiro automático da cena de teste (precisa de janela, para capturar tela):
#   godot --path . --resolution 1280x720 --script res://tools/teste_cena.gd
# Força a entrada do jogador por código, registra o estado a cada 0,5 s, tira capturas e confere o comportamento.
# As capturas saem de uma câmera lateral só do teste, para o Fagulha aparecer mesmo quando fica atrás da câmera do jogo.

const PASTA := "tools/capturas/"
const FIM := 19.5

var cena: Node
var jog: Jogador
var fag: Fagulha
var cam_jogo: Camera3D
var cam_lateral: Camera3D
var t := 0.0
var proximo_log := 0.0
var vistas := {}              # animações do Fagulha que apareceram
var altura_max_voo := 0.0
var altura_max_no_chao := 0.0  # maior altura enquanto NÃO estava no modo voo (deve ser ~0)
var dist_parado_max := 0.0     # maior distância vista enquanto ele estava em Idle no chão
var z_inicial := 0.0
var feitas := {}
var capturas := {1.0: "1_andando", 4.5: "2_juntos_andando", 8.5: "3_correndo", 11.8: "4_parado", 15.5: "5_voando", 19.0: "6_voando_seguindo"}
var nome_pendente := ""
var espera_frames := 0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	cena = load("res://scenes/teste/cena_teste.tscn").instantiate()
	(cena.get_node("Camera") as CameraTerceiraPessoa).capturar_mouse = false   # o teste não pode prender o mouse
	root.add_child(cena)
	jog = cena.get_node("Jogador")
	fag = cena.get_node("Fagulha")
	cam_jogo = cena.get_node("Camera/Braco/Lente")
	cam_lateral = Camera3D.new()
	cena.add_child(cam_lateral)


func _process(delta: float) -> bool:
	t += delta
	if z_inicial == 0.0:
		z_inicial = jog.global_position.z
	_roteiro()
	_medir()
	_capturar()
	if t >= FIM:
		_resultado()
		return true
	return false


func _roteiro() -> void:
	if t >= 2.0 and not feitas.has("anda"):
		feitas["anda"] = true
		jog.entrada_forcada = Vector2(0, -1)
	if t >= 5.0 and not feitas.has("corre"):
		feitas["corre"] = true
		jog.correndo_forcado = true
	if t >= 9.0 and not feitas.has("para"):
		feitas["para"] = true
		jog.entrada_forcada = Vector2.ZERO
		jog.correndo_forcado = false
	if t >= 13.0 and not feitas.has("voa"):
		feitas["voa"] = true
		fag.modo_voo = true
	if t >= 16.0 and not feitas.has("anda2"):
		feitas["anda2"] = true
		jog.entrada_forcada = Vector2(0, -1)


func _medir() -> void:
	var d := Vector2(fag.global_position.x - jog.global_position.x, fag.global_position.z - jog.global_position.z).length()
	vistas[fag.animacao_atual] = true
	if fag.modo_voo:
		altura_max_voo = max(altura_max_voo, fag.global_position.y)
	else:
		altura_max_no_chao = max(altura_max_no_chao, fag.global_position.y)
		if fag.animacao_atual == "Idle":
			dist_parado_max = max(dist_parado_max, d)
	if t >= proximo_log:
		proximo_log += 0.5
		print("T %4.1f  jog=(%6.1f, %6.1f)  fag=(%6.1f, %4.1f, %6.1f)  dist=%5.2f  anim=%-5s voo=%s  anim_player=%s" % [
			t, jog.global_position.x, jog.global_position.z, fag.global_position.x, fag.global_position.y,
			fag.global_position.z, d, fag.animacao_atual, fag.modo_voo, fag._anim.current_animation if fag._anim else "?"])


func _capturar() -> void:
	if nome_pendente != "":
		espera_frames -= 1
		if espera_frames <= 0:
			root.get_viewport().get_texture().get_image().save_png(PASTA + nome_pendente + ".png")
			print("CAPTURA ", nome_pendente)
			nome_pendente = ""
			cam_jogo.current = true
		return
	for quando in capturas:
		if t >= quando and not feitas.has(quando):
			feitas[quando] = true
			var meio := (jog.global_position + fag.global_position) / 2.0
			cam_lateral.global_position = meio + Vector3(11.0, 3.0, 0.0)
			cam_lateral.look_at(meio + Vector3(0.0, 1.2, 0.0))
			cam_lateral.current = true
			nome_pendente = capturas[quando]
			espera_frames = 3   # a câmera nova só vale nos quadros seguintes
			return


func _resultado() -> void:
	var avancou: float = z_inicial - jog.global_position.z
	var checks := {
		"Fagulha mostrou Idle, Walk, Run e Fly": vistas.has("Idle") and vistas.has("Walk") and vistas.has("Run") and vistas.has("Fly"),
		"Jogador andou para frente (-Z) mais de 30 m": avancou > 30.0,
		"Fagulha parado nunca ficou a mais de 3,5 m": dist_parado_max <= 3.5,
		"Fagulha ficou no chão (y <= 0,01) até o voo": altura_max_no_chao <= 0.01,
		"Fagulha subiu a pelo menos 2,3 m no voo": altura_max_voo >= 2.3,
	}
	print("ANIMACOES_VISTAS ", vistas.keys(), " | altura_max_voo ", snapped(altura_max_voo, 0.01), " | altura_max_no_chao ",
		snapped(altura_max_no_chao, 0.001), " | dist_parado_max ", snapped(dist_parado_max, 0.01), " | jogador_avancou ", snapped(avancou, 0.1))
	var tudo := true
	for nome in checks:
		print("  ", "PASSOU " if checks[nome] else "FALHOU ", nome)
		tudo = tudo and checks[nome]
	print("RESULTADO ", "TUDO PASSOU" if tudo else "HA FALHAS")
