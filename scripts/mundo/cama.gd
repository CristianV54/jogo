class_name Cama
extends Interagivel
## Cama de uma casa. O Torin dorme nela (E): a tela escurece, o tempo passa até as 6h30 da manhã seguinte e a vida volta
## ao máximo. Os NPCs usam a mesma cama para dormir à noite e quando chove (ver `Npc`): `dono` guarda quem a ocupa.

var dono := ""
var _fade: ColorRect


func _ready() -> void:
	super()
	texto = "Dormir até de manhã"
	raio = 2.6
	uma_vez = false


func _ao_acionar() -> void:
	var jogo := get_tree().get_first_node_in_group("jogo")
	if jogo == null:
		return
	var jogador: Jogador = jogo.get("jogador")
	var clima: Clima = jogo.get("clima")
	if jogador == null or clima == null or jogador.travado:
		return
	jogador.travado = true
	var camada := CanvasLayer.new()
	camada.layer = 90
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(_fade)
	get_tree().root.add_child(camada)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 1.0)
	tw.tween_callback(func() -> void:
		clima.definir_hora(6.5)
		clima.forcar_tempo(Clima.Tempo.LIMPO)
		jogador.vida = jogador.vida_max
		jogador.vida_mudou.emit(jogador.vida, jogador.vida_max))
	tw.tween_interval(0.8)
	tw.tween_property(_fade, "color:a", 0.0, 1.0)
	tw.tween_callback(func() -> void:
		jogador.travado = false
		camada.queue_free()
		var hud = jogo.get("hud")
		if hud:
			hud.mensagem("Você dormiu bem. Amanheceu.", 3.0))
