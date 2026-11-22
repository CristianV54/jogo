extends SceneTree
# Fotografa uma área de câmeras escolhidas à mão.
#   godot --path . --resolution 1280x720 --script res://tools/ver_area.gd -- res://scenes/areas/x.tscn prefixo "nome:px,py,pz:lx,ly,lz;nome2:..."
const PASTA := "tools/capturas/"
var vistas: Array = []
var etapa := -1
var espera := 150
var cam: Camera3D
var prefixo := ""
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	prefixo = args[1]
	for v in String(args[2]).split(";"):
		var partes := v.split(":")
		var p := partes[1].split(",")
		var l := partes[2].split(",")
		vistas.append([partes[0], Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(l[0]), float(l[1]), float(l[2]))])
	DirAccess.make_dir_recursive_absolute(PASTA)
	if args.size() > 3 and args[3] == "comluz":   # cenas de teste sem céu nem sol próprios
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.7, 0.75, 0.8)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.55, 0.55, 0.58)
		env.environment = e
		root.add_child(env)
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = Vector3(-45, -30, 0)
		luz.shadow_enabled = true
		root.add_child(luz)
		var chao := MeshInstance3D.new()
		var plano := PlaneMesh.new()
		plano.size = Vector2(60, 60)
		chao.mesh = plano
		var mt := StandardMaterial3D.new()
		mt.albedo_color = Color(0.4, 0.5, 0.35)
		chao.material_override = mt
		root.add_child(chao)
	var area: Node = load(args[0]).instantiate()
	root.add_child(area)
	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 1500.0
	root.add_child(cam)
	cam.current = true
func _process(_d: float) -> bool:
	espera -= 1
	if espera > 0:
		return false
	if etapa >= 0:
		RenderingServer.force_draw()
		root.get_viewport().get_texture().get_image().save_png(PASTA + prefixo + "_" + vistas[etapa][0] + ".png")
		print("CAPTURA ", prefixo, "_", vistas[etapa][0])
	etapa += 1
	if etapa >= vistas.size():
		return true
	cam.global_position = vistas[etapa][1]
	cam.look_at(vistas[etapa][2])
	espera = 30
	return false
