extends SceneTree
# Fotografa uma área de câmeras escolhidas à mão.
#   godot --path . --resolution 1280x720 --script res://tools/ver_area.gd -- res://scenes/areas/x.tscn prefixo "nome:px,py,pz:lx,ly,lz;nome2:..."
const PASTA := "tools/capturas/"
var vistas: Array = []
var etapa := -1
var espera := 40
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
		root.get_viewport().get_texture().get_image().save_png(PASTA + prefixo + "_" + vistas[etapa][0] + ".png")
		print("CAPTURA ", prefixo, "_", vistas[etapa][0])
	etapa += 1
	if etapa >= vistas.size():
		return true
	cam.global_position = vistas[etapa][1]
	cam.look_at(vistas[etapa][2])
	espera = 8
	return false
