extends SceneTree
## Abre o jogo normal (janela jogável) com um lobo a 4 m do Torin. Não fecha sozinho.
##   godot --path . --resolution 1280x720 --script res://tools/abrir_com_lobo.gd
var jogo: Jogo
func _init() -> void:
	jogo = load("res://scenes/jogo.tscn").instantiate()
	root.add_child(jogo)
	_r.call_deferred()
func _r() -> void:
	while jogo.area_nome != "refugio_do_pinhal" or jogo._trocando:
		await create_timer(0.3).timeout
	await create_timer(2.5).timeout
	var jog: Jogador = jogo.jogador
	var lobo := (load("res://scenes/inimigos/lobo.tscn") as PackedScene).instantiate() as Inimigo
	jogo.mundo.add_child(lobo)
	var p := jog.global_position + Vector3(4.0, 0.0, 0.0)
	lobo.global_position = Vector3(p.x, jogo.mundo.chao_em(p.x, p.z) + 0.3, p.z)
	lobo.set_physics_process(false)   # parado para a foto: lobo e Torin lado a lado, de frente para o mesmo lado
	jogo.camera.yaw = atan2(0.0, 1.0)
	await create_timer(1.5).timeout
	RenderingServer.force_draw()
	root.get_viewport().get_texture().get_image().save_png("res://tools/capturas/lobo_corrigido_jogo.png")
	lobo.set_physics_process(true)
