extends SceneTree
# Fotografa um personagem em vários ângulos, inclusive rente ao piso, e mede altura e pés.
#   godot --path . --resolution 1024x768 --script res://tools/ver_personagem.gd -- res://scenes/personagens/torin.tscn Idle_Loop torin
# Saída: tools/capturas/<nome>_<vista>.png e linhas ALTURA_M / PE_Y_MIN no log.

const PASTA := "tools/capturas/"
var VISTAS := []

var raiz: Node3D
var cam: Camera3D
var nome := ""
var etapa := -1
var espera := 8
var t := 0.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena_caminho: String = args[0]
	nome = args[1]
	var d := float(args[2])
	var ya := float(args[3])
	var sem_chao := args.size() > 4 and args[4] == "semchao"   # áreas já têm céu, sol e chão próprios
	VISTAS = [["frente", 0.0, ya + 2.0, d, ya], ["lado", 90.0, ya + 2.0, d, ya], ["costas", 180.0, ya + 2.0, d, ya],
		["tres_quartos", 40.0, ya + d * 0.5, d, ya], ["alto", 20.0, d * 1.1, d * 0.3, 0.0]]
	DirAccess.make_dir_recursive_absolute(PASTA)

	if not sem_chao:
		_ambiente_de_teste()
	raiz = load(cena_caminho).instantiate()
	root.add_child(raiz)
	cam = Camera3D.new()
	cam.fov = 55
	cam.far = 1500.0
	root.add_child(cam)
	cam.current = true
	await process_frame
	await process_frame
	_medir()


func _ambiente_de_teste() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment = e
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, -30, 0)
	luz.shadow_enabled = true
	root.add_child(luz)
	# chão com um quadrado de 1 m de lado desenhado em cada metro, para dar escala
	var chao := MeshInstance3D.new()   # chão de referência
	var plano := PlaneMesh.new()
	plano.size = Vector2(20, 20)
	chao.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.5, 0.38)
	chao.material_override = mat
	root.add_child(chao)
	for i in range(-3, 4):
		var marca := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(0.04, 0.02, 6.0)
		marca.mesh = caixa
		marca.position = Vector3(i, 0.01, 0)
		var m2 := StandardMaterial3D.new()
		m2.albedo_color = Color(0.9, 0.9, 0.9)
		marca.material_override = m2
		root.add_child(marca)



func _medir() -> void:
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = mi.global_transform * mi.get_aabb()
		mn = mn.min(a.position)
		mx = mx.max(a.position + a.size)
	print("ALTURA_M ", snapped(mx.y - mn.y, 0.01), " | PE_Y_MIN ", snapped(mn.y, 0.001), " | LARGURA_M ", snapped(mx.x - mn.x, 0.01),
		" | PROFUNDIDADE_M ", snapped(mx.z - mn.z, 0.01))


func _process(delta: float) -> bool:
	t += delta
	if t < 0.3:
		return false
	espera -= 1
	if espera > 0:
		return false
	if etapa >= 0:
		var v = VISTAS[etapa]
		root.get_viewport().get_texture().get_image().save_png(PASTA + nome + "_" + v[0] + ".png")
		print("CAPTURA ", nome, "_", v[0])
	etapa += 1
	if etapa >= VISTAS.size():
		return true
	var v = VISTAS[etapa]
	var ang := deg_to_rad(v[1])
	var alvo := Vector3(0, v[4], 0)
	cam.global_position = Vector3(sin(ang) * v[3], v[2], cos(ang) * v[3])
	cam.look_at(alvo)
	espera = 6
	return false
