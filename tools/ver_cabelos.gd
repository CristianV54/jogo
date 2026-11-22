extends SceneTree
# Todos os personagens com cabelo, lado a lado, em pleno rolamento: o cabelo tem que acompanhar a cabeça.
const CENAS := ["torin", "brenn", "tessa", "dorn", "orin", "kaelor", "solon"]
var raiz_lista: Array = []
var etapa := 0
var espera := 25
var cam: Camera3D
func _init() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, -30, 0)
	root.add_child(luz)
	for i in CENAS.size():
		var n: Humanoide = load("res://scenes/personagens/%s.tscn" % CENAS[i]).instantiate()
		n.position = Vector3((i - 3) * 1.5, 0, 0)
		root.add_child(n)
		raiz_lista.append(n)
	cam = Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	cam.current = true
func _process(_d: float) -> bool:
	espera -= 1
	if espera > 0:
		return false
	if etapa == 0:
		for n in raiz_lista:
			n.tocar("Roll", 0.0)
			n.animacoes.seek(0.35, true)
		cam.global_position = Vector3(0, 1.2, 7.5)
		cam.look_at(Vector3(0, 0.8, 0))
		espera = 8
		etapa = 1
		return false
	if etapa == 1:
		root.get_viewport().get_texture().get_image().save_png("tools/capturas/cabelos_frente.png")
		cam.global_position = Vector3(7.5, 1.2, 0)
		cam.look_at(Vector3(0, 0.8, 0))
		espera = 8
		etapa = 2
		return false
	root.get_viewport().get_texture().get_image().save_png("tools/capturas/cabelos_lado.png")
	return true
