extends SceneTree
# Fotografa uma arma na mão direita com 8 giros diferentes, para escolher o certo olhando.
#   godot --path . --resolution 800x600 --script res://tools/calibrar_arma.gd -- res://scenes/personagens/torin.tscn res://assets/models/armas/shortsword.glb 0.25
const PASTA := "tools/capturas/"
const GIROS := [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(-90, 0, 0), Vector3(0, 0, 90), Vector3(0, 0, -90), Vector3(180, 0, 0), Vector3(0, 90, 0), Vector3(0, -90, 0)]
var args := OS.get_cmdline_user_args()
var idx := -1
var espera := 30
var cam: Camera3D
var atual: Node3D
var fase := 0
var mao := Vector3.ZERO
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.7, 0.72, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment = e
	root.add_child(env)
	cam = Camera3D.new()
	cam.fov = 40
	root.add_child(cam)
	cam.current = true
func _montar(giro: Vector3) -> void:
	if atual:
		atual.queue_free()
	atual = (load(args[0]) as PackedScene).instantiate()
	root.add_child(atual)
func _process(_d: float) -> bool:
	espera -= 1
	if espera > 0:
		return false
	if fase == 1:   # a animação já rodou: agora a mão está onde está de verdade
		var h2: Humanoide = atual
		var esq2: Skeleton3D = h2.modelo.find_child("Skeleton3D", true, false)
		mao = esq2.global_transform * esq2.get_bone_global_pose(esq2.find_bone("hand_r")).origin
		cam.global_position = mao + Vector3(0.7, 0.35, 1.1)
		cam.look_at(mao)
		fase = 2
		espera = 6
		return false
	if fase == 2:
		root.get_viewport().get_texture().get_image().save_png(PASTA + "arma_%d.png" % idx)
		print("CAPTURA arma_", idx, " mao ", mao)
	idx += 1
	if idx >= GIROS.size():
		return true
	_montar(GIROS[idx])
	var h: Humanoide = atual
	h.equipar_arma(load(args[1]), float(args[2]), GIROS[idx], Vector3.ZERO)
	fase = 1
	espera = 8
	return false
