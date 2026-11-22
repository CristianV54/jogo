extends SceneTree
# Com a orientação da lâmina já escolhida, varre o ponto do punho (x e y no espaço de hand_r) e fotografa de 2 ângulos.
#   godot --path . --resolution 700x500 --script res://tools/calibrar_punho.gd -- cena arma escala centro_cabo gx gy gz
const PASTA := "tools/capturas/"
var args := OS.get_cmdline_user_args()
var xs := [float(OS.get_cmdline_user_args()[7])]
var ys := [float(OS.get_cmdline_user_args()[8])]
const VISTAS := [Vector3(0.45, 0.12, 0.55), Vector3(0.7, 0.1, 0.0), Vector3(-0.45, 0.12, -0.5), Vector3(0.15, 0.75, 0.15)]
var combos: Array = []
var idx := -1
var espera := 30
var fase := 0
var vista := 0
var atual: Node3D
var cam: Camera3D
var mao := Vector3.ZERO

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	for y in ys:
		for x in xs:
			combos.append(Vector3(x, y, 0.0))
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
	cam.fov = 28
	root.add_child(cam)
	cam.current = true

func _process(_d: float) -> bool:
	espera -= 1
	if espera > 0:
		return false
	if fase == 1:   # posiciona a câmera na vista atual
		var h: Humanoide = atual
		var esq: Skeleton3D = h.modelo.find_child("Skeleton3D", true, false)
		mao = esq.global_transform * esq.get_bone_global_pose(esq.find_bone("hand_r")).origin
		cam.global_position = mao + VISTAS[vista]
		cam.look_at(mao + Vector3(0, 0.05, 0), Vector3.UP if vista != 3 else Vector3(0, 0, -1))
		fase = 2
		espera = 5
		return false
	if fase == 2:
		root.get_viewport().get_texture().get_image().save_png(PASTA + "punho_%d_%d.png" % [idx, vista])
		if vista < VISTAS.size() - 1:
			vista += 1
			fase = 1
			espera = 3
			return false
		print("PUNHO ", idx, " = ", combos[idx])
	idx += 1
	vista = 0
	if idx >= combos.size():
		return true
	if atual:
		atual.queue_free()
	atual = (load(args[0]) as PackedScene).instantiate()
	(atual as Humanoide).arma_cena = null
	root.add_child(atual)
	var arma_inst: Node3D = (atual as Humanoide).equipar_arma(load(args[1]), float(args[2]), Vector3(float(args[4]), float(args[5]), float(args[6])), combos[idx], Vector3(0, float(args[3]), 0))
	var marca := MeshInstance3D.new()   # bolinha vermelha no centro do punho calculado
	var esf := SphereMesh.new()
	esf.radius = 0.012
	esf.height = 0.024
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(1, 0, 0)
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.no_depth_test = true
	esf.material = mm
	marca.mesh = esf
	marca.position = combos[idx]
	arma_inst.get_parent().add_child(marca)
	var azul := MeshInstance3D.new()   # bolinha azul: onde eu acho que é o centro do cabo, filha da espada
	var esf2 := SphereMesh.new()
	esf2.radius = 0.012
	esf2.height = 0.024
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = Color(0, 0.3, 1)
	m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m2.no_depth_test = true
	esf2.material = m2
	azul.mesh = esf2
	azul.position = Vector3(0, float(args[3]), 0)
	arma_inst.add_child(azul)
	print("MARCADORES vermelho_mundo=", marca.global_position, " azul_mundo=", azul.global_position, " sword_origin=", arma_inst.global_position)
	fase = 1
	espera = 8
	return false
