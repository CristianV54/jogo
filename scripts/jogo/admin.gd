class_name Admin
extends Node
## Ferramentas de teste e auditoria, separadas do jogo normal (nó filho do Jogo; não toca no gameplay):
##   F1 a F6   teleporte para cada região (Torin, ou o Drone se estiver ligado), ignorando os bloqueios da história
##   F9        hora: 6h, 12h, 18h, 22h      F10  tempo: limpo, nublado, chuva, tempestade
##   F11       liga e desliga o Drone (câmera livre)

const REGIOES := ["refugio_do_pinhal", "pomar_alto", "bosque_velado", "acampamento_ruptura", "fronteira_ferrogris", "cratera_ignis"]
const HORAS := [6.0, 12.0, 18.0, 22.0]

var jogo: Node
var drone: Drone
var _i_hora := 0
var _i_tempo := 0


func _ready() -> void:
	jogo = get_parent()
	drone = Drone.new()
	jogo.add_child.call_deferred(drone)


func _unhandled_key_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	var tecla: Key = evento.physical_keycode
	var f := tecla - KEY_F1
	if f >= 0 and f < REGIOES.size():
		teleportar(REGIOES[f])
	elif tecla == KEY_F9:
		_i_hora = (_i_hora + 1) % HORAS.size()
		jogo.get("clima").definir_hora(HORAS[_i_hora])
		_msg("Hora: %dh" % int(HORAS[_i_hora]))
	elif tecla == KEY_F10:
		var tempos := [Clima.Tempo.LIMPO, Clima.Tempo.NUBLADO, Clima.Tempo.CHUVA, Clima.Tempo.TEMPESTADE]
		_i_tempo = (_i_tempo + 1) % tempos.size()
		jogo.get("clima").forcar_tempo(tempos[_i_tempo])
		_msg("Tempo: " + Clima.NOMES[tempos[_i_tempo]])
	elif tecla == KEY_F11:
		alternar_drone()


func teleportar(regiao: String) -> void:
	var hud = jogo.get("hud")
	if hud and (hud.dialogo_aberto or jogo.get("jogador").morto):
		return
	if drone.ligado:   # o drone vai por cima da região, sem mexer no Torin
		var c := MundoDados.centro(regiao)
		drone.global_position = Vector3(c.x, 80.0, c.y + 90.0)
		drone.olhar(drone.global_position, Vector3(c.x, 0.0, c.y))
	else:
		jogo.ir_para(regiao, "Principal", true)
	_msg("Teleporte: " + MundoDados.REGIOES[regiao]["nome"])


func alternar_drone() -> void:
	if drone.ligado:
		drone.desligar(jogo)
		_msg("Drone desligado")
	else:
		var jog := jogo.get("jogador") as Node3D
		drone.ligar(jogo, jog.global_position + Vector3(0.0, 40.0, 25.0))
		drone.olhar(drone.global_position, jog.global_position)
		_msg("Drone ligado (WASD, Espaço, C, Shift, mouse; F11 desliga)")


func _msg(texto: String) -> void:
	var hud = jogo.get("hud")
	if hud:
		hud.mensagem(texto, 2.0)
