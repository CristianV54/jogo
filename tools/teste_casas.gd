extends SceneTree
# Teste de física das casas do Refúgio: um corpo do tamanho do jogador (capsula de 0,35 x 1,8 m) tenta
#   1) entrar pela porta (tem que ficar DENTRO da casa) e 2) atravessar a parede lateral (tem que ficar FORA).
#   godot --headless --path . --script res://tools/teste_casas.gd

func _init() -> void:
	_rodar.call_deferred()


func _andar(area: Node3D, ponto_inicial: Vector3, direcao: Vector3, segundos: float, como_jogador := true) -> Vector3:
	var corpo := CharacterBody3D.new()
	if como_jogador:
		corpo.add_to_group("jogador")   # as portas só abrem para o jogador
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	corpo.add_child(cs)
	area.add_child(corpo)
	corpo.global_position = ponto_inicial
	var quadros := int(segundos * 60.0)
	for i in quadros:
		corpo.velocity.x = direcao.x * 4.0
		corpo.velocity.z = direcao.z * 4.0
		corpo.velocity.y = 0.0 if corpo.is_on_floor() else corpo.velocity.y - 20.0 * (1.0 / 60.0)
		corpo.move_and_slide()
		await physics_frame
	var fim := corpo.global_position
	corpo.queue_free()
	return fim


func _rodar() -> void:
	var area: AreaBase = load("res://scenes/areas/refugio_do_pinhal.tscn").instantiate()
	root.add_child(area)
	await create_timer(1.0).timeout
	var falhas := 0
	for nome in ["CasaDoVane", "Forja", "Cabana1", "Cabana2", "Cabana3"]:
		var casa: Node3D = area.get_node(nome)
		var colunas: int = casa.get_meta("colunas")
		var linhas: int = casa.get_meta("linhas")
		var xp: float = casa.get_meta("x_porta")
		var meia_x := colunas * 1.0
		var meia_z := linhas * 1.0
		var t := casa.global_transform
		# 1) pela porta
		var ini := t * Vector3(xp, 0.4, meia_z + 3.0)
		var dir := (t.basis * Vector3(0, 0, -1)).normalized()
		var fim := await _andar(area, ini, dir, 2.6)
		var l := t.affine_inverse() * fim
		var entrou := absf(l.x) < meia_x - 0.2 and absf(l.z) < meia_z - 0.2
		# 1b) porta fechada: quem não é o jogador não passa
		var fim_b := await _andar(area, ini, dir, 2.6, false)
		var barrou_porta := (t.affine_inverse() * fim_b).z > meia_z - 0.2
		# 2) pela parede lateral (meio da lateral +X)
		var ini2 := t * Vector3(meia_x + 3.0, 0.4, 0.0)
		var dir2 := (t.basis * Vector3(-1, 0, 0)).normalized()
		var fim2 := await _andar(area, ini2, dir2, 2.6)
		var l2 := t.affine_inverse() * fim2
		var barrou := l2.x > meia_x - 0.15
		print("CASA ", nome, " ", colunas, "x", linhas, " | porta: fim local (", snapped(l.x, 0.1), ", ", snapped(l.z, 0.1), ") entrou=", entrou,
			" | parede lateral: fim local x=", snapped(l2.x, 0.1), " barrou=", barrou, " | porta fechada barra não-jogador=", barrou_porta)
		if not entrou or not barrou or not barrou_porta:
			falhas += 1
	print("RESULTADO_CASAS ", "OK" if falhas == 0 else "FALHAS %d" % falhas)
	quit(0 if falhas == 0 else 1)
