extends SceneTree
# Fotografa uma arma segurada de 8 jeitos (direção da lâmina x torção do cabo) e imprime o giro de cada um.
# O cabo atravessa o punho paralelo ao eixo Z da mão (medido: nós dos dedos alinhados em Z).
#   godot --path . --resolution 800x600 --script res://tools/calibrar_arma.gd -- cena arma escala cabo_x cabo_y cabo_z   (cabo no espaço da RAIZ da arma)
const PASTA := "tools/capturas/"
const PUNHO := Vector3(-0.017, 0.098, 0.006)   # centro do punho fechado, medido na malha da luva (tools/medir_punho.gd)
var args := OS.get_cmdline_user_args()
var idx := -1
var espera := 30
var cam: Camera3D
var atual: Node3D
var fase := 0
var mao := Vector3.ZERO
var giros: Array = []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	for a in [0.0, 180.0]:   # 0: lâmina fica em -Z da mão; 180: lâmina em +Z da mão
		for t in [0.0, 90.0, 180.0, 270.0]:
			var b := Basis(Vector3(0, 0, 1), deg_to_rad(t)) * Basis(Vector3(1, 0, 0), deg_to_rad(a))
			giros.append(b.get_euler() * 180.0 / PI)
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
	cam.fov = 38
	root.add_child(cam)
	cam.current = true

func _process(_d: float) -> bool:
	espera -= 1
	if espera > 0:
		return false
	if fase == 1:
		var h2: Humanoide = atual
		var esq: Skeleton3D = h2.modelo.find_child("Skeleton3D", true, false)
		mao = esq.global_transform * esq.get_bone_global_pose(esq.find_bone("hand_r")).origin
		cam.global_position = mao + Vector3(0.75, 0.2, 0.9)
		cam.look_at(mao + Vector3(0, 0.15, 0))
		fase = 2
		espera = 6
		return false
	if fase == 2:
		root.get_viewport().get_texture().get_image().save_png(PASTA + "arma_%d.png" % idx)
		print("GIRO ", idx, " = ", giros[idx].snapped(Vector3(0.1, 0.1, 0.1)))
	idx += 1
	if idx >= giros.size():
		return true
	if atual:
		atual.queue_free()
	atual = (load(args[0]) as PackedScene).instantiate()
	(atual as Humanoide).arma_cena = null   # sem a arma que já vem na cena: só o candidato
	root.add_child(atual)
	(atual as Humanoide).equipar_arma(load(args[1]), float(args[2]), giros[idx], PUNHO, Vector3(float(args[3]), float(args[4]), float(args[5])))
	fase = 1
	espera = 8
	return false
