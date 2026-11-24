extends SceneTree
# Animais colados na cerca e nas casas vagam por 40 s de jogo (tempo acelerado 4x): nenhum pode atravessar.
#   godot --path . --resolution 800x450 --script res://tools/teste_animais_obstaculos.gd
const RAIO_CERCA := 40.0
var area: AreaBase
var violacoes := 0
var amostras := 0
var _animais: Array[AnimalVila] = []


func _init() -> void:
	area = load("res://scenes/areas/refugio_do_pinhal.tscn").instantiate()
	root.add_child(area)
	_rodar.call_deferred()


func _novo(arquivo: String, pos: Vector3) -> void:
	var a := AnimalVila.new()
	a.modelo = load("res://assets/models/criaturas/%s/%s.glb" % [arquivo, arquivo])
	a.raio_vagar = 9.0
	a.velocidade = 2.5
	a.altura_em = area.altura_em
	a.raio_colisao = 0.8
	a.position = Vector3(pos.x, area.altura_em(pos.x, pos.z), pos.z)
	area.add_child(a)
	if _dentro_de_casa(a):   # o ponto de teste caiu dentro de uma construção (o Depósito veio depois deste teste): não vale
		a.free()
		return
	_animais.append(a)


func _dentro_de_casa(a: Node3D) -> bool:
	for no in area.get_children():
		if no.has_meta("colunas"):
			var l: Vector3 = (no as Node3D).to_local(a.global_position)
			if absf(l.x) < float(no.get_meta("colunas")) - 0.5 and absf(l.z) < float(no.get_meta("linhas")) - 0.5:
				return true
	return false


func _rodar() -> void:
	await create_timer(1.0).timeout
	# colados na cerca (lados oeste e sul, sem as saídas norte e leste) e nas paredes de casas
	for k in 6:
		var ang := deg_to_rad(100.0 + k * 28.0)
		_novo("vaca", Vector3(cos(ang), 0.0, sin(ang)) * (RAIO_CERCA - 2.6))
	var casa3: Node3D = area.get_node("Cabana3")   # ovelhas a 1,2 m da fachada (a porta fechada fica no meio)
	var casa1: Node3D = area.get_node("Cabana1")   # porcos a 1,2 m da lateral
	for k in 4:
		_novo("ovelha", casa3.to_global(Vector3((k - 1.5) * 1.8, 0.0, 3.0 + 1.2)))
		_novo("porco", casa1.to_global(Vector3(3.0 + 1.2, 0.0, (k - 1.5) * 1.6)))
	Engine.time_scale = 4.0
	var t := 0.0
	while t < 40.0:
		await create_timer(0.25, true, false, true).timeout
		t += 1.0   # 0,25 s reais a 4x de velocidade = 1 s de jogo
		for no in area.find_children("*", "AnimalVila", false, false):
			var a := no as AnimalVila
			amostras += 1
			var r := Vector2(a.global_position.x, a.global_position.z).length()
			if r > RAIO_CERCA - 0.2 and not (a.global_position.z < 0.0 and absf(a.global_position.x) < 8.0) and not absf(a.global_position.z) < 8.0:   # fora dos vãos dos portões norte, leste e oeste
				violacoes += 1
				print("VIOLACAO cerca: ", a.name, " r=", snapped(r, 0.1))
			elif _dentro_de_casa(a):
				violacoes += 1
				print("VIOLACAO casa: ", a.name, " em ", a.global_position)
	print("AMOSTRAS ", amostras, " | VIOLACOES ", violacoes)
	print("RESULTADO_ANIMAIS ", "OK" if violacoes == 0 and amostras > 0 else "FALHOU")
	quit(0)
