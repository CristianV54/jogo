class_name Sons
extends Node
## O SOM DO JOGO. Filho do Jogo; só observa (jogador, clima, mundo) e toca: não muda nada no jogo.
##   - efeitos: passos (terra fora da cidade, pedra dentro da muralha), casco do cavalo, asa do dragão em voo, espada no
##     ar, acerto, dano, morte, pegar item, rugido ao domar, aviso do tubarão;
##   - ambiente em laço: vento (mais forte no alto), mar (perto da costa), grilos (de noite) e pássaros soltos (de dia);
##   - música de fundo em laço, baixa.
## Os arquivos são gerados por `tools/audio/gerar_sons.py` (síntese; ver assets/ASSETS.md). `tocados` conta cada efeito
## que saiu, para os testes. Outros sistemas pedem um efeito por grupo: get_tree().call_group("sons", "tocar", "rugido").

const PASTA := "res://assets/audio/"
const EFEITOS := ["passo_terra_0", "passo_terra_1", "passo_terra_2", "passo_pedra_0", "passo_pedra_1", "passo_pedra_2", "casco", "golpe", "acerto", "dano", "coletar", "morte", "aviso", "asa", "rugido", "passaro_0", "passaro_1", "passaro_2"]
const LACOS := {"vento": -20.0, "mar": -60.0, "grilos": -60.0, "musica": -17.0}   # volume inicial em dB (-60 = calado)

var jogo: Jogo
var tocados := {}
var _amostras := {}
var _vozes: Array[AudioStreamPlayer] = []
var _voz := 0
var _lacos := {}
var _t_passo := 0.0
var _t_passaro := 4.0
var _vida_antes := -1
var _golpeando_antes := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("sons")
	for nome in EFEITOS:
		_amostras[nome] = load(PASTA + nome + ".wav")
	for k in 6:
		var v := AudioStreamPlayer.new()
		add_child(v)
		_vozes.append(v)
	for nome in LACOS:
		var fluxo := (load(PASTA + String(nome) + ".wav") as AudioStreamWAV).duplicate() as AudioStreamWAV
		fluxo.loop_mode = AudioStreamWAV.LOOP_FORWARD
		fluxo.loop_begin = 0
		fluxo.loop_end = fluxo.data.size() / 2   # 16 bits, mono: duas posições por amostra
		var p := AudioStreamPlayer.new()
		p.name = String(nome).capitalize()
		p.stream = fluxo
		p.volume_db = float(LACOS[nome])
		add_child(p)
		p.play()
		_lacos[nome] = p
	jogo.jogador.vida_mudou.connect(_ao_mudar_vida)
	jogo.jogador.morreu.connect(tocar.bind("morte"))
	jogo.jogador.item_coletado.connect(func(_i: String, _q: int, _inv: Dictionary) -> void: tocar("coletar", -8.0))
	jogo.jogador.acertou.connect(tocar.bind("acerto"))


## Toca um efeito uma vez. `tom` varia a altura (1 = como gravado).
func tocar(nome: String, volume_db := 0.0, tom := 1.0) -> void:
	if not _amostras.has(nome):
		push_warning("Sons: efeito desconhecido " + nome)
		return
	var v := _vozes[_voz]
	_voz = (_voz + 1) % _vozes.size()
	v.stream = _amostras[nome]
	v.volume_db = volume_db
	v.pitch_scale = tom
	v.play()
	tocados[nome] = int(tocados.get(nome, 0)) + 1


func _ao_mudar_vida(atual: int, _maximo: int) -> void:
	if _vida_antes >= 0 and atual < _vida_antes and atual > 0:
		tocar("dano")
	_vida_antes = atual


func _process(delta: float) -> void:
	var j := jogo.jogador
	if jogo.mundo == null or j == null:
		return
	var golpeando := j.animacao_atual == "Sword_Attack"   # a espada corta o ar no começo do golpe
	if golpeando and not _golpeando_antes:
		tocar("golpe", -4.0, _rng.randf_range(0.92, 1.1))
	_golpeando_antes = golpeando
	_passos(j, delta)
	_ambiente(j, delta)


## Passos a pé, cascos a cavalo, asas no dragão em voo: o ritmo acompanha a velocidade.
func _passos(j: Jogador, delta: float) -> void:
	var rapidez := Vector2(j.velocity.x, j.velocity.z).length()
	_t_passo -= delta
	if _t_passo > 0.0 or j.morto:
		return
	if j.montaria and j.montaria.voa and not j.is_on_floor():
		tocar("asa", -6.0, _rng.randf_range(0.9, 1.05))
		_t_passo = 0.85
	elif rapidez > 1.0 and j.is_on_floor():
		if j.montaria:
			tocar("casco", -7.0, _rng.randf_range(0.9, 1.1))
			_t_passo = clampf(2.2 / rapidez, 0.16, 0.5)
		else:
			var piso := "pedra" if MundoDados.ate_a_muralha(j.global_position.x, j.global_position.z) < 0.0 else "terra"
			tocar("passo_%s_%d" % [piso, _rng.randi() % 3], -10.0, _rng.randf_range(0.92, 1.08))
			_t_passo = clampf(1.9 / rapidez, 0.26, 0.55)


## Vento mais forte no alto; mar só perto da costa; grilos de noite; pássaros soltos de dia, longe do mar.
func _ambiente(j: Jogador, delta: float) -> void:
	var p := j.global_position
	var noite: bool = jogo.clima.eh_noite()
	var costa := Costa.distancia(p.x, p.z)
	_levar("vento", -22.0 + clampf(p.y / 12.0, 0.0, 14.0), delta)
	_levar("mar", lerpf(-8.0, -60.0, clampf(costa / 160.0, 0.0, 1.0)), delta)
	_levar("grilos", -22.0 if noite and costa > 60.0 else -60.0, delta)
	_t_passaro -= delta
	if _t_passaro <= 0.0:
		_t_passaro = _rng.randf_range(3.0, 9.0)
		if not noite and costa > 80.0 and MundoDados.ate_a_muralha(p.x, p.z) > 20.0:
			tocar("passaro_%d" % (_rng.randi() % 3), _rng.randf_range(-22.0, -14.0), _rng.randf_range(0.9, 1.15))


func _levar(nome: String, alvo_db: float, delta: float) -> void:
	var p: AudioStreamPlayer = _lacos[nome]
	p.volume_db = move_toward(p.volume_db, alvo_db, 18.0 * delta)
